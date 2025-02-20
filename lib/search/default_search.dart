import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:algolia_helper_flutter/algolia_helper_flutter.dart';
import 'package:gym_buddy/auth/secrets.dart' as secrets;
import 'package:circular_buffer/circular_buffer.dart';
import 'package:gym_buddy/consts/common_consts.dart';
import 'package:rxdart/rxdart.dart';
import 'package:image_fade/image_fade.dart';
import 'dart:async';

final FirebaseFirestore db = FirebaseFirestore.instance;

typedef UserData = ({String profilePicUrl, String displayUsername, String username});

final hitsSearcherUser = HitsSearcher(
  applicationID: secrets.Algolia.applicationID,
  apiKey: secrets.Algolia.searchAPIKey,
  indexName: secrets.Algolia.indexNameUsers,
);

final hitsSearcherUserSettings = HitsSearcher(
  applicationID: secrets.Algolia.applicationID,
  apiKey: secrets.Algolia.searchAPIKey,
  indexName: secrets.Algolia.indexNameUserSettings,
);

/// A circular queue (buffer) acts as a cache that holds the previous queires
/// and their associated hits plus some metadata about the users
class HitCache {
  final CircularBuffer<Map<String, dynamic>> _cache;

  HitCache({required cache}) : _cache = cache;

  /// Adds an entry to the cache if not already present.
  /// An entry is in the form {searchQuery: listOfHits}
  void add(Map<String, dynamic> entry) {
    if (_cache.where((el) => el.keys.toList()[0] == entry.keys.toList()[0]).isNotEmpty) return;
    _cache.add(entry);
  }

  /// Fetches an entry from cache given a query (if exists).
  ({bool isHit, Map<String, dynamic>? hit}) get(String query) {
    final res = _cache.where((el) => el.keys.toList()[0] == query);
    if (res.isEmpty) return (isHit: false, hit: null);
    return (isHit: true, hit: res.toList()[0]);
  }
}

final cache = HitCache(
  cache: CircularBuffer<Map<String, dynamic>>(HomePageConsts.cacheSize)
);
String latestQuery = '';
bool cacheHit = false;

// Searches are performed on both "users" and "user settings" indicies
// So we need to combine their results into one stream
Stream<List<Map<String, dynamic>>> combinedUserStream = Rx.combineLatest2(
  hitsSearcherUser.responses,
  hitsSearcherUserSettings.responses,
  (userResponse, userSettingsResponse) => [
    ...userResponse.hits,
    ...userSettingsResponse.hits,
  ],
).asBroadcastStream();

enum SearchStates {
  emptySearch, // the search bar is in focus but no text is entered
  textSearch, // the search bar is in focus with text
  noSearch // the search bar is not in focus
}

class SearchRowUser extends StatelessWidget {
  final Map<String, dynamic> hit;
  final Future<UserData> future;
  final bool cached;

  const SearchRowUser({
    required this.hit,
    required this.future,
    required this.cached,
    super.key
  });
  
  factory SearchRowUser.fromHit(Map<String, dynamic> hit, bool cached) {
    return SearchRowUser(
      hit: hit,
      future: SearchRowUser._getUserInfo(hit, cached),
      cached: cached,
    );
  }

  static Future<UserData> _getUserInfo(Map<String, dynamic> hit, bool cached) async {
    final String userID = hit['objectID'];
    final Map<String, dynamic> userSettingsData = (await db.collection('user_settings')
      .doc(userID)
      .get())
      .data() as Map<String, dynamic>;
    final Map<String, dynamic> userData = (await db.collection('users')
      .doc(userID)
      .get())
      .data() as Map<String, dynamic>;

    final String profilePicUrl = userSettingsData['profile_pic_url'] as String;
    final String displayUsername = userSettingsData['display_username'] as String;
    final String username = userData['username'] as String;

    // If the user metadata is not already cached then cache it
    if (!cached) {
      final (:isHit, :hit) = cache.get(latestQuery);
      // A hit is guaranteed so there is no need to check if it's a cache hit
      final record = (hit![latestQuery] as List<Map<String, dynamic>>)
        .where((el) => el['objectID'] == userID).toList()[0];
      record['profile_pic_url'] = profilePicUrl;
      record['display_username'] = displayUsername;
      record['username'] = username;
    }
    return (
      profilePicUrl: profilePicUrl,
      displayUsername: displayUsername,
      username: username
    );
  }

  Widget _row({
    required String profilePicUrl,
    required String displayUsername,
    required String username}) {
    return Row(
      children: [
        SizedBox(
          width: 45,
          height: 45,
          child: ClipOval(
            child: FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
              child: ImageFade(
                image: profilePicUrl.isEmpty ?
                  AssetImage(GlobalConsts.defaultProfilePicPath) :
                  NetworkImage(profilePicUrl),
                placeholder: Container(
                  width: 45,
                  height: 45,
                  color: Colors.black,
                ),
              )
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayUsername,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text("@$username", style: TextStyle(color: Colors.grey),)
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (cached) {
      final (profilePicUrl, displayUsername, username) = (
        hit['profile_pic_url'],
        hit['display_username'],
        hit['username']
      );
      return _row(
        profilePicUrl: profilePicUrl,
        displayUsername: displayUsername,
        username: username
      );
    } else {
      return FutureBuilder(
        future: future,
        builder: (BuildContext context, AsyncSnapshot<UserData> snapshot) {
          if (snapshot.hasData &&
            snapshot.data != null &&
            snapshot.connectionState == ConnectionState.done) {
            final (:profilePicUrl, :displayUsername, :username) = snapshot.data!;
            return _row(
              profilePicUrl: profilePicUrl,
              displayUsername: displayUsername,
              username: username
            );
          } else {
            return Container();
          }
        }
      );
    }
  }
}

class SearchContent extends StatelessWidget {
  const SearchContent({
    super.key
  });

  /// Filters results by a unique ID given the hits from "users" and "user settings"
  List<Map<String, dynamic>> _filterUnique(List<Map<String, dynamic>> hits) {
    List<Map<String, dynamic>> res = [];
    for (final hit in hits) {
      if (!res.map((el) => el['objectID']).contains(hit['objectID'])) {
        res.add(hit);
      }
    }
    return res;
  }

  Widget _generateColumns(Iterable hits, {required bool cached}) {
    return Column(
      children: [
        for (final hit in hits) Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              SearchRowUser.fromHit(hit, cached)
            ],
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final (:isHit, :hit) = cache.get(latestQuery);
    cacheHit = isHit;
    return isHit ?
    _generateColumns(hit![latestQuery], cached: true)
    :
    StreamBuilder(
      stream: combinedUserStream,
      builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
        if (snapshot.hasData &&
          snapshot.data != null &&
          snapshot.connectionState == ConnectionState.active) {
          List<Map<String, dynamic>> filteredData = _filterUnique(snapshot.data!);
          cache.add({latestQuery: filteredData});
          return _generateColumns(filteredData, cached: false);
        } else {
          return Padding(
            padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
            child: GlobalConsts.spinkit,
          );
        }
      }
    );
  }
}

class DefaultSearch extends StatefulWidget {
  final TextEditingController searchController;
  final FocusNode searchFocus;

  const DefaultSearch({
    required this.searchController,
    required this.searchFocus,
    super.key
  });

  @override
  State<DefaultSearch> createState() => _DefaultSearchState();
}

class _DefaultSearchState extends State<DefaultSearch> {
  final hitsSearcher = HitsSearcher(
    applicationID: secrets.Algolia.applicationID,
    apiKey: secrets.Algolia.searchAPIKey,
    indexName: secrets.Algolia.indexNamePosts,
  );

  SearchStates _curSearchState = SearchStates.noSearch;
  DateTime _prevTime = DateTime.now();
  String _prevText = '';
  Timer? _timer;
  
  void _setSearchState() {
    if (widget.searchController.text.isEmpty && widget.searchFocus.hasFocus &&
      _curSearchState != SearchStates.emptySearch) {
      setState(() {
        _curSearchState = SearchStates.emptySearch;
      });
    } else if (widget.searchController.text.isNotEmpty && widget.searchFocus.hasFocus &&
      _curSearchState != SearchStates.textSearch) {
      setState(() {
        _curSearchState = SearchStates.textSearch;
      });
    }
  }

  /// Update search state with the current value in the search field
  void _applySearchState() {
    latestQuery = widget.searchController.text;
    for (final searcher in [hitsSearcherUser, hitsSearcherUserSettings]) {
      searcher.applyState((state) {
        return state.copyWith(query: latestQuery, page: 0, hitsPerPage: 5);
      });
    }
  }

  void _setPrevTime() {
    _prevTime = DateTime.now();
  }

  /// Only make API calls if there is a minimum elapsed time between two consecutive
  /// key types and the text is different that what was previously
  void _query() {
    if (DateTime.now().difference(_prevTime).inMilliseconds > 200 &&
      _prevText != widget.searchController.text) {
      _applySearchState();
      _setSearchState();
      setState(() {});
      _prevText = widget.searchController.text;
    }
  }

  @override
  void initState() {
    super.initState();
    widget.searchController.addListener(_setPrevTime);
    _timer = Timer.periodic(Duration(milliseconds: 100), (Timer t) => _query());
  }
  
  @override
  void dispose() {
    super.dispose();
    widget.searchController.dispose();
    widget.searchFocus.dispose();
    widget.searchController.removeListener(_setPrevTime);
    _timer?.cancel();
  }


  @override
  Widget build(BuildContext context) {
    return _curSearchState == SearchStates.textSearch ?
      SearchContent(key: UniqueKey(),)
      :
      Container();
  }
}
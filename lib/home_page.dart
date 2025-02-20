import 'package:rxdart/rxdart.dart';
import 'package:flutter/material.dart';
import 'package:gym_buddy/consts/common_consts.dart';
import 'profile_page.dart';
import 'post_page.dart';
import 'utils/helpers.dart' as helpers;
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:awesome_bottom_bar/awesome_bottom_bar.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:algolia_helper_flutter/algolia_helper_flutter.dart';
import 'package:gym_buddy/auth/secrets.dart' as secrets;
import 'dart:async';
import 'package:image_fade/image_fade.dart';
import 'package:circular_buffer/circular_buffer.dart';

final FirebaseFirestore db = FirebaseFirestore.instance;

typedef UserData = ({String profilePicUrl, String displayUsername, String username});

final hitsSearcherUser = HitsSearcher(
  applicationID: secrets.Algolia.applicationID,
  apiKey: secrets.Algolia.searchAPIKey,
  indexName: secrets.Algolia.indexNameUsers,
);

class HitCache {
  final CircularBuffer<Map<String, dynamic>> _cache;

  HitCache({required cache}) : _cache = cache;

  void add(Map<String, dynamic> entry) {
    if (_cache.where((el) => el.keys.toList()[0] == entry.keys.toList()[0]).isNotEmpty) return;
    _cache.add(entry);
  }

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

final hitsSearcherUserSettings = HitsSearcher(
  applicationID: secrets.Algolia.applicationID,
  apiKey: secrets.Algolia.searchAPIKey,
  indexName: secrets.Algolia.indexNameUserSettings,
);

Stream<List<Map<String, dynamic>>> combinedUserStream = Rx.combineLatest2(
  hitsSearcherUser.responses,
  hitsSearcherUserSettings.responses,
  (userResponse, userSettingsResponse) => [
    ...userResponse.hits,
    ...userSettingsResponse.hits,
  ],
).asBroadcastStream();

class HomePage extends StatefulWidget {
  final List<String> postPageActs;
  final List<Map<String, dynamic>> postPageGyms;

  const HomePage({
    required this.postPageActs,
    required this.postPageGyms,
    super.key
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class HomePageContent extends StatefulWidget {
  const HomePageContent({super.key});

  @override
  State<HomePageContent> createState() => _HomePageContentState();
}

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

class _HomePageContentState extends State<HomePageContent> {
  Future<Object> fetchPosts() async {
    // First get the geoloc of the user (if possible) and update it in db
    Position? geoloc = await helpers.getGeolocation(); 
    String? userID = await helpers.getUserID(); 
    if (geoloc != null) {
      try {
        final geoPoint = GeoFirePoint(GeoPoint(geoloc.latitude, geoloc.longitude));
        db.collection('users').doc(userID).update({'geoloc': geoPoint.data}); 
      } catch (e) {
        // print(e);
      }
    }

    return {};
  }
  
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  SearchStates _curSearchState = SearchStates.noSearch;
  DateTime _prevTime = DateTime.now();
  String _prevText = '';
  Timer? _timer;
  
  void _setSearchState() {
    if (_searchController.text.isEmpty && _searchFocus.hasFocus &&
      _curSearchState != SearchStates.emptySearch) {
      setState(() {
        _curSearchState = SearchStates.emptySearch;
      });
    } else if (_searchController.text.isNotEmpty && _searchFocus.hasFocus &&
      _curSearchState != SearchStates.textSearch) {
      setState(() {
        _curSearchState = SearchStates.textSearch;
      });
    }
  }

  void _applySearchState() {
    latestQuery = _searchController.text;
    for (final searcher in [hitsSearcherUser, hitsSearcherUserSettings]) {
      searcher.applyState((state) {
        return state.copyWith(query: latestQuery, page: 0, hitsPerPage: 5);
      });
    }
  }

  void _setPrevTime() {
    _prevTime = DateTime.now();
  }

  void _query() {
    if (DateTime.now().difference(_prevTime).inMilliseconds > 200 &&
      _prevText != _searchController.text) {
      _applySearchState();
      _setSearchState();
      setState(() {});
      _prevText = _searchController.text;
    }
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_setPrevTime);
    _timer = Timer.periodic(Duration(milliseconds: 100), (Timer t) => _query());
  }
  
  @override
  void dispose() {
    super.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    _searchController.removeListener(_setPrevTime);
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(0),
        child: AppBar(
          scrolledUnderElevation: 0,
        )
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            // Search bar
            child: SearchAnchor( 
              builder: (BuildContext context, SearchController controller) {
                return SearchBar(
                  controller: _searchController,
                  padding: WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.symmetric(horizontal: 15, vertical: 0)),
                  leading: Icon(Icons.search, color: Theme.of(context).colorScheme.secondary,),
                  backgroundColor: WidgetStatePropertyAll<Color>(Colors.black),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12))
                    )
                  ),
                  onTapOutside: (event) {
                    _searchFocus.unfocus();      
                  },
                  focusNode: _searchFocus,
                  hintText: 'Search', 
                  hintStyle: WidgetStatePropertyAll(
                    TextStyle(
                      color: Theme.of(context).colorScheme.secondary
                    )
                  ),
                );
              },
              suggestionsBuilder: (BuildContext context, SearchController controller) {
                return [Container()]; // not used
              }
            ),
          ),
          Expanded(
            child: SingleChildScrollView( 
              child: Column(
                children: [
                  _curSearchState == SearchStates.textSearch ?
                  SearchContent(key: UniqueKey(),)
                  :
                  Container() 
                ],
              ),
            )
          )
        ],
      )
    );
  }
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; 

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index; 
    });
  } 

  final List<TabItem> items = [
    TabItem(
      icon: Icons.home,
      title: 'Home',
    ),
    TabItem(
      icon: Icons.add_box_rounded,
      title: 'Post',
    ),
    TabItem(
      icon: Icons.people_alt_rounded,
      title: 'Buddies',
    ),
    TabItem(
      icon: Icons.account_box,
      title: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: Key('homepage'),
      extendBody: true,
      body: Center(
        child: [
          HomePageContent(),
          PostPage(postPageActs: widget.postPageActs, postPageGyms: widget.postPageGyms),
          Container(),
          ProfilePage()
        ][_selectedIndex], 
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(30), 
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(30)) 
          ),
          clipBehavior: Clip.hardEdge,
          child: BottomBarFloating(
            items: items,
            backgroundColor: Colors.black,
            color: Theme.of(context).colorScheme.primary,
            colorSelected: Theme.of(context).colorScheme.tertiary,
            indexSelected: _selectedIndex,
            onTap: _onItemTapped,
            duration: Duration(milliseconds: 200), 
            titleStyle: TextStyle(
              letterSpacing: 0,
            ),
            pad: 1,
            animated: false,
            paddingVertical: 8,
            iconSize: 18,
          ),
        ),
      ),
    );
  }
}
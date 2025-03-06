import 'package:algolia_helper_flutter/algolia_helper_flutter.dart';
import 'package:circular_buffer/circular_buffer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_buddy/data/service/search_service.dart';
import 'package:gym_buddy/ui/search/view_models/search_view_model.dart' show UserData;

class SearchRepository {
  SearchRepository();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Stream<List<Map<String, dynamic>>> combinedUserStream = SearchService.combinedUserStream;
  final HitsSearcher hitsSearcherUser = SearchService.hitsSearcherUser;
  final HitsSearcher hitsSearcherUserSettings = SearchService.hitsSearcherUserSettings;

  Future<UserData> getUserInfo({
    required Map<String, dynamic> hit,
    required bool cached,
    required HitCache cache,
    required String latestQuery
    }) async {
    final String userID = hit['objectID'];
    final Map<String, dynamic> userSettingsData = (await _db.collection('user_settings')
      .doc(userID)
      .get())
      .data() as Map<String, dynamic>;
    final Map<String, dynamic> userData = (await _db.collection('users')
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
      record['cached'] = true;
    }
    return (
      profilePicUrl: profilePicUrl,
      displayUsername: displayUsername,
      username: username
    );
  }
}

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
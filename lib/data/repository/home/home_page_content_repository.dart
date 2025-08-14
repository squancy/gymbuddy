import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:gym_buddy/data/repository/core/common_repository.dart';
import 'package:gym_buddy/data/service/common_service.dart';



class HomePageContentRepository {
  HomePageContentRepository();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  Position? _lastKnownPosition;
  GeoFirePoint? _geoPoint;
  StreamSubscription<List<DocumentSnapshot<Map<String, dynamic>>>>? gymSubscription;
  double _currentRadius = 1.0;
  List<String> _nearbyGyms = [];
  List<Map<String, dynamic>> nearbyPosts = [];
  Future<void>? fetchDataFuture;
  Position? geoloc;

  final CommonRepository _commonRepository = CommonRepository();
  final CommonService _commonService = CommonService();

  Future<void> _updateLocation() async {
    await _commonService.requestPosition();
    Position? geoloc = await _commonService.getGeolocation();
    String? userID = await _commonRepository.getUserID();
    if (_lastKnownPosition != null) {
      double distance = Geolocator.distanceBetween(
        _lastKnownPosition!.latitude, _lastKnownPosition!.longitude,
        geoloc!.latitude, geoloc.longitude,
      );
      if (distance < 100) return;
    }
    _geoPoint = GeoFirePoint(GeoPoint(geoloc!.latitude, geoloc.longitude));
    await _db.collection('users').doc(userID).update({'geoloc': _geoPoint!.data});
    _lastKnownPosition = geoloc;
  }
  
  Future<void> fetchData() async {
    await _updateLocation();
    print(_lastKnownPosition);
    await _fetchNearbyGyms();
    print("Nearbypost: --- $nearbyPosts");
  }


  Future<void> _fetchNearbyGyms() async {
    if (_lastKnownPosition == null) {
      print("Last known position is null");
      return;
    }

    final Completer<void> completer = Completer<void>();

    GeoFirePoint user_GeoPoint = GeoFirePoint(GeoPoint(_lastKnownPosition!.latitude, _lastKnownPosition!.longitude));
    final collectionReference = _db.collection('gyms').doc('budapest').collection('gyms');

    gymSubscription?.cancel();
    gymSubscription = GeoCollectionReference<Map<String, dynamic>>(collectionReference)
        .subscribeWithin(
          center: user_GeoPoint,
          radiusInKm: _currentRadius,
          field: 'geoloc',
          geopointFrom: (data) => (data['geoloc'] as Map<String, dynamic>?)?['_geopoint'] as GeoPoint? ?? GeoPoint(0, 0),
        )
        .listen((snapshots) async {
          print("Gyms were fetched: ${snapshots.length}");
          if (snapshots.isEmpty) {
            print("No gyms found within the radius.");
            completer.complete();
            return;
          }
          _nearbyGyms = snapshots.map((doc) => doc.id).toList();
          print("Nearby gyms: $_nearbyGyms");
          await _fetchPostsForNearbyGyms();
          await _getUserDataForPostById();
          completer.complete();
        }, onError: (e) {
          print("Error fetching gyms: $e");
          completer.completeError(e);
        });

    await completer.future;
  }

  Future<void> _fetchPostsForNearbyGyms() async {
    if (_nearbyGyms.isEmpty) {
      print("No nearby gyms to fetch posts for.");
      return;
    }
    nearbyPosts.clear();
    for (var gymBatch in _chunkList(_nearbyGyms, 10)) {
      try {
        print("Fetching posts for gyms: $gymBatch");
        final postsQuery = _db.collection('posts')
            .where('gym', whereIn: gymBatch)
            .orderBy('date', descending: true)
            .limit(50);
        final postsSnapshot = await postsQuery.get();
        if (postsSnapshot.docs.isEmpty) {
          print("No posts found for gyms: $gymBatch");
        } else {
          final fetchedPosts = postsSnapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            print("Post data with ID: $data");
            return data;
          }).toList();
          nearbyPosts.addAll(fetchedPosts);
          print("Fetched ${fetchedPosts.length} posts for gyms: $gymBatch");
        }
      } catch (e) {
        print("Error fetching posts for gyms $gymBatch: $e");
      }
    }
    print("Total nearby posts: ${nearbyPosts.length}");
  }

  Future<void> _getUserDataForPostById() async {
  Set<String> userIDs = {for (var post in nearbyPosts) post['author'] as String};
  if (userIDs.isEmpty) {
    print("No user IDs found in posts.");
    return;
  }
  List<String> userList = userIDs.toList();
  Map<String, Map<String, dynamic>> userSettingsMap = {};
  print("Fetching user data for posts.");
  try {
    for (var batch in _chunkList(userList, 10)) {
      final usersSnapshot = await _db.collection('user_settings').where(FieldPath.documentId, whereIn: batch).get();
      for (var doc in usersSnapshot.docs) {
        userSettingsMap[doc.id] = doc.data();
      }
    }
    for (var post in nearbyPosts) {
      final userSettings = userSettingsMap[post['author']];
      if (userSettings != null) {
        post['displayUsername'] = userSettings['display_username'];
        post['author_profile_pic_url'] = userSettings['profile_pic_url'];
      }
    }
    print("User data fetched for posts.");
  } catch (e) {
    print("Error fetching user data: $e");
  }
}

List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
  List<List<T>> chunks = [];
  for (var i = 0; i < list.length; i += chunkSize) {
    chunks.add(list.sublist(i, i + chunkSize > list.length ? list.length : i + chunkSize));
  }
  return chunks;
}
}
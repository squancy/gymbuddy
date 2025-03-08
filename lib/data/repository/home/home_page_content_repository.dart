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
  bool _dataLoaded = false;
  StreamSubscription<List<DocumentSnapshot<Map<String, dynamic>>>>? gymSubscription;
  double _currentRadius = 1.0;
  List<String> _nearbyGyms = [];
  List<Map<String, dynamic>> nearbyPosts = [];
  Future<void>? fetchDataFuture;
  Position? geoloc;

  final CommonRepository _commonRepository = CommonRepository();
  final CommonService _commonService = CommonService();

  Future<void> updateLocation() async {
    await _commonService.requestPosition();
    Position? geoloc = await _commonService.getGeolocation();
    String? userID = await _commonRepository.getUserID();
    _geoPoint = GeoFirePoint(GeoPoint(geoloc!.latitude, geoloc.longitude));
    await _db.collection('users').doc(userID).update({'geoloc': _geoPoint!.data});
    _lastKnownPosition = geoloc;
  }
  
  Future<void> fetchData() async {
    if (_dataLoaded) return;  // Prevent unnecessary fetching
    if (_lastKnownPosition == null) return;
    
    await updateLocation();
    await fetch_NearbyGyms();
  }


  Future<void> fetch_NearbyGyms() async {
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
          print("Gyms were fetched");
          if (snapshots.isEmpty) return;
          _nearbyGyms = snapshots.map((doc) => doc.id).toList();
          await updateLocationFor_NearbyGyms();
          await _getUserDataForPostById();
        }, onError: (e) => print("Error fetching gyms: $e"));
  }

  Future<void> updateLocationFor_NearbyGyms() async {
    if (_nearbyGyms.isEmpty) return;
    nearbyPosts.clear();
    for (var gymBatch in _chunkList(_nearbyGyms, 10)) {
      try {
        final postsQuery = _db.collection('posts')
            .where('gym', whereIn: gymBatch)
            .orderBy('date', descending: true)
            .limit(50);
        final postsSnapshot = await postsQuery.get();
        nearbyPosts.addAll(postsSnapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList());
      } catch (e) {
        print("Error fetching posts: $e");
      }
    }
  }

  Future<void> _getUserDataForPostById() async {
    Set<String> userIDs = {for (var post in nearbyPosts) post['author'] as String};
    if (userIDs.isEmpty) return;
    List<String> userList = userIDs.toList();
    Map<String, Map<String, dynamic>> userSettingsMap = {};
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
          post['profilePic'] = userSettings['profile_pic_url'];
        }
      }
      // setState(() {});
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
import 'package:gym_buddy/utils/helpers.dart' as helpers;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';

class HomePageContentRepository {
  HomePageContentRepository();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Object> fetchPosts() async {
    // First get the geoloc of the user (if possible) and update it in db
    // TODO: finish function
    Position? geoloc = await helpers.getGeolocation(); 
    String? userID = await helpers.getUserID(); 
    if (geoloc != null) {
      final geoPoint = GeoFirePoint(GeoPoint(geoloc.latitude, geoloc.longitude));
      _db.collection('users').doc(userID).update({'geoloc': geoPoint.data}); 
    }

    return {};
  }
}
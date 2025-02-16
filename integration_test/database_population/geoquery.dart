import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:integration_test/integration_test.dart';
import 'package:gym_buddy/utils/helpers.dart' as helpers;

void main() async{
  TestWidgetsFlutterBinding.ensureInitialized();

  await helpers.firebaseInit(test: true);
  FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8080);

  test("Getting geoquery", () async {
    final FirebaseFirestore db = FirebaseFirestore.instance;
    final GeoFirePoint userGeoPoint = GeoFirePoint(GeoPoint(47.497913, 19.040236));

    print("User location: ${userGeoPoint.latitude}, ${userGeoPoint.longitude}");

    const double radius = 50.0;
    final collectionReference = db.collection('gyms').doc('budapest').collection('gyms');
    const String field = 'geoloc';

    // 🔹 Manual Firestore Query to Check Data Exists
    final gymsSnapshot = await collectionReference.get();
    print("🔥 Fetched ${gymsSnapshot.docs.length} gyms from Firestore.");

    // for (var doc in gymsSnapshot.docs) {
    //   print("Gym ID: ${doc.id}, Raw Data: ${doc.data()}");
    // }

    // // 🔹 GeoQuery Firestore Stream
    // GeoPoint geopointFrom(Map<String, dynamic> data) {
    //   print("🔍 Parsing geopoint from Firestore data: $data");

    //   if (data.containsKey("geoloc") &&
    //       data["geoloc"] is Map<String, dynamic> &&
    //       data["geoloc"]["geopoint"] is GeoPoint) {
    //     final geo = data["geoloc"]["geopoint"] as GeoPoint;
    //     print("✅ Extracted GeoPoint: (${geo.latitude}, ${geo.longitude})");
    //     return geo;
    //   }

    //   throw Exception("❌ Invalid geopoint structure: $data");
    // }

    // GeoPoint geopointFrom(Map<String, dynamic> data) =>
    //  (data['geoloc'] as Map<String, dynamic>)['geopoint'] as GeoPoint;

    // final Stream<List<DocumentSnapshot<Map<String, dynamic>>>> gyms =
    //     GeoCollectionReference<Map<String, dynamic>>(collectionReference).subscribeWithin(
    //   center: userGeoPoint,
    //   radiusInKm: radius,
    //   field: field,
    //   geopointFrom: geopointFrom,
    // );


    // gyms.listen(
    //   (List<DocumentSnapshot<Map<String, dynamic>>> snapshots) {
    //     print("📡 GeoQuery Stream Triggered! Received ${snapshots.length} gyms.");

    //     if (snapshots.isEmpty) {
    //       print("⚠️ No gyms found within ${radius}km.");
    //     } else {
    //       for (var doc in snapshots) {
    //         final data = doc.data();
    //         if (data != null) {
    //           print("Gym ID: ${doc.id}, Data: $data");
    //         } else {
    //           print("Gym ID: ${doc.id}, but data is null");
    //         }
    //       }
    //     }
    //   },
    //   onError: (e) {
    //     print("❌ Error fetching gyms from GeoQuery: $e");
    //   },
    // );
  });
}

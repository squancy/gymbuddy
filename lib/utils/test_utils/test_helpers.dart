import 'package:shared_preferences/shared_preferences.dart';
import 'package:integration_test/integration_test.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

Future<void> logInUser(String userID) async {
  final SharedPreferencesAsync prefs = SharedPreferencesAsync();
  await prefs.setBool('loggedIn', true);
  await prefs.setString('userID', userID);
}

void registerTextInput() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.testTextInput.register();
}

List<GeoFirePoint?> generateRandomCoordinates(int n) {
  Random random = Random();
  List<GeoFirePoint> coordinates = [];

  for (int i = 0; i < n; i++) {
    double lat = -90 + random.nextDouble() * 180; // Latitude range: -90 to 90
    double lon = -180 + random.nextDouble() * 360; // Longitude range: -180 to 180
    coordinates.add(GeoFirePoint(GeoPoint(lat, lon)));
  }

  return coordinates; 
}

String generateRandomString(int len) {
  var r = Random();
  const chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  return List.generate(len, (index) => chars[r.nextInt(chars.length)]).join();
}

Future<void> deleteAllDocsFromCollection(CollectionReference collection, FirebaseFirestore db) async {
  const int batchSize = 200; 
  WriteBatch batch = db.batch();
  int count = 0;

  var snapshots = await collection.get();
  for (var doc in snapshots.docs) {
    count++;
    batch.delete(doc.reference);
    if (count % batchSize == 0) {
      await batch.commit();
      batch = db.batch();
    }
  }
  await batch.commit();
}

List<int> randNumOfRandNums(int n) {
  final random = Random();
  List<int> res = [];
  for (int i = 0; i < random.nextInt(n); i++) {
    if (random.nextBool()) {
      int randNum = random.nextInt(n);
      while (res.contains(randNum)) {
        randNum = random.nextInt(n);
      }
      res.add(randNum);
    }
  }
  return res;
}
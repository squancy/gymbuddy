import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_buddy/utils/helpers.dart' as helpers;
import 'package:integration_test/integration_test.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:uuid/uuid.dart';
import 'package:gym_buddy/utils/test_utils/test_helpers.dart' as test_helpers;
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';

// Import the web scraped csv files containing gyms in Hungary to the database

void main() async {
  test('Push scraped gyms to database', () async {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();
    await helpers.firebaseInit(test: true); // set it to false when pushing to the live database
    final FirebaseFirestore db = FirebaseFirestore.instance;
    final gymCollRef = db.collection('gyms').doc('budapest').collection('gyms');

    // First delete all documents in gyms/budapest/gyms
    await test_helpers.deleteAllDocsFromCollection(gymCollRef, db);

    final csvString = await rootBundle.loadString('assets/budapest_gyms.csv');
    final fields = CsvToListConverter().convert(csvString);

    // Add all gyms in the csv file
    final uuid = Uuid();
    int count = 0;
    const int batchSize = 200; 
    WriteBatch batch = db.batch();
    batch = db.batch();

    for (final (i, row) in fields.indexed) {
      if (i == 0) {
        continue; // first row in csv is the description: do not add it
      }

      count++;
      String gymID = uuid.v4();
      final gyms = gymCollRef.doc(gymID);
      final data = {
        'id': gymID,
        'name': row[0],
        'address': row[1],
        'geoloc': GeoFirePoint(GeoPoint(row[3], row[4])).data
      };
      batch.set(gyms, data);

      if (count % batchSize == 0) {
        await batch.commit();
        batch = db.batch();
      }
    }

    if (count % batchSize != 0) {
      await batch.commit();
    }
  });  
}

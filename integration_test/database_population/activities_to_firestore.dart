import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_buddy/utils/helpers.dart' as helpers;
import 'package:integration_test/integration_test.dart';
import 'package:uuid/uuid.dart';
import 'package:gym_buddy/consts/common_consts.dart' as consts;
import 'package:gym_buddy/utils/test_utils/test_helpers.dart' as test_helpers;

// Import potential activities to the database

void main() async {
  test('Push activities to database', () async {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();
    await helpers.firebaseInit(test: true); // set it to false when pushing to the live database
    final FirebaseFirestore db = FirebaseFirestore.instance;
    final actDocRef = db.collection('activities');
    
    // First delete all documents in activities/
    test_helpers.deleteAllDocsFromCollection(actDocRef, db);

    final uuid = Uuid();
    int count = 0;
    int batchSize = 200;
    WriteBatch batch = db.batch();

    for (final el in consts.GlobalConsts.activities) {
      count++;
      String actID = uuid.v4();
      final acts = actDocRef.doc(actID);
      final data = {
        'name': el,
      };
      batch.set(acts, data);

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

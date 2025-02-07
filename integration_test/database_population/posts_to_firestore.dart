import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dbcrypt/dbcrypt.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_buddy/utils/helpers.dart' as helpers;
import 'package:integration_test/integration_test.dart';
import 'package:uuid/uuid.dart';
import 'package:gym_buddy/consts/test_consts.dart' as test_consts;
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:gym_buddy/utils/test_utils/test_helpers.dart' as test_helpers;

// Import posts to the database for testing

void main() async {
  test('Push posts to database', () async {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();
    await helpers.firebaseInit(test: true); // set it to false when pushing to the live database
    final FirebaseFirestore db = FirebaseFirestore.instance;
    final dbcrypt = DBCrypt();
    final uuid = Uuid();

    /*
      There are two users who are used throughout most of the tests
      Their data can be found in consts/test_consts.dart
    */

    // First delete all posts from db
    test_helpers.deleteAllDocsFromCollection(db.collection('users'), db);

  });  
}
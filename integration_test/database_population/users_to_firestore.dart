import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dbcrypt/dbcrypt.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_buddy/consts/common_consts.dart';
import 'package:integration_test/integration_test.dart';
import 'package:uuid/uuid.dart';
import 'package:gym_buddy/consts/test_consts.dart' as test_consts;
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:gym_buddy/utils/test_utils/test_helpers.dart' as test_helpers;
import 'package:gym_buddy/data/repository/core/common_repository.dart';

// Import random users to the database for testing

void main() async {
  test('Push users to database', () async {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();
    await CommonRepository().firebaseInit(test: GlobalConsts.test);
    final FirebaseFirestore db = FirebaseFirestore.instance;
    final dbcrypt = DBCrypt();
    final uuid = Uuid();

    /*
      There are two users who are used throughout most of the tests
      Their data can be found in consts/test_consts.dart
    */

    // First delete all users from db
    await test_helpers.deleteAllDocsFromCollection(db.collection('users'), db);
    await test_helpers.deleteAllDocsFromCollection(db.collection('user_settings'), db);

    // Add these two users to the db
    for (final user in [test_consts.user1, test_consts.user2]) {
      final GeoFirePoint centerOfBudapest = GeoFirePoint(GeoPoint(47.497913, 19.040236));
      String salt = dbcrypt.gensaltWithRounds(10);
      var pwh = dbcrypt.hashpw(user.password, salt);

      await db.collection('users').doc(user.userID).set({
        'email': user.email,
        'geoloc': centerOfBudapest.data,
        'id': user.userID,
        'password': pwh,
        'platform': 'iOS', // it doesn't really matter for now, may be changed later
        'salt': salt,
        'signup_date': FieldValue.serverTimestamp(),
        'username': user.username,
      });

      // Add further settings for each user
      await db.collection('user_settings').doc(user.userID).set({
        'bio': user.bio,
        'display_username': user.displayUsername,
        'profile_pic_path': user.profilePicPath,
        'profile_pic_url': user.profilePicUrl
      });
    }

    // Add further users to db with different locations (including null)
    int numOfUsers = 100;
    int numOfNulls = 25;

    // Convert each element to nullable since Dart infers the type as List<GeoFirePoint>
    List<GeoFirePoint?> geoPoints = test_helpers
    .generateRandomCoordinates(numOfUsers - numOfNulls)
    .map((e) => e as GeoFirePoint?) 
    .toList();
    geoPoints.addAll(List<GeoFirePoint?>.generate(numOfNulls, (_) => null));

    for (int i = 0; i < numOfUsers; i++) {
      final String userID = uuid.v4();
      String salt = dbcrypt.gensaltWithRounds(10);
      var pwh = dbcrypt.hashpw('asdasd', salt);
      String username = test_helpers.generateRandomString(12);

      await db.collection('users').doc(userID).set({
        'email': '${test_helpers.generateRandomString(10)}@gmail.com',
        'geoloc': geoPoints[i]?.data,
        'id': userID,
        'password': pwh,
        'platform': 'iOS', 
        'salt': salt,
        'signup_date': FieldValue.serverTimestamp(),
        'username': username
      });     

      // Add further settings for each user
      await db.collection('user_settings').doc(userID).set({
        'bio': '',
        'display_username': username,
        'profile_pic_path': '',
        'profile_pic_url': ''
      });
    }
  });  
}
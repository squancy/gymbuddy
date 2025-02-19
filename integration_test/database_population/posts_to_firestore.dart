import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_buddy/utils/helpers.dart' as helpers;
import 'package:integration_test/integration_test.dart';
import 'package:gym_buddy/consts/test_consts.dart' as test_consts;
import 'package:gym_buddy/utils/test_utils/test_helpers.dart' as test_helpers;
import 'package:uuid/uuid.dart';
import 'dart:math';

// Import posts to the database for testing

void main() async {
  test('Push posts to database', () async {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();
    await helpers.firebaseInit(test: true); // set it to false when pushing to the live database
    final FirebaseFirestore db = FirebaseFirestore.instance;
    final allActivities = await helpers.getAllActivitiesWithoutProps(db.collection('activities'));
    final allGyms = (await helpers.getAllGymsWithProps(db.collection('gyms/budapest/gyms')))
      .map((el) => el.keys.toList()[0]).toList();
    Random random = Random();
    final uuid = Uuid();
    final numOfRandomUsers = 10;

    // Can be found in firestorage emulator
    const filenameList = [
      '5b97e4dd-def9-4119-b84e-101e445bfd3e.jpg',
      '217eef45-de63-42ac-aca1-eb573b457885.jpg',
      '7e438bfc-9ab9-4e67-bcf9-1262e098ce17.jpg'
    ];
    
    const filenameUrls = [
      'http://127.0.0.1:9199/v0/b/gym-buddy-9ab39.firebasestorage.app/o/post_pics%2Fdfc64a4f-70c4-4745-a01a-ec0df8af13c8%2F5b97e4dd-def9-4119-b84e-101e445bfd3e.jpg?alt=media&token=a3199e3d-f125-49f3-a69e-22adc374ca23',
      'http://127.0.0.1:9199/v0/b/gym-buddy-9ab39.firebasestorage.app/o/post_pics%2Fdfc64a4f-70c4-4745-a01a-ec0df8af13c8%2F217eef45-de63-42ac-aca1-eb573b457885.jpg?alt=media&token=785321de-eb64-40c4-9c42-4a8d54dafa10',
      'http://127.0.0.1:9199/v0/b/gym-buddy-9ab39.firebasestorage.app/o/post_pics%2Fdfc64a4f-70c4-4745-a01a-ec0df8af13c8%2F7e438bfc-9ab9-4e67-bcf9-1262e098ce17.jpg?alt=media&token=6b9586c6-39a1-4ec0-a498-d543558c5bf5'
    ];

    final imageFiles = {
      for (var i = 0; i < filenameList.length; i++) filenameList[i]: filenameUrls[i]
    };

    // First delete all posts from db
    test_helpers.deleteAllDocsFromCollection(db.collection('posts'), db);

    /*
      There are two users who are used throughout most of the tests
      Their data can be found in consts/test_consts.dart
      One user has no posts while the other one has enough posts to test pagination
    */

    final userWithPosts = test_consts.user2;
    
    final commonFields = {
      'author': userWithPosts.userID,
      'content': test_helpers.generateRandomString(50),
      'date': FieldValue.serverTimestamp(),
    };

    // User with posts has a few fixed posts and a bunch of random ones
    final post1 = {
      ...commonFields,
      'day_type': '',
      'download_url_list': [],
      'filename_list': [],
      'gym': '',
      'when': null
    };

    final post2 = {
      ...commonFields,
      'day_type': allActivities[random.nextInt(allActivities.length)],
      'download_url_list': [],
      'filename_list': [],
      'gym': '',
      'when': null
    };

    final post3 = {
      ...commonFields,
      'day_type': allActivities[random.nextInt(allActivities.length)],
      'download_url_list': [],
      'filename_list': [],
      'gym': allGyms[random.nextInt(allGyms.length)],
      'when': null
    };

    final post4 = {
      ...commonFields,
      'day_type': allActivities[random.nextInt(allActivities.length)],
      'download_url_list': imageFiles.values.toList(),
      'filename_list': imageFiles.keys.toList(),
      'gym': allGyms[random.nextInt(allGyms.length)],
      'when': DateTime(2025, 07, 11, 11, 11),
    };

    for (final el in [post1, post2, post3, post4]) {
      await db.collection('posts').doc(uuid.v4()).set(el);
    } 
    final nearby_gyms = ["93b15e60-0a20-45f1-a41c-e7c4a7ee6c6f", "ac308b1d-8d9f-408c-bda3-55ae700dd719", "dc80b715-ccb3-4c0e-bada-68b62808f53c", "880b6743-370f-4ac8-b907-2bb5a568367f"];

    // Add random posts
    for (int i = 0; i < numOfRandomUsers; i++) {
      bool isActivity = random.nextBool();
      bool isGym = random.nextBool();
      bool isTime = random.nextBool();
      bool isImages = random.nextBool();
      final rands = test_helpers.randNumOfRandNums(filenameList.length);
      final fList = [for (final el in rands) filenameList[el]];
      final urlList = [for (final el in rands) filenameUrls[el]];

      final post = {
        ...commonFields,
        if (isActivity) 'day_type': allActivities[random.nextInt(allActivities.length)] else 'day_type': '',
        if (isGym) 'gym': nearby_gyms[random.nextInt(nearby_gyms.length)],
        if (isTime) 'when': DateTime(
          DateTime.now().year,
          random.nextInt(13) + 1,
          random.nextInt(31) + 1,
          random.nextInt(24),
          random.nextInt(60)
        ) else 'when': null,
        if (isImages) 'filename_list': fList else 'filename_list': [],
        if (isImages) 'download_url_list': urlList else 'download_url_list': [],
      };

      await db.collection('posts').doc(uuid.v4()).set(post);
    }
  });
}
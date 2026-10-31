import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:integration_test/integration_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_buddy/consts/common_consts.dart' as consts;
import 'package:gym_buddy/utils/test_utils/test_helpers.dart' as test_helpers;
import 'dart:math';
import 'package:gym_buddy/data/repository/core/upload_image_repository.dart';
import 'package:gym_buddy/data/repository/post/post_page_repository.dart';
import 'package:gym_buddy/ui/post/widgets/post_page_screen.dart';
import 'package:gym_buddy/ui/post/view_models/post_page_view_model.dart';
import 'package:gym_buddy/data/repository/core/common_repository.dart';

final CommonRepository commonRepo = CommonRepository();

String gymToString(Map<String, dynamic> gym) {
  return "${gym[gym.keys.toList()[0]]['name']}\t|\t${gym[gym.keys.toList()[0]]['address']}";
}

Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getDBRecord(
  String postText,
  String dayType) async {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  return (await db.collection('posts')
    .where('author', isEqualTo: await commonRepo.getUserID())
    .where('day_type', isEqualTo: dayType)
    .where('content', isEqualTo: postText).get()).docs;
}

Future<void> main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  await commonRepo.firebaseInit(test: true);
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final random = Random();
  final numOfRandomPosts = 10;
  final consts.InfoRecord actsAndGyms = await commonRepo.getActivitiesAndGyms();

  testWidgets('Post page testing', (tester) async {
    // Necessary for being able to enterText when not in debug mode 
    test_helpers.registerTextInput();

    // User with the given ID, its username is 'test' and can be found in the test database
    test_helpers.logInUser('b727fd96-f618-4121-b875-e5fb74539034');
    await tester.pumpWidget(
      MaterialApp(
        home: PostPage(
          postPageActs: actsAndGyms.activities,
          postPageGyms: actsAndGyms.gyms,
          viewModel: PostPageViewModel(
            postPageRepository: PostPageRepository(),
            uploadImageRepository: UploadImageRepository()
          ),
          key: const Key('postPage1'),
        ),
      )
    );
    await tester.pumpAndSettle();
    
    // First check the existance of widgets
    final titleFinder = find.text(consts.PostPageConsts.appBarText);
    expect(titleFinder, findsOneWidget);

    final textField = find.byKey(const Key('textField'));
    expect(textField, findsOneWidget);

    final actDD = find.byKey(const Key('activityField'));
    expect(actDD, findsOneWidget);

    final gymDD = find.byKey(const Key('gymField'));
    expect(gymDD, findsOneWidget);

    final timeField = find.byKey(const Key('timeField'));
    expect(timeField, findsOneWidget);

    final uploadField = find.byKey(const Key('uploadField'));
    expect(uploadField, findsOneWidget);

    final postBtn = find.byKey(const Key('postBtn'));
    expect(postBtn, findsOneWidget);

    // Make sure the dropdown menus have the correct content
    // TODO: silence warnings

    await tester.tap(actDD);
    await tester.pumpAndSettle();
    final actScroll = find.byType(Scrollable).first;
    var activities = await commonRepo.getAllActivitiesWithoutProps(db.collection('activities'));
    activities.sort();

    for (final el in activities) {
      final itemFinder = find.text(el);
      await tester.scrollUntilVisible(itemFinder, 500, scrollable: actScroll);
      expect(itemFinder, findsOneWidget);
      await tester.pumpAndSettle();
    }

    await tester.tap(actDD);
    await tester.pumpAndSettle();
    await tester.tap(gymDD);
    await tester.pumpAndSettle();

    final gymsScroll = find.byType(Scrollable).last;
    var gyms = (await commonRepo.getAllGymsWithProps(db.collection('gyms/budapest/gyms')));
    commonRepo.sortGymsByName(gyms);

    // NOTE: this takes a lot of time to run since it scrolls through thousands of gyms in a dropdown
    for (final el in gyms) {
      final itemFinder = find.text(
        gymToString(el),
        findRichText: true
      );
      await tester.scrollUntilVisible(itemFinder, 500, scrollable: gymsScroll);
      expect(itemFinder, findsOneWidget);
      await tester.pumpAndSettle();
    }

    // Posting without filling the text field is not permitted
    await tester.tapAt(Offset(0, 0)); // Make sure the dropdowns are closed by tapping outside
    await tester.pumpAndSettle();
    await tester.tap(postBtn);
    await tester.pumpAndSettle(); 

    final errorText = find.text(consts.PostPageConsts.emptyFieldError);
    expect(errorText, findsOneWidget);

    // // Post with just text
    await tester.enterText(textField, 'sample post');
    await tester.pumpAndSettle();
    await tester.tap(postBtn);
    await tester.pumpAndSettle();
    
    // Make sure the new post is pushed to database
    var post = await db.collection('posts')
      .where('author', isEqualTo: await commonRepo.getUserID())
      .where('content', isEqualTo: 'sample post').get();
    expect(post.docs.length, 1, reason: "Make sure there is exactly one entry in db");

    // Post with text and activity
    await tester.enterText(textField, 'sample post 2');
    await tester.pumpAndSettle();
    await tester.tap(actDD);
    await tester.pumpAndSettle();
    var actSel = find.descendant(
      of: actDD,
      matching: find.text(activities[1])
    ).last;
    await tester.tap(actSel);
    await tester.pumpAndSettle();
    await tester.tapAt(Offset(0, 0)); // Make sure the dropdowns are closed by tapping outside
    await tester.tap(postBtn);
    await tester.pumpAndSettle();

    // Make sure it is pushed to db
    var dbRec = await getDBRecord('sample post 2', activities[1]);
    expect(dbRec.length, 1, reason: "Make sure there is exactly one entry in db");

    // Post with text, activity and gym
    await tester.enterText(textField, 'sample post 3');
    await tester.pumpAndSettle();
    await tester.tap(actDD);
    await tester.pumpAndSettle();
    actSel = find.descendant(
      of: actDD,
      matching: find.text(activities[2])
    ).last;
    await tester.tap(actSel);
    await tester.pumpAndSettle();
    await tester.tapAt(Offset(0, 0)); // Make sure the dropdowns are closed by tapping outside
    await tester.tap(gymDD);
    await tester.pumpAndSettle();
    var gymSel = find.descendant(
      of: gymDD,
      matching: find.text(gymToString(gyms[2]), findRichText: true)
    ).last;
    await tester.tap(gymSel);
    await tester.pumpAndSettle();
    await tester.tap(postBtn);
    await tester.pumpAndSettle();

    // Make sure it is pushed to db
    dbRec = await getDBRecord('sample post 3', activities[2]);
    expect(dbRec.length, 1, reason: "Make sure there is exactly one entry in db");

    // Post with text, activity, gym and time
    await tester.enterText(textField, 'sample post 4');
    await tester.pumpAndSettle();
    await tester.tap(actDD);
    await tester.pumpAndSettle();
    actSel = find.descendant(
      of: actDD,
      matching: find.text(activities[2])
    ).last;
    await tester.tap(actSel);
    await tester.pumpAndSettle();
    await tester.tapAt(Offset(0, 0)); // Make sure the dropdowns are closed by tapping outside
    await tester.tap(gymDD);
    await tester.pumpAndSettle();
    gymSel = find.descendant(
      of: gymDD,
      matching: find.text(gymToString(gyms[1]), findRichText: true)
    ).last;
    await tester.tap(gymSel);
    await tester.pumpAndSettle();
    await tester.tap(timeField);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.tap(postBtn);
    await tester.pumpAndSettle();   

    // Make sure it is pushed to db
    dbRec = await getDBRecord('sample post 4', activities[2]);
    expect(dbRec.length, 1, reason: "Make sure there is exactly one entry in db");

    // Post with text, activity, gym, time and image upload
    await tester.enterText(textField, 'sample post 5');
    await tester.pumpAndSettle();
    await tester.tap(actDD);
    await tester.pumpAndSettle();
    actSel = find.descendant(
      of: actDD,
      matching: find.text(activities[2])
    ).last;
    await tester.tap(actSel);
    await tester.pumpAndSettle();
    await tester.tapAt(Offset(0, 0)); // Make sure the dropdowns are closed by tapping outside
    await tester.tap(gymDD);
    await tester.pumpAndSettle();
    gymSel = find.descendant(
      of: gymDD,
      matching: find.text(gymToString(gyms[1]), findRichText: true)
    ).last;
    await tester.tap(gymSel);
    await tester.pumpAndSettle();
    await tester.tap(timeField);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.tap(uploadField);
    await tester.pumpAndSettle();

    // In test mode the image picker is mocked by using the default profile pic the selected image
    await tester.tap(find.text(consts.GlobalConsts.photoGalleryText));
    await tester.pumpAndSettle();
    await tester.tap(postBtn);
    await tester.pumpAndSettle();   
    await tester.pump(Duration(milliseconds: 10000));
    dbRec = await getDBRecord('sample post 5', activities[2]);
    expect(dbRec.length, 1, reason: "Make sure there is exactly one entry in db");

    // Random posts
    for (int i = 0; i < numOfRandomPosts; i++){
      /*
        Pumping a Container first and then the app again with a different key
        forces Flutter to rebuild the widget tree AND reset the states
      */ 
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        MaterialApp(
          home: PostPage(
            postPageActs: actsAndGyms.activities,
            postPageGyms: actsAndGyms.gyms,
            viewModel: PostPageViewModel(
              postPageRepository: PostPageRepository(),
              uploadImageRepository: UploadImageRepository()
            ),
            key: const Key('postPage2'),
          ),
        )
      );
      await tester.pumpAndSettle();

      // Random string with a few emojis
      String randomText = '${test_helpers.generateRandomString(
        random.nextInt(100) + 1
        )}${test_helpers.generateEmojis()
      }';

      // Select an activity from the first few ones to avoid scrolling
      int randomIndex = random.nextInt(5);

      bool textSelected = random.nextBool();
      bool actSelected = random.nextBool();
      bool gymSelected = random.nextBool();
      bool dateSelected = random.nextBool();
      bool picSelected = random.nextBool();

      if (textSelected) {
        await tester.enterText(textField, randomText);
        await tester.pumpAndSettle();
      }

      if (actSelected) {
        await tester.tap(actDD);
        await tester.pumpAndSettle();
        var actSel = find.descendant(
          of: actDD,
          matching: find.text(activities[randomIndex])
        ).last;
        await tester.tap(actSel);
        await tester.pumpAndSettle();
        await tester.tapAt(Offset(0, 0));
      }

      if (gymSelected) {
        await tester.tap(gymDD);
        await tester.pumpAndSettle();
        var gymSel = find.descendant(
          of: gymDD,
          matching: find.text(gymToString(gyms[1]), findRichText: true)
        ).last;
        await tester.tap(gymSel);
        await tester.pumpAndSettle();
      }
      
      if (dateSelected) {
        await tester.tap(timeField);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();
      }
      
      if (picSelected) {
        await tester.tap(uploadField);
        await tester.pumpAndSettle();
        final photoGallery = find.text(consts.GlobalConsts.photoGalleryText);
        await tester.tap(photoGallery);
        await tester.pumpAndSettle();
      }

      await tester.tap(postBtn);
      await tester.pumpAndSettle();   

      if (textSelected) {
        final post = await db.collection('posts')
          .where('author', isEqualTo: await commonRepo.getUserID())
          .where('content', isEqualTo: randomText).get();
        expect(post.docs.length, 1, reason: "Make sure there is exactly one entry in db");
      } else {
        final errorText = find.text(consts.PostPageConsts.emptyFieldError);
        expect(errorText, findsOneWidget);
      }
    }
  });
}
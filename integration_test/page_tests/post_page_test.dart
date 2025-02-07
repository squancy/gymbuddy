import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:integration_test/integration_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_buddy/utils/helpers.dart' as helpers;
import 'package:gym_buddy/post_page.dart';
import 'package:gym_buddy/consts/common_consts.dart' as consts;
import 'package:gym_buddy/utils/test_utils/test_helpers.dart' as test_helpers;
import "dart:math";
String gymToString(Map<String, dynamic> gym) {
  return "${gym[gym.keys.toList()[0]]['name']}\t|\t${gym[gym.keys.toList()[0]]['address']}";
}

Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getDBRecord(String postText, String dayType) async {
  return (await db.collection('posts')
    .where('author', isEqualTo: await helpers.getUserID())
    .where('day_type', isEqualTo: dayType)
    .where('content', isEqualTo: postText).get()).docs;
}

Future<void> main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  await helpers.firebaseInit(test: true);
  final FirebaseFirestore db = FirebaseFirestore.instance;

  testWidgets('Post page testing', (tester) async {
    // Necessary for being able to enterText when not in debug mode 
    test_helpers.registerTextInput();

    // User with the given ID, its username is 'test' and can be found in the test database
    test_helpers.logInUser('b727fd96-f618-4121-b875-e5fb74539034');
    await tester.pumpWidget(MaterialApp(home: PostPage()));
    await tester.pumpAndSettle();   // First check the existance of widgets
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
    // Wait a second for the content to be loaded
    await tester.pump(Duration(milliseconds: 1000));

    await tester.tap(actDD);
    await tester.pumpAndSettle();
    await tester.pump(Duration(milliseconds: 1000));
    final actScroll = find.byType(Scrollable).first;
    var activities = await helpers.getAllActivitiesWithoutProps(db.collection('activities'));
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
    var gyms = (await helpers.getAllGymsWithProps(db.collection('gyms/budapest/gyms')));
    helpers.sortGymsByName(gyms);

    // NOTE: this takes a lot of time to run since it scrolls through thousands of gyms in a dropdown
    // for (final el in gyms) {
    //   final itemFinder = find.text(
    //     gymToString(el),
    //     findRichText: true
    //   );
    //   await tester.scrollUntilVisible(itemFinder, 500, scrollable: gymsScroll);
    //   expect(itemFinder, findsOneWidget);
    //   await tester.pumpAndSettle();
    // }

    // Posting without filling the text field is not permitted
    await tester.tapAt(Offset(0, 0)); // Make sure the dropdowns are closed by tapping outside
    await tester.pumpAndSettle();
    await tester.tap(postBtn);
    await tester.pumpAndSettle(); 

    final errorText = find.text(consts.PostPageConsts.emptyFieldError);
    expect(errorText, findsOneWidget);

    // // Post with just text
    // await tester.enterText(textField, 'sample post');
    // await tester.pumpAndSettle();
    // await tester.tap(postBtn);
    // await tester.pumpAndSettle();
    
    // // Make sure the new post is pushed to database
    // var post = await db.collection('posts')
    //   .where('author', isEqualTo: await helpers.getUserID())
    //   .where('content', isEqualTo: 'sample post').get();
    // print(post.docs.map((e) => e.data(),).toList());
    // expect(post.docs.length, 1, reason: "Make sure there is exactly one entry in db");

    // // Post with text and activity
    // await tester.enterText(textField, 'sample post 2');
    // await tester.pumpAndSettle();
    // await tester.tap(actDD);
    // await tester.pumpAndSettle();
    // var actSel = find.descendant(
    //   of: actDD,
    //   matching: find.text(activities[1])
    // ).last;
    // await tester.tap(actSel);
    // await tester.pumpAndSettle();
    // await tester.tapAt(Offset(0, 0)); // Make sure the dropdowns are closed by tapping outside
    // await tester.tap(postBtn);
    // await tester.pumpAndSettle();

    // // Make sure it is pushed to db
    // var dbRec = await getDBRecord('sample post 2', activities[1]);
    // expect(dbRec.length, 1, reason: "Make sure there is exactly one entry in db");

    // // Post with text, activity and gym
    // await tester.enterText(textField, 'sample post 3');
    // await tester.pumpAndSettle();
    // await tester.tap(actDD);
    // await tester.pumpAndSettle();
    // actSel = find.descendant(
    //   of: actDD,
    //   matching: find.text(activities[2])
    // ).last;
    // await tester.tap(actSel);
    // await tester.pumpAndSettle();
    // await tester.tapAt(Offset(0, 0)); // Make sure the dropdowns are closed by tapping outside
    // await tester.tap(gymDD);
    // await tester.pumpAndSettle();
    // var gymSel = find.descendant(
    //   of: gymDD,
    //   matching: find.text(gymToString(gyms[2]), findRichText: true)
    // ).last;
    // await tester.tap(gymSel);
    // await tester.pumpAndSettle();
    // await tester.tap(postBtn);
    // await tester.pumpAndSettle();

    // // Make sure it is pushed to db
    // dbRec = await getDBRecord('sample post 3', activities[2]);
    // expect(dbRec.length, 1, reason: "Make sure there is exactly one entry in db");

    // // Post with text, activity, gym and time
    // await tester.enterText(textField, 'sample post 4');
    // await tester.pumpAndSettle();
    // await tester.tap(actDD);
    // await tester.pumpAndSettle();
    // actSel = find.descendant(
    //   of: actDD,
    //   matching: find.text(activities[2])
    // ).last;
    // await tester.tap(actSel);
    // await tester.pumpAndSettle();
    // await tester.tapAt(Offset(0, 0)); // Make sure the dropdowns are closed by tapping outside
    // await tester.tap(gymDD);
    // await tester.pumpAndSettle();
    // gymSel = find.descendant(
    //   of: gymDD,
    //   matching: find.text(gymToString(gyms[1]), findRichText: true)
    // ).last;
    // await tester.tap(gymSel);
    // await tester.pumpAndSettle();
    // await tester.tap(timeField);
    // await tester.pumpAndSettle();
    // await tester.tap(find.text('Done'));
    // await tester.pumpAndSettle();
    // await tester.tap(postBtn);
    // await tester.pumpAndSettle();   

    // // Make sure it is pushed to db
    // dbRec = await getDBRecord('sample post 4', activities[2]);
    // expect(dbRec.length, 1, reason: "Make sure there is exactly one entry in db");

    // // Post with text, activity, gym, time and image upload
    // await tester.enterText(textField, 'sample post 5');
    // await tester.pumpAndSettle();
    // await tester.tap(actDD);
    // await tester.pumpAndSettle();
    // actSel = find.descendant(
    //   of: actDD,
    //   matching: find.text(activities[2])
    // ).last;
    // await tester.tap(actSel);
    // await tester.pumpAndSettle();
    // await tester.tapAt(Offset(0, 0)); // Make sure the dropdowns are closed by tapping outside
    // await tester.tap(gymDD);
    // await tester.pumpAndSettle();
    // gymSel = find.descendant(
    //   of: gymDD,
    //   matching: find.text(gymToString(gyms[1]), findRichText: true)
    // ).last;
    // await tester.tap(gymSel);
    // await tester.pumpAndSettle();
    // await tester.tap(timeField);
    // await tester.pumpAndSettle();
    // await tester.tap(find.text('Done'));
    // await tester.pumpAndSettle();
    // await tester.tap(uploadField);
    // await tester.pumpAndSettle();
    // // In test mode the image picker is mocked by using the default profile pic the selected image
    // await tester.tap(find.text(consts.GlobalConsts.photoGalleryText));
    // await tester.pumpAndSettle();
    // await tester.tap(postBtn);
    // await tester.pumpAndSettle();   
    // await tester.pump(Duration(milliseconds: 10000));
    // dbRec = await getDBRecord('sample post 5', activities[2]);
    // expect(dbRec.length, 1, reason: "Make sure there is exactly one entry in db");

    // TODO: instead of hardcoding the test cases generate a bunch of random ones
    // and programatically check the correctness of each case
    final random = Random();
    // Post with text, activity, gym, time and image upload
    for (int i = 0; i < 10; i++){
      int randomIndex = random.nextInt(activities.length);
      bool gymSelected = random.nextBool();
      bool dateSelected = random.nextBool();
      bool picSelected = random.nextBool();
      await tester.enterText(textField, "sample post $i");
      await tester.pumpAndSettle();
      await tester.tap(actDD);
      await tester.pumpAndSettle();
      var actSel = find.descendant(
        of: actDD,
        matching: find.text(activities[randomIndex])
      ).last;
      await tester.tap(actSel);
      await tester.pumpAndSettle();
      await tester.tapAt(Offset(0, 0));
      if (gymSelected){
         // Make sure the dropdowns are closed by tapping outside
        await tester.tap(gymDD);
        await tester.pumpAndSettle();
        var gymSel = find.descendant(
        of: gymDD,
        matching: find.text(gymToString(gyms[1]), findRichText: true)
      ).last;
        await tester.tap(gymSel);
        await tester.pumpAndSettle();
      }
      
      if (dateSelected){
        await tester.tap(timeField);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();
      }
      
      // In test mode the image picker is mocked by using the default profile pic the selected image
      if (picSelected){
        await tester.tap(uploadField);
        await tester.pumpAndSettle();
        final photoGallery = find.text(consts.GlobalConsts.photoGalleryText);
        if (photoGallery.evaluate().isNotEmpty) {
          await tester.tap(photoGallery);
          await tester.pumpAndSettle();
        }
      }

      await tester.tap(postBtn);
      await tester.pumpAndSettle();   
      await tester.pump(Duration(milliseconds: 10000));
      
      var dbRec = await getDBRecord("sample post $i", activities[randomIndex]);
      print("Gymselected: $gymSelected, DateSelected: $dateSelected, PicSelected: $picSelected");
      print("Database records found: ${dbRec.length}");
      expect(dbRec.length, 1, reason: "Make sure there is exactly one entry in db");
    }
  });
}
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:gym_buddy/data/repository/post_builder/post_builder_repository.dart';
import 'package:gym_buddy/data/repository/profile/profile_field_repository.dart';
import 'package:gym_buddy/data/repository/profile/profile_repository.dart';
import 'package:gym_buddy/ui/profile/view_models/profile_field_view_model.dart';
import 'package:gym_buddy/ui/profile/view_models/profile_page_view_model.dart';
import 'package:integration_test/integration_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_buddy/utils/test_utils/test_helpers.dart' as test_helpers;
import 'package:gym_buddy/consts/common_consts.dart' as consts;
import 'package:image_fade/image_fade.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:gym_buddy/utils/time_ago_format.dart';
import 'package:gym_buddy/data/repository/core/common_repository.dart';
import 'package:gym_buddy/ui/post_builder/view_models/post_builder_view_model.dart';
import 'package:gym_buddy/ui/profile/widgets/profile_page_screen.dart';

Future<void> main() async {
  final CommonRepository commonRepo = CommonRepository();
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  await commonRepo.firebaseInit(test: true);
  final FirebaseFirestore db = FirebaseFirestore.instance;

  final newBioTxt = 'new bio';
  final newUnameTxt = 'new display username';

  Future<String> getBio() async {
    return (await db.collection('user_settings')
      .doc(await commonRepo.getUserID())
      .get())
      .data()?['bio'];
  }

  Future<String> getDisplayUname() async {
    return (await db.collection('user_settings')
      .doc(await commonRepo.getUserID())
      .get())
      .data()?['display_username'];
  }

  Future<Map<String, dynamic>> getUserData() async {
    final userData = (await db.collection('users')
      .where('id', isEqualTo: await commonRepo.getUserID())
      .get())
      .docs
      .toList()[0]
      .data();
    
    final userSettingsData = (await db.collection('user_settings')
      .doc(await commonRepo.getUserID())
      .get())
      .data();
    
    return {
      'bio': userSettingsData?['bio'],
      'display_username': userSettingsData?['display_username'],
      'profile_pic_url': userSettingsData?['profile_pic_url'],
      'username': userData['username'],
      'profile_pic_path': userSettingsData?['profile_pic_path']
    };
  }

  testWidgets('Profile page testing', (tester) async {
    final SharedPreferencesAsync prefs = SharedPreferencesAsync();
    timeago.setLocaleMessages('en', CustomMessages());

    // Necessary for being able to enterText when not in debug mode 
    test_helpers.registerTextInput();

    // User with the given ID, its username is 'test' and can be found in the test database
    // This user does not have any posts
    test_helpers.logInUser('b727fd96-f618-4121-b875-e5fb74539034');
    await tester.pumpWidget(MaterialApp(home: ProfilePage(
      viewModel: ProfilePageViewModel(
        profileRepository: ProfileRepository(),
        commonRepository: CommonRepository(),
        postBuilderRepository: PostBuilderRepository()
      ),
      viewModelField: ProfileFieldViewModel(
        profileFieldRepository: ProfileFieldRepository()
      ),
    )));

    Future<void> doubleTap(obj) async {
      await tester.tap(obj);
      await tester.pump(kDoubleTapMinTime);
      await tester.tap(obj);
    }

    Future<void> changeUserDataField(Key key, String content, obj, f) async {
      await doubleTap(obj); 
      await tester.pumpAndSettle();
      final udataField = find.byKey(key);
      expect(udataField, findsOneWidget);
      await tester.enterText(udataField, content);
      await tester.tapAt(Offset(0, 0)); // data field is saved in db when user taps outside the textfield
      await tester.pumpAndSettle();
      final curData = await f();
      expect(curData, content);   
    }

    Finder findBio() {
      return find.byKey(const Key('bioField'));
    }

    Finder findUname() {
      return find.byKey(const Key('displayUnameField'));
    }

    /*
      General note: now the profile page is only responsible for displaying the logged in user's content
      Once we implement more functionality it's going to handle any user's profile
      Thus, some test cases only make sense now (e.g., the presence of the log out button)
      But generally, separate test cases will be needed once we implement it
    */

    // Get user data and make sure they are displayed correctly on the profile page
    final udata = await getUserData();

    await tester.pumpAndSettle();
    final displayUname = find.text(udata['display_username']);
    expect(displayUname, findsOneWidget);

    final uname = find.text("@${udata['username']}");
    expect(uname, findsOneWidget);

    final bio = find.text(udata['bio']);
    expect(bio, findsOneWidget);

    final logOutIcon = find.byIcon(Icons.logout_rounded);
    expect(logOutIcon, findsOneWidget); 

    await tester.pumpAndSettle();

    final image = find.byKey(const Key('profilePic')).evaluate().single.widget as ImageFade;
    expect(image.image is NetworkImage, true); // this user has a custom profile pic
    final networkImg = image.image as NetworkImage;
    expect(networkImg.url, udata['profile_pic_url']);

    await changeUserDataField(const Key('bioField'), newBioTxt, bio, getBio);
    await changeUserDataField(const Key('displayUnameField'), newUnameTxt, displayUname, getDisplayUname);

    // Single taps should not make the fields editable
    await tester.tap(find.text(newBioTxt));
    expect(findBio(), findsNothing);

    await tester.tap(find.text(newUnameTxt));
    expect(findUname(), findsNothing);

    // Taps on the other field while one is being in edit mode is an edge case
    await doubleTap(find.text(newBioTxt));
    await tester.pumpAndSettle();
    await tester.tap(find.text(newUnameTxt));
    await tester.pumpAndSettle();
    await tester.pump(Duration(milliseconds: 1000));
    expect(findBio(), findsNothing);
    expect(findUname(), findsNothing);
    expect(await getBio(), newBioTxt);
    expect(await getDisplayUname(), newUnameTxt);

    await doubleTap(find.text(newUnameTxt));
    await tester.pumpAndSettle();
    await tester.tap(find.text(newBioTxt));
    await tester.pumpAndSettle();
    await tester.pump(Duration(milliseconds: 1000));
    expect(findBio(), findsNothing);
    expect(findUname(), findsNothing);
    expect(await getBio(), newBioTxt);
    expect(await getDisplayUname(), newUnameTxt);

    // Random taps and then edit both fields
    await doubleTap(find.text(newUnameTxt));
    await tester.pumpAndSettle();
    expect(findBio(), findsNothing);
    expect(findUname(), findsOneWidget);

    await doubleTap(find.text(newBioTxt));
    await tester.pumpAndSettle();
    expect(findBio(), findsOneWidget);
    expect(findUname(), findsNothing);

    await doubleTap(find.text(newBioTxt));
    await tester.pumpAndSettle();
    expect(findBio(), findsOneWidget);
    expect(findUname(), findsNothing);

    await tester.tap(find.text(newBioTxt));
    await tester.pumpAndSettle();
    expect(findBio(), findsOneWidget);
    expect(findUname(), findsNothing);

    await tester.tap(find.text(newUnameTxt));
    await tester.pumpAndSettle();
    expect(findBio(), findsNothing);
    expect(findUname(), findsNothing);

    await tester.tap(find.text(newBioTxt));
    await tester.pumpAndSettle();
    expect(findBio(), findsNothing);
    expect(findUname(), findsNothing);

    await doubleTap(find.text(newBioTxt));
    await tester.pumpAndSettle();
    expect(findBio(), findsOneWidget);
    expect(findUname(), findsNothing);

    await doubleTap(find.text(newBioTxt));
    await tester.pumpAndSettle();
    expect(findBio(), findsOneWidget);
    expect(findUname(), findsNothing);
    
    await doubleTap(find.text(newUnameTxt));
    await tester.pumpAndSettle();
    expect(findBio(), findsNothing);
    expect(findUname(), findsOneWidget);

    await doubleTap(find.text(newUnameTxt));
    await tester.pumpAndSettle();
    expect(findBio(), findsNothing);
    expect(findUname(), findsOneWidget);
    await changeUserDataField(const Key('displayUnameField'), 'a', find.text(newUnameTxt), getDisplayUname);
    await tester.pumpAndSettle();

    await doubleTap(find.text(newBioTxt));
    await tester.pumpAndSettle();
    expect(findBio(), findsOneWidget);
    expect(findUname(), findsNothing);
    await changeUserDataField(const Key('bioField'), 'b', find.text(newBioTxt), getBio);
    await tester.pumpAndSettle();
    await tester.pump(Duration(milliseconds: 1000)); // wait for db to be populated
    expect(await getDisplayUname(), 'a');
    expect(await getBio(), 'b');

    // Empty display username and bio are permitted
    // When clicking outside the bio/username textfield it should display the default text
    await changeUserDataField(const Key('displayUnameField'), '', find.text('a'), getDisplayUname);
    await tester.pumpAndSettle();
    await tester.tapAt(Offset(0, 0));
    await tester.pumpAndSettle();
    expect(findBio(), findsNothing);
    expect(findUname(), findsOneWidget);

    await tester.tap(findUname());
    await tester.pumpAndSettle();
    await tester.enterText(findUname(), 'very new username');
    await tester.pumpAndSettle();
    await changeUserDataField(const Key('bioField'), '', find.text('b'), getBio);
    await tester.pumpAndSettle();
    expect(await getDisplayUname(), 'very new username');
    expect(await getBio(), '');
    expect(findBio(), findsOneWidget);
    expect(findUname(), findsNothing);

    // Change profile picture
    await doubleTap(find.byKey(const Key('profilePic')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(consts.GlobalConsts.photoGalleryText));
    await tester.pumpAndSettle();

    // Make sure it's changed in db as well
    final newProfilePicPath = (await getUserData())['profile_pic_path'];
    expect(newProfilePicPath != udata['profile_pic_path'], true);

    // Log out user
    await tester.tap(logOutIcon);
    await tester.pump(Duration(milliseconds: 2000)); // wait for log out to complete
    expect(await prefs.getBool('loggedIn'), false);

    // This user has a lot of posts so post pagination can also be tested 
    test_helpers.logInUser('4f307ff7-f201-4732-93a9-72810a52e194');
    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
    await tester.pumpWidget(MaterialApp(home: ProfilePage(
      viewModel: ProfilePageViewModel(
        profileRepository: ProfileRepository(),
        commonRepository: CommonRepository(),
        postBuilderRepository: PostBuilderRepository()
      ),
      viewModelField: ProfileFieldViewModel(
        profileFieldRepository: ProfileFieldRepository()
      ),
    )));
    await tester.pumpAndSettle();
    final postDUname = await getDisplayUname();

    // This user has the default profile picture
    final imagePP = find.byKey(const Key('profilePic')).evaluate().single.widget as ImageFade;
    expect(imagePP.image is AssetImage, true); // this user has a custom profile pic
    final assetImg = imagePP.image as AssetImage;
    expect(assetImg.assetName, consts.GlobalConsts.defaultProfilePicPath);

    // Get all posts by the user 
    var userPosts = (await db.collection('posts')
      .where('author', isEqualTo: await commonRepo.getUserID())
      .orderBy('date', descending: true)
      .get()).docs;
    final postScroll = find.byType(Scrollable).first;
    for (final post in userPosts) {
      final String postID = post.reference.id;
      final Map<String, dynamic> postData = post.data();
      final postToFind = find.byKey(Key(postID));

      // Scroll to post
      await tester.scrollUntilVisible(postToFind, 500, scrollable: postScroll);
      expect(postToFind, findsOneWidget);

      final authorDUname = find.descendant(
        of: postToFind,
        matching: find.text(postDUname)
      );
      expect(authorDUname, findsOneWidget);

      final agoText = find.descendant(
        of: postToFind,
        matching: find.text(timeago.format(post['date'].toDate()))
      );
      expect(agoText, findsOneWidget);

      final authorProfilePic = find.descendant(
        of: postToFind,
        matching: find.byType(Image)
      );
      final img = authorProfilePic.evaluate().first.widget as Image;
      final assetImg = img.image as AssetImage;

      // this user has the default profile pic which is loaded as an asset image
      final assetImgName = assetImg.assetName; 
      expect(authorProfilePic, findsOneWidget);
      expect(assetImgName, consts.GlobalConsts.defaultProfilePicPath);

      // Make sure every piece of content appears correctly in the post
      for (final el in <String>['content', 'gym', 'when', 'day_type']) {
        String text = '';
        if (el == 'gym' && (postData[el] as String).isNotEmpty) {
          text = (await db.doc('gyms/budapest/gyms/${postData[el]}').get()).data()?['name'];
        } else if (el == 'when' && postData[el] != null) {
          text = DateFormat('MM-dd hh:mm a').format(postData[el].toDate()).toString();
        } else if (postData[el] != null) {
          text = postData[el];
        }

        if (text.isNotEmpty) {
          final elTxt = find.descendant(
            of: postToFind,
            matching: find.text(text)
          );
          await tester.scrollUntilVisible(elTxt, 500, scrollable: postScroll);
          expect(elTxt, findsOneWidget);
          
          if (el == 'gym' || el == 'when' || el == 'day_type') {
            final fieldIconData = PostBuilderViewModel().getPostIcon(el);
            final icon = find.descendant(
              of: postToFind,
              matching: find.byIcon(fieldIconData)
            ); 
            expect(icon, findsOneWidget); 
          }
        }
      }

      // Also test images attached to the post
      List<dynamic> imgUrls = post['download_url_list'];
      if (imgUrls.isNotEmpty) {
        final imgFade = find.descendant(
          of: postToFind,
          matching: find.byType(ImageFade)
        );

        for (final el in imgFade.evaluate()) {
          await tester.scrollUntilVisible(
            find.byWidget(el.widget),
            500,
            scrollable: find.descendant(
              of: postToFind,
              matching: find.byType(Scrollable)
            )
          );
        }

        final imgf = imgFade.evaluate().toList().map((el) => el.widget as ImageFade).toList();
        for (int i = 0; i < imgf.length; i++) {
          final networkImg = imgf[i].image as NetworkImage;
          expect(networkImg.url, imgUrls[i]);
        }
      }
    }
  });
}
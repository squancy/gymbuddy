import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gym_buddy/utils/helpers.dart' as helpers;
import 'package:gym_buddy/signup_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_buddy/consts/common_consts.dart' as consts;

Future<void> main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  await helpers.firebaseInit(test: true);
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final users = db.collection('users');

  testWidgets('Sign up test with Firestore', (tester) async {
    await tester.pumpWidget(MaterialApp(home: SignupPage()));
    final signupBtn = find.widgetWithText(FilledButton, 'Sign up');

    List<Finder> fields = [];
    for (final labelName in ['Username', 'Email', 'Password', 'Confirm password']) {
      final labelField = find.ancestor(
        of: find.text(labelName),
        matching: find.byType(TextField),
      );
      fields.add(labelField);
      expect(labelField, findsOneWidget);
    }

    await tester.enterText(fields[0], "test");
    await tester.enterText(fields[1], "t@abc.com");
    await tester.enterText(fields[2], "password");
    await tester.enterText(fields[3], "password");

    await tester.tap(signupBtn);
    await tester.pumpAndSettle(); 
    final usernameTakenMsg = find.text(consts.SignupConsts.usernameTakenText);
    expect(usernameTakenMsg, findsOneWidget);

    // Make sure it is not pushed to db
    QuerySnapshot usersWithUsername = await users.where('username', isEqualTo: 'test').get();
    expect(usersWithUsername.docs.length, 1);

    await tester.enterText(fields[0], "newuser1");
    await tester.tap(signupBtn);
    await tester.pumpAndSettle(); 
    final emailTakenMsg = find.text(consts.SignupConsts.emailAddrTakenText);
    print(emailTakenMsg);
    expect(emailTakenMsg, findsOneWidget);

    // Make sure it is not pushed to db
    usersWithUsername = await users.where('username', isEqualTo: 'newuser1').get();
    expect(usersWithUsername.docs.isEmpty, true);

    await tester.enterText(fields[1], "newemail@newemail.com");
    await tester.tap(signupBtn);
    await tester.pumpAndSettle();

    // Make sure it is pushed to db
    usersWithUsername = await users.where('username', isEqualTo: 'newuser1').get();
    expect(usersWithUsername.docs.isEmpty, false);

    final homepage = find.byKey(Key('homepage'));
    expect(homepage, findsOneWidget);
  });
  testWidgets("Signup page test for login navigation", (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: SignupPage()));
    final loginBtn = find.widgetWithText(TextButton, consts.SignupConsts.accountExistsText); 
    await tester.tap(loginBtn);
    await tester.pumpAndSettle();
    expect(find.text(consts.LoginConsts.mainScreenText), findsOneWidget);
  });
}
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_buddy/consts/common_consts.dart' as consts;
import 'package:gym_buddy/ui/auth/view_models/signup_view_model.dart';
import 'package:gym_buddy/data/repository/auth/signup_repository.dart';
import 'package:gym_buddy/data/repository/auth/email_repository.dart';
import 'package:gym_buddy/data/service/common_service.dart';
import 'package:gym_buddy/ui/auth/widgets/signup_screen.dart';
import 'package:gym_buddy/data/repository/core/common_repository.dart';
import 'package:gym_buddy/routes.dart';

Future<void> main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  await CommonRepository().firebaseInit(test: true);
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final users = db.collection('users');

  testWidgets('Sign up test with Firestore', (tester) async {
    // Remove the user a previous run created, so the test can be re-run
    final leftovers = await users.where('username', isEqualTo: 'username_does_not_exist').get();
    for (final doc in leftovers.docs) {
      await doc.reference.delete();
      await db.collection('user_settings').doc(doc.id).delete();
    }

    // Use the seed user's actual email rather than assuming it
    final existingUser = await users.where('username', isEqualTo: 'test').get();
    expect(existingUser.docs.length, 1);
    final String existingEmail = existingUser.docs.first.data()['email'];

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: CustomRoutes.generateRoute,
        home: SignupPage(
          viewModel:SignupViewModel(
            signupRepository: SignupRepository(
              commononService: CommonService()
            ),
            emailRepository: EmailRepository()
          )
        )
      )
    );
    final signupBtn = find.widgetWithText(FilledButton, 'Sign up');

    List<Finder> fields = [];
    for (final labelName in ['Username', 'Email', 'Password']) {
      final labelField = find.ancestor(
        of: find.text(labelName),
        matching: find.byType(TextField),
      );
      fields.add(labelField);
      expect(labelField, findsOneWidget);
    }

    await tester.enterText(fields[0], "test");
    await tester.enterText(fields[1], existingEmail);
    await tester.enterText(fields[2], "password");

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Male').last);
    await tester.pumpAndSettle();

    await tester.tap(signupBtn);
    await tester.pumpAndSettle(); 
    final usernameTakenMsg = find.text(consts.SignupConsts.usernameTakenText);
    expect(usernameTakenMsg, findsOneWidget);

    // Make sure it is not pushed to db
    QuerySnapshot usersWithUsername = await users.where('username', isEqualTo: 'test').get();
    expect(usersWithUsername.docs.length, 1);

    await tester.enterText(fields[0], "username_does_not_exist");
    await tester.tap(signupBtn);
    await tester.pumpAndSettle(); 
    final emailTakenMsg = find.text(consts.SignupConsts.emailAddrTakenText);
    expect(emailTakenMsg, findsOneWidget);

    // Make sure it is not pushed to db
    usersWithUsername = await users.where('username', isEqualTo: 'username_does_not_exist').get();
    expect(usersWithUsername.docs.isEmpty, true);

    await tester.enterText(fields[1], "newemail@newemail.com");
    await tester.tap(signupBtn);
    await tester.pumpAndSettle();

    // Make sure it is pushed to db
    usersWithUsername = await users.where('username', isEqualTo: 'username_does_not_exist').get();
    expect(usersWithUsername.docs.isEmpty, false);

    final homepage = find.byKey(Key('homepage'));
    expect(homepage, findsOneWidget);
  });

  testWidgets("Signup page test for login navigation", (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: CustomRoutes.generateRoute,
        home: SignupPage(
          viewModel:SignupViewModel(
            signupRepository: SignupRepository(
              commononService: CommonService()
            ),
            emailRepository: EmailRepository()
          )
        )
      )
    );
    final loginBtn = find.widgetWithText(TextButton, consts.SignupConsts.accountExistsText); 
    await tester.tap(loginBtn);
    await tester.pumpAndSettle();
    expect(find.text(consts.LoginConsts.mainScreenText), findsOneWidget);
  });
}
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:integration_test/integration_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_buddy/consts/common_consts.dart';
import 'package:gym_buddy/ui/auth/view_models/login_view_model.dart';
import 'package:gym_buddy/ui/auth/widgets/login_screen.dart';
import 'package:gym_buddy/data/repository/auth/login_repository.dart';
import 'package:gym_buddy/data/repository/auth/signup_repository.dart';
import 'package:gym_buddy/data/service/common_service.dart';
import 'package:gym_buddy/data/repository/core/common_repository.dart';

Future<void> main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  await CommonRepository().firebaseInit(test: GlobalConsts.test);
  final FirebaseFirestore db = FirebaseFirestore.instance;

  testWidgets('Log in page testing with Firestore', (tester) async {
    await tester.pumpWidget(MaterialApp(home: LoginPage(
      viewModel: LoginViewModel(
        loginRepository: LoginRepository(),
        signupRepository: SignupRepository(
          commononService: CommonService()
        )
      )
    )));

    final loginBtn = find.widgetWithText(FilledButton, LoginConsts.appBarText);
    List<Finder> fields = [];
    for (final labelName in ['Email', 'Password']) {
      final labelField = find.ancestor(
        of: find.text(labelName),
        matching: find.byType(TextField),
      );
      fields.add(labelField);
    }

    List<String> emails = ["thisuserdoesnotexists@example.com", "asd@test.com"];

    List<String> passwords = ["incorrect password", "asdasd"];

    for (int i = 0; i < 2; i++) {
      for (int j = 0; j < 2; j++) {
        await tester.enterText(fields[0], emails[i]);
        await tester.enterText(fields[1], passwords[j]);
        await tester.tap(loginBtn);
        await tester.pumpAndSettle();
        (bool, String, String) res = await LoginRepository().validateLogin(
          email: emails[i],
          password: passwords[j]
        );
        if (i == 1 && j == 1) {
          final user = (await db.collection('users').where('email', isEqualTo: emails[i])
            .get())
            .docs[0]
            .data();
          expect(res, (true, '', user['id']));
          expect(find.byKey(Key('homepage')), findsOneWidget);
        } else {
          expect(res, (false, ForgotPasswordConsts.wrongCredentialsText, ''));
          expect(find.text(ForgotPasswordConsts.wrongCredentialsText), findsOneWidget);
        }
      }
    }
  });
  group("Navigation testing", () {
    testWidgets("Login page test for homepage navigation", (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: LoginPage(
        viewModel: LoginViewModel(
          loginRepository: LoginRepository(),
          signupRepository: SignupRepository(
            commononService: CommonService()
          )
        )
      )));
      final loginBtn = find.widgetWithText(FilledButton, LoginConsts.appBarText);
      List<Finder> fields = [];
      for (final labelName in ['Email', 'Password']) {
        final labelField = find.ancestor(
          of: find.text(labelName),
          matching: find.byType(TextField),
        );
        fields.add(labelField);
      }
      await tester.enterText(fields[0], "asd@test.com");
      await tester.enterText(fields[1], "asdasd");
      await tester.pumpAndSettle(Duration(seconds: 2));
      await tester.tap(loginBtn);
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(Duration(seconds: 2));
      expect(find.byKey(Key('homepage')), findsOneWidget);
    });

    testWidgets("Login page test for forgot password navigation", (WidgetTester tester) async {
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
      await tester.pumpWidget(MaterialApp(home: LoginPage(
        viewModel: LoginViewModel(
          loginRepository: LoginRepository(),
          signupRepository: SignupRepository(
            commononService: CommonService()
          )
        )
      )));
      await tester.pumpAndSettle();
      final forgotPasswordBtn = find.widgetWithText(TextButton, LoginConsts.forgotPasswordText);
      await tester.tap(forgotPasswordBtn);
      await tester.pumpAndSettle();
      expect(find.byKey(Key("forgotPasswordPage")), findsOneWidget);
    });
  });
}

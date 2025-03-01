import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:integration_test/integration_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_buddy/utils/helpers.dart' as helpers;
import 'package:gym_buddy/consts/common_consts.dart' as consts;
import 'package:gym_buddy/ui/auth/widgets/forgot_pass_screen.dart';
import 'package:gym_buddy/ui/auth/view_models/forgot_pass_view_model.dart';
import 'package:gym_buddy/data/repository/email_repository.dart';
import 'package:gym_buddy/data/repository/forgot_pass_repository.dart';

Future<void> main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  await helpers.firebaseInit(test: true);
  final FirebaseFirestore db = FirebaseFirestore.instance;

  testWidgets('Forgot password page testing (also other pages that are related)', (tester) async {
    await tester.pumpWidget(MaterialApp(home: ForgotPasswordPage(
      viewModel: ForgotPassViewModel(
        emailRepository: EmailRepository(),
        forgotPassRepository: ForgotPassRepository()
      ),
    )));

    final String wrongEmail = 'does_not_exist@example.com';
    final String correctEmail = 'mark@pearscom.com';

    final sendPwdBtn = find.widgetWithText(
      FilledButton,
      consts.ForgotPasswordConsts.sendBtnText
    );

    final emailField = find.ancestor(
      of: find.text('Email'),
      matching: find.byType(TextField),
    ); 

    // Email not in firestore
    await tester.enterText(emailField, wrongEmail);
    await tester.pumpAndSettle();
    await tester.tap(sendPwdBtn);
    await tester.pumpAndSettle();
    expect(find.text(consts.ForgotPasswordConsts.userNotExistsText), findsOneWidget);

    // Email in firestore
    await tester.tap(emailField);
    await tester.enterText(emailField, correctEmail);
    await tester.pumpAndSettle();
    await tester.tap(sendPwdBtn);
    await tester.pumpAndSettle();

    /*
      Now the user should be redirected to the the page where they can enter the code
      received in email
      To test whether the email has actually been sent one can give a valid email address
      and temporarily add this email to one of the users in db
    */

    // Make sure the widgets appear on the screen
    // With this page transition is also tested implicitly
    final mainText = find.text(consts.ForgotPasswordConsts.codePageMainText);
    expect(mainText, findsOneWidget);
    final infoText = find.text(consts.ForgotPasswordConsts.codePageInfoText);
    expect(infoText, findsOneWidget);
    final codeField = find.ancestor(
      of: find.text('Code'),
      matching: find.byType(TextField),
    );
    expect(codeField, findsOneWidget);
    final confirmBtn = find.widgetWithText(
      FilledButton,
      'Confirm'
    );
    expect(confirmBtn, findsOneWidget);
    final resendBtn = find.byKey(const Key('resendBtn'));
    expect(resendBtn, findsOneWidget);

    // Wrong code is entered
    await tester.enterText(codeField, 'wrong_code');
    await tester.pumpAndSettle();
    await tester.tap(confirmBtn);
    await tester.pumpAndSettle();
    expect(find.text(consts.ForgotPasswordConsts.codePageErrorText), findsOneWidget);

    // Tapping the resend code button while still in coundown phase should not send an email
    await tester.tap(resendBtn);
    await tester.pumpAndSettle();
    await tester.tap(resendBtn);
    await tester.pumpAndSettle();

    // Wait for 60 seconds to be able to resend a code
    await tester.pump(Duration(seconds: 60));
    await tester.pumpAndSettle();
    await tester.tap(resendBtn);
    await tester.pumpAndSettle();
    await tester.pump(Duration(seconds: 2));

    // Correct code is entered
    final String correctCode = (await db.collection('users')
      .where('email', isEqualTo: correctEmail)
      .get())
      .docs
      .toList()[0]
      .data()['temp_pass'];

    await tester.tap(codeField); 
    await tester.pumpAndSettle();
    await tester.enterText(codeField, correctCode);
    await tester.pumpAndSettle();
    await tester.tap(confirmBtn);
    await tester.pumpAndSettle();

    // Now the user should be on the page where they can set a new password
    final setPwdText = find.text(consts.ForgotPasswordConsts.createNewPassText);
    expect(setPwdText, findsOneWidget);
    final subText = find.text(consts.ForgotPasswordConsts.renewPasswordInfoText);
    expect(subText, findsOneWidget);
    final passwordField = find.ancestor(
      of: find.text('Password'),
      matching: find.byType(TextField),
    );
    expect(passwordField, findsOneWidget);
    final confPasswordField = find.ancestor(
      of: find.text('Confirm password'),
      matching: find.byType(TextField),
    );
    expect(confPasswordField, findsOneWidget);
    final updatePassBtn = find.widgetWithText(
      FilledButton,
      'Update password'
    );
    expect(updatePassBtn, findsOneWidget);

    // First give a few incorrect passwords
    await tester.enterText(passwordField, 'asd');
    await tester.pumpAndSettle();
    await tester.enterText(confPasswordField, '');
    await tester.pumpAndSettle();
    await tester.tap(updatePassBtn);
    await tester.pumpAndSettle();
    expect(find.text(consts.SignupConsts.allFieldsText), findsOneWidget);
    await tester.tap(confPasswordField); 
    await tester.pumpAndSettle();
    await tester.enterText(confPasswordField, 'def');
    await tester.pumpAndSettle();
    await tester.tap(updatePassBtn);
    await tester.pumpAndSettle();
    expect(find.text(consts.SignupConsts.passwordMismatchText), findsOneWidget);
    await tester.tap(confPasswordField); 
    await tester.pumpAndSettle();
    await tester.enterText(confPasswordField, 'asd');
    await tester.pumpAndSettle();
    await tester.tap(updatePassBtn);
    await tester.pumpAndSettle();
    expect(find.text(consts.SignupConsts.passwordLengthText), findsOneWidget);
    await tester.tap(passwordField); 
    await tester.pumpAndSettle();
    await tester.enterText(passwordField, 'newpassword');
    await tester.pumpAndSettle();
    await tester.tap(confPasswordField); 
    await tester.pumpAndSettle();
    await tester.enterText(confPasswordField, 'newpassword');
    await tester.pumpAndSettle();
    await tester.tap(updatePassBtn);
    await tester.pumpAndSettle();

    // Now the user should be redirected to the log in page
    final loginEmailField = find.ancestor(
      of: find.text('Email'),
      matching: find.byType(TextField),
    );

    final loginPasswordField = find.ancestor(
      of: find.text('Password'),
      matching: find.byType(TextField),
    );

    final logInBtn = find.widgetWithText(
      FilledButton,
      consts.LoginConsts.appBarText
    );

    await tester.enterText(loginEmailField, correctEmail);
    await tester.pumpAndSettle();
    await tester.enterText(loginPasswordField, 'newpassword');
    await tester.pumpAndSettle();
    await tester.tap(logInBtn);
    await tester.pumpAndSettle();
    expect(find.byKey(Key('homepage')), findsOneWidget);
  });
}

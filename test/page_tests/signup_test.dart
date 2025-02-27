import 'package:gym_buddy/handlers/handle_signup.dart';
import 'package:gym_buddy/consts/common_consts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:gym_buddy/ui/auth/view_models/signup_view_model.dart';
import 'package:gym_buddy/data/repository/signup_repository.dart';
import 'package:gym_buddy/data/repository/email_repository.dart';
import 'package:gym_buddy/service/common_service.dart';
import 'package:gym_buddy/ui/auth/widgets/signup_screen.dart';

void main() {
  final SignupViewModel signupViewModel = SignupViewModel(
    signupRepository: SignupRepository(commononService: CommonService()),
    emailRepository: EmailRepository()
  );

  /// Sign up logic test START
  group('Test the validity of username, email and password fields on the sign up page', () {
    group('If any field is empty return false', () {
      List<dynamic> emptyTestcases = [
        ('', '', '', ''),
        ('testusername', '', '', ''),
        ('', 'testemail@test.com', '', ''),
        ('', '', 'password', ''),
        ('', '', '', 'password'),
        ('testusername', 'testemail@test.com', '', ''),
        ('testusername', '', 'password', ''),
        ('testusername', '', '', 'password'),
        ('', 'testemail@test.com', 'password', ''),
        ('', 'testemail@test.com', '', 'password'),
        ('', '', 'password', 'password'),
        ('testusername', 'testemail@test.com', 'password', ''),
        ('testusername', 'testemail@test.com', '', 'password'),
        ('testusername', '', 'password', 'password'),
        ('testusername', '', 'password', 'password'),
      ];

      for (final testcase in emptyTestcases) {
        test('Some of the fields are empty', () {
          final t = ValidateSignup(testcase.$1, testcase.$2, testcase.$3, testcase.$4);      
          final v = t.isValidParams();
          expect(v, (false, SignupConsts.allFieldsText));
        });
      }
    });
    test(SignupConsts.usernameTooLongText, () {
      final t = ValidateSignup('a' * (ValidateSignupConsts.maxUsernameLength + 1), 'testemail@test.com', 'password', 'password');
      final v = t.isValidParams();
      expect(v, (false, SignupConsts.usernameTooLongText));
    });

    List<dynamic> invalidEmails = [
      ('testusername', 'wrongemail', 'password', 'password'),
      ('testusername', 'wrongemail@', 'password', 'password'),
      ('testusername', '@wrongemail', 'password', 'password'),
      ('testusername', 'wron@gemail', 'password', 'password')
    ];

    for (final testcase in invalidEmails) {
      test('Invalid emails', () {
        final t = ValidateSignup(testcase.$1, testcase.$2, testcase.$3, testcase.$4);      
        final v = t.isValidParams();
        expect(v, (false, SignupConsts.invalidEmailText));
      });
    }

    test('Password length < ${ValidateSignupConsts.maxPasswordLength}', () {
      final t = ValidateSignup('testusername', 'testemail@test.com', 'asd', 'asd');      
      final v = t.isValidParams();
      expect(v, (false, SignupConsts.passwordLengthText));
    });

    test(SignupConsts.invalidUsernameText, () {
      final t = ValidateSignup('hey(=)', 'testemail@test.com', 'password', 'password');      
      final v = t.isValidParams();
      expect(v, (false, SignupConsts.invalidUsernameText));
    });

    test(SignupConsts.passwordMismatchText, () {
      final t = ValidateSignup('testusername', 'testemail@test.com', 'password1', 'password2');      
      final v = t.isValidParams();
      expect(v, (false, SignupConsts.passwordMismatchText));
    });

    test('All parameters are valid', () {
      final t = ValidateSignup('testusername', 'testemail@test.com', 'password', 'password');      
      final v = t.isValidParams();
      expect(v, (true, ''));
    });
  });
  /// Sign up logic test END
  
  /// Sign up UI test START
  testWidgets('Sign up page UI testing', (tester) async {
    await tester.pumpWidget(MaterialApp(home: SignupPage(viewModel: signupViewModel,)));

    final createAccountTxt = find.text(SignupConsts.mainScreenText);
    final signupBtn = find.widgetWithText(FilledButton, SignupConsts.appBarText);
    final haveAccountBtn = find.widgetWithText(TextButton, SignupConsts.accountExistsText);

    List<Finder> fields = [];
    for (final labelName in ['Username', 'Email', 'Password', 'Confirm password']) {
      final labelField = find.ancestor(
        of: find.text(labelName),
        matching: find.byType(TextField),
      );
      fields.add(labelField);
      expect(labelField, findsOneWidget);
    }

    expect(createAccountTxt, findsOneWidget);
    expect(signupBtn, findsOneWidget);
    expect(haveAccountBtn, findsOneWidget);

    await tester.tap(signupBtn);
    await tester.pumpAndSettle();
    final msgFill = find.text(SignupConsts.allFieldsText);
    expect(msgFill, findsOneWidget);

    await tester.enterText(fields[0], "a" * 101);
    await tester.enterText(fields[1], "a");
    await tester.enterText(fields[2], "a");
    await tester.enterText(fields[3], "a");
    await tester.tap(signupBtn);
    await tester.pumpAndSettle();
    final msgTooLong = find.text(SignupConsts.usernameTooLongText);
    expect(msgTooLong, findsOneWidget);

    await tester.enterText(fields[0], "testusername");
    await tester.enterText(fields[1], "invalid email");
    await tester.tap(signupBtn);
    await tester.pumpAndSettle();
    final msgInvalidEmail = find.text(SignupConsts.invalidEmailText);
    expect(msgInvalidEmail, findsOneWidget);

    await tester.enterText(fields[1], "valid@email.com");
    await tester.enterText(fields[2], "short");
    await tester.enterText(fields[3], "short");
    await tester.tap(signupBtn);
    await tester.pumpAndSettle();
    final msgShortPwd = find.text(SignupConsts.passwordLengthText);
    expect(msgShortPwd, findsOneWidget);

    await tester.enterText(fields[2], "password1");
    await tester.enterText(fields[3], "password2");
    await tester.tap(signupBtn);
    await tester.pumpAndSettle();
    final msgMismatchPwd = find.text(SignupConsts.passwordMismatchText);
    expect(msgMismatchPwd, findsOneWidget);

    await tester.enterText(fields[0], "invalid_username!");
    await tester.enterText(fields[2], "password");
    await tester.enterText(fields[3], "password");
    await tester.tap(signupBtn);
    await tester.pumpAndSettle();
    final msgInvalidUname = find.text(SignupConsts.invalidUsernameText);
    expect(msgInvalidUname, findsOneWidget);
  });
  /// Sign up UI test END
}
import 'package:gym_buddy/consts/common_consts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:gym_buddy/ui/auth/view_models/signup_view_model.dart';
import 'package:gym_buddy/ui/auth/widgets/signup_screen.dart';
import '../fakes/fake_auth_repositories.dart';

SignupViewModel makeViewModel({FakeSignupRepository? signupRepository}) {
  return SignupViewModel(
    signupRepository: signupRepository ?? FakeSignupRepository(),
    emailRepository: FakeEmailRepository()
  );
}

void main() {
  /// Sign up logic test START
  group('Test the validity of username, email, password and sex fields on the sign up page', () {
    final SignupViewModel signupViewModel = makeViewModel();

    group('If any field is empty return false', () {
      // (username, email, password, sex)
      List<(String, String, String, String)> emptyTestcases = [
        ('', '', '', ''),
        ('testusername', '', '', ''),
        ('', 'testemail@test.com', '', ''),
        ('', '', 'password', ''),
        ('', '', '', 'Male'),
        ('testusername', 'testemail@test.com', '', ''),
        ('testusername', '', 'password', ''),
        ('', 'testemail@test.com', 'password', ''),
        ('testusername', 'testemail@test.com', 'password', ''),
        ('', 'testemail@test.com', 'password', 'Male'),
        ('testusername', '', 'password', 'Male'),
        ('testusername', 'testemail@test.com', '', 'Male'),
      ];

      for (final testcase in emptyTestcases) {
        test('Some of the fields are empty: $testcase', () {
          final v = signupViewModel.isValidParams(
            username: testcase.$1,
            email: testcase.$2,
            password: testcase.$3,
            sex: testcase.$4
          );
          expect(v, (false, SignupConsts.allFieldsText));
        });
      }
    });

    test(SignupConsts.usernameTooLongText, () {
      final v = signupViewModel.isValidParams(
        username: 'a' * (ValidateSignupConsts.maxUsernameLength + 1),
        email: 'testemail@test.com',
        password: 'password',
        sex: 'Male'
      );
      expect(v, (false, SignupConsts.usernameTooLongText));
    });

    List<String> invalidEmails = ['wrongemail', 'wrongemail@', '@wrongemail', 'wron@gemail'];

    for (final email in invalidEmails) {
      test('Invalid email: $email', () {
        final v = signupViewModel.isValidParams(
          username: 'testusername',
          email: email,
          password: 'password',
          sex: 'Female'
        );
        expect(v, (false, SignupConsts.invalidEmailText));
      });
    }

    test('Password length < ${ValidateSignupConsts.maxPasswordLength}', () {
      final v = signupViewModel.isValidParams(
        username: 'testusername',
        email: 'testemail@test.com',
        password: 'asd',
        sex: 'Male'
      );
      expect(v, (false, SignupConsts.passwordLengthText));
    });

    test(SignupConsts.invalidUsernameText, () {
      final v = signupViewModel.isValidParams(
        username: 'hey(=)',
        email: 'testemail@test.com',
        password: 'password',
        sex: 'Male'
      );
      expect(v, (false, SignupConsts.invalidUsernameText));
    });

    test('All parameters are valid', () {
      final v = signupViewModel.isValidParams(
        username: 'testusername',
        email: 'testemail@test.com',
        password: 'password',
        sex: 'Female'
      );
      expect(v, (true, ''));
    });
  });
  /// Sign up logic test END

  /// Sign up UI test START
  testWidgets('Sign up page UI testing', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(home: SignupPage(
      viewModel: makeViewModel(
        signupRepository: FakeSignupRepository(takenUsernames: {'takenname'})
      )
    )));

    final createAccountTxt = find.text(SignupConsts.mainScreenText);
    final signupBtn = find.widgetWithText(FilledButton, SignupConsts.appBarText);
    final haveAccountBtn = find.widgetWithText(TextButton, SignupConsts.accountExistsText);
    final sexDropdown = find.byType(DropdownButtonFormField<String>);

    List<Finder> fields = [];
    for (final labelName in ['Username', 'Email', 'Password']) {
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
    expect(sexDropdown, findsOneWidget);

    Future<void> submit() async {
      await tester.tap(signupBtn);
      await tester.pumpAndSettle();
    }

    await submit();
    expect(find.text(SignupConsts.allFieldsText), findsOneWidget);

    // Every text field filled but no sex chosen
    await tester.enterText(fields[0], 'testusername');
    await tester.enterText(fields[1], 'valid@email.com');
    await tester.enterText(fields[2], 'password');
    await submit();
    expect(find.text(SignupConsts.allFieldsText), findsOneWidget);

    await tester.tap(sexDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Male').last);
    await tester.pumpAndSettle();
    expect(find.text('Male'), findsOneWidget);

    await tester.enterText(fields[0], 'a' * 101);
    await submit();
    expect(find.text(SignupConsts.usernameTooLongText), findsOneWidget);

    await tester.enterText(fields[0], 'testusername');
    await tester.enterText(fields[1], 'invalid email');
    await submit();
    expect(find.text(SignupConsts.invalidEmailText), findsOneWidget);

    await tester.enterText(fields[1], 'valid@email.com');
    await tester.enterText(fields[2], 'short');
    await submit();
    expect(find.text(SignupConsts.passwordLengthText), findsOneWidget);

    await tester.enterText(fields[0], 'invalid_username!');
    await tester.enterText(fields[2], 'password');
    await submit();
    expect(find.text(SignupConsts.invalidUsernameText), findsOneWidget);

    // Passes validation, then the repository reports the username as taken
    await tester.enterText(fields[0], 'takenname');
    await submit();
    expect(find.text('username taken'), findsOneWidget);
  });
  /// Sign up UI test END
}

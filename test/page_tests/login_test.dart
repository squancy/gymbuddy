import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:gym_buddy/consts/common_consts.dart';
import 'package:gym_buddy/ui/auth/widgets/login_screen.dart';
import 'package:gym_buddy/ui/auth/view_models/login_view_model.dart';
import 'package:gym_buddy/data/repository/auth/signup_repository.dart';
import 'package:gym_buddy/data/repository/auth/login_repository.dart';
import 'package:gym_buddy/data/service/common_service.dart';

void main() {
  testWidgets('Login page UI testing', (tester) async {
    final LoginPage loginPage = LoginPage(
      viewModel: LoginViewModel(
        signupRepository: SignupRepository(commononService: CommonService()),
        loginRepository: LoginRepository()
      )
    );

    await tester.pumpWidget(MaterialApp(home: loginPage));

    final welcomeBackTxt = find.text(LoginConsts.mainScreenText);
    expect(welcomeBackTxt, findsOneWidget);
    
    final loginBtn = find.widgetWithText(FilledButton, LoginConsts.appBarText);
    expect(loginBtn, findsOneWidget);

    final forgotPassBtn = find.widgetWithText(TextButton, LoginConsts.forgotPasswordText);
    expect(forgotPassBtn, findsOneWidget);

    List<Finder> fields = [];
    for (final labelName in ['Email', 'Password']) {
      final labelField = find.ancestor(
        of: find.text(labelName),
        matching: find.byType(TextField),
      );
      fields.add(labelField);
      expect(labelField, findsOneWidget);
    }
  });
}
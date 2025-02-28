import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:gym_buddy/consts/common_consts.dart';
import 'package:gym_buddy/ui/auth/widgets/forgot_pass_screen.dart';
import 'package:gym_buddy/ui/auth/view_models/forgot_pass_view_model.dart';
import 'package:gym_buddy/data/repository/email_repository.dart';
import 'package:gym_buddy/data/repository/forgot_pass_repository.dart';

void main() {
  testWidgets('Forgot password UI testing', (tester) async {
    final ForgotPasswordPage forgotPasswordPage = ForgotPasswordPage(
      viewModel: ForgotPassViewModel(
      emailRepository: EmailRepository(),
      forgotPassRepository: ForgotPassRepository()
      )
    );

    await tester.pumpWidget(MaterialApp(home: forgotPasswordPage));
    final newPwdTxt = find.text(ForgotPasswordConsts.mainScreenText);
    expect(newPwdTxt, findsOneWidget);

    final infoTxt = find.text(ForgotPasswordConsts.infoText);
    expect(infoTxt, findsOneWidget);

    final sendPwdBtn = find.widgetWithText(FilledButton, ForgotPasswordConsts.sendBtnText);
    expect(sendPwdBtn, findsOneWidget);

    final field = find.ancestor(
      of: find.text('Email'),
      matching: find.byType(TextField),
    );

    expect(field, findsOneWidget);
  });
}
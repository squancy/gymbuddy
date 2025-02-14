import 'package:flutter_test/flutter_test.dart';
import 'package:gym_buddy/forgot_password.dart';
import 'package:flutter/material.dart';
import 'package:gym_buddy/consts/common_consts.dart';

void main() {
  testWidgets('Forgot password UI testing', (tester) async {
    await tester.pumpWidget(MaterialApp(home: ForgotPasswordPage()));
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
import 'package:flutter/material.dart';
import 'package:gym_buddy/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_buddy/consts/common_consts.dart';

void main() {
  testWidgets('Homepage test', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: WelcomePage()));
    await tester.pumpAndSettle();
    final loginBtn = find.text(HomeConsts.loginButtonTitle);
    expect(loginBtn, findsOneWidget);
    await tester.tap(loginBtn);
    await tester.pumpAndSettle();
    expect(find.text(LoginConsts.mainScreenText), findsOneWidget);
  });
}
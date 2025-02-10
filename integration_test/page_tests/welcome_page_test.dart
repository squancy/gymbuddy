import 'package:flutter/material.dart';
import 'package:gym_buddy/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_buddy/consts/common_consts.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gym_buddy/utils/helpers.dart' as helpers;

Future<void> main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  await helpers.firebaseInit(test: true);
  group("Welcome page testing", () {
    testWidgets('Welcomepage test for login navigation', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: WelcomePage(key: const Key("welcomePage1"))));

      /*
        pumpAndSettle() cannot be used here since there is a background animation running forever
      */
      await tester.pump(Duration(seconds: 5));
      final loginBtn = find.text(WelcomePageConsts.loginButtonTitle);
      expect(loginBtn, findsOneWidget);

      await tester.tap(loginBtn);
      await tester.pumpAndSettle();
      expect(find.text(LoginConsts.mainScreenText), findsOneWidget);
    });

    // Navigating back to Welcome page
    testWidgets("Welcomepage test for signup navigation", (WidgetTester tester) async {
      // Reload the page and reset states
      await tester.pumpWidget(Container());
      await tester.pumpAndSettle();
      await tester.pumpWidget(MaterialApp(home: WelcomePage(key: const Key("welcomePage2"))));
      await tester.pump(Duration(seconds: 5));

      final signupBtn = find.text(WelcomePageConsts.signupButtonTitle);
      expect(signupBtn, findsOneWidget);

      await tester.tap(signupBtn);
      await tester.pumpAndSettle();
      expect(find.text(SignupConsts.mainScreenText), findsOneWidget);
    });
  });
}

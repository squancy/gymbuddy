import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_buddy/consts/common_consts.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gym_buddy/ui/main/view_models/welcome_page_view_model.dart';
import 'package:gym_buddy/ui/main/widgets/welcome_page_screen.dart';
import 'package:gym_buddy/data/repository/core/common_repository.dart';

Future<void> main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  await CommonRepository().firebaseInit(test: true);
  group("Welcome page testing", () {
    testWidgets('Welcomepage test for login navigation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: WelcomePage(
            key: const Key("welcomePage1"),
            viewModel: WelcomePageViewModel(),
          )
        )
      );

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
      await tester.pumpWidget(
        MaterialApp(
          home: WelcomePage(
            key: const Key("welcomePage2"),
            viewModel: WelcomePageViewModel(),
          )
        )
      );
      await tester.pump(Duration(seconds: 5));

      final signupBtn = find.text(WelcomePageConsts.signupButtonTitle);
      expect(signupBtn, findsOneWidget);

      await tester.tap(signupBtn);
      await tester.pumpAndSettle();
      expect(find.text(SignupConsts.mainScreenText), findsOneWidget);
    });
  });
}

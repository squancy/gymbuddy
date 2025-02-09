import 'package:flutter/material.dart';
import 'package:gym_buddy/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_buddy/consts/common_consts.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gym_buddy/utils/helpers.dart' as helpers;

Future<void> main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  await helpers.firebaseInit(test: true);
  group("Welcomepage testing", (){
    testWidgets('Welcomepage test for login navigation', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: WelcomePage(key: const Key("welcomePage1"))));
    print("Welcome page loaded");
    await tester.pump(Duration(seconds: 5)); 

    final loginBtn = find.text(HomeConsts.loginButtonTitle);
    print("Login button found");
    expect(loginBtn, findsOneWidget);
    await tester.tap(loginBtn);
    await tester.pumpAndSettle(); 
    print("Navigated to login page");
    expect(find.text(LoginConsts.mainScreenText), findsOneWidget);
  });

  //Navigating back to Welcome page
  testWidgets("Welcomepage test for signup navigation", (WidgetTester tester) async {
    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();

    await tester.pumpWidget(MaterialApp(home: WelcomePage(key: const Key("welcomePage5"))));
    print("Welcome page loaded again");
    await tester.pump(Duration(seconds: 5)); 

    final signupBtn = find.text(HomeConsts.signupButtonTitle);
    print("Signup button found");
    expect(signupBtn, findsOneWidget);
    await tester.tap(signupBtn);
    await tester.pumpAndSettle(); 
    print("Navigated to signup page");
    expect(find.text(SignupConsts.mainScreenText), findsOneWidget);
  });
    
  });

  }

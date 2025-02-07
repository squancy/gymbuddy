import 'package:flutter/material.dart';
import 'consts/common_consts.dart';
import 'forgot_password.dart';
import 'handlers/handle_login.dart';
import 'home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moye/widgets/gradient_overlay.dart';
import 'utils/helpers.dart' as helpers;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

// Login page state
class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController(); 
  final TextEditingController _passwordController = TextEditingController(); 
  final FocusNode _emailFocusNode = FocusNode(); 
  final FocusNode _passwordFocusNode = FocusNode();

  final ValueNotifier<String> _loginStatus = ValueNotifier<String>(""); 

  Future<void> _login() async {
    final String email = _emailController.text.trim(); 
    final String password = _passwordController.text.trim();

    _loginStatus.value = '';

    final loginValidator = CheckLogin(email, password); 
    final (bool isValid, String errorMsg, String userID) = await loginValidator.validateLogin();
    if (!isValid) {
      setState(() { _loginStatus.value = errorMsg; });
      return;
    }

    final SharedPreferencesAsync prefs = SharedPreferencesAsync();
    await prefs.setBool('loggedIn', true);
    await prefs.setString('userID', userID);

    // On successful login redirect user to the home page
    // Also delete every previous route so that he cannot go back with a right swipe
    setState(() {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => HomePage(),
        ),
        (Route<dynamic> route) => false,
      );
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  // Build the login page
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: Container(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                    child: Text(
                      LoginConsts.mainScreenText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 34,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ).withGradientOverlay(gradient: LinearGradient(colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.tertiary,
                      Theme.of(context).colorScheme.primary,
                    ])),
                  ),
                  // Email textfield
                  Padding( 
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                    child: helpers.BlackTextfield(
                      context,
                      'Email',
                      _emailController,
                      _emailFocusNode,
                      isPassword: false,
                      isEmail: true
                    )
                  ),
                  // Password textfield
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                    child: helpers.BlackTextfield(
                      context,
                      'Password',
                      _passwordController,
                      _passwordFocusNode,
                      isPassword: true,
                      isEmail: false
                    )
                  ),
                  Column(
                    children: [
                      // Login button
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                        child: SizedBox(
                          height: 45,
                          child: helpers.ProgressBtn(
                            onPressedFn: _login,
                            child: Text(LoginConsts.appBarText)
                          )
                        ),
                      ),
                      // Forgot password button
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
                            );
                          },
                          child: Text(
                            LoginConsts.forgotPasswordText, // 'Forgot password' text
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface
                            )
                          )
                        ),
                      ),
                      ValueListenableBuilder<String>(
                        valueListenable: _loginStatus,
                        builder: (BuildContext context, String value, Widget? child) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                            child: Text(
                              value,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface
                              )
                            ),
                          );
                        }
                      ),
                    ],
                  )
                ],
              ),
            )
          )
        ),
      ),
    );
  }
}
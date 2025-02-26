import 'package:flutter/material.dart';
import 'package:gym_buddy/consts/common_consts.dart';
import 'package:moye/widgets/gradient_overlay.dart';
import 'package:gym_buddy/utils/helpers.dart' as helpers;
import 'package:gym_buddy/login_page.dart';
import 'package:gym_buddy/ui/signup/view_model/signup_view_model.dart';
import 'package:gym_buddy/home_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({
    required this.viewModel,
    super.key
  });

  final SignupViewModel viewModel;

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.pageTransition.addListener(() {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => HomePage(
            postPageActs: widget.viewModel.actsAndGyms.activities,
            postPageGyms: widget.viewModel.actsAndGyms.gyms,
          ),
        ),
        (Route<dynamic> route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                        child: Text(
                          SignupConsts.mainScreenText, // "Create account"
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 34,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ).withGradientOverlay(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.tertiary,
                              Theme.of(context).colorScheme.primary,
                            ],
                          ),
                        ),
                      ),
                      // Username textfield
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                        child: helpers.BlackTextfield(
                          context,
                          SignupConsts.usernameText, // "Username"
                          widget.viewModel.usernameController,
                          widget.viewModel.usernameFocusNode,
                          isPassword: false,
                          isEmail: false,
                        ),
                      ),
                      // Email textfield
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                        child: helpers.BlackTextfield(
                          context,
                          SignupConsts.emailText, // "Email"
                          widget.viewModel.emailController,
                          widget.viewModel.emailFocusNode,
                          isPassword: false,
                          isEmail: true,
                        ),
                      ),
                      // Password textfield
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                        child: helpers.BlackTextfield(
                          context,
                          SignupConsts.passwordText, // "Password"
                          widget.viewModel.passwordController,
                          widget.viewModel.passwordFocusNode,
                          isPassword: true,
                          isEmail: false,
                        ),
                      ),
                      // Signup button
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 45,
                              child: helpers.ProgressBtn(
                                onPressedFn: widget.viewModel.signup,
                                child: Text(SignupConsts.appBarText), // "Sign up"
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginPage()),
                            );
                          },
                          child: Text(
                            SignupConsts.accountExistsText, // "Already have an account?"
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                      ValueListenableBuilder<String>(
                        valueListenable: widget.viewModel.signupStatus,
                        builder: (BuildContext context, String value, Widget? child) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                            child: Text(
                              value,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
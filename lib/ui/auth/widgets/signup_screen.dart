import 'package:flutter/material.dart';
import 'package:gym_buddy/consts/common_consts.dart';
import 'package:moye/widgets/gradient_overlay.dart';
import 'package:gym_buddy/utils/helpers.dart' as helpers;
import 'package:gym_buddy/ui/auth/view_models/signup_view_model.dart';
import 'package:gym_buddy/ui/auth/widgets/login_screen.dart';
import 'package:gym_buddy/ui/auth/view_models/login_view_model.dart';
import 'package:gym_buddy/data/repository/signup_repository.dart';
import 'package:gym_buddy/data/repository/login_repository.dart';
import 'package:gym_buddy/service/common_service.dart';

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

    // On successful sign up redirect user to the home page
    // Also delete every previous route so that he cannot go back with a right swipe
    widget.viewModel.pageTransition.addListener(_handlePageTransition);
  }

  void _handlePageTransition() {
    if (widget.viewModel.pageTransition.value == PageTransition.stayOnPage) return;
    Navigator.of(context).pushAndRemoveUntil(
      helpers.homePageRoute(widget.viewModel.actsAndGyms),
      (Route<dynamic> route) => false,
    );
  }

  @override
  void dispose() {
    widget.viewModel.pageTransition.removeListener(_handlePageTransition);
    super.dispose();
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
                          SignupConsts.mainScreenText, 
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
                          SignupConsts.usernameText, 
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
                          SignupConsts.emailText,
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
                          SignupConsts.passwordText,
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
                                child: Text(SignupConsts.appBarText), 
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
                              MaterialPageRoute(builder: (context) => LoginPage(
                                viewModel: LoginViewModel(
                                  signupRepository: SignupRepository(
                                    commononService: CommonService()
                                  ),
                                  loginRepository: LoginRepository()
                                ),
                              )),
                            );
                          },
                          child: Text(
                            SignupConsts.accountExistsText, 
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
import 'package:flutter/material.dart';
import 'package:gym_buddy/consts/common_consts.dart';
import 'package:gym_buddy/data/repository/email_repository.dart';
import 'package:gym_buddy/data/repository/forgot_pass_repository.dart';
import 'package:gym_buddy/ui/auth/view_models/login_view_model.dart';
import 'package:moye/widgets/gradient_overlay.dart';
import 'package:gym_buddy/ui/auth/widgets/forgot_pass_screen.dart';
import 'package:gym_buddy/ui/auth/view_models/forgot_pass_view_model.dart';
import 'package:gym_buddy/ui/core/common_ui.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    required this.viewModel,
    super.key,
  });

  final LoginViewModel viewModel;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  void initState() {
    super.initState();

    // On successful log in redirect user to the home page
    // Also delete every previous route so that he cannot go back with a right swipe
    widget.viewModel.pageTransition.addListener(_handlePageTransition);
  }

  void _handlePageTransition() {
    if (widget.viewModel.pageTransition.value == PageTransition.stayOnPage) return;
    Navigator.of(context).pushAndRemoveUntil(
      homePageRoute(widget.viewModel.actsAndGyms),
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
                  Padding( 
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                    child: BlackTextfield(
                      context,
                      'Email',
                      widget.viewModel.emailController,
                      widget.viewModel.emailFocusNode,
                      isPassword: false,
                      isEmail: true
                    )
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                    child: BlackTextfield(
                      context,
                      'Password',
                      widget.viewModel.passwordController,
                      widget.viewModel.passwordFocusNode,
                      isPassword: true,
                      isEmail: false
                    )
                  ),
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                        child: SizedBox(
                          height: 45,
                          child: ProgressBtn(
                            onPressedFn: widget.viewModel.login,
                            child: Text(LoginConsts.appBarText)
                          )
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ForgotPasswordPage(
                                viewModel: ForgotPassViewModel(
                                  emailRepository: EmailRepository(),
                                  forgotPassRepository: ForgotPassRepository()
                                )
                              )),
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
                        valueListenable: widget.viewModel.loginStatus,
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
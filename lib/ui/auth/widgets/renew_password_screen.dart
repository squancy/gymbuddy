import 'package:flutter/material.dart';
import 'package:gym_buddy/consts/common_consts.dart';
import 'package:moye/widgets/gradient_overlay.dart';
import 'package:gym_buddy/ui/auth/view_models/renew_password_view_model.dart';
import 'package:gym_buddy/ui/auth/widgets/login_screen.dart';
import 'package:gym_buddy/ui/auth/view_models/login_view_model.dart';
import 'package:gym_buddy/data/repository/login_repository.dart';
import 'package:gym_buddy/data/repository/signup_repository.dart';
import 'package:gym_buddy/service/common_service.dart';
import 'package:gym_buddy/ui/core/common_ui.dart';

class RenewPasswordPage extends StatefulWidget {
  final String userID;

  const RenewPasswordPage({
    required this.viewModel,
    required this.userID,
    super.key
  });

  final RenewPasswordViewModel viewModel;

  @override
  State<RenewPasswordPage> createState() => _RenewPasswordPageState();
}

class _RenewPasswordPageState extends State<RenewPasswordPage> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.pageTransition.addListener(_handlePageTransition);
  }

  void _handlePageTransition() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => LoginPage(
          viewModel: LoginViewModel(
            loginRepository: LoginRepository(),
            signupRepository: SignupRepository(
              commononService: CommonService()
            )
          )
        ),
      ),
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
                          ForgotPasswordConsts.createNewPassText, 
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
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                        child: Text(
                          ForgotPasswordConsts.renewPasswordInfoText,
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface)
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                        child: BlackTextfield(
                          context,
                          SignupConsts.passwordText, 
                          widget.viewModel.passwordController,
                          widget.viewModel.passwordFocusNode,
                          isPassword: true,
                          isEmail: false,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                        child: BlackTextfield(
                          context,
                          SignupConsts.passwordConfText, 
                          widget.viewModel.passwordConfController,
                          widget.viewModel.passwordConfFocusNode,
                          isPassword: true,
                          isEmail: false,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 45,
                              child: ProgressBtn(
                                onPressedFn: () {
                                  return widget.viewModel.checkPassword(widget.userID);
                                },
                                child:
                                  Text(ForgotPasswordConsts.updatePassText),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ValueListenableBuilder<String>(
                        valueListenable: widget.viewModel.passwordsStatus,
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

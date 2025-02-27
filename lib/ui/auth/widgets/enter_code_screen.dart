import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gym_buddy/renew_password.dart';
import 'package:gym_buddy/consts/common_consts.dart';
import 'package:moye/widgets/gradient_overlay.dart';
import 'package:gym_buddy/utils/helpers.dart' as helpers;
import 'package:timer_button/timer_button.dart';
import 'package:gym_buddy/ui/auth/view_models/enter_code_view_model.dart';

class EnterCodePage extends StatefulWidget {
  const EnterCodePage({
    required this.email,
    required this.userData,
    required this.viewModel,
    super.key
  });

  final String email;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> userData;
  final EnterCodeViewModel viewModel;

  @override
  State<EnterCodePage> createState() => _EnterCodePageState();
}

class _EnterCodePageState extends State<EnterCodePage> {
  @override
  void initState() {
    super.initState();

    // When the correct code is entered redirect user to the page
    // where they can change their password
    widget.viewModel.pageTransition.addListener(() {
      if (widget.viewModel.pageTransition.value == PageTransition.stayOnPage) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => RenewPasswordPage(
            userID: widget.viewModel.userIDRenewPass,
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
            child: Container(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                    child: Text(
                      ForgotPasswordConsts.codePageMainText,
                      style: TextStyle(
                        fontSize: 34,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ).withGradientOverlay(
                      gradient: LinearGradient(colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.tertiary,
                        Theme.of(context).colorScheme.primary,
                      ])
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                    child: Text(
                      ForgotPasswordConsts.codePageInfoText,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface
                      )
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                    child: helpers.BlackTextfield(
                      context,
                      'Code',
                      widget.viewModel.codeController,
                      widget.viewModel.codeFocusNode,
                      isPassword: false,
                      isEmail: true
                    )
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                    child: SizedBox(
                      height: 45,
                      child: helpers.ProgressBtn(
                        onPressedFn: () {
                          widget.viewModel.checkCode(
                            email: widget.email,
                            code: widget.viewModel.codeController.text
                          );
                        },
                        child: Text('Confirm')
                      )
                    ),
                  ),
                  ValueListenableBuilder<String>(
                    valueListenable: widget.viewModel.codeStatus,
                    builder: (BuildContext context, String value, Widget? child) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                        child: Text(
                          value,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface
                          ),
                        ),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                    child: TimerButton(
                      key: const Key('resendBtn'), // key for testing
                      label: 'Resend code',
                      timeOutInSeconds: 60,
                      onPressed: () {
                        widget.viewModel.sendPassword(
                          email: widget.email,
                          userData: widget.userData
                        );
                      },
                      disabledColor: Theme.of(context).colorScheme.surface,
                      color: Theme.of(context).colorScheme.secondary,
                      disabledTextStyle: TextStyle(
                        color: const Color.fromARGB(255, 145, 144, 144)
                      ),
                      activeTextStyle: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          )
        ),
      ),
    );
  }
}
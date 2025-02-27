import 'package:flutter/material.dart';
import 'package:gym_buddy/consts/common_consts.dart';
import 'package:moye/widgets/gradient_overlay.dart';
import 'package:gym_buddy/utils/helpers.dart' as helpers;
import 'package:gym_buddy/ui/auth/view_models/forgot_pass_view_model.dart';
import 'package:gym_buddy/enter_code_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({
    required this.viewModel,
    super.key
  });
  
  final ForgotPassViewModel viewModel;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.pageTransition.addListener(() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EnterCodePage(
            email: widget.viewModel.emailEnterCode as String,
            userData: widget.viewModel.userDataEnterCode as List<QueryDocumentSnapshot<Map<String, dynamic>>> 
          ) 
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: Key('forgotPasswordPage'), // Key for testing
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
                      ForgotPasswordConsts.mainScreenText, // 'New password'
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
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                    child: Text(
                      ForgotPasswordConsts.infoText, // 'We will send a temporary password to your email'
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface)
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                    child: helpers.BlackTextfield(
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
                    child: SizedBox(
                      height: 45,
                      child: helpers.ProgressBtn(
                        onPressedFn: widget.viewModel.sendPassword,
                        child: Text('Send password')
                      )
                    ),
                  ),
                  ValueListenableBuilder<String>(
                    valueListenable: widget.viewModel.forgotPassStatus,
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
          )
        ),
      ),
    );
  }
}
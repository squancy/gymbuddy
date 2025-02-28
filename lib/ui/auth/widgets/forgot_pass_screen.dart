import 'package:flutter/material.dart';
import 'package:gym_buddy/consts/common_consts.dart';
import 'package:gym_buddy/data/repository/email_repository.dart';
import 'package:gym_buddy/data/repository/enter_code_repository.dart';
import 'package:gym_buddy/data/repository/forgot_pass_repository.dart';
import 'package:gym_buddy/ui/auth/view_models/enter_code_view_model.dart';
import 'package:moye/widgets/gradient_overlay.dart';
import 'package:gym_buddy/utils/helpers.dart' as helpers;
import 'package:gym_buddy/ui/auth/view_models/forgot_pass_view_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_buddy/ui/auth/widgets/enter_code_screen.dart';

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

    // When a valid email address is entered redirect user to the
    // page where they can enter the code received in email
    widget.viewModel.pageTransition.addListener(_handlePageTransition);
  }

  void _handlePageTransition() {
    if (widget.viewModel.pageTransition.value == PageTransition.stayOnPage) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnterCodePage(
          email: widget.viewModel.emailEnterCode as String,
          userData: widget.viewModel.userDataEnterCode as List<QueryDocumentSnapshot<Map<String, dynamic>>>,
          viewModel: EnterCodeViewModel(
            emailRepository: EmailRepository(),
            forgotPassRepository: ForgotPassRepository(),
            enterCodeRepository: EnterCodeRepository()
          ),
        ) 
      ),
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
                      ForgotPasswordConsts.mainScreenText,
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
                      ForgotPasswordConsts.infoText, 
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
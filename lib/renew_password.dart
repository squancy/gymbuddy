import 'package:flutter/material.dart';
import 'package:gym_buddy/consts/common_consts.dart';
import 'utils/helpers.dart' as helpers;
import 'package:moye/widgets/gradient_overlay.dart';
import 'package:dbcrypt/dbcrypt.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'package:gym_buddy/handlers/handle_forgot_pass.dart';

class RenewPasswordPage extends StatefulWidget {
  @override
  _RenewPasswordPageState createState() => _RenewPasswordPageState();
}

class _RenewPasswordPageState extends State<RenewPasswordPage> {
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _passwordConfFocusNode = FocusNode();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfController = TextEditingController();
  final ValueNotifier<String> _passwordsStatus = ValueNotifier<String>("");

  @override
  void dispose() {
    _passwordFocusNode.dispose();
    _passwordConfFocusNode.dispose();
    super.dispose();
  }

  // Check if the password and password confirmation match

  Future<void> _renewpassword() async {
    final FirebaseFirestore db = FirebaseFirestore.instance;
    final String userID = "your_user_id"; // Replace with actual user ID
    final passwordValidator = ValidatePassword(
      _passwordController.text,
      _passwordConfController.text,
    );

    // Check password validation
    var (bool isValid, String errorMsg) = passwordValidator.isValidParams();
    if (!isValid) {
      setState(() {
        _passwordsStatus.value = errorMsg;
      });
      return;
    }

    try {
      // Hash the password and generate a salt
      final dbcrypt = DBCrypt();
      String salt = dbcrypt.gensaltWithRounds(10);
      String hashedPassword = dbcrypt.hashpw(_passwordController.text, salt);

      // Update the password in Firestore
      await db.collection('users').doc(userID).update({
        'password': hashedPassword,
        'salt': salt,
      });

      // Navigate to the LoginPage after successful password update
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginPage()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      // Handle Firestore update errors
      setState(() {
        _passwordsStatus.value = ForgotPasswordConsts.failureText;
      });
    }
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
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 0),
                        child: Text(
                          ForgotPasswordConsts
                              .createNewPassText, // "Create account"
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
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 0),
                        child: helpers.BlackTextfield(
                          context,
                          SignupConsts.passwordText, // "Password"
                          _passwordController,
                          _passwordFocusNode,
                          isPassword: true,
                          isEmail: false,
                        ),
                      ),
                      // Password confirmation textfield
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 0),
                        child: helpers.BlackTextfield(
                          context,
                          SignupConsts.passwordConfText, // "Confirm password"
                          _passwordConfController,
                          _passwordConfFocusNode,
                          isPassword: true,
                          isEmail: false,
                        ),
                      ),
                      // Signup button
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 0),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 45,
                              child: helpers.ProgressBtn(
                                onPressedFn: _renewpassword,
                                child: Text(ForgotPasswordConsts
                                    .updatePassText), // "Update password"
                              ),
                            ),
                          ],
                        ),
                      ),

                      ValueListenableBuilder<String>(
                        valueListenable: _passwordsStatus,
                        builder: (BuildContext context, String value,
                            Widget? child) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 0),
                            child: Text(
                              value,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface),
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

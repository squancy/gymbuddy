import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'consts/common_consts.dart';
import 'package:moye/widgets/gradient_overlay.dart';
import 'utils/helpers.dart' as helpers;
import 'package:gym_buddy/utils/email.dart' as email_send;
import 'package:gym_buddy/consts/email_templates.dart';
import 'package:gym_buddy/utils/test_utils/test_helpers.dart' as test_helpers;
import 'package:gym_buddy/enter_code_page.dart' as enter_code_page;

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final ValueNotifier<String> _forgotPassStatus = ValueNotifier<String>("");

  Future<void> _sendPassword() async {
    final String email = _emailController.text;
    final FirebaseFirestore db = FirebaseFirestore.instance;

    // Make sure the email is in db
    final userData = (
      await db.collection('users')
        .where('email', isEqualTo: email)
        .get())
      .docs
      .toList();
    if (userData.isEmpty) {
      setState(() {
        _forgotPassStatus.value = ForgotPasswordConsts.userNotExistsText;
      });
    } else {
      setState(() {
        _forgotPassStatus.value = '';
      });

      // Generate a temporary password: user can change it later in their profile
      final tempPass = test_helpers.generateRandomString(10);

      final username = userData[0].data()['username'];
      final userID = userData[0].reference.id;
      final TemporaryPassEmail tempPassEmail = TemporaryPassEmail(
        username: username,
        tempPass: tempPass
      );

      // Send temporary password to user's email address
      try {
        await email_send.sendEmail(
          from: GlobalConsts.infoEmail,
          to: email,
          subject: tempPassEmail.subject,
          content: tempPassEmail.generateEmail()
        );
      } catch (e) {
        setState(() {
          _forgotPassStatus.value = GlobalConsts.unknownErrorText;
        });
        return;
      }

      // Set temporary password in db
      await db.collection('users')
        .doc(userID)
        .update({'temp_pass': tempPass});

      // Redirect to a new page when user has to enter the code in the email
      setState(() {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => enter_code_page.EnterCodePage(email: email, userData: userData) 
          ),
        );
      });
    }
  }


  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    _forgotPassStatus.dispose();
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
                      _emailController,
                      _emailFocusNode,
                      isPassword: false,
                      isEmail: true
                    )
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                    child: SizedBox(
                      height: 45,
                      child: helpers.ProgressBtn(
                        onPressedFn: _sendPassword,
                        child: Text('Send password')
                      )
                    ),
                  ),
                  ValueListenableBuilder<String>(
                    valueListenable: _forgotPassStatus,
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
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gym_buddy/renew_password.dart';
import 'consts/common_consts.dart';
import 'package:moye/widgets/gradient_overlay.dart';
import 'utils/helpers.dart' as helpers;
import 'package:gym_buddy/utils/test_utils/test_helpers.dart' as test_helpers;
import 'package:gym_buddy/utils/email.dart' as email_send;
import 'package:gym_buddy/consts/email_templates.dart';
import 'package:timer_button/timer_button.dart';

class EnterCodePage extends StatefulWidget {
  final String email;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> userData;

  const EnterCodePage({
    required this.email,
    required this.userData,
    super.key
  });

  @override
  State<EnterCodePage> createState() => _EnterCodePageState();
}

class _EnterCodePageState extends State<EnterCodePage> {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final FocusNode _codeFocusNode = FocusNode();
  final TextEditingController _codeController = TextEditingController();
  final ValueNotifier<String> _codeStatus = ValueNotifier<String>("");
  final ValueNotifier<String> _forgotPassStatus = ValueNotifier<String>("");

  /// Make sure the user enters the correct code (=temporary password) received in email
  Future<void> _checkCode() async {
    final String code = _codeController.text;
    final String email = widget.email;

    // Get the ID of the potential user
    final userDocs = (await db
        .collection('users')
        .where('email', isEqualTo: email)
        .where('temp_pass', isEqualTo: code)
        .get())
      .docs;

    if (userDocs.isEmpty) {
      setState(() {
        _codeStatus.value = ForgotPasswordConsts.codePageErrorText;
      });
      return;
    } else if (userDocs.length == 1) {
      final String userID = userDocs.toList()[0].reference.id;

      // If the entered code is correct redirect user to the next page
      // There they can change their password
      setState(() {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => RenewPasswordPage(
              userID: userID,
            ),
          ),
          (Route<dynamic> route) => false,
        );
      });
    } else {
      setState(() {
        _codeStatus.value = GlobalConsts.unknownErrorText;
      });
    }
  }

  Future<void> _sendPassword() async {
    final String email = widget.email;
    final userData = widget.userData;
    final FirebaseFirestore db = FirebaseFirestore.instance;

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
        content: tempPassEmail.generateEmail());
    } catch (e) {
      setState(() {
        _forgotPassStatus.value = GlobalConsts.unknownErrorText;
      });
      return;
    }

    // Set temporary password in db
    await db.collection('users').doc(userID).update({'temp_pass': tempPass});
  }

  @override
  void dispose() {
    super.dispose();
    _codeController.dispose();
    _codeFocusNode.dispose();
    _codeStatus.dispose();
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
                      _codeController,
                      _codeFocusNode,
                      isPassword: false,
                      isEmail: true
                    )
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                    child: SizedBox(
                      height: 45,
                      child: helpers.ProgressBtn(
                        onPressedFn: _checkCode,
                        child: Text('Confirm')
                      )
                    ),
                  ),
                  ValueListenableBuilder<String>(
                    valueListenable: _codeStatus,
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
                      label: "Resend code",
                      timeOutInSeconds: 60,
                      onPressed: _sendPassword,
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
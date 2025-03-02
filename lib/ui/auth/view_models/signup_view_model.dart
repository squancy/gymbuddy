import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:gym_buddy/consts/common_consts.dart';
import 'package:email_validator/email_validator.dart';
import 'package:gym_buddy/data/repository/auth/signup_repository.dart';
import 'package:gym_buddy/data/repository/auth/email_repository.dart';
import 'package:gym_buddy/consts/email_templates.dart';
import 'package:gym_buddy/data/repository/core/common_repository.dart';

class SignupViewModel extends ChangeNotifier {
  SignupViewModel({
    required signupRepository,
    required emailRepository
  }) :
  _signupRepository = signupRepository,
  _emailRepository = emailRepository;

  final SignupRepository _signupRepository;
  final EmailRepository _emailRepository;

  final TextEditingController emailController = TextEditingController(); 
  final TextEditingController passwordController = TextEditingController(); 
  final TextEditingController usernameController = TextEditingController(); 
  final FocusNode emailFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();
  final FocusNode usernameFocusNode = FocusNode();

  final ValueNotifier<String> signupStatus = ValueNotifier<String>("");
  late ActGymRecord actsAndGyms;
  ValueNotifier<PageTransition> pageTransition = ValueNotifier(PageTransition.stayOnPage);

  (bool isValid, String errorMsg) isValidParams({
    required String username,
    required String email,
    required String password
    }) {
    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      return (false, SignupConsts.allFieldsText);
    } else if (username.length > ValidateSignupConsts.maxUsernameLength) {
      return (false, SignupConsts.usernameTooLongText);
    } else if (!EmailValidator.validate(email)) {
      return (false, SignupConsts.invalidEmailText);
    } else if (password.length < ValidateSignupConsts.maxPasswordLength) {
      return (false, SignupConsts.passwordLengthText);
    } else if (!RegExp(r'^[a-zA-Z0-9_\.]+$').hasMatch(username)) { 
      return (false, SignupConsts.invalidUsernameText); 
    }
    return (true, '');
  }

  Future<void> signup() async {
    final String email = emailController.text.trim();
    final String password = passwordController.text;
    final String username = usernameController.text.trim();

    try {
      signupStatus.value = '';
      if (!GlobalConsts.test) {
        await _signupRepository.requestPosition();
      }

      // Validate data for signup
      var (bool isValid, String errorMsg) = isValidParams(
        username: username, email: email, password: password
      );
      if (!isValid) {
        signupStatus.value = errorMsg;
        notifyListeners();
        return;
      }

      (isValid, errorMsg) = await _signupRepository.userExists(
        username: username, email: email
      );
      if (!isValid) {
        signupStatus.value = errorMsg;
        notifyListeners();
        return;
      }

      // At this point the validation was successful
      String userID;
      (isValid, errorMsg, userID) = await _signupRepository.insertToDB(
        username: username,
        email: email,
        password: password
      );
      if (!isValid) {
        signupStatus.value = errorMsg;
        notifyListeners();
        return;
      }

      // Send email to user about successful sign up
      final signUpEmail = SignUpEmail(username: username);
      await _emailRepository.sendEmail(
        from: GlobalConsts.infoEmail,
        to: email,
        template: signUpEmail
      );

      await _signupRepository.setUserState(userID: userID, loggedIn: true);

      actsAndGyms = await CommonRepository().getActivitiesAndGyms();

      pageTransition.value = PageTransition.goToNextPage;
    } catch (error) {
      log("signup(): $error");
      signupStatus.value = GlobalConsts.unknownErrorText;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    usernameController.dispose();

    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    usernameFocusNode.dispose();
    super.dispose();
  }
}
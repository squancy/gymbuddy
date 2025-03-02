import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:gym_buddy/consts/common_consts.dart';
import 'package:gym_buddy/data/repository/auth/signup_repository.dart';
import 'package:gym_buddy/data/repository/auth/login_repository.dart';
import 'package:gym_buddy/data/repository/core/common_repository.dart';

class LoginViewModel extends ChangeNotifier {
  LoginViewModel({
    required loginRepository,
    required signupRepository
  }) :
  _loginRepository = loginRepository,
  _signupRepository = signupRepository;

  final LoginRepository _loginRepository;
  final SignupRepository _signupRepository;

  final TextEditingController emailController = TextEditingController(); 
  final TextEditingController passwordController = TextEditingController(); 
  final FocusNode emailFocusNode = FocusNode(); 
  final FocusNode passwordFocusNode = FocusNode();

  final ValueNotifier<String> loginStatus = ValueNotifier<String>(""); 
  late ActGymRecord actsAndGyms;
  ValueNotifier<PageTransition> pageTransition = ValueNotifier(PageTransition.stayOnPage);

  Future<void> login() async {
    final String email = emailController.text.trim(); 
    final String password = passwordController.text.trim();

    loginStatus.value = '';

    try {
      final (bool isValid, String errorMsg, String userID) = await _loginRepository.validateLogin(
        email: email, password: password
      );
      if (!isValid) {
        loginStatus.value = errorMsg;
        notifyListeners();
        return;
      }

      await _signupRepository.setUserState(userID: userID, loggedIn: true);
      actsAndGyms = await CommonRepository().getActivitiesAndGyms();
      pageTransition.value = PageTransition.goToNextPage;
    } catch (error) {
      log("login(): $error");
      loginStatus.value = GlobalConsts.unknownErrorText;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }
}
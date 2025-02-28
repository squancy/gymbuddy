import 'package:flutter/material.dart';
import 'package:gym_buddy/consts/common_consts.dart';
import 'package:dbcrypt/dbcrypt.dart';
import 'package:gym_buddy/data/repository/renew_password_repository.dart';

class RenewPasswordViewModel extends ChangeNotifier {
  RenewPasswordViewModel({
    required renewPasswordRepository
  }) :
  _renewPasswordRepository = renewPasswordRepository;

  final RenewPasswordRepository _renewPasswordRepository;

  final FocusNode passwordFocusNode = FocusNode();
  final FocusNode passwordConfFocusNode = FocusNode();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordConfController = TextEditingController();
  final ValueNotifier<String> passwordsStatus = ValueNotifier<String>("");
  final _dbcrypt = DBCrypt();
  ValueNotifier<PageTransition> pageTransition = ValueNotifier(PageTransition.stayOnPage);

  (bool isValid, String errorMsg) _isValidPassword(String password, String passwordConf) {
    if (password.isEmpty || passwordConf.isEmpty) {
      return (false, SignupConsts.allFieldsText);
    } else if (password != passwordConf) {
      return (false, SignupConsts.passwordMismatchText);
    } else if (password.length < ValidateSignupConsts.maxPasswordLength) {
      return (false, SignupConsts.passwordLengthText);
    }
    return (true, '');
  }

  /// Make sure the two password fields match
  Future<void> checkPassword(String userID) async {
    var (bool isValid, String errorMsg) = _isValidPassword(
      passwordController.text,
      passwordConfController.text
    );

    if (!isValid) {
      passwordsStatus.value = errorMsg;
      notifyListeners();
      return;
    }

    try {
      // Hash the password and generate a salt
      String salt = _dbcrypt.gensaltWithRounds(10);
      String hashedPassword = _dbcrypt.hashpw(passwordController.text, salt);

      // Update the password in Firestore
      _renewPasswordRepository.updatePassword(
        userID: userID,
        hashedPassword: hashedPassword,
        salt: salt
      );

      // Navigate to LoginPage after successful password update
      pageTransition.value = PageTransition.goToNextPage;
    } catch (e) {
      passwordsStatus.value = ForgotPasswordConsts.failureText;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    passwordFocusNode.dispose();
    passwordController.dispose();
    passwordConfController.dispose();
    passwordConfFocusNode.dispose();
    passwordsStatus.dispose();
    super.dispose();
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_buddy/consts/common_consts.dart';

class HandleForgotPass {
  const HandleForgotPass(this.email);

  final String email;

  Future<bool> emailExists() async {
    // Check if email exists in DB
    return Future(() => true,);
  }
}

class ValidatePassword {
  ValidatePassword(
    this._password,
    this._passwordConf,
  );
  final String _password;
  final String _passwordConf;

  (bool isValid, String errorMsg) isValidParams() {
    if (_password.isEmpty || _passwordConf.isEmpty) {
      return (false, SignupConsts.allFieldsText);
    } else if (_password != _passwordConf) {
      return (false, SignupConsts.passwordMismatchText);
    } else if (_password.length < ValidateSignupConsts.maxPasswordLength) {
      return (false, SignupConsts.passwordLengthText);
    }
    return (true, '');
  }
}
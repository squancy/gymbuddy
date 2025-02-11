import 'package:email_validator/email_validator.dart';
import '../consts/common_consts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io' show Platform;
import 'package:uuid/uuid.dart';
import '../utils/helpers.dart' as helpers;
import 'package:dbcrypt/dbcrypt.dart';
import 'package:gym_buddy/consts/common_consts.dart' as consts;
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';

/*
  Validates parameters used during the sign up process
*/

class ValidateSignup {
  ValidateSignup(
    this._username,
    this._email,
    this._password,
    this._passwordConf,
  );

  final String _username;
  final String _email;
  final String _password;
  final String _passwordConf;

  (bool isValid, String errorMsg) isValidParams() {
    if (_username.isEmpty || _email.isEmpty || _password.isEmpty || _passwordConf.isEmpty) {
      return (false, SignupConsts.allFieldsText);
    } else if (_username.length > ValidateSignupConsts.maxUsernameLength) {
      return (false, SignupConsts.usernameTooLongText);
    } else if (!EmailValidator.validate(_email)) {
      return (false, SignupConsts.invalidEmailText);
    } else if (_password != _passwordConf) {
      return (false, SignupConsts.passwordMismatchText);
    } else if (_password.length < ValidateSignupConsts.maxPasswordLength) {
      return (false, SignupConsts.passwordLengthText);
    } else if (!RegExp(r'^[a-zA-Z0-9_\.]+$').hasMatch(_username)) { // TODO - Add more characters
      return (false, SignupConsts.invalidUsernameText); 
    }
    return (true, '');
  }

  /// Make sure username and email are unique
  Future<(bool isValid, String errorMsg)> userExists() async {
    try {
      final FirebaseFirestore db = FirebaseFirestore.instance;
      final users = db.collection('users');
      final QuerySnapshot usersWithUsername = await users.where('username', isEqualTo: _username).get();
      if (usersWithUsername.docs.isNotEmpty) {
        return (false, consts.SignupConsts.usernameTakenText);
      }

      final QuerySnapshot usersWithEmail = await users.where('email', isEqualTo: _email).get();
      if (usersWithEmail.docs.isNotEmpty) {
        return (false, consts.SignupConsts.emailAddrTakenText);
      }

      return (true, '');
    } catch(error) {
      print(error);
      return (false, consts.GlobalConsts.unknownErrorText);
    }
  }
}

/*
  Inserts information about the new user into the db
*/

class InsertSignup {
  InsertSignup(
    this._email,
    this._password,
    this._username
  );

  final String _email;
  final String _password;
  final String _username;
  final _dbcrypt = DBCrypt();

  String _getPlatform() {
    // Detect current platform
    String platform = 'unknown';
    if (Platform.isAndroid) {
      platform = 'Android';
    } else if (Platform.isIOS) {
      platform = 'iOS';
    }
    return platform;
  }

  ({String salt, String password}) _hashPassword() {
    // Create a different salt for each user
    // After that, hash the password with the generated salt
    String salt = _dbcrypt.gensaltWithRounds(10);
    var pwh = _dbcrypt.hashpw(_password, salt);
    return (salt: salt, password: pwh);
  }

  Future<(bool success, String errorMsg, String userID)> insertToDB() async {
    // Insert user into db
    final FirebaseFirestore db = FirebaseFirestore.instance;
    final users = db.collection('users');
    final userSettings = db.collection('user_settings');

    final (salt: salt, password: pwh) = _hashPassword();
    final String platform = _getPlatform();
    final Position? geoloc = await helpers.getGeolocation();

    final uuid = Uuid();
    String userID = uuid.v4();
    GeoFirePoint? userGeoPoint;

    if (geoloc != null) {
      userGeoPoint = GeoFirePoint(GeoPoint(geoloc.latitude, geoloc.longitude));
    }

    final data = {
      'id': userID,
      'username': _username,
      'email': _email,
      'password': pwh,
      'salt': salt,
      'platform': platform,
      'geoloc': userGeoPoint?.data,
      'signup_date': FieldValue.serverTimestamp()
    };

    final dataProfile = {
      'display_username': _username,
      'bio': '',
      'profile_pic_path': '',
      'profile_pic_url': ''
    };

    // Insert user into db
    try {
      await users.doc(userID).set(data);
      await userSettings.doc(userID).set(dataProfile);
    } catch (e) {
      return (false, consts.GlobalConsts.unknownErrorText, '');
    }

    // Successful signup
    return (true, '', userID);
  }
}
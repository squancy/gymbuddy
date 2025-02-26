import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gym_buddy/consts/common_consts.dart';
import 'dart:developer';
import 'package:dbcrypt/dbcrypt.dart';
import 'package:gym_buddy/service/common_service.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignupRepository {
  SignupRepository({
    required commononService
  }) : _commonService = commononService;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _dbcrypt = DBCrypt();
  final CommonService _commonService;
  
  /// Make sure username and email are unique
  Future<(bool isValid, String errorMsg)> userExists({
    required String username,
    required String email
    }) async {
    try {
      final users = _db.collection('users');
      final QuerySnapshot usersWithUsername = await users.where(
        'username',
        isEqualTo: username)
        .get();
      if (usersWithUsername.docs.isNotEmpty) {
        return (false, SignupConsts.usernameTakenText);
      }

      final QuerySnapshot usersWithEmail = await users.where(
        'email',
        isEqualTo: email)
        .get();
      if (usersWithEmail.docs.isNotEmpty) {
        return (false, SignupConsts.emailAddrTakenText);
      }

      return (true, '');
    } catch (error) {
      log("userExists(): $error");
      return (false, GlobalConsts.unknownErrorText);
    }
  }

  ({String salt, String password}) _hashPassword(String password) {
    // Create a different salt for each user
    // After that, hash the password with the generated salt
    String salt = _dbcrypt.gensaltWithRounds(10);
    var pwh = _dbcrypt.hashpw(password, salt);
    return (salt: salt, password: pwh);
  }

  Future<void> requestPosition() {
    return _commonService.requestPosition();
  }

  /// Insert a validated user's data to db
  Future<(bool success, String errorMsg, String userID)> insertToDB({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final users = _db.collection('users');
      final userSettings = _db.collection('user_settings');

      final (salt: salt, password: pwh) = _hashPassword(password);
      final String platform = _commonService.getPlatform();
      final Position? geoloc = await _commonService.getGeolocation();

      final uuid = Uuid();
      String userID = uuid.v4();
      GeoFirePoint? userGeoPoint;

      if (geoloc != null) {
        userGeoPoint = GeoFirePoint(GeoPoint(geoloc.latitude, geoloc.longitude));
      }

      final data = {
        'id': userID,
        'username': username,
        'email': email,
        'password': pwh,
        'salt': salt,
        'platform': platform,
        'geoloc': userGeoPoint?.data,
        'signup_date': FieldValue.serverTimestamp()
      };

      final dataProfile = {
        'display_username': username,
        'bio': '',
        'profile_pic_path': '',
        'profile_pic_url': ''
      };

      // Insert user into db
      await users.doc(userID).set(data);
      await userSettings.doc(userID).set(dataProfile);

      // Successful signup
      return (true, '', userID);
    } catch (error) {
      log("insertToDb(): $error");
      return (false, GlobalConsts.unknownErrorText, '');
    }
  }

  Future<void> setUserState({required String userID, required bool loggedIn}) async {
    final SharedPreferencesAsync prefs = SharedPreferencesAsync();
    await prefs.setBool('loggedIn', loggedIn);
    await prefs.setString('userID', userID);
  }
}
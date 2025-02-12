import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dbcrypt/dbcrypt.dart';
import 'package:gym_buddy/consts/common_consts.dart';

class CheckLogin {
  CheckLogin(
    this._email,
    this._password
  );

  final String _email;
  final String _password;

  /// Get the user whose email matches the provided email
  Future<QuerySnapshot> _getUserWithEmail(users) async {
    return await users.where('email', isEqualTo: _email).get();
  }

  /// Verify if the provided password matches the stored hash
  Future<bool> _isPasswordValid(user) async {
    String passwordDB = user['password'];
    var bcrypt = DBCrypt();

    return bcrypt.checkpw(_password, passwordDB);
  }

  /// Validate the login credentials of the user and return the result
  Future<(bool success, String errorMsg, String userID)> validateLogin() async {
    // Fetch user with the given email, if exists
    final FirebaseFirestore db = FirebaseFirestore.instance;
    final users = db.collection('users');

    final QuerySnapshot userWithEmail = await _getUserWithEmail(users); 
    if (userWithEmail.docs.isEmpty) {
      return (false, ForgotPasswordConsts.wrongCredentialsText, '');
    }

    var user = userWithEmail.docs[0].data() as Map<String, dynamic>;
    bool valid = await _isPasswordValid(user);
    return valid ?
      (true, '', user['id'] as String) :
      (false, ForgotPasswordConsts.wrongCredentialsText, '');
  }
}
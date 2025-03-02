import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dbcrypt/dbcrypt.dart';
import 'package:gym_buddy/consts/common_consts.dart';

class LoginRepository {
  LoginRepository();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<QuerySnapshot> _getUserWithEmail(String email) async {
    return await _db.collection('users').where('email', isEqualTo: email).get();
  }

  /// Verify if the provided password matches the stored hash
  bool _isPasswordValid(Map<String, dynamic> user, String password) {
    String passwordDB = user['password'];
    var bcrypt = DBCrypt();

    return bcrypt.checkpw(password, passwordDB);
  }

  /// Validate the login credentials of the user and return the result
  Future<(bool success, String errorMsg, String userID)> validateLogin({
    required String email,
    required String password
  }) async {
    // Fetch user with the given email, if exists
    final QuerySnapshot userWithEmail = await _getUserWithEmail(email); 
    if (userWithEmail.docs.isEmpty) {
      return (false, ForgotPasswordConsts.wrongCredentialsText, '');
    }

    var user = userWithEmail.docs[0].data() as Map<String, dynamic>;
    bool valid = _isPasswordValid(user, password);
    return valid ?
      (true, '', user['id'] as String) :
      (false, ForgotPasswordConsts.wrongCredentialsText, '');
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';

class RenewPasswordRepository {
  RenewPasswordRepository();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> updatePassword({
    required String userID,
    required String hashedPassword,
    required String salt
  }) async {
    await _db.collection('users').doc(userID).update({
      'password': hashedPassword,
      'salt': salt,
    });
  }
}
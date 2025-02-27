import 'package:cloud_firestore/cloud_firestore.dart';

class EnterCodeRepository {
  EnterCodeRepository();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getUserWithCode({
    required String email,
    required String code
  }) async {
    return (await _db
      .collection('users')
      .where('email', isEqualTo: email)
      .where('temp_pass', isEqualTo: code)
      .get())
      .docs;
  }
}
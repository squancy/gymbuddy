import 'package:cloud_firestore/cloud_firestore.dart';

class ForgotPassRepository {
  ForgotPassRepository();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getUserWithEmail(String email) async {
    return (await _db.collection('users')
      .where('email', isEqualTo: email)
      .get())
      .docs
      .toList();
  }

  Future<void> setTempPass({
    required String userID,
    required String tempPass
    }) async {
    await _db.collection('users')
      .doc(userID)
      .update({'temp_pass': tempPass});
  }
}
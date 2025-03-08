import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_buddy/consts/common_consts.dart';

class ProfileRepository {
  ProfileRepository();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<QuerySnapshot<Map<String, dynamic>>> getUserPosts({
    required String userID,
    required dynamic lastVisible
  }) async {
    return await _db.collection('posts')
      .where('author', isEqualTo: userID)
      .orderBy('date', descending: true)
      .startAfterDocument(lastVisible)
      .limit(ProfileConsts.paginationNum).get();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> getUserPostDocs({
    required QuerySnapshot<Map<String, dynamic>> userPosts,
    required bool isFirst,
    required dynamic lastVisible
    }) {
    final userPostDocs = userPosts.docs;
    if (isFirst) {
      userPostDocs.insert(0, lastVisible);
    }
    return userPostDocs;
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getLastPostByUser({
    required String userID
  }) async {
    return (await _db.collection('posts')
      .where('author', isEqualTo: userID)
      .orderBy('date', descending: true)
      .limit(1).get());
  }

  Future<int> getTotalNumOfPostsByUser({
    required String userID
  }) async {
    return (await _db.collection('posts')
      .where('author', isEqualTo: userID)
      .count()
      .get())
      .count as int;
  }

  Future<QuerySnapshot> getUser({
    required String userID
  }) async {
    return await _db.collection('users')
      .where('id', isEqualTo: userID)
      .get();
  }

  Future<DocumentSnapshot> getUserSettings({
    required String userID
  }) async {
    return await _db.collection('user_settings')
      .doc(userID)
      .get();
  }
}
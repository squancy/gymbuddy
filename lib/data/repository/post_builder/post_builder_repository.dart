import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_buddy/data/repository/core/common_repository.dart';

class PostBuilderRepository {
  PostBuilderRepository();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> createDataForPosts(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> userPostDocs) async {
    List<Map<String, dynamic>> res = [];
    String? userID = await CommonRepository().getUserID();
    var userData = (await _db.collection('user_settings').doc(userID).get()).data();
    for (final post in userPostDocs) {
      Map<String, dynamic> data = post.data();
      data['author_display_username'] = userData!['display_username'];
      data['author_profile_pic_url'] = userData['profile_pic_url'];
      data['post_id'] = post.reference.id;
      List<String> gymNames = (await _db.collection('gyms/budapest/gyms')
        .where('id', isEqualTo: data['gym']).get())
        .docs
        .map((doc) => (doc.data() as Map<String, dynamic>?)?['name'] as String? ?? '')
        .toList();
      data['gymName'] = gymNames.isNotEmpty ? gymNames[0] : '';
      res.add(data);
    }
    return res;
  }
}
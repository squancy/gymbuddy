import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_buddy/data/repository/core/common_repository.dart';

class PostPageRepository {
  PostPageRepository();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> pushToDB({
    required String postID,
    required String postText,
    required String? dayType,
    required String? gymID,
    required List<String> downloadURLs,
    required List<String> filenames,
    required DateTime? when
  }) async {
    final postsDocRef = _db.collection('posts').doc(postID);
    final data = {
      'author': await CommonRepository().getUserID(),
      'content': postText,
      'day_type': dayType,
      'gym': gymID,
      'download_url_list': downloadURLs,
      'filename_list': filenames,
      'when': when,
      'date': FieldValue.serverTimestamp()
    };

    await postsDocRef.set(data);
  }
}
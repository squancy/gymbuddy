import 'package:gym_buddy/consts/common_consts.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_buddy/data/repository/core/upload_image_repository.dart';

class ProfilePhotoRepository {
  ProfilePhotoRepository({
    required uploadImageRepository
  }) :
  _uploadImageRepository = uploadImageRepository;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final UploadImageRepository _uploadImageRepository;

  /// Upload the profile picture to Firebase Storage
  Future<void> uploadPic(File file, String? userID) async {
    var (String downloadURL, String filename) = await _uploadImageRepository
      .uploadImage(
        image: file,
        size: ProfileConsts.profilePicSize,
        pathPrefix: "profile_pics/$userID"
      ); 
    final settingsDocRef = _db.collection('user_settings').doc(userID);
    await settingsDocRef.update({
      'profile_pic_path': filename,
      'profile_pic_url': downloadURL
    });
  }

  /// Get the profile picture URL
  Future<String> getProfilePicURL(String userID) async {
    final settingsDocRef = _db.collection('user_settings').doc(userID);
    final usettings = await settingsDocRef.get();
    final userSettings = usettings.data() as Map<String, dynamic>;
    return userSettings['profile_pic_url'];
  }
}
import 'package:flutter/material.dart';
import 'package:gym_buddy/consts/common_consts.dart';
import 'package:gym_buddy/data/repository/core/common_repository.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:gym_buddy/data/repository/profile/profile_photo_repository.dart';
import 'package:gym_buddy/utils/mocks.dart';

class ProfilePhotoViewModel extends ChangeNotifier {
  ProfilePhotoViewModel({
    required profilePhotoRepository
  }) :
  _profilePhotoRepository = profilePhotoRepository;

  final ProfilePhotoRepository _profilePhotoRepository;
  final CommonRepository _commonRepo = CommonRepository();

  var image = File(ProfileConsts.defaultProfilePicPath);
  final _picker = ImagePicker();
  bool showFile = false;
  Map<String, String>? profilePicFile;

  /// Select an image from the gallery or camera
  Future<void> _selectFromSourceReal(ImageSource sourceType) async {
    final pickedFile = await _picker.pickImage(source: sourceType);
    final userID = await _commonRepo.getUserID();
    if (pickedFile != null) {
      _profilePhotoRepository.uploadPic(
        File(pickedFile.path),
        userID
      );
    }

    if (pickedFile != null) {
      image = File(pickedFile.path);
      showFile = true;
    }
    notifyListeners();
  }

  /// Image selection mock (select default profile pic)
  Future<void> _selectFromSourceMock(ImageSource sourceType) async {
    File file = await getDefaultProfilePicAsFile();
    _profilePhotoRepository.uploadPic(
      file,
      await _commonRepo.getUserID()
    );
    image = file;
    showFile = true;
    notifyListeners();
  }

  Future<void> selectFromSource(ImageSource sourceType) async {
    GlobalConsts.test ?
      await _selectFromSourceMock(sourceType) :
      await _selectFromSourceReal(sourceType);
  }

  Future<void> getProfilePicFile() async {
    final profilePicURL = await _profilePhotoRepository.getProfilePicURL();
    if (profilePicURL.isEmpty) {
      profilePicFile = {
        'type': 'default',
        'path': ProfileConsts.defaultProfilePicPath
      };
    } else {
      profilePicFile = {
        'type': 'url',
        'path': profilePicURL
      };
    }
    notifyListeners();
  }

  ImageProvider getBgImage() {
    if (profilePicFile?['type'] == 'default') {
      return AssetImage(profilePicFile?['path'] as String);
    } else {
      return NetworkImage(profilePicFile?['path'] as String);
    }
  }
}
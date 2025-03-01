import 'dart:developer';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:gym_buddy/consts/common_consts.dart';
import 'package:gym_buddy/data/repository/post/post_page_repository.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:gym_buddy/data/repository/core/upload_image_repository.dart';
import 'package:gym_buddy/utils/mocks.dart';

class PostPageViewModel extends ChangeNotifier {
  PostPageViewModel({
    required postPageRepository,
    required uploadImageRepository
  }) :
  _postPageRepository = postPageRepository,
  _uploadImageRepository = uploadImageRepository;

  final PostPageRepository _postPageRepository;
  final UploadImageRepository _uploadImageRepository;

  String? dayTypeVal = '';
  String? gymVal = '';
  bool showImages = false;
  final picker = ImagePicker(); 
  List<File> selectedImages = [];
  final controller = TextEditingController();
  String errorMsg = '';
  bool hasError = false;
  DateTime? datetimeVal;
  double? progress;

  /// Select images from source (camera or gallery)
  Future<void> _selectFromSource(ImageSource sourceType) async {
    final pickedFiles = await picker.pickMultiImage(limit: PostPageConsts.maxNumOfImages);
    if (pickedFiles.isNotEmpty) {
      selectedImages = pickedFiles.map((el) => File(el.path)).toList();
      showImages = true;
    }
  }

  /// Select image from source mock (load default profile picture)
  Future<void> _selectFromSourceMock(ImageSource sourceType) async {
    File file = await getDefaultProfilePicAsFile();
    selectedImages = [file];
    showImages = true;
  }

  Future<void> selectFromSource(ImageSource sourceType) async {
    await (GlobalConsts.test ?
      _selectFromSourceMock(sourceType) :
      _selectFromSource(sourceType));
  }

  set dayType(String? val) {
    dayTypeVal = val;
  }

  set gym(String? val) {
    gymVal = val;
  }

  set datetime(DateTime? val) {
    datetimeVal = val;
    notifyListeners();
  }

  /// Create a new post
  Future<void> createNewPost({
    required List<File> images,
    required String postText,
    required String? dayType,
    required String? gymID,
    required DateTime? when}) async {
    final uuid = Uuid(); 
    final postID = uuid.v4();
    List<String> downloadURLs = [];
    List<String> filenames = [];

    errorMsg = '';
    hasError = false;
    notifyListeners();
    if (postText.isEmpty) {
      errorMsg = PostPageConsts.emptyFieldError;
      hasError = true;
      notifyListeners();
      return;
    }

    if (images.isNotEmpty) {
      // Upload every image
      for (var i = 0; i < images.length; i++) {
        final image = images[i];
        final [UploadTask uploadTask, ref, filename] = await _uploadImageRepository.uploadImageProgess(
          image: image,
          size: 800,
          pathPrefix: "post_pics/$postID"
        );
        uploadTask.snapshotEvents.listen((TaskSnapshot taskSnapshot) async {
          switch (taskSnapshot.state) {
            case TaskState.running:
              if (progress == null) {
                progress = 0;
              } else if (taskSnapshot.totalBytes > 0) {
                progress = progress! +
                  (taskSnapshot.bytesTransferred / taskSnapshot.totalBytes) /
                  images.length;
              }
              notifyListeners();
              break;
            case TaskState.success:
              downloadURLs.add(await ref.getDownloadURL());
              if (downloadURLs.length == images.length) {
                try {
                  await _postPageRepository.pushToDB(
                    postID: postID,
                    postText: postText,
                    dayType: dayType,
                    gymID: gymID,
                    downloadURLs: downloadURLs,
                    filenames: filenames,
                    when: when
                  );
                  progress = null;
                  hasError = false;
                  notifyListeners();
                } catch (error) {
                  log("createNewPost(): $error");
                  errorMsg = GlobalConsts.unknownErrorText; 
                  hasError = true;
                  notifyListeners();
                }
              }
              break;
            default:
              break;
          }
        });
        filenames.add(filename);
      }
    } else {
      try {
        await _postPageRepository.pushToDB(
          postID: postID,
          postText: postText,
          dayType: dayType,
          gymID: gymID,
          downloadURLs: downloadURLs,
          filenames: filenames,
          when: when
        );
        progress = null;
        hasError = false;
        notifyListeners();
      } catch (error) {
        log("createNewPost(): $error");
        errorMsg = GlobalConsts.unknownErrorText; 
        hasError = true;
        notifyListeners();
      }
    }
  }
}
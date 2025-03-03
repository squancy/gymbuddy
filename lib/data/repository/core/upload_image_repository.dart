import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class UploadImageRepository {
  UploadImageRepository();

  static const Uuid _uuid = Uuid();
  final Reference _storageRef = FirebaseStorage.instance.ref();

  /// Returns the metadata, filename and pathname of an image
  ({SettableMetadata metadata, String filename, String pathname}) _getImageData(
    File image,
    String pathPrefix) {
    final extension = p.extension(image.path);
    final metadata = SettableMetadata(contentType: "image/${extension.substring(1)}");
    final filename = "${_uuid.v4()}$extension";
    final pathname = "$pathPrefix/$filename";
    return (metadata: metadata, filename: filename, pathname: pathname);
  }

  /// Resizes an image to a specified size
  Future<void> _resizeImage(File image, int size) async {
    final cmd = img.Command()
      ..decodeImageFile(image.path)
      ..copyResize(width: size)
      ..writeToFile(image.path);
    await cmd.executeThread();
  }

  /// Uploads an image to Firebase Storage and returns the download URL and filename
  Future<(String downloadURL, String filename)> uploadImage({
    required File image,
    required int size,
    required String pathPrefix}) async {
    final (:metadata, :filename, :pathname) = _getImageData(image, pathPrefix);
    await _resizeImage(image, size);
    await _storageRef.child(pathname).putFile(image, metadata);
    final downloadURL = await _storageRef.child(pathname).getDownloadURL();
    return (downloadURL, filename);
  }

  /// Uploads an image to Firebase Storage and returns the upload task, storage reference and filename
  Future<List<dynamic>> uploadImageProgess({
    required File image,
    required int size,
    required String pathPrefix
    }) async {
    final (:metadata, :filename, :pathname) = _getImageData(image, pathPrefix);
    await _resizeImage(image, size); 
    return [
      _storageRef.child(pathname).putFile(image, metadata),
      _storageRef.child(pathname),
      filename
    ];
  }
}
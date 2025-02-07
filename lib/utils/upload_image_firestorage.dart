import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class UploadImageFirestorage {
  const UploadImageFirestorage(
    this.storageRef
  );

  static const Uuid uuid = Uuid();
  final Reference storageRef;

  /// Returns the metadata, filename and pathname of an image
  List<dynamic> getImageData(File image, String pathPrefix) {
    final extension = p.extension(image.path);
    final metadata = SettableMetadata(contentType: "image/${extension.substring(1)}");
    final filename = "${uuid.v4()}$extension";
    final pathname = "$pathPrefix/$filename";
    return [metadata, filename, pathname];
  }

  /// Resizes an image to a specified size
  Future<void> resizeImage(File image, int size) async {
    final cmd = img.Command()..decodeImageFile(image.path)..copyResize(width: size)..writeToFile(image.path);
    await cmd.executeThread();
  }

  /// Uploads an image to Firebase Storage and returns the download URL and filename
  Future<(String downloadURL, String filename)> uploadImage(File image, int size, String pathPrefix) async {
    final [metadata, filename as String, pathname] = getImageData(image, pathPrefix);
    await resizeImage(image, size);
    await storageRef.child(pathname).putFile(image, metadata);
    final downloadURL = await storageRef.child(pathname).getDownloadURL();
    return (downloadURL, filename);
  }

  /// Uploads an image to Firebase Storage and returns the upload task, storage reference and filename
  Future<List<dynamic>> uploadImageProgess(File image, int size, String pathPrefix) async {
    final [metadata, filename as String, pathname] = getImageData(image, pathPrefix);
    await resizeImage(image, size);
    return [storageRef.child(pathname).putFile(image, metadata), storageRef.child(pathname), filename];
  }
}
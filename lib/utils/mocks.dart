import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:gym_buddy/consts/common_consts.dart' as consts;
import 'dart:io';

Future<File> getDefaultProfilePicAsFile() async {
  final byteData = await rootBundle.load(consts.GlobalConsts.defaultProfilePicPath);
  final file = File('${(await getTemporaryDirectory()).path}/${consts.GlobalConsts.defaultProfilePicPath}');
  await file.create(recursive: true);
  await file.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
  return file;
}
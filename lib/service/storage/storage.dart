import 'dart:io' show File, Directory, Platform;

import 'package:external_path/external_path.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:path/path.dart' as path_;
import 'package:path_provider/path_provider.dart';

// =============
// path and name
// =============

Future<String> getExternalStorageDirectoryPath() async {
  final storageDirectories = await ExternalPath.getExternalStorageDirectories();
  if (storageDirectories.isEmpty) {
    throw Exception('Cannot get external storage directory.');
  }
  return await joinPath(
    [storageDirectories.first, APP_NAME],
    checkDirectory: true,
    directoryPath: true,
  ); // /storage/emulated/0/Manhuagui
}

Future<String> getPrivateStorageDirectoryPath() async {
  final storageDirectory = await getExternalStorageDirectory(); // sandbox
  return await joinPath(
    [storageDirectory!.path],
    checkDirectory: true,
    directoryPath: true,
  ); // /storage/emulated/0/android/com.aoihosizora.manhuagui_flutter
}

Future<String> joinPath(List<String> paths, {bool checkDirectory = false, bool directoryPath = false}) async {
  var newPath = path_.joinAll(paths);
  if (checkDirectory) {
    var directory = Directory(directoryPath ? newPath : path_.dirname(newPath));
    if (!(await directory.exists())) {
      await directory.create(recursive: true);
    }
  }
  return newPath;
}

String getTimestampTokenForFilename([DateTime? time, String? pattern]) {
  final df = DateFormat(pattern ?? 'yyyyMMdd_HHmmss_SSS');
  return df.format(time ?? DateTime.now());
}

// =======
// gallery
// =======

const _channelName = 'com.example.manhuagui_flutter';
const _methodInsertMedia = 'insertMedia';
const _channel = MethodChannel(_channelName);

Future<void> addToGallery(File file) async {
  if (Platform.isAndroid) {
    await _channel.invokeMethod(_methodInsertMedia, <String, dynamic>{
      'filepath': file.path,
    });
  }
}

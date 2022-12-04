import 'dart:io' show File, Directory;

import 'package:external_path/external_path.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:intl/intl.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:path/path.dart' as path_;
import 'package:path_provider/path_provider.dart';

// ============
// storage path
// ============

Future<String> getPublicStorageDirectoryPath() async {
  final storageDirectories = await ExternalPath.getExternalStorageDirectories(); // external public
  if (storageDirectories.isEmpty) {
    throw Exception('Cannot get public storage directory.');
  }
  return await PathUtils.joinPathAndCheck(
    [storageDirectories.first, APP_NAME],
    isDirectoryPath: true,
  ); // /storage/emulated/0/Manhuagui
}

Future<String> getPrivateStorageDirectoryPath() async {
  final storageDirectory = await getExternalStorageDirectory(); // external private (sandbox)
  if (storageDirectory == null) {
    throw Exception('Cannot get private storage directory.');
  }
  return await PathUtils.joinPathAndCheck(
    [storageDirectory.path],
    isDirectoryPath: true,
  ); // /storage/emulated/0/android/com.aoihosizora.manhuagui/files
}

Future<String> getSharedPicturesDirectoryPath() async {
  final sharedDirectoryPath = await ExternalPath.getExternalStoragePublicDirectory(ExternalPath.DIRECTORY_PICTURES); // external shared
  if (sharedDirectoryPath.isEmpty) {
    throw Exception('Cannot get shared pictures directory.');
  }
  return await PathUtils.joinPathAndCheck(
    [sharedDirectoryPath],
    isDirectoryPath: true,
  ); // /storage/emulated/0/Pictures
}

String getTimestampTokenForFilename([DateTime? time, String? pattern]) {
  final df = DateFormat(pattern ?? 'yyyyMMdd_HHmmss_SSS');
  return df.format(time ?? DateTime.now());
}

// ==========
// path utils
// ==========

class PathUtils {
  static String joinPath(List<String> paths) {
    return path_.joinAll(paths);
  }

  static String getWithoutExtension(String path) {
    return path_.withoutExtension(path);
  }

  static String getExtension(String path) {
    return path_.extension(path);
  }

  static String getBasename(String path) {
    return path_.basename(path);
  }

  static String getDirname(String path) {
    return path_.dirname(path);
  }

  static Future<String> joinPathAndCheck(List<String> paths, {bool isDirectoryPath = false}) async {
    var newPath = path_.joinAll(paths);
    var directory = Directory(isDirectoryPath ? newPath : path_.dirname(newPath));
    if (!(await directory.exists())) {
      await directory.create(recursive: true);
    }
    return newPath;
  }
}

// =====
// cache
// =====

Future<String> getDefaultCacheManagerDirectoryPath() async {
  var baseDir = await getTemporaryDirectory();
  return PathUtils.joinPath([baseDir.path, DefaultCacheManager.key]);
}

Future<int> getDefaultCacheManagerDirectoryBytes() async {
  var cachePath = await getDefaultCacheManagerDirectoryPath();
  var directory = Directory(cachePath);
  if (!(await directory.exists())) {
    return 0;
  }

  var totalBytes = 0;
  await for (var entity in directory.list(recursive: true, followLinks: false)) {
    if (entity is File) {
      totalBytes += await entity.length();
    }
  }
  return totalBytes;
}

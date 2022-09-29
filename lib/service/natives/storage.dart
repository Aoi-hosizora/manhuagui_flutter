import 'dart:async';
import 'dart:io';

import 'package:external_path/external_path.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<String> getExternalStorageDirectoryPath() async {
  final storageDirectories = await ExternalPath.getExternalStorageDirectories();
  if (storageDirectories.isEmpty) {
    throw Exception('Cannot get external storage directory.');
  }
  return await joinPath(
    [storageDirectories.first, APP_NAME],
    checkDirectory: true,
    isDirectory: true,
  ); // /storage/emulated/0/Manhuagui
}

Future<String> getPrivateStorageDirectoryPath() async {
  final storageDirectory = await getExternalStorageDirectory(); // sandbox
  return await joinPath(
    [storageDirectory!.path],
    checkDirectory: true,
    isDirectory: true,
  ); // /storage/emulated/0/android/com.aoihosizora.manhuagui_flutter
}

Future<String> joinPath(List<String> paths, {bool checkDirectory = false, bool isDirectory = false}) async {
  var newPath = p.joinAll(paths);
  if (checkDirectory) {
    var directory = Directory(isDirectory ? newPath : p.dirname(newPath));
    if (!(await directory.exists())) {
      await directory.create(recursive: true);
    }
  }
  return newPath;
}

String getTimestampTokenForFilename([String? pattern]) {
  return DateFormat(pattern ?? 'yyyyMMdd_HHmmss_SSS').format(DateTime.now());
}

Future<File> downloadAndSaveFile({
  required String url,
  required String filepath,
  Map<String, String>? headers,
  String Function(String? mime, String? extension)? redecide,
  bool overwrite = false,
  bool headThrowable = true,
  bool mustCache = false,
  bool forceDownload = false,
  String? cacheKey,
  CacheManager? cacheManager,
}) async {
  assert(
  !mustCache || !forceDownload,
  'downloadAndSaveFile: mustCache and forceDownload must only have at most one true.',
  );
  var uri = Uri.parse(url);

  // 1. http head url
  Future<String> filepathFuture;
  if (redecide != null) {
    filepathFuture = http.head(uri, headers: headers).then((resp) {
      if (resp.statusCode != 200 && resp.statusCode != 201) {
        throw Exception('Got invalid status code ${resp.statusCode} from $url.');
      }
      var mime = resp.headers['content-type'] ?? '';
      var extension = getPreferredExtensionFromMime(mime);
      return redecide.call(mime, extension);
    }).timeout(Duration(milliseconds: HEAD_TIMEOUT), onTimeout: () {
      throw Exception('Failed to make http HEAD request to $url, timeout.');
    }).onError((e, s) {
      if (headThrowable) {
        return Future.error(e as dynamic, s);
      }
      return Future.value(redecide.call(null, null));
    });
  } else {
    filepathFuture = Future.value(filepath);
  }

  // 2. check file existence
  var fileFuture = filepathFuture.then((filepath) async {
    var newFile = File(filepath);
    if (await newFile.exists()) {
      if (!overwrite) {
        throw Exception('File $filepath has been found before saving.');
      }
      await newFile.delete();
    }
    await newFile.create(recursive: true);
    return newFile;
  });

  try {
    // 3. save cached data to file
    if (!forceDownload) {
      cacheManager ??= DefaultCacheManager();
      var cached = await cacheManager.getFileFromCache(cacheKey ?? url);
      if (cached != null && !cached.validTill.isBefore(DateTime.now())) {
        var destination = await fileFuture;
        return await cached.file.copy(destination.path);
      }
      if (mustCache) {
        throw Exception('There is no data for $url in cache.');
      }
    }

    // 4. download and save to file
    var resp = await http.get(uri, headers: headers);
    if (resp.statusCode != 200 && resp.statusCode != 201) {
      throw Exception('Got invalid status code ${resp.statusCode} from $url.');
    }
    var destination = await fileFuture;
    return await destination.writeAsBytes(resp.bodyBytes, flush: true);
  } catch (_) {
    var destination = await fileFuture;
    await destination.delete();
    rethrow;
  }
}

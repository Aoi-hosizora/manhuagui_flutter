import 'dart:io' show File;

import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/service/storage/storage.dart';

enum DownloadBehavior {
  preferUsingCache,
  mustUseCache,
  forceDownload,
}

enum OverwriteBehavior {
  notAllow,
  overwrite,
  addSuffix,
}

Future<OverwriteBehavior> _defaultWhenOverwrite(String filepath) async {
  return OverwriteBehavior.notAllow;
}

String _defaultSuffixBuilder(int index) {
  return ' ($index)';
}

class DownloadOption {
  const DownloadOption({
    this.behavior = DownloadBehavior.preferUsingCache,
    this.redecideFilepath,
    this.ignoreHeadError = false,
    this.whenOverwrite = _defaultWhenOverwrite,
    this.suffixBuilder = _defaultSuffixBuilder,
    this.headTimeout = const Duration(milliseconds: HEAD_TIMEOUT),
    this.downloadTimeout,
  });

  final DownloadBehavior behavior;
  final String Function(String? mime, String? extension)? redecideFilepath;
  final bool ignoreHeadError;
  final Future<OverwriteBehavior> Function(String filepath) whenOverwrite;
  final String Function(int index) suffixBuilder;
  final Duration? headTimeout;
  final Duration? downloadTimeout;
}

enum DownloadExceptionType {
  head,
  existed,
  noCache,
  download,
  other,
}

class DownloadException implements Exception {
  const DownloadException._(this.msg, [this.type = DownloadExceptionType.other]);

  const DownloadException._head(String msg) : this._(msg, DownloadExceptionType.head);

  const DownloadException._existed(String msg) : this._(msg, DownloadExceptionType.existed);

  const DownloadException._noCache(String msg) : this._(msg, DownloadExceptionType.noCache);

  const DownloadException._download(String msg) : this._(msg, DownloadExceptionType.download);

  final DownloadExceptionType type;
  final String msg;

  factory DownloadException._fromObject(Object o, [DownloadExceptionType type = DownloadExceptionType.other]) {
    if (o is DownloadException) {
      return o;
    }
    return DownloadException._(o.toString(), type);
  }

  @override
  String toString() {
    return '[$type] $msg';
  }
}

// !!!
Future<File> downloadFile({
  required String url,
  required String filepath,
  Map<String, String>? headers,
  CacheManager? cacheManager,
  String? cacheKey,
  DownloadOption? option,
}) async {
  option ??= DownloadOption();
  var uri = Uri.parse(url);

  // 1. make http HEAD request asynchronously
  Future<String> filepathFuture;
  if (option.redecideFilepath == null) {
    filepathFuture = Future.value(filepath);
  } else {
    filepathFuture = Future<String>.microtask(() async {
      http.Response resp;
      try {
        var future = http.head(uri, headers: headers);
        if (option!.headTimeout != null) {
          future = future.timeout(option.headTimeout!, onTimeout: () => throw DownloadException._head('timed out'));
        }
        resp = await future;
      } catch (e) {
        throw DownloadException._head('Failed to make http HEAD request to $url: $e.');
      }
      if (resp.statusCode != 200 && resp.statusCode != 201) {
        throw DownloadException._head('Got invalid status code ${resp.statusCode} from $url.');
      }
      var mime = resp.headers['content-type'] ?? '';
      var extension = getPreferredExtensionFromMime(mime);
      return option.redecideFilepath!.call(mime, extension);
    }).onError((e, s) {
      if (!option!.ignoreHeadError) {
        return Future.error(DownloadException._fromObject(e!), s);
      }
      return Future.value(option.redecideFilepath!.call(null, null));
    });
  }

  // 2. check file existence asynchronously
  var fileFuture = filepathFuture.then((filepath) async {
    var newFile = File(filepath);
    if (await newFile.exists()) {
      switch (await option!.whenOverwrite(filepath)) {
        case OverwriteBehavior.overwrite:
          await newFile.delete();
          break;
        case OverwriteBehavior.addSuffix:
          for (var i = 1;; i++) {
            var basename = PathUtils.getWithoutExtension(filepath);
            var extension = PathUtils.getExtension(filepath);
            var fallbackFile = File('$basename${option.suffixBuilder(i)}$extension');
            if (!(await fallbackFile.exists())) {
              newFile = fallbackFile;
              break;
            }
          }
          break;
        case OverwriteBehavior.notAllow:
        default:
          throw DownloadException._existed('File $filepath exists before saving.');
      }
    }
    await newFile.create(recursive: true);
    return newFile;
  }).onError((e, s) {
    return Future.error(DownloadException._fromObject(e!));
  });

  try {
    // 3. save cached data to file
    if (option.behavior != DownloadBehavior.forceDownload) {
      cacheManager ??= DefaultCacheManager();
      var cached = await cacheManager.getFileFromCache(cacheKey ?? url);
      if (cached != null && !cached.validTill.isBefore(DateTime.now())) {
        var destination = await fileFuture;
        return await cached.file.copy(destination.path);
      }
      if (option.behavior == DownloadBehavior.mustUseCache) {
        throw DownloadException._noCache('There is no data for $url in cache.');
      }
    }

    // 4. download and save to file
    http.Response resp;
    try {
      var future = http.get(uri, headers: headers);
      if (option.downloadTimeout != null) {
        future = future.timeout(option.downloadTimeout!, onTimeout: () => throw DownloadException._download('timed out'));
      }
      resp = await future;
    } catch (e) {
      throw DownloadException._download('Failed to make http GET request to $url: $e.');
    }
    if (resp.statusCode != 200 && resp.statusCode != 201) {
      throw DownloadException._download('Got invalid status code ${resp.statusCode} from $url.');
    }
    var destination = await fileFuture;
    return await destination.writeAsBytes(resp.bodyBytes, flush: true);
  } catch (e) {
    try {
      var destination = await fileFuture;
      await destination.delete();
    } catch (_) {}
    throw DownloadException._fromObject(e);
  }
}

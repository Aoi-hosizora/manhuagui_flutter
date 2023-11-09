import 'dart:convert';
import 'dart:io' show Directory, File, FileSystemEntity, FileSystemEntityType;
import 'dart:math' as math;

import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:image/image.dart' as imagelib;
import 'package:manhuagui_flutter/app_setting.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/service/db/download.dart';
import 'package:manhuagui_flutter/service/native/android.dart';
import 'package:manhuagui_flutter/service/storage/storage.dart';

// ====
// path
// ====

String _getExtensionFromUrl(String url) {
  return PathUtils.getExtension(url.split('?')[0]); // include "."
}

Future<String> _getDownloadImageFilePath(String extension) async {
  var basename = getTimestampTokenForFilename();
  var filename = '$basename$extension';
  var directoryPath = await lowerThanAndroidR()
      ? await getPublicStorageDirectoryPath() // /storage/emulated/0/Manhuagui/manhuagui_image/IMG_20220917_131013_206.jpg
      : await getSharedPicturesDirectoryPath(); // /storage/emulated/0/Pictures/manhuagui_image/IMG_20220917_131013_206.jpg
  return PathUtils.joinPath([directoryPath, 'manhuagui_image', 'IMG_$filename']);
}

Future<String> _getDownloadMangaDirectoryPath([int? mangaId, int? chapterId]) async {
  var directoryPath = await lowerThanAndroidR()
      ? await getPublicStorageDirectoryPath() // /storage/emulated/0/Manhuagui/manhuagui_download/...
      : await getPrivateStorageDirectoryPath(); // /storage/emulated/0/android/com.aoihosizora.manhuagui/files/manhuagui_download/...
  if (mangaId == null) {
    return PathUtils.joinPath([directoryPath, 'manhuagui_download']);
  }
  if (chapterId == null) {
    return PathUtils.joinPath([directoryPath, 'manhuagui_download', mangaId.toString()]);
  }
  return PathUtils.joinPath([directoryPath, 'manhuagui_download', mangaId.toString(), chapterId.toString()]);
}

Future<String> _getDownloadedChapterPageFilePath({required int mangaId, required int chapterId, required int pageIndex, required String? url}) async {
  var basename = (pageIndex + 1).toString().padLeft(4, '0');
  var extension = PathUtils.getExtension((url ?? 'xxx.webp').split('?')[0]); // include "."
  var filename = '$basename$extension';
  return PathUtils.joinPath([await _getDownloadMangaDirectoryPath(mangaId, chapterId), filename]);
}

Future<String?> getDownloadedMangaDirectoryPath() async {
  try {
    return await _getDownloadMangaDirectoryPath();
  } catch (e, s) {
    globalLogger.e('getDownloadedMangaDirectoryPath', e, s);
    return null;
  }
}

Future<File?> getDownloadedChapterPageFile({required int mangaId, required int chapterId, required int pageIndex, required String? url}) async {
  try {
    var filepath = await _getDownloadedChapterPageFilePath(mangaId: mangaId, chapterId: chapterId, pageIndex: pageIndex, url: url); // url is used only to get extension
    return File(filepath);
  } catch (e, s) {
    globalLogger.e('getDownloadedChapterPageFile', e, s);
    return null;
  }
}

Future<String?> getCachedOrDownloadedChapterPageFilePath({required int mangaId, required int chapterId, required int pageIndex, required String? url}) async {
  try {
    var filepath = await _getDownloadedChapterPageFilePath(mangaId: mangaId, chapterId: chapterId, pageIndex: pageIndex, url: url); // url is used only to get extension
    return await getCachedOrDownloadedFilepath(url: url, file: File(filepath));
  } catch (e, s) {
    globalLogger.e('getCachedOrDownloadedChapterPageFilepath', e, s);
    return null;
  }
}

// ==============
// download image
// ==============

Future<File?> downloadImageToGallery(String url, {File? precheck, bool convertFromWebp = false, bool alsoAddToGallery = true}) async {
  try {
    var filepath = await _getDownloadImageFilePath(_getExtensionFromUrl(url));
    File f;
    if (precheck != null && await precheck.exists()) {
      // copy given file directly
      var dir = Directory(PathUtils.getDirname(filepath));
      if (!(await dir.exists())) {
        await dir.create(recursive: true);
      }
      f = await precheck.copy(filepath);
    } else {
      // download from network
      f = await downloadFile(
        url: url,
        filepath: filepath,
        headers: {
          'User-Agent': USER_AGENT,
          'Referer': REFERER,
        },
        cacheManager: DefaultCacheManager(),
        option: DownloadOption(
          behavior: DownloadBehavior.preferUsingCache,
          conflictHandler: (_) async => DownloadConflictBehavior.addSuffix,
          headTimeout: AppSetting.instance.other.dlTimeoutBehavior.determineValue(
            normal: Duration(milliseconds: DOWNLOAD_HEAD_TIMEOUT),
            long: Duration(milliseconds: DOWNLOAD_HEAD_LTIMEOUT),
            longLong: Duration(milliseconds: DOWNLOAD_HEAD_LLTIMEOUT),
          ),
          downloadTimeout: AppSetting.instance.other.dlTimeoutBehavior.determineValue(
            normal: Duration(milliseconds: DOWNLOAD_IMAGE_TIMEOUT),
            long: Duration(milliseconds: DOWNLOAD_IMAGE_LTIMEOUT),
            longLong: Duration(milliseconds: DOWNLOAD_IMAGE_LLTIMEOUT),
          ),
        ),
      );
    }

    var isWebp = PathUtils.getExtension(filepath).toLowerCase() == '.webp';
    if (isWebp) {
      try {
        var webp = imagelib.decodeImage(await f.readAsBytes());
        if (webp != null) {
          var jpg = imagelib.encodeJpg(webp);
          var newFile = File('${PathUtils.getWithoutExtension(filepath)}.jpg');
          await newFile.writeAsBytes(jpg);
          try {
            await f.delete();
          } catch (_) {}
          f = newFile;
        }
      } catch (e, s) {
        globalLogger.e('downloadImageToGallery.decodeImage/writeAsBytes', e, s);
      }
    }

    if (alsoAddToGallery) {
      await addToGallery(f); // <<<
    }
    return f;
  } catch (e, s) {
    globalLogger.e('downloadImageToGallery', e, s);
    return null;
  }
}

enum ConcatImageMode {
  horizontal,
  vertical,
  horizontalReverse,
  verticalReverse,
}

Future<File?> downloadAndConcatImagesToGallery(String url1, String url2, ConcatImageMode mode, {File? precheck1, File? precheck2, bool alsoAddToGallery = true}) async {
  File? f1, f2;
  f1 = await downloadImageToGallery(url1, precheck: precheck1, convertFromWebp: false, alsoAddToGallery: false);
  if (f1 != null) {
    f2 = await downloadImageToGallery(url2, precheck: precheck2, convertFromWebp: false, alsoAddToGallery: false);
  }
  if (f1 == null || f2 == null) {
    return null;
  }

  try {
    var image1 = imagelib.decodeImage(await f1.readAsBytes())?.clone();
    var image2 = imagelib.decodeImage(await f2.readAsBytes())?.clone();
    if (image1 == null || image2 == null) {
      return null;
    }

    imagelib.Image newImage;
    var reverseMode = mode == ConcatImageMode.horizontalReverse || mode == ConcatImageMode.verticalReverse;
    if (mode == ConcatImageMode.horizontal || mode == ConcatImageMode.horizontalReverse) {
      newImage = imagelib.Image(image1.width + image2.width, math.max(image1.height, image2.height));
      imagelib.copyInto(newImage, image1, blend: false, dstX: !reverseMode ? 0 : image2.width);
      imagelib.copyInto(newImage, image2, blend: false, dstX: !reverseMode ? image1.width : 0);
    } else {
      newImage = imagelib.Image(math.max(image1.width, image2.width), image1.height + image2.height);
      imagelib.copyInto(newImage, image1, blend: false, dstY: !reverseMode ? 0 : image2.height);
      imagelib.copyInto(newImage, image2, blend: false, dstY: !reverseMode ? image1.height : 0);
    }
    var jpg = imagelib.encodeJpg(newImage);

    var filepath = await _getDownloadImageFilePath('.jpg');
    var dir = Directory(PathUtils.getDirname(filepath));
    if (!(await dir.exists())) {
      await dir.create(recursive: true);
    }
    var f = File(filepath);
    await f.writeAsBytes(jpg);

    try {
      await f1.delete();
      await f2.delete();
    } catch (_) {}

    if (alsoAddToGallery) {
      await addToGallery(f); // <<<
    }
    return f;
  } catch (e, s) {
    globalLogger.e('downloadAndConcatImagesToGallery', e, s);
    return null;
  }
}

Future<bool> downloadChapterPage({required int mangaId, required int chapterId, required int pageIndex, required String url}) async {
  try {
    var filepath = await _getDownloadedChapterPageFilePath(mangaId: mangaId, chapterId: chapterId, pageIndex: pageIndex, url: url);
    if (await File(filepath).exists()) {
      return true;
    }
    await downloadFile(
      url: url,
      filepath: filepath,
      headers: {
        'User-Agent': USER_AGENT,
        'Referer': REFERER,
      },
      cacheManager: DefaultCacheManager(),
      option: DownloadOption(
        behavior: DownloadBehavior.preferUsingCache,
        conflictHandler: (_) async => DownloadConflictBehavior.overwrite,
        downloadTimeout: Duration(milliseconds: DOWNLOAD_IMAGE_TIMEOUT),
      ),
    );
    return true;
  } catch (e, s) {
    globalLogger.e('downloadChapterPage', e, s);
    return false;
  }
}

// =====================
// download task related
// =====================

Future<void> createNomediaFile() async {
  // 留到 DownloadMangaQueueTask 再捕获异常
  var nomediaPath = PathUtils.joinPath([await _getDownloadMangaDirectoryPath(), '.nomedia']);
  var nomediaFile = File(nomediaPath);
  if (!(await nomediaFile.exists())) {
    await nomediaFile.create(recursive: true);
  }
}

Future<bool> writeMetadataFile({required int mangaId, required int chapterId, required DownloadChapterMetadata metadata}) async {
  try {
    var metadataPath = PathUtils.joinPath([await _getDownloadMangaDirectoryPath(mangaId, chapterId), 'metadata.json']);
    var metadataFile = File(metadataPath);
    if (!(await metadataFile.exists())) {
      await metadataFile.create(recursive: true);
    }

    var obj = <String, dynamic>{
      'version': 1,
      'manga_id': mangaId,
      'chapter_id': chapterId,
      'next_cid': metadata.nextCid,
      'prev_cid': metadata.prevCid,
      'pages': metadata.pages,
      'updated_at': (metadata.updatedAt ?? DateTime.now()).toIso8601String(),
    };
    var encoder = JsonEncoder.withIndent('  ');
    var content = encoder.convert(obj);
    await metadataFile.writeAsString(content, flush: true);
    return true;
  } catch (e, s) {
    globalLogger.e('writeMetadataFile', e, s);
    return false;
  }
}

Future<DownloadChapterMetadata> readMetadataFile({required int mangaId, required int chapterId, required int pageCount}) async {
  List<String>? pages;
  int? nextCid;
  int? prevCid;
  DateTime? updatedAt;
  try {
    var metadataPath = PathUtils.joinPath([await _getDownloadMangaDirectoryPath(mangaId, chapterId), 'metadata.json']);
    var metadataFile = File(metadataPath);
    if (await metadataFile.exists()) {
      var content = await metadataFile.readAsString();
      var obj = json.decode(content) as Map<String, dynamic>; // version: 1
      pages = (obj['pages'] as List<dynamic>?)?.map((e) => e.toString()).toList();
      nextCid = obj['next_cid'] as int?;
      prevCid = obj['prev_cid'] as int?;
      updatedAt = DateTime.tryParse((obj['updated_at'] as String?) ?? ''); // maybe null
    } else {
      globalLogger.w('readMetadataFile "$metadataPath" not found');
    }
  } catch (e, s) {
    globalLogger.e('readMetadataFile', e, s);
  }

  pages ??= <String>[];
  if (pageCount > pages.length) {
    pages.addAll(List.generate(pageCount - pages.length, (i) => '<placeholder_${i + 1}>.webp')); // extension defaults to webp
  } else if (pages.length > pageCount) {
    pages = pages.sublist(0, pageCount);
  }
  return DownloadChapterMetadata(pages: pages, nextCid: nextCid, prevCid: prevCid, updatedAt: updatedAt);
}

bool isValidPageUrlForMetadata(String url) {
  return url.isNotEmpty && !url.startsWith('<placeholder_');
}

Future<int> getDownloadedMangaBytes({required int mangaId}) async {
  try {
    String mangaPath = await _getDownloadMangaDirectoryPath(mangaId);
    var directory = Directory(mangaPath);
    if (!(await directory.exists())) {
      return 0;
    }

    var totalBytes = 0;
    await for (var entity in directory.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        try {
          totalBytes += await entity.length();
        } catch (e, s) {
          globalLogger.e('getDownloadedMangaBytes (skip)', e, s);
        }
      }
    }
    return totalBytes;
  } catch (e, s) {
    globalLogger.e('getDownloadedMangaBytes', e, s);
    return 0;
  }
}

// ======
// delete
// ======

Future<bool> deleteDownloadedManga({required int mangaId}) async {
  try {
    var mangaPath = await _getDownloadMangaDirectoryPath(mangaId);
    var directory = Directory(mangaPath);
    await directory.delete(recursive: true);
    return true;
  } catch (e, s) {
    globalLogger.e('deleteDownloadedManga', e, s);
    return false;
  }
}

Future<bool> deleteDownloadedChapter({required int mangaId, required int chapterId}) async {
  try {
    var mangaPath = await _getDownloadMangaDirectoryPath(mangaId, chapterId);
    var directory = Directory(mangaPath);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
    return true;
  } catch (e, s) {
    globalLogger.e('deleteDownloadedChapter', e, s);
    return false;
  }
}

Future<Tuple3<int, int, bool /* all checked */ >> deleteUnusedFilesInDownloadDirectory() async {
  var successChapters = 0;
  var failedChapters = 0;
  Future<int?> getDirectoryNumericName(FileSystemEntity entity) async {
    if ((await entity.stat()).type != FileSystemEntityType.directory) {
      return null; // not directory
    }
    return int.tryParse(PathUtils.getBasename(entity.path));
  }

  try {
    var downloadPath = await _getDownloadMangaDirectoryPath();
    await for (var entity in Directory(downloadPath).list(recursive: false, followLinks: false)) {
      var mangaId = await getDirectoryNumericName(entity);
      if (mangaId == null) {
        continue; // not a directory or not a valid id
      }

      // 1. check manga
      var directory = Directory(entity.path);
      var existed = await DownloadDao.checkMangaExistence(mid: mangaId) ?? true;
      if (!existed) {
        // manga is not in task => delete this directory
        var mangaChapters = 0;
        await for (var entity in directory.list(recursive: false, followLinks: false)) {
          var chapterId = await getDirectoryNumericName(entity);
          if (chapterId != null) {
            mangaChapters++; // is a directory, and is a valid chapter id
          }
        }
        try {
          await entity.delete(recursive: true);
          successChapters += mangaChapters;
        } catch (e, s) {
          globalLogger.e('deleteUnusedFilesInDownloadDirectory (delete manga)', e, s);
          failedChapters += mangaChapters;
        }
      }

      // 2. check chapter
      await for (var entity in directory.list(recursive: false, followLinks: false)) {
        var chapterId = await getDirectoryNumericName(entity);
        if (chapterId == null) {
          continue; // not a directory or not a valid id
        }
        var existed = await DownloadDao.checkChapterExistence(mid: mangaId, cid: chapterId) ?? true;
        if (!existed) {
          // chapter is not in task => delete this directory
          try {
            await entity.delete(recursive: true);
            successChapters++;
          } catch (e, s) {
            globalLogger.e('deleteUnusedFilesInDownloadDirectory (delete chapter)', e, s);
            failedChapters++;
          }
        }
      }
    }
    return Tuple3(successChapters, failedChapters, true);
  } catch (e, s) {
    globalLogger.e('deleteUnusedFilesInDownloadDirectory', e, s);
    return Tuple3(successChapters, failedChapters, false);
  }
}

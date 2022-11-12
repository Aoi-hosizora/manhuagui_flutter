import 'dart:io' show File, Directory;

import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/page/page/glb_setting.dart';
import 'package:manhuagui_flutter/service/storage/storage.dart';

// ====
// path
// ====

Future<String> _getDownloadImageDirectoryPath(String url) async {
  var basename = getTimestampTokenForFilename();
  var extension = PathUtils.getExtension(url.split('?')[0]);
  var filename = '$basename$extension';
  return PathUtils.joinPath([await getPublicStorageDirectoryPath(), 'manhuagui_image', 'IMG_$filename']); // IMG_20220917_131013_206.jpg
}

Future<String> _getDownloadMangaDirectoryPath([int? mangaId, int? chapterId]) async {
  if (mangaId == null) {
    return PathUtils.joinPath([await getPublicStorageDirectoryPath(), 'manhuagui_download']);
  }
  if (chapterId == null) {
    return PathUtils.joinPath([await getPublicStorageDirectoryPath(), 'manhuagui_download', mangaId.toString()]);
  }
  return PathUtils.joinPath([await getPublicStorageDirectoryPath(), 'manhuagui_download', mangaId.toString(), chapterId.toString()]);
}

Future<String> getDownloadedChapterPageFilePath({required int mangaId, required int chapterId, required int pageIndex, required String url}) async {
  var basename = (pageIndex + 1).toString().padLeft(4, '0');
  var extension = PathUtils.getExtension(url.split('?')[0]);
  var filename = '$basename$extension';
  return PathUtils.joinPath([await _getDownloadMangaDirectoryPath(mangaId, chapterId), filename]);
}

// ========
// download
// ========

Future<File?> downloadImageToGallery(String url) async {
  var filepath = await _getDownloadImageDirectoryPath(url);
  try {
    var f = await downloadFile(
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
        headTimeout: GlbSetting.global.dlTimeoutBehavior.determineDuration(
          normal: Duration(milliseconds: DOWNLOAD_HEAD_TIMEOUT),
          long: Duration(milliseconds: DOWNLOAD_HEAD_LTIMEOUT),
        ),
        downloadTimeout: GlbSetting.global.dlTimeoutBehavior.determineDuration(
          normal: Duration(milliseconds: DOWNLOAD_IMAGE_TIMEOUT),
          long: Duration(milliseconds: DOWNLOAD_IMAGE_LTIMEOUT),
        ),
      ),
    );
    await addToGallery(f); // <<<
    return f;
  } catch (e, s) {
    globalLogger.e('downloadImageToGallery', e, s);
    return null;
  }
}

Future<bool> downloadChapterPage({required int mangaId, required int chapterId, required int pageIndex, required String url}) async {
  var filepath = await getDownloadedChapterPageFilePath(mangaId: mangaId, chapterId: chapterId, pageIndex: pageIndex, url: url);
  if (await File(filepath).exists()) {
    return true;
  }
  try {
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

Future<void> createNomediaFile() async {
  var nomediaPath = PathUtils.joinPath([await _getDownloadMangaDirectoryPath(), '.nomedia']);
  var nomediaFile = File(nomediaPath);
  if (!(await nomediaFile.exists())) {
    await nomediaFile.create(recursive: true);
  }
}

Future<int> getDownloadedMangaBytes({required int mangaId}) async {
  var mangaPath = await _getDownloadMangaDirectoryPath(mangaId);
  var directory = Directory(mangaPath);
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

// ======
// delete
// ======

Future<bool> deleteDownloadedManga({required int mangaId}) async {
  var mangaPath = await _getDownloadMangaDirectoryPath(mangaId);
  var directory = Directory(mangaPath);
  try {
    await directory.delete(recursive: true);
    return true;
  } catch (e, s) {
    globalLogger.e('deleteDownloadedManga', e, s);
    return false;
  }
}

Future<bool> deleteDownloadedChapter({required int mangaId, required int chapterId}) async {
  var mangaPath = await _getDownloadMangaDirectoryPath(mangaId, chapterId);
  var directory = Directory(mangaPath);
  try {
    await directory.delete(recursive: true);
    return true;
  } catch (e, s) {
    globalLogger.e('deleteDownloadedChapter', e, s);
    return false;
  }
}

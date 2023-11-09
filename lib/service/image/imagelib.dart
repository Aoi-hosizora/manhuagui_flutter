import 'dart:io' show File;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:image/image.dart' as imagelib;

Future<bool> convertFromWebpToJpg(File file, File newFile) async {
  Future<Tuple1<List<int>?>> func(File file) async {
    try {
      var webp = imagelib.decodeImage(await file.readAsBytes());
      if (webp != null) {
        var jpg = imagelib.encodeJpg(webp);
        return Tuple1(jpg);
      }
    } catch (e, s) {
      globalLogger.e('convertFromWebpToJpg', e, s);
    }
    return Tuple1(null);
  }

  var jpg = (await compute(func, file)).item;
  if (jpg == null) {
    return false;
  }
  try {
    await newFile.writeAsBytes(jpg);
  } catch (e, s) {
    globalLogger.e('convertFromWebpToJpg', e, s);
  }
  return true;
}

enum ConcatImageMode {
  horizontal,
  vertical,
  horizontalReverse,
  verticalReverse,
}

Future<bool> concatTwoImages(File f1, File f2, ConcatImageMode mode, File newFile) async {
  Future<Tuple1<List<int>?>> func(Tuple2<File, File> fileTuple) async {
    try {
      var f1 = fileTuple.item1, f2 = fileTuple.item2;
      var image1 = imagelib.decodeImage(await f1.readAsBytes())?.clone();
      var image2 = imagelib.decodeImage(await f2.readAsBytes())?.clone();
      if (image1 == null || image2 == null) {
        return Tuple1(null);
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
      return Tuple1(jpg);
    } catch (e, s) {
      globalLogger.e('concatTwoImages', e, s);
      return Tuple1(null);
    }
  }

  var jpg = (await compute(func, Tuple2(f1, f2))).item;
  if (jpg == null) {
    return false;
  }

  try {
    await newFile.writeAsBytes(jpg);
    return true;
  } catch (e, s) {
    globalLogger.e('concatTwoImages', e, s);
    return false;
  }
}

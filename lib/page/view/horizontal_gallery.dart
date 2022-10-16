import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:photo_view/photo_view.dart';

class HorizontalGalleryView extends ExtendedPhotoGallery {
  HorizontalGalleryView({
    Key? key,
    required int imageCount,
    required ExtendedPhotoGalleryPageOptions Function(BuildContext, int) imagePageBuilder,
    required Widget Function(BuildContext context) firstPageBuilder, // <<<
    required Widget Function(BuildContext context) lastPageBuilder, // <<<
    void Function()? onImageLongPressed, // <<<
    BoxDecoration? backgroundDecoration,
    bool wantKeepAlive = false,
    bool gaplessPlayback = false,
    bool reverse = false,
    PageController? pageController,
    void Function(int)? onPageChanged,
    bool changePageWhenFinished = false,
    bool keepViewportMainAxisSize = true,
    double? viewportMainAxisFactor,
    void Function(PhotoViewScaleState)? scaleStateChangedCallback,
    bool enableRotation = false,
    ScrollPhysics? scrollPhysics,
    Axis scrollDirection = Axis.horizontal,
    Size? customSize,
    double? pageMainAxisHintSize,
    int preloadPagesCount = 0,
  }) : super.advanced(
          key: key,
          pageCount: imageCount + 2,
          builder: imagePageBuilder,
          advancedBuilder: (c, index, builder) {
            if (index == 0) {
              return firstPageBuilder(c); // <<<
            }
            if (index == imageCount + 1) {
              return lastPageBuilder(c); // <<<
            }
            return GestureDetector(
              onLongPress: onImageLongPressed, // <<<
              child: builder(c, index - 1),
            );
            // return builder(c, index - 1);
          },
          backgroundDecoration: backgroundDecoration,
          wantKeepAlive: wantKeepAlive,
          gaplessPlayback: gaplessPlayback,
          reverse: reverse,
          pageController: pageController,
          onPageChanged: onPageChanged,
          changePageWhenFinished: changePageWhenFinished,
          keepViewportMainAxisSize: keepViewportMainAxisSize,
          viewportMainAxisFactor: viewportMainAxisFactor,
          scaleStateChangedCallback: scaleStateChangedCallback,
          enableRotation: enableRotation,
          scrollPhysics: scrollPhysics,
          scrollDirection: scrollDirection,
          customSize: customSize,
          pageMainAxisHintSize: pageMainAxisHintSize,
          preloadPagesCount: preloadPagesCount,
        );
}

import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/page/view/image_load.dart';
import 'package:manhuagui_flutter/service/native/android.dart';
import 'package:manhuagui_flutter/service/native/system_ui.dart';
import 'package:manhuagui_flutter/service/storage/download.dart';
import 'package:manhuagui_flutter/service/storage/storage.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:photo_view/photo_view.dart';

class ImageViewerPage extends StatefulWidget {
  const ImageViewerPage({
    Key? key,
    required this.url,
    required this.title,
    this.ignoreSystemUI = false,
  }) : super(key: key);

  final String url;
  final String title;
  final bool ignoreSystemUI;

  @override
  State<ImageViewerPage> createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<ImageViewerPage> {
  final _photoViewKey = GlobalKey<ReloadablePhotoViewState>();
  final _cache = DefaultCacheManager();

  @override
  void initState() {
    super.initState();
    if (!widget.ignoreSystemUI) {
      WidgetsBinding.instance?.addPostFrameCallback((_) {
        setSystemUIOverlayStyle(
          navigationBarIconBrightness: Brightness.light,
          navigationBarColor: Colors.black,
          navigationBarDividerColor: Colors.black,
        );
      });
    }
  }

  Future<void> _download(String url) async {
    var f = await downloadImageToGallery(url);
    if (f != null) {
      Fluttertoast.showToast(msg: '图片已保存至 ${f.path}');
    } else {
      Fluttertoast.showToast(msg: '无法保存图片');
    }
  }

  @override
  Widget build(BuildContext context) {
    var url = widget.url;
    if (url.startsWith('//')) {
      url = 'https:$url';
    }

    return WillPopScope(
      onWillPop: () async {
        if (!widget.ignoreSystemUI) {
          setDefaultSystemUIOverlayStyle();
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          leading: AppBarActionButton.leading(context: context),
          actions: [
            AppBarActionButton(
              icon: Icon(Icons.refresh),
              tooltip: '重新加载',
              onPressed: () => _photoViewKey.currentState?.reload(),
            ),
            AppBarActionButton(
              icon: Icon(Icons.file_download),
              tooltip: '下載图片',
              onPressed: () => _download(url),
            ),
            AppBarActionButton(
              icon: Icon(MdiIcons.imageMove),
              tooltip: '分享图片',
              onPressed: () async {
                var filepath = await getCachedOrDownloadedFilepath(url: url);
                if (filepath == null) {
                  Fluttertoast.showToast(msg: '图片未加载完成，无法分享图片');
                } else {
                  await shareFile(filepath: filepath, type: 'image/*');
                }
              },
            ),
          ],
        ),
        backgroundColor: Colors.black,
        body: Container(
          decoration: BoxDecoration(color: Colors.black),
          constraints: BoxConstraints.expand(
            height: MediaQuery.of(context).size.height,
          ),
          child: ReloadablePhotoView(
            imageProviderBuilder: (key) => LocalOrCachedNetworkImageProvider.fromNetwork(
              key: key,
              url: url,
              headers: {'User-Agent': USER_AGENT, 'Referer': REFERER},
              cacheManager: _cache,
            ),
            initialScale: PhotoViewComputedScale.contained / 2,
            minScale: PhotoViewComputedScale.contained / 2,
            maxScale: PhotoViewComputedScale.covered * 2,
            filterQuality: FilterQuality.high,
            loadingBuilder: (_, ev) => ImageLoadingView(
              title: '',
              event: ev,
            ),
            errorBuilder: (_, err, __) => ImageLoadFailedView(
              title: '',
              error: err,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/page/view/image_load.dart';
import 'package:manhuagui_flutter/service/native/system_ui.dart';
import 'package:manhuagui_flutter/service/storage/download.dart';
import 'package:manhuagui_flutter/service/storage/storage.dart';
import 'package:path/path.dart' as path_;
import 'package:photo_view/photo_view.dart';

class ImageViewerPage extends StatefulWidget {
  const ImageViewerPage({
    Key? key,
    required this.url,
    required this.title,
  }) : super(key: key);

  final String url;
  final String title;

  @override
  State<ImageViewerPage> createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<ImageViewerPage> {
  final _cache = DefaultCacheManager();
  final _notifier = ValueNotifier<String>('');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      setSystemUIOverlayStyle(navigationBarColor: Colors.black);
    });
  }

  String get url {
    var url = widget.url;
    if (url.startsWith('//')) {
      url = 'https:$url';
    }
    return url;
  }

  void _reload() {
    _notifier.value = DateTime.now().microsecondsSinceEpoch.toString();
  }

  Future<void> _download(String url) async {
    var basename = getTimestampTokenForFilename();
    var extension = path_.extension(url.split('?')[0]);
    var filename = '$basename$extension';
    var filepath = await joinPath([await getExternalStorageDirectoryPath(), 'manhuagui_image', 'IMG_$filename']);
    try {
      var f = await downloadFile(
        url: url,
        filepath: filepath,
        cacheManager: _cache,
        option: DownloadOption(
          behavior: DownloadBehavior.preferUsingCache,
          whenOverwrite: (_) async => OverwriteBehavior.addSuffix,
        ),
      );
      await addToGallery(f);
      Fluttertoast.showToast(msg: '图片已保存至 ${f.path}');
    } catch (e) {
      Fluttertoast.showToast(msg: '无法保存图片');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        setDefaultSystemUIOverlayStyle();
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
              onPressed: () => _reload(),
            ),
            AppBarActionButton(
              icon: Icon(Icons.file_download),
              tooltip: '下載图片',
              onPressed: () => _download(url),
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(color: Colors.black),
          ),
          constraints: BoxConstraints.expand(
            height: MediaQuery.of(context).size.height,
          ),
          child: ValueListenableBuilder<String>(
            valueListenable: _notifier,
            builder: (_, v, __) => PhotoView(
              key: ValueKey(v),
              imageProvider: LocalOrCachedNetworkImageProvider.fromNetwork(
                key: ValueKey(v),
                url: url,
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
      ),
    );
  }
}

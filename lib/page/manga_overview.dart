import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/page/view/full_ripple.dart';
import 'package:manhuagui_flutter/page/view/multi_selection_fab.dart';
import 'package:manhuagui_flutter/page/view/network_image.dart';
import 'package:manhuagui_flutter/service/native/android.dart';
import 'package:manhuagui_flutter/service/storage/download.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

/// 章节页面一览页
class MangaOverviewPage extends StatefulWidget {
  const MangaOverviewPage({
    Key? key,
    required this.mangaId,
    required this.mangaTitle,
    required this.chapterId,
    required this.chapterTitle,
    required this.chapterUrl,
    required this.imageUrls, // all valid
    required this.currentIndex, // start from 0
    required this.loadAllImages,
    required this.onJumpRequested, // also pop this page
    required this.replaceNavigateWrapper,
  }) : super(key: key);

  final int chapterId;
  final String chapterTitle;
  final String chapterUrl;
  final int mangaId;
  final String mangaTitle;
  final List<String> imageUrls;
  final int currentIndex;
  final bool loadAllImages;
  final void Function(BuildContext pageContext, int imageIndex) onJumpRequested;
  final void Function(Future<void> Function({Object? routeResult}) navigate) replaceNavigateWrapper;

  @override
  State<MangaOverviewPage> createState() => _MangaOverviewPageState();
}

class _MangaOverviewPageState extends State<MangaOverviewPage> {
  final _controller = ScrollController();
  final _msController = MultiSelectableController<ValueKey<int>>();

  @override
  void dispose() {
    _controller.dispose();
    _msController.dispose();
    super.dispose();
  }

  // only used when loadAllImages is false
  late final List<Future<File?>> _imageFileFutures = widget.loadAllImages
      ? List.generate(widget.imageUrls.length, (_) => Future.value(null)) // no need for this file list when want to load all images
      : [
          for (var i = 0; i < widget.imageUrls.length; i++) //
            getCachedOrDownloadedChapterPageFilePath(mangaId: widget.mangaId, chapterId: widget.chapterId, pageIndex: i, url: widget.imageUrls[i]).then(
              (filepath) => filepath == null ? null : File(filepath),
            ),
        ];

  Future<void> _toLoadAllImages() async {
    var ok = await showYesNoAlertDialog(
      context: context,
      title: Text('加载所有图片'),
      content: Text('是否在章节页面一览页加载全部页面图片？\n\n提示：如果加载所有图片，有可能会出现在短时间内频繁发出大量请求的情况，有一定概率会导致当前IP被漫画柜封禁'),
      yesText: Text('确定'),
      noText: Text('取消'),
    );
    if (ok == true) {
      widget.replaceNavigateWrapper.call(
        ({routeResult}) => Navigator.of(context).pushReplacement(
          CustomPageRoute.fromTheme(
            themeData: CustomPageRouteTheme.of(context),
            builder: (_) => MangaOverviewPage(
              mangaId: widget.mangaId,
              mangaTitle: widget.mangaTitle,
              chapterId: widget.chapterId,
              chapterTitle: widget.chapterTitle,
              chapterUrl: widget.chapterUrl,
              imageUrls: widget.imageUrls,
              currentIndex: widget.currentIndex,
              loadAllImages: true,
              onJumpRequested: widget.onJumpRequested,
              replaceNavigateWrapper: widget.replaceNavigateWrapper,
            ),
          ),
          result: routeResult,
        ),
      );
    }
  }

  void _onPressed(int index) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('跳转确认'),
        content: Text('是否跳转并查看第${index + 1}页？'),
        actions: [
          TextButton(
            child: Text('跳转'),
            onPressed: () {
              Navigator.of(c).pop();
              widget.onJumpRequested.call(context, index);
            },
          ),
          TextButton(child: Text('取消'), onPressed: () => Navigator.of(c).pop()),
        ],
      ),
    );
  }

  Future<void> _downloadImages(List<int> indices) async {
    // _msController.exitMultiSelectionMode(); // => 不退出多选模式
    indices.sort();

    var canceled = false;
    showDialog(
      context: context,
      builder: (c) => WillPopScope(
        onWillPop: () async {
          canceled = true;
          return true;
        },
        child: AlertDialog(
          contentPadding: EdgeInsets.zero,
          content: CircularProgressDialogOption(
            progress: CircularProgressIndicator(),
            child: Text('正在保存图片...'),
          ),
        ),
      ),
    );
    await Future.delayed(Duration(milliseconds: 300));

    var results = <String>[];
    for (var i in indices) {
      if (canceled) {
        results.add('第${i + 1}页：已取消');
      } else {
        var url = widget.imageUrls[i];
        var f = await downloadImageToGallery(url);
        if (f != null) {
          results.add('第${i + 1}页：已保存至 ${f.path}');
        } else {
          results.add('第${i + 1}页：无法保存第${i + 1}页');
        }
      }
    }

    if (!canceled) {
      Navigator.of(context).pop(); // dismiss progress dialog
    }
    showYesNoAlertDialog(
      context: context,
      title: Text('图片保存结果'),
      scrollable: true,
      content: Text(results.join('\n')),
      yesText: Text('确定'),
      noText: null,
    );
  }

  void _shareLinks(List<int> indices) {
    // _msController.exitMultiSelectionMode(); // => 不退出多选模式
    indices.sort();
    var urls = indices.map((el) => '${widget.chapterUrl}#p=${el + 1}').join('\n');
    shareText(text: '【${widget.mangaTitle} ${widget.chapterTitle}】第${indices.map((el) => el + 1).join(',')}页\n$urls');
  }

  Future<void> _shareImages(List<int> indices) async {
    // _msController.exitMultiSelectionMode(); // => 不退出多选模式
    indices.sort();
    var filepaths = <String>[];
    for (var index in indices) {
      var filepath = await getCachedOrDownloadedChapterPageFilePath(mangaId: widget.mangaId, chapterId: widget.chapterId, pageIndex: index, url: widget.imageUrls[index]);
      if (filepath == null) {
        Fluttertoast.showToast(msg: '第${index + 1}页未加载完成，无法分享图片');
        return;
      }
      filepaths.add(filepath);
    }
    shareFiles(filepaths: filepaths, type: 'image/*');
  }

  Widget _buildItem({required int index, required double width, required double imgHeight, required void Function() onPressed, required void Function()? onLongPressed}) {
    return SizedBox(
      width: width,
      child: FullRippleWidget(
        onTap: onPressed,
        onLongPress: onLongPressed,
        highlightColor: null,
        splashColor: null,
        backgroundDecoration: index != widget.currentIndex
            ? null
            : BoxDecoration(
                border: Border.all(color: Colors.red, width: 1.0),
                color: Colors.orange[50],
              ),
        child: Padding(
          padding: EdgeInsets.all(1.5),
          child: Column(
            children: [
              if (widget.loadAllImages)
                NetworkImageView(
                  url: widget.imageUrls[index],
                  width: width,
                  height: imgHeight,
                  fit: BoxFit.contain,
                  quality: FilterQuality.low,
                ),
              if (!widget.loadAllImages)
                NetworkImageView.butForLocal(
                  fileFuture: _imageFileFutures[index],
                  width: width,
                  height: imgHeight,
                  fit: BoxFit.contain,
                  quality: FilterQuality.low,
                  errorBuilder: (_, __) => Container(
                    width: width,
                    height: imgHeight,
                    color: Colors.orange[50],
                    child: Center(
                      child: IconText(
                        icon: Icon(Icons.pending, color: Colors.grey),
                        text: Text('未加载', style: Theme.of(context).textTheme.bodyText1!.copyWith(color: Colors.grey[600])),
                        space: 4,
                        alignment: IconTextAlignment.t2b,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                      ),
                    ),
                  ),
                ),
              SizedBox(height: 4),
              Text(
                (index + 1).toString(),
                style: Theme.of(context).textTheme.bodyText2?.copyWith(
                      color: index != widget.currentIndex ? Colors.black : Colors.red,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const hPadding = 18.0;
    const vPadding = 12.0;
    const hSpace = 8.0;
    const vSpace = 10.0;
    var width = (MediaQuery.of(context).size.width - hPadding * 2 - hSpace * 2) / 3; // |  ▢ ▢ ▢  |

    return WillPopScope(
      onWillPop: () async {
        if (_msController.multiSelecting) {
          _msController.exitMultiSelectionMode();
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.chapterTitle} (共 ${widget.imageUrls.length} 页)'),
          leading: AppBarActionButton.leading(context: context),
          actions: [
            if (!widget.loadAllImages)
              AppBarActionButton(
                icon: Icon(Icons.visibility),
                tooltip: '加载所有图片',
                onPressed: _toLoadAllImages,
              ),
          ],
        ),
        body: Column(
          children: [
            Material(
              color: Colors.white,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  child: IconText(
                    icon: Icon(Icons.import_contacts, color: Colors.black54),
                    text: Flexible(
                      child: Text('该章节当前阅读至第${widget.currentIndex + 1}页，点击继续阅读该页。', maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    space: 10,
                  ),
                ),
              ),
            ),
            Divider(height: 0, thickness: 1),
            Expanded(
              child: ExtendedScrollbar(
                controller: _controller,
                interactive: true,
                mainAxisMargin: 2,
                crossAxisMargin: 2,
                child: ListView(
                  controller: _controller,
                  padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding),
                  physics: AlwaysScrollableScrollPhysics(),
                  children: [
                    MultiSelectable<ValueKey<int>>(
                      controller: _msController,
                      stateSetter: () => mountedSetState(() {}),
                      onModeChanged: (_) => mountedSetState(() {}),
                      child: Wrap(
                        spacing: hSpace,
                        runSpacing: vSpace,
                        children: [
                          for (var i = 0; i < widget.imageUrls.length; i++)
                            SelectableCheckboxItem<ValueKey<int>>(
                              key: ValueKey<int>(i),
                              checkboxPosition: PositionArgument.fill(
                                bottom: TextSpan(text: '0', style: Theme.of(context).textTheme.bodyText2).layoutSize(context).height + 4 /* bypass bottom index */,
                              ),
                              checkboxBuilder: (_, __, tip) => tip.isSelected //
                                  ? CheckboxForSelectableItem(tip: tip, scale: 1.4, scaleAlignment: Alignment.center)
                                  : SizedBox.shrink(),
                              itemBuilder: (c, key, tip) => _buildItem(
                                index: i,
                                width: width,
                                imgHeight: width,
                                onPressed: () => _onPressed(i),
                                onLongPressed: !tip.isNormal ? null : () => _msController.enterMultiSelectionMode(alsoSelect: [key]),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: MultiSelectionFabContainer(
          multiSelectableController: _msController,
          onCounterPressed: () {
            var indices = _msController.selectedItems.map((e) => e.value).toList();
            indices.sort();
            var titles = indices.map((el) => '第${el + 1}页').toList();
            var allKeys = List.generate(widget.imageUrls.length, (el) => ValueKey(el)).toList();
            MultiSelectionFabContainer.showCounterDialog(context, controller: _msController, selected: titles, allKeys: allKeys);
          },
          fabForMultiSelection: [
            MultiSelectionFabOption(
              child: Icon(Icons.download),
              tooltip: '保存所有图片',
              onPressed: () => _downloadImages(_msController.selectedItems.map((e) => e.value).toList()),
            ),
            MultiSelectionFabOption(
              child: Icon(Icons.share),
              tooltip: '分享所有图片链接',
              onPressed: () => _shareLinks(_msController.selectedItems.map((e) => e.value).toList()),
            ),
            MultiSelectionFabOption(
              child: Icon(MdiIcons.imageMove),
              tooltip: '分享所有图片',
              onPressed: () => _shareImages(_msController.selectedItems.map((e) => e.value).toList()),
            ),
          ],
          fabForNormal: ScrollAnimatedFab(
            scrollController: _controller,
            condition: !_msController.multiSelecting ? ScrollAnimatedCondition.direction : ScrollAnimatedCondition.custom,
            customBehavior: (_) => false,
            fab: FloatingActionButton(
              child: Icon(Icons.vertical_align_top),
              heroTag: null,
              onPressed: () => _controller.scrollToTop(),
            ),
          ),
        ),
      ),
    );
  }
}
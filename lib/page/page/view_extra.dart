import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/manga_viewer.dart';
import 'package:manhuagui_flutter/page/view/action_row.dart';
import 'package:manhuagui_flutter/page/view/custom_icons.dart';
import 'package:manhuagui_flutter/page/view/full_ripple.dart';
import 'package:manhuagui_flutter/page/view/later_manga_banner.dart';
import 'package:manhuagui_flutter/page/view/network_image.dart';
import 'package:manhuagui_flutter/service/native/clipboard.dart';

/// 漫画章节阅读页-额外页
class ViewExtraSubPage extends StatefulWidget {
  const ViewExtraSubPage({
    Key? key,
    required this.isHeader,
    required this.isRtlOperation,
    required this.data,
    required this.onlineMode,
    required this.subscribing,
    required this.inShelf,
    required this.inFavorite,
    required this.laterManga,
    required this.onHeightChanged,
    required this.callbacks,
  }) : super(key: key);

  final bool isHeader;
  final bool isRtlOperation;
  final MangaViewerPageData data;
  final bool onlineMode;
  final bool subscribing;
  final bool inShelf;
  final bool inFavorite;
  final LaterManga? laterManga;
  final void Function({bool byOpt, bool byLater}) onHeightChanged;
  final ViewExtraSubPageCallbacks callbacks;

  @override
  State<ViewExtraSubPage> createState() => ViewExtraSubPageState();
}

/// 一堆回调函数，在 [ViewExtraSubPage] 使用
class ViewExtraSubPageCallbacks {
  const ViewExtraSubPageCallbacks({
    required this.toJumpToImage,
    required this.toGotoNeighbor,
    required this.toShowNeighborTip,
    required this.toPop,
    required this.toSubscribe,
    required this.toDownload,
    required this.toShowToc,
    required this.toShowSettings,
    required this.toShowDetails,
    required this.toShowComments,
    required this.toShowOverview,
    required this.toShare,
    required this.toShowLaters,
    required this.toShowImage,
    required this.toOnlineMode,
  });

  final void Function(int imageIndex /* start from 0 */, bool animated) toJumpToImage;
  final void Function(bool gotoPrevious) toGotoNeighbor;
  final void Function(bool previous) toShowNeighborTip;
  final void Function() toPop;
  final void Function() toSubscribe;
  final void Function() toDownload;
  final void Function() toShowToc;
  final void Function() toShowSettings;
  final void Function() toShowDetails;
  final void Function() toShowComments;
  final void Function() toShowOverview;
  final void Function(bool short) toShare;
  final void Function() toShowLaters;
  final void Function(String url, String title) toShowImage;
  final void Function() toOnlineMode;
}

class ViewExtraSubPageState extends State<ViewExtraSubPage> {
  final _headerTitleBoxKey = GlobalKey();
  final _footerTitleBoxKey = GlobalKey();

  var _moreActions = false; // 显示更多选项

  @override
  void didUpdateWidget(covariant ViewExtraSubPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.laterManga == null && oldWidget.laterManga != null) || (widget.laterManga != null && oldWidget.laterManga == null)) {
      WidgetsBinding.instance?.addPostFrameCallback((_) => widget.onHeightChanged.call(byLater: true));
    }
  }

  double? getTitleBoxHeight() {
    return (widget.isHeader ? _headerTitleBoxKey : _footerTitleBoxKey).currentContext?.findRenderBox()?.size.height;
  }

  Widget _buildChapters() {
    if (widget.data.chapterNeighbor?.notLoaded != false) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: Text(
            '当前处于离线模式，但未在下载列表获取到章节跳转信息',
            style: Theme.of(context).textTheme.subtitle1?.copyWith(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
          ),
        ),
      );
    }

    Widget _buildAction({required String text, required String subText, required bool left, required void Function() action, void Function()? longPress, required bool disable}) {
      return InkWell(
        onTap: disable ? null : action,
        onLongPress: disable ? null : longPress,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: disable
              ? Text(
                  text,
                  style: Theme.of(context).textTheme.subtitle1?.copyWith(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Transform.rotate(
                      angle: left ? math.pi : 0,
                      child: Icon(
                        Icons.arrow_right_alt,
                        size: 30,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    Text(
                      text,
                      style: Theme.of(context).textTheme.subtitle1?.copyWith(
                            fontSize: 18,
                            color: Theme.of(context).primaryColor,
                          ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      subText,
                      style: Theme.of(context).textTheme.bodyText2!.copyWith(fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
        ),
      );
    }

    var neighbor = widget.data.chapterNeighbor!;
    var prev = Expanded(
      child: _buildAction(
        text: neighbor.hasPrevChapter ? '阅读上一章节' : '暂无上一章节',
        subText: neighbor.getAvailableNeighbors(previous: true).map((t) => t.title).let((t) => t.isEmpty ? '' : (t.length == 1 ? t.first : '${t.first}等')),
        left: !widget.isRtlOperation ? true : false,
        disable: !neighbor.hasPrevChapter,
        action: () => widget.callbacks.toGotoNeighbor.call(true),
        longPress: () => widget.callbacks.toShowNeighborTip.call(true),
      ),
    );
    var next = Expanded(
      child: _buildAction(
        text: neighbor.hasNextChapter ? '阅读下一章节' : '暂无下一章节',
        subText: neighbor.getAvailableNeighbors(previous: false).map((t) => t.title).let((t) => t.isEmpty ? '' : (t.length == 1 ? t.first : '${t.first}等')),
        left: !widget.isRtlOperation ? false : true,
        disable: !neighbor.hasNextChapter,
        action: () => widget.callbacks.toGotoNeighbor.call(false),
        longPress: () => widget.callbacks.toShowNeighborTip.call(false),
      ),
    );

    return IntrinsicHeight(
      child: Row(
        children: [
          if (!widget.isRtlOperation) prev, // 上一章
          if (widget.isRtlOperation) next, // 下一章(反)
          VerticalDivider(width: 15 * 2 + 2, thickness: 2),
          if (!widget.isRtlOperation) next, // 下一章(反)
          if (widget.isRtlOperation) prev, // 上一章
        ],
      ),
    );
  }

  Widget _buildActions() {
    Widget iconBuilder(ActionItem action) => Container(
          height: 45,
          width: 45,
          margin: EdgeInsets.only(bottom: 3),
          decoration: BoxDecoration(
            border: Border.all(width: 0.8, color: Colors.grey[400]!),
            shape: BoxShape.circle,
          ),
          child: Icon(
            action.icon,
            size: 22,
            color: action.enable ? Colors.grey[800] : Colors.grey,
          ),
        );

    return Column(
      children: [
        ActionRowView.five(
          iconBuilder: iconBuilder,
          action1: ActionItem(text: '结束阅读', icon: Icons.arrow_back, action: () => widget.callbacks.toPop.call()),
          action2: ActionItem(
            text: !widget.inShelf && !widget.inFavorite
                ? '订阅漫画'
                : widget.inShelf && widget.inFavorite
                    ? '查看订阅'
                    : (widget.inShelf && !widget.inFavorite ? '已放书架' : '已加收藏'),
            icon: !widget.inShelf && !widget.inFavorite ? Icons.sell : Icons.loyalty,
            action: widget.subscribing ? null : () => widget.callbacks.toSubscribe.call(),
            enable: !widget.subscribing,
          ),
          action3: ActionItem(text: '章节列表', icon: Icons.menu, action: () => widget.callbacks.toShowToc.call()),
          action4: ActionItem(text: '下载漫画', icon: Icons.download, action: () => widget.callbacks.toDownload.call()),
          action5: ActionItem(
            text: !_moreActions ? '更多操作' : '更少操作',
            icon: Icons.more_vert,
            action: () {
              _moreActions = !_moreActions;
              if (mounted) setState(() {});
              WidgetsBinding.instance?.addPostFrameCallback((_) => widget.onHeightChanged.call(byOpt : true));
            },
          ),
        ),
        if (_moreActions)
          ActionRowView.five(
            iconBuilder: iconBuilder,
            action1: ActionItem(text: '阅读设置', icon: CustomIcons.opened_book_cog, action: () => widget.callbacks.toShowSettings.call()),
            action2: ActionItem(text: '章节详情', icon: Icons.subject, action: () => widget.callbacks.toShowDetails.call()),
            action3: ActionItem(text: '查看评论', icon: Icons.forum, action: () => widget.callbacks.toShowComments.call()),
            action4: ActionItem(text: '页面一览', icon: CustomIcons.image_timeline, action: () => widget.callbacks.toShowOverview.call()),
            action5: ActionItem(text: '分享章节', icon: Icons.share, action: () => widget.callbacks.toShare.call(false), longPress: () => widget.callbacks.toShare.call(true)),
          ),
      ],
    );
  }

  void _vibrateAndCopy(String msg) {
    HapticFeedback.vibrate();
    copyText(msg, showToast: true);
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      removeBottom: true,
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Column(
          children: [
            // ****************************************************************
            // 额外页首页-头部框
            // ****************************************************************
            if (widget.isHeader)
              Container(
                key: _headerTitleBoxKey,
                color: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 18, horizontal: 18),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FullRippleWidget(
                          child: NetworkImageView(
                            url: widget.data.mangaCover,
                            height: 200,
                            width: 150,
                            quality: FilterQuality.high,
                            border: Border.all(
                              width: 1.0,
                              color: Colors.grey[400]!,
                            ),
                          ),
                          onTap: () => widget.callbacks.toShowImage(widget.data.mangaCover, '漫画封面'),
                        ),
                        SizedBox(width: 18),
                        Container(
                          width: MediaQuery.of(context).size.width - 18 * 3 - 150 - 2, // | ▢ ▢▢ |
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Flexible(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  child: Text(
                                    widget.data.mangaTitle,
                                    style: Theme.of(context).textTheme.headline6,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onLongPress: () => _vibrateAndCopy(widget.data.mangaTitle),
                                ),
                              ),
                              SizedBox(height: 4),
                              Flexible(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 4, bottom: 4),
                                    child: Text(
                                      widget.data.chapterTitle,
                                      style: Theme.of(context).textTheme.subtitle1?.copyWith(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w500,
                                            color: Theme.of(context).primaryColor,
                                          ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  onLongPress: () => _vibrateAndCopy(widget.data.chapterTitle),
                                ),
                              ),
                              if (widget.data.mangaAuthors != null || (widget.data.newestDate != null && widget.data.isMangaFinished != null))
                                Flexible(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    child: Padding(
                                      padding: EdgeInsets.only(top: 4, bottom: 4),
                                      child: Text(
                                        [
                                          widget.data.mangaAuthors?.map((a) => a.name).join('/'),
                                          widget.data.isMangaFinished?.let((fin) => '${fin ? '更新' : '完结'}于 ${widget.data.newestDate}'),
                                        ].join('・'),
                                        style: Theme.of(context).textTheme.subtitle1?.copyWith(
                                              fontSize: 14,
                                              fontWeight: FontWeight.normal,
                                              color: Theme.of(context).primaryColor,
                                            ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    onLongPress: widget.data.mangaAuthors == null ? null : () => _vibrateAndCopy(widget.data.mangaAuthors!.map((a) => a.name).join('/')),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 18),
                    SizedBox(
                      height: 45,
                      width: 200,
                      child: ElevatedButton(
                        child: Text('开始阅读'),
                        onPressed: () => widget.callbacks.toJumpToImage.call(0, true),
                      ),
                    ),
                  ],
                ),
              ),
            // ****************************************************************
            // 额外页尾页-头部框
            // ****************************************************************
            if (!widget.isHeader)
              Container(
                key: _footerTitleBoxKey,
                color: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 18, horizontal: 18),
                child: Column(
                  children: [
                    FullRippleWidget(
                      child: NetworkImageView(
                        url: widget.data.chapterCover,
                        height: 150,
                        width: 150 / 0.618,
                        fit: BoxFit.cover,
                        quality: FilterQuality.high,
                        border: Border.all(
                          width: 1.0,
                          color: Colors.grey[400]!,
                        ),
                      ),
                      onTap: () => widget.callbacks.toShowImage(widget.data.chapterCover, '章节封面'),
                    ),
                    SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            child: Text(
                              '- ${widget.data.chapterTitle} -',
                              style: Theme.of(context).textTheme.headline6?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).primaryColor,
                                  ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onLongPress: () => _vibrateAndCopy(widget.data.chapterTitle),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: EdgeInsets.only(top: 4, bottom: 4),
                              child: Text(
                                '《${widget.data.mangaTitle}》',
                                style: Theme.of(context).textTheme.bodyText2!.copyWith(fontSize: 14),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            onLongPress: () => _vibrateAndCopy(widget.data.mangaTitle),
                          ),
                        ),
                      ],
                    ),
                    if (widget.data.mangaAuthors != null || (widget.data.newestDate != null && widget.data.isMangaFinished != null))
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding: EdgeInsets.only(top: 4, bottom: 4),
                                child: Text(
                                  [
                                    widget.data.mangaAuthors?.map((a) => a.name).join('/').let((a) => '作者 $a'),
                                    widget.data.isMangaFinished?.let((fin) => '${fin ? '最近更新' : '漫画完结'}于 ${widget.data.newestDate}'),
                                  ].join('・'),
                                  style: Theme.of(context).textTheme.bodyText2!.copyWith(fontSize: 14),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              onLongPress: widget.data.mangaAuthors == null ? null : () => _vibrateAndCopy(widget.data.mangaAuthors!.map((a) => a.name).join('/')),
                            ),
                          ),
                        ],
                      ),
                    SizedBox(height: 18 - 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 45,
                          width: 150,
                          child: ElevatedButton(
                            child: Text('重新阅读'),
                            onPressed: () => widget.callbacks.toJumpToImage.call(0, false),
                          ),
                        ),
                        SizedBox(width: 18),
                        SizedBox(
                          height: 45,
                          width: 150,
                          child: ElevatedButton(
                            child: Text('返回上一页'),
                            onPressed: () => widget.callbacks.toJumpToImage.call(widget.data.pageCount - 1, true),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            // ****************************************************************
            // 稍后阅读
            // ****************************************************************
            if (widget.laterManga != null)
              Padding(
                padding: EdgeInsets.only(top: 18),
                child: LaterMangaBannerView(
                  manga: widget.laterManga!,
                  currentNewestChapter: widget.data.newestChapter,
                  currentNewestDate: widget.data.newestDate,
                  action: () => widget.callbacks.toShowLaters.call(),
                ),
              ),
            // ****************************************************************
            // 离线模式提醒
            // ****************************************************************
            if (!widget.onlineMode)
              Container(
                color: Colors.white,
                margin: EdgeInsets.only(top: 18),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    child: IconText(
                      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12), // hPadding_18 <= 15, vPadding_12 <= 18
                      icon: Icon(Icons.public_off, size: 26, color: Colors.black54),
                      space: 18,
                      text: Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '当前正以离线模式阅读漫画章节',
                              style: Theme.of(context).textTheme.subtitle1!.copyWith(fontSize: 18),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2),
                            Text(
                              '下载数据更新于 ${widget.data.formattedMetadataUpdatedAt}',
                              style: Theme.of(context).textTheme.bodyText2!.copyWith(fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    onTap: () => showYesNoAlertDialog(
                      context: context,
                      title: Text('离线模式'),
                      content: Text('当前正以离线模式阅读漫画章节，如果漫画章节已更新，可切换至在线模式更新下载数据。'),
                      yesText: Text('切换'),
                      noText: Text('关闭'),
                      yesOnPressed: (c) {
                        Navigator.of(c).pop();
                        widget.callbacks.toOnlineMode.call();
                      },
                    ),
                  ),
                ),
              ),
            // ****************************************************************
            // 上下章节 / 五个按钮
            // ****************************************************************
            SizedBox(height: 18),
            Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 18 - 6),
              child: Material(
                color: Colors.transparent,
                child: _buildChapters(), // InkWell vertical padding: 6
              ),
            ),
            SizedBox(height: 18),
            Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 18 - 6 - 8),
              child: Material(
                color: Colors.transparent,
                child: _buildActions(), // InkWell vertical padding: 6, ActionRowView vertical padding: 8
              ),
            ),
          ],
        ),
      ),
    );
  }
}

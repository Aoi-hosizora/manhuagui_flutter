import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/entity.dart';
import 'package:manhuagui_flutter/page/manga_viewer.dart';
import 'package:manhuagui_flutter/page/view/action_row.dart';
import 'package:manhuagui_flutter/page/view/full_ripple.dart';
import 'package:manhuagui_flutter/page/view/later_manga_banner.dart';
import 'package:manhuagui_flutter/page/view/network_image.dart';
import 'package:manhuagui_flutter/service/native/clipboard.dart';

/// 漫画章节阅读页-额外页
class ViewExtraSubPage extends StatefulWidget {
  const ViewExtraSubPage({
    Key? key,
    required this.isHeader,
    required this.reverseScroll,
    required this.data,
    required this.onlineMode,
    required this.subscribing,
    required this.inShelf,
    required this.inFavorite,
    required this.laterManga,
    required this.toJumpToImage,
    required this.toGotoNeighbor,
    required this.toShowNeighborTip,
    required this.toSubscribe,
    required this.toDownload,
    required this.toShowToc,
    required this.toShowDetails,
    required this.toShowComments,
    required this.toShowLaters,
    required this.toShowImage,
    required this.toOnlineMode,
  }) : super(key: key);

  final bool isHeader;
  final bool reverseScroll;
  final MangaViewerPageData data;
  final bool onlineMode;
  final bool subscribing;
  final bool inShelf;
  final bool inFavorite;
  final LaterManga? laterManga;
  final void Function(int imageIndex /* start from 0 */, bool animated) toJumpToImage;
  final void Function(bool gotoPrevious) toGotoNeighbor;
  final void Function(bool previous) toShowNeighborTip;
  final void Function() toSubscribe;
  final void Function() toDownload;
  final void Function() toShowToc;
  final void Function() toShowDetails;
  final void Function() toShowComments;
  final void Function() toShowLaters;
  final void Function(String url, String title) toShowImage;
  final void Function() toOnlineMode;

  @override
  State<ViewExtraSubPage> createState() => _ViewExtraSubPageState();
}

class _ViewExtraSubPageState extends State<ViewExtraSubPage> {
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
                        size: 28,
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
        subText: neighbor.getAvailableChapters(previous: true).map((t) => t.title).let((t) => t.isEmpty ? '' : (t.length == 1 ? t.first : '${t.first}等')),
        left: !widget.reverseScroll ? true : false,
        disable: !neighbor.hasPrevChapter,
        action: () => widget.toGotoNeighbor.call(true),
        longPress: () => widget.toShowNeighborTip.call(true),
      ),
    );

    var next = Expanded(
      child: _buildAction(
        text: neighbor.hasNextChapter ? '阅读下一章节' : '暂无下一章节',
        subText: neighbor.getAvailableChapters(previous: false).map((t) => t.title).let((t) => t.isEmpty ? '' : (t.length == 1 ? t.first : '${t.first}等')),
        left: !widget.reverseScroll ? false : true,
        disable: !neighbor.hasNextChapter,
        action: () => widget.toGotoNeighbor.call(false),
        longPress: () => widget.toShowNeighborTip.call(false),
      ),
    );

    return IntrinsicHeight(
      child: Row(
        children: [
          if (!widget.reverseScroll) prev, // 上一章
          if (widget.reverseScroll) next, // 下一章(反)
          VerticalDivider(width: 36, thickness: 2),
          if (!widget.reverseScroll) next, // 下一章(反)
          if (widget.reverseScroll) prev, // 上一章
        ],
      ),
    );
  }

  Widget _buildActions() {
    return ActionRowView.five(
      iconBuilder: (action) => Container(
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
      ),
      action1: ActionItem(
        text: !widget.inShelf && !widget.inFavorite
            ? '订阅漫画'
            : widget.inShelf && widget.inFavorite
                ? '查看订阅'
                : (widget.inShelf && !widget.inFavorite ? '已放书架' : '已加收藏'),
        icon: !widget.inShelf && !widget.inFavorite ? Icons.sell : Icons.loyalty,
        action: widget.subscribing ? null : () => widget.toSubscribe.call(),
        enable: !widget.subscribing,
      ),
      action2: ActionItem(
        text: '下载漫画',
        icon: Icons.download,
        action: () => widget.toDownload.call(),
      ),
      action3: ActionItem(
        text: '章节列表',
        icon: Icons.menu,
        action: () => widget.toShowToc.call(),
      ),
      action4: ActionItem(
        text: '章节详情',
        icon: Icons.subject,
        action: () => widget.toShowDetails.call(),
      ),
      action5: ActionItem(
        text: '查看评论',
        icon: Icons.forum,
        action: () => widget.toShowComments.call(),
      ),
      // TODO add 更多操作 (包含查看评论、查看漫画详情、查看章节详情等)，并恢复 "结束阅读" 按钮
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
                          onTap: () => widget.toShowImage(widget.data.mangaCover, '漫画封面'),
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
                                  child: Text(
                                    widget.data.mangaTitle,
                                    style: Theme.of(context).textTheme.headline6,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onLongPress: () => _vibrateAndCopy(widget.data.mangaTitle),
                                ),
                              ),
                              Flexible(
                                child: GestureDetector(
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 8), // TODO test
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
                              if (widget.data.mangaAuthors != null)
                                Flexible(
                                  child: GestureDetector(
                                    child: Padding(
                                      padding: EdgeInsets.only(top: 8),
                                      child: Text(
                                        widget.data.mangaAuthors!.map((a) => a.name).join('/'),
                                        style: Theme.of(context).textTheme.subtitle1?.copyWith(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Theme.of(context).primaryColor,
                                            ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    onLongPress: () => _vibrateAndCopy(widget.data.mangaAuthors!.map((a) => a.name).join('/')),
                                  ),
                                ),
                              if (widget.data.newestDateAndFinished != null)
                                Flexible(
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 8), // TODO test
                                    child: Text(
                                      '${!widget.data.newestDateAndFinished!.item2 ? '更新中' : '已完结'}・${widget.data.newestDateAndFinished!.item1}', // TODO test
                                      style: Theme.of(context).textTheme.subtitle1?.copyWith(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Theme.of(context).primaryColor,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
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
                        onPressed: () => widget.toJumpToImage.call(0, true),
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
                      onTap: () => widget.toShowImage(widget.data.chapterCover, '章节封面'),
                    ),
                    SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: GestureDetector(
                            child: Text(
                              '- ${widget.data.chapterTitle} -',
                              style: Theme.of(context).textTheme.headline6?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).primaryColor,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onLongPress: () => _vibrateAndCopy(widget.data.chapterTitle),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: GestureDetector(
                            child: Text(
                              '《${widget.data.mangaTitle}》',
                              style: Theme.of(context).textTheme.bodyText2!.copyWith(fontSize: 14),
                              textAlign: TextAlign.center, // TODO test
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onLongPress: () => _vibrateAndCopy(widget.data.mangaTitle),
                          ),
                        ),
                      ],
                    ),
                    if (widget.data.mangaAuthors != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: GestureDetector(
                              child: Padding(
                                padding: EdgeInsets.only(top: 6), // TODO test
                                child: Text(
                                  '作者：${widget.data.mangaAuthors!.map((a) => a.name).join('/')}',
                                  style: Theme.of(context).textTheme.bodyText2!.copyWith(fontSize: 14),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              onLongPress: () => _vibrateAndCopy(widget.data.mangaAuthors!.map((a) => a.name).join('/')),
                            ),
                          ),
                        ],
                      ),
                    if (widget.data.newestDateAndFinished != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Padding(
                              padding: EdgeInsets.only(top: 6), // TODO test
                              child: Text(
                                '更新至 ${widget.data.newestDateAndFinished!.item1}・${!widget.data.newestDateAndFinished!.item2 ? '更新中' : '已完结'}', // TODO test
                                style: Theme.of(context).textTheme.bodyText2!.copyWith(fontSize: 14),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 45,
                          width: 150,
                          child: ElevatedButton(
                            child: Text('重新阅读'),
                            onPressed: () => widget.toJumpToImage.call(0, false),
                          ),
                        ),
                        SizedBox(width: 18),
                        SizedBox(
                          height: 45,
                          width: 150,
                          child: ElevatedButton(
                            child: Text('返回上一页'),
                            onPressed: () => widget.toJumpToImage.call(widget.data.pageCount - 1, true),
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
                  action: () => widget.toShowLaters.call(),
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
                        widget.toOnlineMode.call();
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

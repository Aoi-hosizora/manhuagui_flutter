import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:manhuagui_flutter/page/manga_viewer.dart';
import 'package:manhuagui_flutter/page/view/action_row.dart';
import 'package:manhuagui_flutter/page/view/network_image.dart';

/// 漫画章节阅读页-额外页
class ViewExtraSubPage extends StatelessWidget {
  const ViewExtraSubPage({
    Key? key,
    required this.isHeader,
    required this.reverseScroll,
    required this.data,
    required this.subscribing,
    required this.subscribed,
    required this.toJumpToImage,
    required this.toSubscribe,
    required this.toDownload,
    required this.toGotoChapter,
    required this.toShowToc,
    required this.toShowComments,
    required this.toPop,
  }) : super(key: key);

  final bool isHeader;
  final bool reverseScroll;
  final MangaViewerPageData data;
  final bool subscribing;
  final bool subscribed;
  final void Function(int imageIndex, bool animated) toJumpToImage;
  final void Function(bool gotoPrevious) toGotoChapter;
  final void Function() toSubscribe;
  final void Function() toDownload;
  final void Function() toShowToc;
  final void Function() toShowComments;
  final void Function() toPop;

  Widget _buildChapters(BuildContext context) {
    Widget _buildAction({required String text, required String subText, required bool left, required void Function() action, required bool disable}) {
      return InkWell(
        onTap: disable ? null : action,
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
        ),
      );
    }

    var prev = Expanded(
      child: _buildAction(
        text: data.prevChapterId != 0 ? '阅读上一章节' : '暂无上一章节',
        subText: data.prevChapterTitle,
        left: !reverseScroll ? true : false,
        disable: data.prevChapterId == 0,
        action: () => toGotoChapter.call(true),
      ),
    );

    var next = Expanded(
      child: _buildAction(
        text: data.nextChapterId != 0 ? '阅读下一章节' : '暂无下一章节',
        subText: data.nextChapterTitle,
        left: !reverseScroll ? false : true,
        disable: data.nextChapterId == 0,
        action: () => toGotoChapter.call(false),
      ),
    );

    return IntrinsicHeight(
      child: Row(
        children: [
          if (!reverseScroll) prev, // 上一章
          if (reverseScroll) next, // 下一章(反)
          VerticalDivider(width: 36, thickness: 2),
          if (!reverseScroll) next, // 下一章(反)
          if (reverseScroll) prev, // 上一章
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
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
        text: '结束阅读',
        icon: Icons.arrow_back,
        action: () => toPop.call(),
      ),
      action2: ActionItem(
        text: !subscribed ? '订阅漫画' : '取消订阅',
        icon: !subscribed ? Icons.star_border : Icons.star,
        action: () => toSubscribe.call(),
        enable: !subscribing,
      ),
      action3: ActionItem(
        text: '下载漫画',
        icon: Icons.download,
        action: () => toDownload.call(),
      ),
      action4: ActionItem(
        text: '漫画目录',
        icon: Icons.menu,
        action: () => toShowToc.call(),
      ),
      action5: ActionItem(
        text: '查看评论',
        icon: Icons.forum,
        action: () => toShowComments.call(),
      ),
    );
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
            if (isHeader)
              Container(
                color: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 18, horizontal: 18),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        NetworkImageView(
                          url: data.mangaCover,
                          height: 200,
                          width: 150,
                          border: Border.all(
                            width: 1.0,
                            color: Colors.grey[400]!,
                          ),
                        ),
                        SizedBox(width: 18),
                        Container(
                          width: MediaQuery.of(context).size.width - 18 * 3 - 150 - 2, // | ▢ ▢▢ |
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Flexible(
                                child: Text(
                                  data.mangaTitle,
                                  style: Theme.of(context).textTheme.headline6,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(height: 10),
                              Flexible(
                                child: Text(
                                  data.chapterTitle,
                                  style: Theme.of(context).textTheme.subtitle1?.copyWith(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 18),
                    SizedBox(
                      height: 42,
                      width: 200,
                      child: ElevatedButton(
                        child: Text('开始阅读'),
                        onPressed: () => toJumpToImage.call(1, true),
                      ),
                    ),
                  ],
                ),
              ),
            // ****************************************************************
            // 额外页尾页-头部框
            // ****************************************************************
            if (!isHeader)
              Container(
                color: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 18, horizontal: 18),
                child: Column(
                  children: [
                    NetworkImageView(
                      url: data.chapterCover,
                      height: 150,
                      width: 150 / 0.618,
                      fit: BoxFit.cover,
                      border: Border.all(
                        width: 1.0,
                        color: Colors.grey[400]!,
                      ),
                    ),
                    SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            '- ${data.chapterTitle} -',
                            style: Theme.of(context).textTheme.headline6?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).primaryColor,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 42,
                          width: 150,
                          child: ElevatedButton(
                            child: Text('重新阅读'),
                            onPressed: () => toJumpToImage.call(1, false),
                          ),
                        ),
                        SizedBox(width: 18),
                        SizedBox(
                          height: 42,
                          width: 150,
                          child: ElevatedButton(
                            child: Text('返回上一页'),
                            onPressed: () => toJumpToImage.call(data.pageCount, true),
                          ),
                        ),
                      ],
                    ),
                  ],
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
                child: _buildChapters(context), // InkWell vertical padding: 6
              ),
            ),
            SizedBox(height: 18),
            Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 18 - 6 - 8),
              child: Material(
                color: Colors.transparent,
                child: _buildActions(context), // InkWell vertical padding: 6, ActionRowView vertical padding: 8
              ),
            ),
          ],
        ),
      ),
    );
  }
}

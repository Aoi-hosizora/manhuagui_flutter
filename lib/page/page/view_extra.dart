import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/page/view/network_image.dart';

/// 漫画章节阅读页-额外页
class ViewExtraSubPage extends StatelessWidget {
  const ViewExtraSubPage({
    Key? key,
    required this.isHeader,
    required this.reverseScroll,
    required this.chapter,
    required this.mangaCover,
    required this.chapterGroups,
    required this.onJumpToImage,
    required this.onGotoChapter,
    required this.onShowToc,
    required this.onShowComments,
    required this.onPop,
  }) : super(key: key);

  final bool isHeader;
  final bool reverseScroll;
  final MangaChapter chapter;
  final String mangaCover;
  final List<MangaChapterGroup> chapterGroups;
  final void Function(int imageIndex, bool animated) onJumpToImage;
  final void Function(bool gotoPrevious) onGotoChapter;
  final void Function() onShowToc;
  final void Function() onShowComments;
  final void Function() onPop;

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
        text: chapter.prevCid != 0 ? '阅读上一章节' : '暂无上一章节',
        subText: (chapterGroups.findTitle(chapter.prevCid) ?? '未知话'),
        left: !reverseScroll ? true : false,
        disable: chapter.prevCid == 0,
        action: () => onGotoChapter.call(true),
      ),
    );

    var next = Expanded(
      child: _buildAction(
        text: chapter.nextCid != 0 ? '阅读下一章节' : '暂无下一章节',
        subText: (chapterGroups.findTitle(chapter.nextCid) ?? '未知话'),
        left: !reverseScroll ? false : true,
        disable: chapter.nextCid == 0,
        action: () => onGotoChapter.call(false),
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
    Widget _buildAction({required String text, required IconData icon, required void Function() action}) {
      return InkWell(
        onTap: action,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Column(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  border: Border.all(width: 0.8, color: Colors.grey[400]!),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 10),
              Text(text),
            ],
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildAction(
          text: '收藏漫画',
          icon: Icons.star_outlined,
          action: () {}, // TODO
        ),
        _buildAction(
          text: '下载漫画',
          icon: Icons.download,
          action: () {}, // TODO
        ),
        _buildAction(
          text: '漫画目录',
          icon: Icons.menu,
          action: () => onShowToc.call(),
        ),
        _buildAction(
          text: '查看评论',
          icon: Icons.forum,
          action: () => onShowComments.call(),
        ),
        _buildAction(
          text: '结束阅读',
          icon: Icons.arrow_back,
          action: () => onPop.call(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      removeBottom: true,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          NetworkImageView(
                            url: mangaCover,
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
                                    chapter.mangaTitle,
                                    style: Theme.of(context).textTheme.headline6,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Flexible(
                                  child: Text(
                                    chapter.title,
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
                          onPressed: () => onJumpToImage.call(1, true),
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
                        url: chapter.pages[0],
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
                              '- ${chapter.title} -',
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
                              onPressed: () => onJumpToImage.call(1, false),
                            ),
                          ),
                          SizedBox(width: 18),
                          SizedBox(
                            height: 42,
                            width: 150,
                            child: ElevatedButton(
                              child: Text('返回上一页'),
                              onPressed: () => onJumpToImage.call(chapter.pages.length, true),
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
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 18 - 6),
                child: Material(
                  color: Colors.transparent,
                  child: _buildChapters(context), // InkWell vertical padding: 6
                ),
              ),
              SizedBox(height: 18),
              Container(
                color: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 18 - 6),
                child: Material(
                  color: Colors.transparent,
                  child: _buildActions(context), // InkWell vertical padding: 6
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

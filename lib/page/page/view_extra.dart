import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:manhuagui_flutter/model/chapter.dart';
import 'package:manhuagui_flutter/page/view/network_image.dart';

/// 漫画章节阅读页-额外页
class ViewExtraSubPage extends StatelessWidget {
  const ViewExtraSubPage({
    Key? key,
    required this.isHeader,
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
  final MangaChapter chapter;
  final String mangaCover;
  final List<MangaChapterGroup> chapterGroups;
  final void Function(int imageIndex) onJumpToImage;
  final void Function({required bool gotoPrevious}) onGotoChapter;
  final void Function() onShowToc;
  final void Function() onShowComments;
  final void Function() onPop;

  Widget _buildHeaderView(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
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
                    width: MediaQuery.of(context).size.width - 18 * 3 - 152, // | ▢ ▢▢ |
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Text(
                            chapter.mangaTitle,
                            style: Theme.of(context).textTheme.headline6,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(height: 10),
                        Flexible(
                          child: Text(
                            chapter.title,
                            style: Theme.of(context).textTheme.subtitle1?.copyWith(color: Theme.of(context).primaryColor),
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
                  onPressed: () => onJumpToImage.call(1),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 18),
        Container(
          color: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 18 - 4),
          child: Material(
            color: Colors.transparent,
            child: IntrinsicHeight(
              child: Row(
                children: [
                  SizedBox(width: 18),
                  Expanded(
                    child: InkWell(
                      onTap: chapter.prevCid == 0 ? null : () => onGotoChapter.call(gotoPrevious: true),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: chapter.prevCid == 0
                            ? Text(
                                '暂无上一章节',
                                style: Theme.of(context).textTheme.subtitle1?.copyWith(color: Colors.grey[600]),
                                textAlign: TextAlign.center,
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Transform.rotate(
                                    angle: math.pi,
                                    child: Icon(
                                      Icons.arrow_right_alt,
                                      size: 28,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                  Text(
                                    '阅读上一章节',
                                    style: Theme.of(context).textTheme.subtitle1?.copyWith(color: Theme.of(context).primaryColor),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    (chapterGroups.findTitle(chapter.prevCid) ?? '未知话'),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  VerticalDivider(width: 36, thickness: 2),
                  Expanded(
                    child: InkWell(
                      onTap: chapter.nextCid == 0 ? null : () => onGotoChapter.call(gotoPrevious: false),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: chapter.nextCid == 0
                            ? Text(
                                '暂无下一章节',
                                style: Theme.of(context).textTheme.subtitle1?.copyWith(color: Colors.grey[600]),
                                textAlign: TextAlign.center,
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.arrow_right_alt,
                                    size: 28,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  Text(
                                    '阅读下一章节',
                                    style: Theme.of(context).textTheme.subtitle1?.copyWith(color: Theme.of(context).primaryColor),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    chapterGroups.findTitle(chapter.nextCid) ?? '未知话',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  SizedBox(width: 18),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 18),
        Container(
          color: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 18 - 6),
          child: Material(
            color: Colors.transparent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                InkWell(
                  onTap: () {}, // TODO
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
                            Icons.star_outlined,
                            size: 22,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 10),
                        Text('收藏漫画'),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {}, // TODO
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
                            Icons.download,
                            size: 22,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 10),
                        Text('下载漫画'),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => onShowToc.call(),
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
                            Icons.menu,
                            size: 22,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 10),
                        Text('漫画目录'),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => onShowComments.call(),
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
                            Icons.forum,
                            size: 22,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 10),
                        Text('查看评论'),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => onPop.call(),
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
                            Icons.arrow_back,
                            size: 22,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 10),
                        Text('结束阅读'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterView(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(chapter.mangaTitle),
        Text(chapter.title),
        OutlinedButton(
          child: Text('重新阅读'),
          onPressed: () => onJumpToImage.call(1),
        ),
        OutlinedButton(
          child: Text('返回上一页'),
          onPressed: () => onJumpToImage.call(chapter.pages.length),
        ),
        if (chapter.prevCid != 0)
          OutlinedButton(
            child: Text('阅读上一章节: ${chapterGroups.findTitle(chapter.prevCid) ?? '未知话'}'),
            onPressed: () => onGotoChapter.call(gotoPrevious: true),
          ),
        if (chapter.nextCid != 0)
          OutlinedButton(
            child: Text('阅读下一章节: ${chapterGroups.findTitle(chapter.nextCid) ?? '未知话'}'),
            onPressed: () => onGotoChapter.call(gotoPrevious: false),
          ),
        OutlinedButton(
          child: Text('漫画目录'),
          onPressed: () => onShowToc.call(),
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
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: isHeader
            ? _buildHeaderView(context) //
            : _buildFooterView(context),
      ),
    );
  }
}

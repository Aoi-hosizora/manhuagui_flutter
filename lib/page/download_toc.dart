import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/page/image_viewer.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/view/full_ripple.dart';
import 'package:manhuagui_flutter/page/view/manga_toc.dart';
import 'package:manhuagui_flutter/page/view/network_image.dart';
import 'package:manhuagui_flutter/service/native/browser.dart';

/// 漫画已下载章节目录页，查询数据库并展示 [DownloadedManga] 列表信息
class DownloadTocPage extends StatefulWidget {
  const DownloadTocPage({
    Key? key,
    required this.mangaId,
    required this.mangaTitle,
    required this.mangaCover,
    required this.mangaUrl,
  }) : super(key: key);

  final int mangaId;
  final String mangaTitle;
  final String mangaCover;
  final String mangaUrl;

  @override
  State<DownloadTocPage> createState() => _DownloadTocPageState();
}

class _DownloadTocPageState extends State<DownloadTocPage> {
  final _controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('已下载章节'),
        leading: AppBarActionButton.leading(context: context),
        actions: [
          AppBarActionButton(
            icon: Icon(Icons.open_in_browser),
            tooltip: '用浏览器打开',
            onPressed: () => launchInBrowser(
              context: context,
              url: widget.mangaUrl,
            ),
          ),
        ],
      ),
      body: ListView(
        controller: _controller,
        children: [
          Container(
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ****************************************************************
                    // 封面
                    // ****************************************************************
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: FullRippleWidget(
                        child: NetworkImageView(
                          url: widget.mangaCover,
                          height: 160,
                          width: 120,
                        ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (c) => ImageViewerPage(
                              url: widget.mangaCover,
                              title: '漫画封面',
                            ),
                          ),
                        ),
                      ),
                    ),
                    // ****************************************************************
                    // 信息
                    // ****************************************************************
                    Container(
                      width: MediaQuery.of(context).size.width - 14 * 3 - 120, // | ▢ ▢▢ |
                      padding: EdgeInsets.only(top: 10, bottom: 10, right: 14),
                      alignment: Alignment.centerLeft,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Text(
                              widget.mangaTitle,
                              style: Theme.of(context).textTheme.headline6,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(height: 2),
                          IconText(
                            icon: Icon(Icons.download, size: 20, color: Colors.orange),
                            text: Text('已下载章节 1/3 (169.60KB)'),
                            space: 8,
                            iconPadding: EdgeInsets.symmetric(vertical: 3),
                          ),
                          IconText(
                            icon: Icon(Icons.download, size: 20, color: Colors.orange),
                            text: Text('下载于 2022-10-29 XX:XX:XX'),
                            space: 8,
                            iconPadding: EdgeInsets.symmetric(vertical: 3),
                          ),
                          // IconText(
                          //   icon: Icon(Icons.download, size: 20, color: Colors.orange),
                          //   text: Text('当前正在下载 未知章节'),
                          //   space: 8,
                          //   iconPadding: EdgeInsets.symmetric(vertical: 3),
                          // ),
                          ElevatedButton(
                            child: Text('查看漫画详情'),
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (c) => MangaPage(
                                  id: widget.mangaId,
                                  title: widget.mangaTitle,
                                  url: widget.mangaUrl,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(height: 12),
          // ****************************************************************
          // 下载章节列表
          // ****************************************************************
          Container(
            color: Colors.white,
            child: SizedBox(height: 100), // TODO
          ),
          Container(height: 12),
          // ****************************************************************
          // 漫画章节列表
          // ****************************************************************
          Container(
            color: Colors.white,
            // child: MangaTocView(
            //   groups: _data!.chapterGroups, // TODO
            //   mangaId: widget.mangaId,
            //   mangaTitle: widget.mangaTitle,
            //   mangaCover: widget.mangaCover,
            //   mangaUrl: widget.mangaUrl,
            //   full: false,
            //   highlightedChapters: [],
            // ),
            child: SizedBox(height: 300),
          ),
        ],
      ),
      floatingActionButton: ScrollAnimatedFab(
        scrollController: _controller,
        condition: ScrollAnimatedCondition.direction,
        fab: FloatingActionButton(
          child: Icon(Icons.vertical_align_top),
          heroTag: null,
          onPressed: () => _controller.scrollToTop(),
        ),
      ),
    );
  }
}

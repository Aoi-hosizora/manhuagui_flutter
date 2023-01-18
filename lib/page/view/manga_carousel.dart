import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/view/network_image.dart';

/// 漫画推荐展示，在 [RecommendSubPage] 使用
class MangaCarouselView extends StatefulWidget {
  const MangaCarouselView({
    Key? key,
    required this.mangas,
    required this.height,
    required this.imageWidth,
  }) : super(key: key);

  final List<TinyBlockManga> mangas;
  final double height;
  final double imageWidth;

  @override
  _MangaCarouselViewState createState() => _MangaCarouselViewState();
}

class _MangaCarouselViewState extends State<MangaCarouselView> with AutomaticKeepAliveClientMixin {
  var _currentIndex = 0;
  final _key = PageStorageKey(0);

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (widget.mangas.isEmpty) {
      return Container(
        color: Colors.white,
        width: MediaQuery.of(context).size.width,
        height: widget.height,
        child: PlaceholderText(
          state: PlaceholderState.nothing,
          childBuilder: (_) => SizedBox.shrink(),
          setting: PlaceholderSetting(
            showNothingRetry: false,
            iconSize: 42,
            textStyle: Theme.of(context).textTheme.subtitle1!.copyWith(color: Colors.grey[600]),
          ).copyWithChinese(
            nothingText: '漫画推荐列表为空',
          ),
        ),
      );
    }

    return Stack(
      children: [
        CarouselSlider.builder(
          options: CarouselOptions(
            pageViewKey: _key,
            height: widget.height,
            autoPlay: true,
            autoPlayInterval: Duration(seconds: 4),
            autoPlayCurve: Curves.fastOutSlowIn,
            onPageChanged: (i, _) {
              _currentIndex = i;
              if (mounted) setState(() {});
            },
            enableInfiniteScroll: true,
            viewportFraction: 1,
          ),
          itemCount: widget.mangas.length,
          itemBuilder: (c, i, _) => Container(
            color: Colors.white,
            child: Stack(
              children: [
                ClipRect(
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: widget.height,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: CachedNetworkImageProvider(
                          widget.mangas[i].cover,
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 16,
                        sigmaY: 16,
                      ),
                      child: Container(
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: NetworkImageView(
                      url: widget.mangas[i].cover, // 3:4
                      height: widget.height,
                      width: widget.imageWidth,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.of(context).push(
                        CustomPageRoute(
                          context: context,
                          builder: (c) => MangaPage(
                            id: widget.mangas[i].mid,
                            title: widget.mangas[i].title,
                            url: widget.mangas[i].url,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          child: Container(
            width: MediaQuery.of(context).size.width,
            padding: EdgeInsets.only(left: 8, right: 10, top: 5, bottom: 5),
            color: Colors.white.withOpacity(0.75),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      '《${widget.mangas[_currentIndex].title}》${widget.mangas[_currentIndex].newestChapter}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: widget.mangas.map(
                      (p) {
                        var chose = _currentIndex == widget.mangas.indexOf(p);
                        return Container(
                          width: chose ? 10 : 8,
                          height: chose ? 10 : 8,
                          margin: EdgeInsets.symmetric(horizontal: 2.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: chose ? Colors.black87 : Colors.black26,
                          ),
                        );
                      },
                    ).toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

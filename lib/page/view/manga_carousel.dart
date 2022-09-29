import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/view/network_image.dart';

class MangaCarouselView extends StatefulWidget {
  const MangaCarouselView({Key? key, required this.mangas})
      : assert(mangas != null && mangas.length != 0),
        super(key: key);

  final List<TinyBlockManga> mangas;

  @override
  _MangaCarouselViewState createState() => _MangaCarouselViewState();
}

class _MangaCarouselViewState extends State<MangaCarouselView> {
  CarouselController _carouselController;
  var _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _carouselController = CarouselController();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CarouselSlider.builder(
          carouselController: _carouselController,
          options: CarouselOptions(
            height: 220,
            autoPlay: true,
            autoPlayInterval: Duration(seconds: 4),
            autoPlayCurve: Curves.fastOutSlowIn,
            onPageChanged: (i, _) {
              _currentIndex = i;
              if (mounted) setState(() {});
            },
            enableInfiniteScroll: true,
            viewportFraction: 1, // 0.8,
          ),
          itemCount: widget.mangas.length,
          itemBuilder: (c, i) => Container(
            color: Colors.white, // Colors.accents[i],
            child: Stack(
              children: [
                ClipRect(
                  child: Container(
                    width: MediaQuery.of(context).size.width, // * 0.8,
                    height: 220,
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
                        sigmaX: 15,
                        sigmaY: 15,
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
                      url: widget.mangas[i].cover, // 3x4
                      height: 220,
                      width: 165,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        if (_currentIndex != i) {
                          _carouselController.animateToPage(i);
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (c) => MangaPage(
                                id: widget.mangas[i].mid,
                                title: widget.mangas[i].title,
                                url: widget.mangas[i].url,
                              ),
                            ),
                          );
                        }
                      },
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
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            color: Colors.white.withOpacity(0.7),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      '${widget.mangas[_currentIndex].title} - ${widget.mangas[_currentIndex].newestChapter}',
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
                          margin: EdgeInsets.symmetric(horizontal: 2),
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

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/view/network_image.dart';

/// 漫画分组
class MangaGroupPage extends StatefulWidget {
  const MangaGroupPage({
    Key key,
    @required this.group,
    @required this.title,
  })  : assert(group != null),
        assert(title != null),
        super(key: key);

  final MangaGroup group;
  final String title;

  @override
  _MangaGroupPageState createState() => _MangaGroupPageState();
}

class _MangaGroupPageState extends State<MangaGroupPage> {
  double _paddingWidth;
  double _width;
  double _height;

  Widget _buildMangaBlock(TinyManga manga) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              margin: EdgeInsets.symmetric(horizontal: _paddingWidth),
              height: _height,
              width: _width,
              // color: color,
              child: Stack(
                children: [
                  NetworkImageView(
                    url: manga.cover,
                    width: _width,
                    height: _height,
                  ),
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (c) => MangaPage(
                              id: manga.mid,
                              title: manga.title,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: _paddingWidth),
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                width: _width,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0, 1],
                    colors: [
                      Color.fromRGBO(0, 0, 0, 0),
                      Color.fromRGBO(0, 0, 0, 1),
                    ],
                  ),
                ),
                child: Text(
                  (manga.finished ? '共' : '更新至') + manga.newestChapter,
                  style: TextStyle(color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
        Container(
          width: _width,
          margin: EdgeInsets.symmetric(horizontal: _paddingWidth, vertical: 3),
          child: Text(
            manga.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    _paddingWidth = 5.0;
    _width = MediaQuery.of(context).size.width / 3 - _paddingWidth * 2;
    _height = _width / 3 * 4;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: 45,
        title: Text(widget.title),
      ),
      body: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.symmetric(vertical: 10),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMangaBlock(widget.group.mangas[0]),
                _buildMangaBlock(widget.group.mangas[1]),
                _buildMangaBlock(widget.group.mangas[2]),
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMangaBlock(widget.group.mangas[3]),
                _buildMangaBlock(widget.group.mangas[4]),
                _buildMangaBlock(widget.group.mangas[5]),
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMangaBlock(widget.group.mangas[6]),
                _buildMangaBlock(widget.group.mangas[7]),
                _buildMangaBlock(widget.group.mangas[8]),
              ],
            ),
            SizedBox(height: 10),
            if (widget.group.mangas.length == 10)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMangaBlock(widget.group.mangas[9]),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMangaBlock(widget.group.mangas[9]),
                  _buildMangaBlock(widget.group.mangas[10]),
                  _buildMangaBlock(widget.group.mangas[11]),
                ],
              )
          ],
        ),
      ),
    );
  }
}

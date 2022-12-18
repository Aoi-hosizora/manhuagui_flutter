import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/page/manga_group.dart';
import 'package:manhuagui_flutter/page/view/full_ripple.dart';
import 'package:manhuagui_flutter/page/view/homepage_column.dart';
import 'package:manhuagui_flutter/page/view/network_image.dart';

enum MangaGroupViewStyle {
  normalFull,
  smallTruncated,
}

/// 漫画分组，针对推荐列表（热门连载、经典完结、最新上架），在 [RecommendSubPage] / [MangaGroupPage] 使用
class MangaGroupView extends StatefulWidget {
  const MangaGroupView({
    Key? key,
    required this.groupList,
    required this.style,
    this.onMorePressed,
  }) : super(key: key);

  final MangaGroupList groupList;
  final MangaGroupViewStyle style;
  final void Function()? onMorePressed;

  @override
  State<MangaGroupView> createState() => _MangaGroupViewState();
}

class _MangaGroupViewState extends State<MangaGroupView> {
  late Map<String, MangaGroup> _groupMap = {
    '': widget.groupList.topGroup,
    for (var g in widget.groupList.groups1) g.title: g,
    for (var g in widget.groupList.groups2) g.title: g,
  };
  var _currentSelectedName = '';

  @override
  void didUpdateWidget(covariant MangaGroupView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupList != widget.groupList) {
      _groupMap = {
        '': widget.groupList.topGroup,
        for (var g in widget.groupList.groups1) g.title: g,
        for (var g in widget.groupList.groups2) g.title: g,
      };
      _currentSelectedName = '';
    }
  }

  Widget _buildItem({required BuildContext context, required TinyBlockManga manga, required double width, required double height}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FullRippleWidget(
          child: Stack(
            children: [
              Container(
                width: width,
                height: height,
                child: NetworkImageView(
                  url: manga.cover,
                  width: width,
                  height: height,
                  radius: BorderRadius.circular(4),
                  border: Border.all(width: 0.7, color: Colors.grey[400]!),
                ),
              ),
              Positioned(
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                  width: width,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0, 1],
                      colors: [
                        Colors.grey[900]!.withOpacity(0),
                        Colors.grey[900]!.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Text(
                      manga.finished ? '${manga.newestChapter} 全' : '更新至 ${manga.newestChapter}',
                      style: Theme.of(context).textTheme.bodyText2?.copyWith(fontSize: 12, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
          radius: BorderRadius.circular(4),
          highlightColor: null,
          splashColor: null,
          onTap: () => Navigator.of(context).push(
            CustomPageRoute(
              context: context,
              builder: (c) => MangaPage(
                id: manga.mid,
                title: manga.title,
                url: manga.url,
              ),
            ),
          ),
        ),
        Container(
          width: width,
          padding: EdgeInsets.only(top: 2),
          child: Text(
            manga.title,
            style: Theme.of(context).textTheme.bodyText2?.copyWith(fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const hSpace = 15.0;
    const vSpace = 10.0;
    var width = widget.style == MangaGroupViewStyle.normalFull
        ? (MediaQuery.of(context).size.width - hSpace * 4) / 3 // | ▢ ▢ ▢ |
        : (MediaQuery.of(context).size.width - hSpace * 5) / 4; // | ▢ ▢ ▢ ▢ |

    var group = _groupMap[_currentSelectedName] ?? _groupMap['']!;
    var mangas = group.mangas;
    switch (widget.style) {
      case MangaGroupViewStyle.normalFull:
        break;
      case MangaGroupViewStyle.smallTruncated:
        if (mangas.length > 8) {
          mangas = mangas.sublist(0, 8); // X X X X | X X X X
        }
        break;
    }

    return HomepageColumnView(
      title: widget.groupList.title + (_currentSelectedName.isEmpty ? '' : '・$_currentSelectedName'),
      icon: widget.groupList.isSerial ? Icons.whatshot : (widget.groupList.isFinish ? Icons.check_circle_outline : Icons.fiber_new),
      hPadding: 15,
      vPadding: 10,
      onMorePressed: widget.onMorePressed,
      child: Column(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 5), // 15 (hPadding) <= 10 + 5
            physics: AlwaysScrollableScrollPhysics(),
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var name in _groupMap.keys)
                  Material(
                    color: name == _currentSelectedName ? Colors.white : Colors.transparent,
                    child: InkWell(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        child: Text(
                          name.isEmpty ? '置顶漫画' : name,
                          style: Theme.of(context).textTheme.bodyText2?.copyWith(
                                fontSize: 14,
                                color: name == _currentSelectedName ? Theme.of(context).primaryColor : null,
                              ),
                        ),
                      ),
                      onTap: () {
                        _currentSelectedName = name;
                        if (mounted) setState(() {});
                      },
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hSpace),
            child: Wrap(
              spacing: hSpace,
              runSpacing: vSpace,
              children: [
                for (var manga in mangas)
                  _buildItem(
                    context: context,
                    manga: manga,
                    width: width,
                    height: width / 3 * 4,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

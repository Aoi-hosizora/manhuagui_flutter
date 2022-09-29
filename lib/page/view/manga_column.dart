import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/model/manga.dart';
import 'package:manhuagui_flutter/page/manga_group.dart';
import 'package:manhuagui_flutter/page/view/tiny_block_manga.dart';

/// View for [MangaGroup].
/// Used in [RecommendSubPage] and [MangaGroupPage].
class MangaColumnView extends StatefulWidget {
  const MangaColumnView({
    Key? key,
    required this.group,
    required this.type,
    this.controller,
    this.marginV = 12,
    this.showTopMargin = true,
    this.complete = false,
    this.small = false,
    this.singleLine = false,
  })  : assert(group != null),
        assert(type != null),
        assert(showTopMargin != null),
        assert(showTopMargin != null),
        assert(complete != null),
        assert(small != null),
        assert(singleLine != null),
        assert(!(complete && (small || singleLine))),
        super(key: key);

  final MangaGroup group;
  final MangaGroupType type;
  final ScrollController controller;
  final double marginV;
  final bool showTopMargin;
  final bool complete;
  final bool small;
  final bool singleLine;

  @override
  _MangaColumnViewState createState() => _MangaColumnViewState();
}

class _MangaColumnViewState extends State<MangaColumnView> {
  Widget _buildBlock(TinyBlockManga manga, {bool left = false}) {
    final hSpace = 5.0;
    var width = (MediaQuery.of(context).size.width - hSpace * 4) / 3; // | ▢ ▢ ▢ |
    if (widget.small) {
      width = (MediaQuery.of(context).size.width - hSpace * 5) / 4; // | ▢ ▢ ▢ ▢ |
    }
    var height = width / 3 * 4;

    return TinyBlockMangaView(
      manga: manga,
      width: width,
      height: height,
      margin: EdgeInsets.only(left: left ? hSpace : 0, right: hSpace),
      onMorePressed: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (c) => MangaGroupPage(
            group: widget.group,
            type: widget.type,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRows(double vSpace) {
    var mangas = widget.group.mangas;
    var cs = 3;
    if (!widget.complete) {
      if (!widget.small) {
        if (!widget.singleLine) {
          if (mangas.length > 6) {
            mangas = [...mangas.sublist(0, 5), null]; // X X X | X X O
          }
        } else {
          if (mangas.length > 3) {
            mangas = [...mangas.sublist(0, 2), null]; // X X O
          }
        }
      } else {
        cs = 4;
        if (!widget.singleLine) {
          if (mangas.length > 8) {
            mangas = [...mangas.sublist(0, 7), null]; // X X X X | X X X O
          }
        } else {
          if (mangas.length > 4) {
            mangas = [...mangas.sublist(0, 3), null]; // X X X O
          }
        }
      }
    }

    var gridRows = <Widget>[];
    var rows = (mangas.length.toDouble() / cs).ceil();
    for (var r = 0; r < rows; r++) {
      var columns = <TinyBlockManga>[
        for (var i = cs * r; i < cs * (r + 1) && i < mangas.length; i++) mangas[i],
      ];
      gridRows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < columns.length; i++) _buildBlock(columns[i], left: i == 0),
          ],
        ),
      );
      if (r != rows - 1) {
        gridRows.add(
          SizedBox(height: vSpace),
        );
      }
    }

    return gridRows;
  }

  @override
  Widget build(BuildContext context) {
    var title = widget.group.title.isEmpty ? widget.type.toTitle() : (widget.type.toTitle() + '・' + widget.group.title);
    var icon = widget.type == MangaGroupType.serial
        ? Icons.whatshot
        : widget.type == MangaGroupType.finish
            ? Icons.check_circle_outline
            : Icons.fiber_new;

    var vSpace = 6.0;
    var titleLine = Padding(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: IconText(
        icon: Icon(icon, size: 20, color: Colors.orange),
        text: Text(title, style: Theme.of(context).textTheme.subtitle1),
        space: 6,
      ),
    );
    var rows = _buildRows(vSpace);

    return Container(
      color: Colors.white,
      margin: EdgeInsets.only(top: widget.showTopMargin ? widget.marginV : 0),
      padding: EdgeInsets.only(bottom: vSpace),
      child: !widget.complete
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [titleLine, ...rows],
            )
          : ListView(
              controller: widget.controller,
              children: [titleLine, ...rows],
            ),
    );
  }
}

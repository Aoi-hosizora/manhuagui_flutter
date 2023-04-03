import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/service/native/clipboard.dart';

class DetailRow {
  const DetailRow(
    this.key,
    this.value, {
    this.textForCopy,
    this.canCopy = true,
  });

  final String key;
  final String value;
  final String? textForCopy;
  final bool canCopy;
}

/// 详细信息表格，在 [MangaDetailPage] / [AuthorDetailPage] / [ChapterDetailsPage] 使用
class DetailTableView extends StatefulWidget {
  const DetailTableView({
    Key? key,
    required this.rows,
    required this.tableWidth,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    this.fractionColumnWidth = 0.3,
  }) : super(key: key);

  final List<DetailRow> rows;
  final double tableWidth;
  final EdgeInsets padding;
  final double fractionColumnWidth;

  @override
  State<DetailTableView> createState() => _DetailTableViewState();
}

class _DetailTableViewState extends State<DetailTableView> {
  late var _helper = TableCellHelper(widget.rows.length, 2);

  @override
  void didUpdateWidget(covariant DetailTableView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rows.length != widget.rows.length) {
      _helper = TableCellHelper(widget.rows.length, 2);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_helper.hasSearched()) {
      WidgetsBinding.instance?.addPostFrameCallback((_) {
        if (_helper.searchForHighestCells()) {
          if (mounted) setState(() {});
        }
      });
    }

    final firstLineStyle = Theme.of(context).textTheme.bodyText2?.copyWith(color: Colors.grey);
    final textStyle = Theme.of(context).textTheme.bodyText2;

    return Table(
      columnWidths: {
        0: FractionColumnWidth(widget.fractionColumnWidth),
      },
      border: TableBorder(
        horizontalInside: BorderSide(width: 1, color: Colors.grey),
      ),
      children: [
        TableRow(
          children: [
            Padding(padding: widget.padding, child: Text('键', style: firstLineStyle)),
            Padding(padding: widget.padding, child: Text('值', style: firstLineStyle)),
          ],
        ),
        for (var i = 0; i < widget.rows.length; i++)
          TableRow(
            children: [
              TableCell(
                key: _helper.getCellKey(i, 0),
                verticalAlignment: _helper.determineCellAlignment(i, 0, TableCellVerticalAlignment.top),
                child: TableWholeRowInkWell.preferred(
                  child: Text('${widget.rows[i].key}　', style: textStyle),
                  padding: widget.padding,
                  onTap: () {
                    if (widget.rows[i].canCopy) {
                      copyText(widget.rows[i].textForCopy ?? widget.rows[i].value, showToast: true);
                    }
                  },
                  tableWidth: widget.tableWidth,
                  accumulativeWidthRatio: 0,
                ),
              ),
              TableCell(
                key: _helper.getCellKey(i, 1),
                verticalAlignment: _helper.determineCellAlignment(i, 1, TableCellVerticalAlignment.top),
                child: TableWholeRowInkWell.preferred(
                  child: Text('${widget.rows[i].value}　', style: textStyle),
                  padding: widget.padding,
                  onTap: () {
                    if (widget.rows[i].canCopy) {
                      copyText(widget.rows[i].textForCopy ?? widget.rows[i].value, showToast: true);
                    }
                  },
                  tableWidth: widget.tableWidth,
                  accumulativeWidthRatio: widget.fractionColumnWidth,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

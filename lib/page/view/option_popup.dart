import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';

/// 可弹出选项的按钮，在 [CategoryPopupView] / [MangaCategorySubPage] / [AuthorCategorySubPage] / [AuthorPage] / [SearchPage] 使用
class OptionPopupView<T extends Object> extends StatefulWidget {
  const OptionPopupView({
    Key? key,
    required this.items,
    required this.value,
    required this.titleBuilder,
    required this.onSelected,
    this.ifNeedHighlight,
    this.height = 26.0,
    this.width,
    this.enable = true,
    this.onLongPressed,
    this.onOptionLongPressed,
  }) : super(key: key);

  final List<T> items;
  final T value;
  final String Function(BuildContext, T) titleBuilder;
  final void Function(T) onSelected;
  final bool Function(T)? ifNeedHighlight;
  final double height;
  final double? width;
  final bool enable;
  final void Function()? onLongPressed;
  final void Function(T, void Function(T) selectAndPop, StateSetter setState)? onOptionLongPressed;

  @override
  _OptionPopupRouteViewState<T> createState() => _OptionPopupRouteViewState<T>();
}

class _OptionPopupRouteViewState<T extends Object> extends State<OptionPopupView<T>> {
  var _selected = false;

  void _onTap() async {
    _selected = true;
    if (mounted) setState(() {});

    final renderBox = context.findRenderObject()! as RenderBox;
    final itemRect = renderBox.localToGlobal(Offset.zero) & renderBox.size;

    var result = await showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.transparent,
      pageBuilder: (c, _, __) => StatefulBuilder(
        builder: (_, _setState) => Stack(
          children: [
            Positioned(
              top: itemRect.bottom + 5 + 10 /* keep the same as ListHint vertical padding + some spaces */,
              bottom: 0,
              left: 0,
              right: 0,
              child: GestureDetector(
                child: Container(
                  color: const Color(0x80000000),
                ),
                onTap: () => Navigator.of(context).pop(null),
              ),
            ),
            Positioned(
              top: itemRect.bottom + 5 /* keep the same as ListHint vertical padding */,
              left: 0,
              right: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 5,
                      spreadRadius: 0,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: _OptionPopupRouteView<T>(
                  value: widget.value,
                  items: widget.items,
                  titleBuilder: widget.titleBuilder,
                  ifNeedHighlight: widget.ifNeedHighlight,
                  onLongPressed: widget.onOptionLongPressed == null //
                      ? null
                      : (value) => widget.onOptionLongPressed?.call(value, (value) => Navigator.of(c).pop(value), _setState),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    _selected = false;
    if (mounted) setState(() {});
    if (result != null) {
      widget.onSelected(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.enable ? _onTap : null,
        onLongPress: widget.enable ? widget.onLongPressed : null,
        child: Container(
          height: widget.height, // 26 (keep the same as ListHint height)
          width: widget.width,
          child: IconText(
            alignment: IconTextAlignment.r2l,
            mainAxisAlignment: MainAxisAlignment.center,
            space: 0,
            textPadding: EdgeInsets.only(left: 10),
            icon: Icon(
              Icons.arrow_drop_down,
              color: !widget.enable ? Colors.grey[300] : (_selected ? Colors.deepOrange : Colors.grey[700]),
            ),
            text: Text(
              widget.titleBuilder(context, widget.value),
              style: TextStyle(
                color: !widget.enable ? Colors.grey : (_selected ? Colors.deepOrange : Colors.black),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionPopupRouteView<T extends Object> extends StatelessWidget {
  const _OptionPopupRouteView({
    Key? key,
    required this.items,
    required this.value,
    required this.titleBuilder,
    this.ifNeedHighlight,
    this.onLongPressed,
  }) : super(key: key);

  final List<T> items;
  final T value;
  final String Function(BuildContext, T) titleBuilder;
  final bool Function(T)? ifNeedHighlight;
  final void Function(T)? onLongPressed;

  Widget _buildItem({required BuildContext context, required T value, required double width, required double height}) {
    final selected = this.value == value;
    return SizedBox(
      width: width,
      height: height,
      child: OutlinedButton(
        child: Text(
          titleBuilder.call(context, value),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: selected //
                ? (ifNeedHighlight?.call(value) == true ? Colors.yellow : Colors.white)
                : (ifNeedHighlight?.call(value) == true ? Colors.deepOrange : Colors.black),
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          backgroundColor: selected ? Theme.of(context).primaryColor : Colors.white,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: () => Navigator.of(context).pop(value),
        onLongPress: onLongPressed == null ? null : () => onLongPressed?.call(value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const hSpace = 8.0;
    const vSpace = 8.0;
    const padding = EdgeInsets.symmetric(horizontal: 15, vertical: 10);
    final width = (MediaQuery.of(context).size.width - 2 * padding.left - 3 * hSpace) / 4; // |   ▢ ▢ ▢ ▢   |

    return Padding(
      padding: padding,
      child: Wrap(
        spacing: hSpace,
        runSpacing: vSpace,
        children: [
          for (var item in items)
            _buildItem(
              context: context,
              value: item,
              width: width,
              height: 36,
            ),
        ],
      ),
    );
  }
}

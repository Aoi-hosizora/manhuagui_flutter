import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';

class OptionPopupView<T extends Object> extends StatefulWidget {
  const OptionPopupView({
    Key? key,
    required this.items,
    required this.value,
    required this.titleBuilder,
    required this.onSelect,
    this.height = 26.0, // <<<
    this.width,
    this.enable = true,
  }) : super(key: key);

  final List<T> items;
  final T value;
  final String Function(BuildContext, T) titleBuilder;
  final void Function(T) onSelect;
  final double height;
  final double? width;
  final bool enable;

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
      pageBuilder: (c, _, __) => Stack(
        children: [
          Positioned(
            top: itemRect.bottom,
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
            top: itemRect.bottom,
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
              ),
            ),
          ),
        ],
      ),
    );

    _selected = false;
    if (mounted) setState(() {});
    if (result != null) {
      widget.onSelect(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.enable ? _onTap : null,
        child: Container(
          height: widget.height, // 26
          width: widget.width,
          child: IconText(
            alignment: IconTextAlignment.r2l,
            mainAxisAlignment: MainAxisAlignment.center,
            space: 0,
            textPadding: EdgeInsets.only(left: 10),
            icon: Icon(
              Icons.arrow_drop_down,
              color: !widget.enable ? Colors.grey[300] : Colors.grey[700],
            ),
            text: Text(
              widget.titleBuilder(context, widget.value),
              style: TextStyle(
                color: !widget.enable ? Colors.grey : (_selected ? Colors.orange : Colors.black),
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
  }) : super(key: key);

  final List<T> items;
  final T value;
  final String Function(BuildContext, T) titleBuilder;

  Widget _buildItem({required BuildContext context, required T value, required double width, required double height}) {
    final selected = this.value == value;
    return Container(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          color: selected ? Theme.of(context).primaryColor : Colors.white,
        ),
        child: OutlinedButton(
          child: Text(
            titleBuilder.call(context, value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(value),
          style: OutlinedButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const hSpace = 6.0;
    const vSpace = 9.0;
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

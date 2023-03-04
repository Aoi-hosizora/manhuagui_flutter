import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';

/// 一些通用简单的控件，包括 [HelpIconView] / [CheckBoxDialogOption] / [CustomComboboxItem] / [WarningTextView] / [IconTextMenuItem] / [OverflowClipBox]

class HelpIconView extends StatelessWidget {
  const HelpIconView({
    Key? key,
    required this.title,
    required this.hint,
    this.tooltip,
    required this.rectangle,
    required this.padding,
    this.margin,
    this.enable = true,
    this.iconData,
    required this.iconSize,
    this.iconColor,
    this.onPressed,
  }) : super(key: key);

  const HelpIconView.forSettingDlg({
    Key? key,
    required this.title,
    required this.hint,
    this.tooltip,
    this.rectangle = false,
    this.padding = const EdgeInsets.all(5),
    this.margin,
    this.enable = true,
    this.iconData,
    this.iconSize = 20,
    this.iconColor,
    this.onPressed,
  }) : super(key: key);

  const HelpIconView.forListHint({
    Key? key,
    required this.title,
    required this.hint,
    this.tooltip,
    this.rectangle = true,
    this.padding = const EdgeInsets.all(3),
    this.margin,
    this.enable = true,
    this.iconData,
    this.iconSize = 20,
    this.iconColor,
    this.onPressed,
  }) : super(key: key);

  const HelpIconView.asButton({
    Key? key,
    this.tooltip,
    this.rectangle = true,
    this.padding = const EdgeInsets.all(3),
    this.margin,
    this.enable = true,
    required this.iconData,
    this.iconSize = 20,
    this.iconColor,
    required this.onPressed,
  })  : title = '',
        hint = '',
        super(key: key);

  final String title;
  final String hint;
  final String? tooltip;
  final bool rectangle;
  final EdgeInsets padding;
  final EdgeInsets? margin;
  final bool enable;
  final IconData? iconData;
  final double iconSize;
  final Color? iconColor;
  final VoidCallback? onPressed; // ignore title and hint

  @override
  Widget build(BuildContext context) {
    var view = InkResponse(
      child: Padding(
        padding: padding,
        child: Icon(
          iconData ?? Icons.help_outline,
          size: iconSize,
          color: iconColor ?? (enable ? Colors.grey[800] : Colors.grey[400]),
        ),
      ),
      highlightShape: rectangle ? BoxShape.rectangle : BoxShape.circle,
      containedInkWell: rectangle,
      radius: (iconSize + padding.horizontal) / 2 * (rectangle ? calcSqrt(2) : 1),
      onTap: !enable
          ? null
          : onPressed ??
              () => showDialog(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: Text(title),
                      content: Text(hint),
                      actions: [
                        TextButton(
                          child: Text('确定'),
                          onPressed: () => Navigator.of(c).pop(),
                        ),
                      ],
                    ),
                  ),
    );
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: tooltip == null
            ? view
            : Tooltip(
                message: tooltip!,
                child: view,
              ),
      ),
    );
  }
}

class CheckBoxDialogOption extends StatefulWidget {
  const CheckBoxDialogOption({
    Key? key,
    required this.initialValue,
    required this.onChanged,
    required this.text,
  }) : super(key: key);

  final bool initialValue;
  final void Function(bool) onChanged;
  final String text;

  @override
  State<CheckBoxDialogOption> createState() => _CheckBoxDialogOptionState();
}

class _CheckBoxDialogOptionState extends State<CheckBoxDialogOption> {
  late bool _value = widget.initialValue;

  @override
  Widget build(BuildContext context) {
    return IconTextDialogOption(
      icon: AbsorbPointer(
        absorbing: true,
        child: Checkbox(
          value: _value,
          onChanged: (_) {},
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity(horizontal: -4, vertical: -4),
        ),
      ),
      text: Text(widget.text),
      onPressed: () {
        _value = !_value;
        if (mounted) setState(() {});
        widget.onChanged.call(_value);
      },
    );
  }
}

class CustomComboboxItem<T> {
  const CustomComboboxItem({
    required this.value,
    required this.text,
  });

  final T? value;
  final String text;
}

class CustomCombobox<T> extends StatelessWidget {
  const CustomCombobox({
    Key? key,
    required this.value,
    required this.onChanged,
    required this.items,
    this.textStyle,
  }) : super(key: key);

  final T? value;
  final ValueChanged<T?>? onChanged;
  final List<CustomComboboxItem<T>> items;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    DropdownMenuItem<T> _buildItem(CustomComboboxItem<T> item, {Color? textColor}) {
      return DropdownMenuItem<T>(
        value: item.value,
        child: Padding(
          padding: EdgeInsets.only(left: 2),
          child: Text(
            item.text,
            style: (textStyle ?? Theme.of(context).textTheme.bodyText2)?.copyWith(color: textColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    return ExtendedDropdownButton<T>(
      value: value,
      selectedItemBuilder: (c) => [
        for (var item in items) _buildItem(item),
      ],
      items: [
        for (var item in items) _buildItem(item, textColor: value == item.value ? Colors.deepOrange : null),
      ],
      isExpanded: true,
      onChanged: onChanged,
      underlinePosition: PositionArgument.fromLTRB(0, null, 0, 6),
      underline: Container(
        height: 0.8,
        margin: EdgeInsets.only(right: 3),
        color: Theme.of(context).primaryColor,
      ),
      adjustRectToAvoidBottomInset: true /* !!! deal with popup menu layout when dismissing keyboard */,
      bottomViewInsetGetter: null /* <<< use default behavior */,
      adjustButtonRect: null /* <<< use default behavior */,
    );
  }
}

class WarningTextView extends StatelessWidget {
  const WarningTextView({
    Key? key,
    required this.text,
    required this.isWarning,
  }) : super(key: key);

  final String text;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 12),
      decoration: BoxDecoration(color: Colors.yellow),
      alignment: Alignment.center,
      child: TextGroup.normal(
        texts: [
          PlainTextItem(text: '【'),
          PlainTextItem(
            text: isWarning ? '注意' : '提示',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SpanItem(
            span: WidgetSpan(
              child: Icon(
                Icons.warning_amber,
                color: Colors.grey[800],
                size: 22,
              ),
            ),
          ),
          PlainTextItem(text: '】$text'),
        ],
      ),
    );
  }
}

class IconTextMenuItem extends StatelessWidget {
  const IconTextMenuItem(
    this.icon,
    this.text, {
    Key? key,
    this.space = 12.0,
    this.color,
  }) : super(key: key);

  final IconData icon;
  final String text;
  final double? space;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconText(
      icon: Icon(icon, color: color ?? kIconTextDialogOptionIconColor),
      text: Text(text, style: Theme.of(context).textTheme.subtitle1?.copyWith(color: color ?? Colors.black)),
      space: space ?? 12.0,
      mainAxisSize: MainAxisSize.min,
    );
  }
}

enum OverflowDirection {
  horizontal,
  vertical,
}

class OverflowClipBox extends StatelessWidget {
  const OverflowClipBox({
    Key? key,
    required this.direction,
    required this.child,
    this.useOverflowBox = true,
    this.alignment = Alignment.topCenter,
    this.useClipRect = true,
    this.clipBehavior = Clip.hardEdge,
    this.width,
    this.height,
    this.margin = EdgeInsets.zero,
    this.padding = EdgeInsets.zero,
  }) : super(key: key);

  final OverflowDirection direction;
  final Widget child;
  final bool useOverflowBox;
  final Alignment alignment;
  final bool useClipRect;
  final Clip clipBehavior;
  final double? width;
  final double? height;
  final EdgeInsets margin;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    // https://github.com/Limbou/expandable_page_view/blob/main/lib/src/expandable_page_view.dart
    // https://github.com/Limbou/expandable_page_view/blob/main/lib/src/size_reporting_widget.dart
    Widget view = Padding(
      padding: padding,
      child: child,
    );
    if (useOverflowBox) {
      view = OverflowBox(
        child: view,
        alignment: alignment,
        minHeight: direction == OverflowDirection.vertical ? 0 : null,
        maxHeight: direction == OverflowDirection.vertical ? double.infinity : null,
        minWidth: direction == OverflowDirection.horizontal ? 0 : null,
        maxWidth: direction == OverflowDirection.horizontal ? double.infinity : null,
      );
    }
    if (useClipRect) {
      view = ClipRect(
        child: view,
        clipBehavior: clipBehavior,
      );
    }
    return view = Padding(
      padding: margin,
      child: SizedBox(
        width: width,
        height: height,
        child: view,
      ),
    );
  }
}

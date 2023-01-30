import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';

/// 一些通用简单的控件，包括 [HelpIconView] / [CheckBoxDialogOption] / [CustomComboboxItem] / [WarningTextView]

class HelpIconView extends StatelessWidget {
  const HelpIconView({
    Key? key,
    required this.title,
    required this.hint,
    required this.rectangle,
    required this.padding,
    this.iconData,
    required this.iconSize,
    this.iconColor,
    this.onPressed,
  }) : super(key: key);

  const HelpIconView.forSettingDlg({
    Key? key,
    required this.title,
    required this.hint,
    this.rectangle = false,
    this.padding = const EdgeInsets.all(5),
    this.iconData,
    this.iconSize = 20,
    this.iconColor,
    this.onPressed,
  }) : super(key: key);

  const HelpIconView.forListHint({
    Key? key,
    required this.title,
    required this.hint,
    this.rectangle = true,
    this.padding = const EdgeInsets.all(3),
    this.iconData,
    this.iconSize = 20,
    this.iconColor,
    this.onPressed,
  }) : super(key: key);

  final String title;
  final String hint;
  final bool rectangle;
  final EdgeInsets padding;
  final IconData? iconData;
  final double iconSize;
  final Color? iconColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkResponse(
        child: Padding(
          padding: padding,
          child: Icon(
            iconData ?? Icons.help_outline,
            size: iconSize,
            color: iconColor ?? Colors.grey[800],
          ),
        ),
        highlightShape: rectangle ? BoxShape.rectangle : BoxShape.circle,
        containedInkWell: rectangle,
        radius: (iconSize + padding.horizontal) / 2 * (rectangle ? calcSqrt(2) : 1),
        onTap: onPressed ??
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
    return Stack(
      children: [
        DropdownButton<T>(
          value: value,
          selectedItemBuilder: (c) => [
            for (var i in items)
              DropdownMenuItem<T>(
                value: i.value,
                child: Padding(
                  padding: EdgeInsets.only(left: 2),
                  child: Text(i.text, style: textStyle ?? Theme.of(context).textTheme.bodyText2),
                ),
              )
          ],
          items: [
            for (var i in items)
              DropdownMenuItem<T>(
                value: i.value,
                child: Padding(
                  padding: EdgeInsets.only(left: 2),
                  child: Text(
                    i.text,
                    style: (textStyle ?? Theme.of(context).textTheme.bodyText2)?.copyWith(
                      color: value == i.value ? Theme.of(context).primaryColor : null,
                    ),
                  ),
                ),
              )
          ],
          isExpanded: true,
          underline: Container(),
          onChanged: onChanged,
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 6,
          child: Container(
            height: 0.8,
            margin: EdgeInsets.only(right: 3),
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
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

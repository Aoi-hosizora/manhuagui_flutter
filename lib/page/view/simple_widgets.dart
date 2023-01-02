import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';

/// 一些简单的控件，包括 [HelpIconView] / [CheckBoxDialogOption] / [CustomComboboxItem]

class HelpIconView extends StatelessWidget {
  const HelpIconView({
    Key? key,
    required this.title,
    required this.hint,
    this.useRectangle = false,
    this.padding = const EdgeInsets.all(5),
    this.iconSize = 20,
    this.iconColor,
  }) : super(key: key);

  final String title;
  final String hint;
  final bool useRectangle;
  final EdgeInsets padding;
  final double iconSize;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkResponse(
        child: Padding(
          padding: padding,
          child: Icon(
            Icons.help_outline,
            size: iconSize,
            color: iconColor ?? Colors.grey[800],
          ),
        ),
        highlightShape: useRectangle ? BoxShape.rectangle : BoxShape.circle,
        containedInkWell: useRectangle,
        radius: (iconSize + padding.horizontal) / 2 * (useRectangle ? calcSqrt(2) : 1),
        onTap: () => showDialog(
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

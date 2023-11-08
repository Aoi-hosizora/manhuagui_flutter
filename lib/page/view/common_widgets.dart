import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';

/// 一些通用简单的控件，包括 [HelpIconView] / [CheckBoxDialogOption] / [SubtitleDialogOption] / [CustomComboboxItem] / [WarningTextView] / [IconTextMenuItem]

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

class SubtitleDialogOption extends StatelessWidget {
  const SubtitleDialogOption({
    Key? key,
    required this.text,
  }) : super(key: key);

  final Widget text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: kAlertDialogDefaultContentPadding.copyWith(bottom: 8, top: 2),
      child: DefaultTextStyle(
        child: text,
        style: Theme.of(context).textTheme.subtitle1!,
      ),
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
    this.enable = true,
    this.textStyle,
  }) : super(key: key);

  final T? value;
  final ValueChanged<T?>? onChanged;
  final List<CustomComboboxItem<T>> items;
  final bool enable;
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
        for (var item in items) _buildItem(item, textColor: enable ? null : Colors.grey),
      ],
      items: [
        for (var item in items) _buildItem(item, textColor: value == item.value ? Colors.deepOrange : null),
      ],
      isExpanded: true,
      onChanged: enable ? onChanged : null,
      underlinePosition: PositionArgument.fromLTRB(0, null, 0, 6),
      underline: Container(
        height: 0.8,
        margin: EdgeInsets.only(right: 3),
        color: enable ? Theme.of(context).primaryColor : Colors.grey,
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
      alignment: Alignment.topLeft,
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

Future<bool> checkWillPopFromChildren(BuildContext context, {WillPopCallback? currentOnWillPop}) async {
  var scopes = context.findDescendantElementsDFS<WillPopScope>(
    -1,
    (element) {
      if (element.widget is! WillPopScope) {
        return null;
      }

      var renderBox = element.findRenderBox();
      if (renderBox != null) {
        var rect = renderBox.localToGlobal(Offset.zero) & renderBox.size;
        if (!rect.isFinite || rect.isEmpty) {
          // only pick visible WillPopScope widget
          return null;
        }
      }

      return element.widget as WillPopScope;
    },
    reverse: true,
  );

  if (scopes.isNotEmpty) {
    scopes.removeLast(); // remove the last WillPopScope, which is the current page
  }

  for (var s in scopes) {
    if (s.onWillPop == null || s.onWillPop == currentOnWillPop) {
      continue; // check equality to prevent recursive
    }

    // test onWillPop of descendants
    var willPop = await s.onWillPop?.call();
    if (willPop == false) {
      return false;
    }
  }

  return true; // current page can be popped
}

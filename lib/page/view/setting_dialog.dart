import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';

abstract class _SettingView extends StatelessWidget {
  const _SettingView({
    Key? key,
    required this.title,
    this.hint,
    this.width,
    this.height = 38,
  }) : super(key: key);

  final String title;
  final String? hint;
  final double? width;
  final double height;

  Widget get rightWidget;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodyText1,
            ),
            if (hint != null) ...[
              SizedBox(width: 2),
              HelpIconView(
                title: title,
                hint: hint!,
              ),
            ],
          ],
        ),
        SizedBox(
          height: height,
          width: width,
          child: rightWidget,
        ),
      ],
    );
  }
}

class SettingComboBoxView<T extends Object> extends _SettingView {
  const SettingComboBoxView({
    Key? key,
    required String title,
    String? hint,
    double width = 120,
    double height = 38,
    this.enable = true,
    required this.value,
    required this.values,
    required this.builder,
    required this.onChanged,
  }) : super(
          key: key,
          title: title,
          hint: hint,
          width: width,
          height: height,
        );

  final bool enable;
  final T value;
  final List<T> values;
  final Widget Function(T) builder;
  final void Function(T) onChanged;

  @override
  Widget get rightWidget => DropdownButton<T>(
        value: value,
        items: values.map((s) => DropdownMenuItem<T>(child: builder(s), value: s)).toList(),
        underline: Container(color: Colors.white),
        isExpanded: true,
        onChanged: enable ? (v) => v?.let((it) => onChanged.call(it)) : null,
      );
}

class SettingSwitcherView extends _SettingView {
  const SettingSwitcherView({
    Key? key,
    required String title,
    String? hint,
    double? width,
    double height = 38,
    this.enable = true,
    required this.value,
    required this.onChanged,
  }) : super(
          key: key,
          title: title,
          hint: hint,
          width: width,
          height: height,
        );

  final bool enable;
  final bool value;
  final void Function(bool) onChanged;

  @override
  Widget get rightWidget => Switch(
        value: value,
        onChanged: enable ? onChanged : null,
      );
}

class SettingButtonView extends _SettingView {
  const SettingButtonView({
    Key? key,
    required String title,
    String? hint,
    double? width,
    double height = 38,
    this.enable = true,
    this.buttonPadding = const EdgeInsets.fromLTRB(0, 3, 9, 3),
    required this.buttonChild,
    required this.onPressed,
  }) : super(
          key: key,
          title: title,
          hint: hint,
          width: width,
          height: height,
        );

  final bool enable;
  final EdgeInsets buttonPadding;
  final Widget buttonChild;
  final void Function() onPressed;

  @override
  Widget get rightWidget => Padding(
        padding: buttonPadding,
        child: ElevatedButton(
          child: buttonChild,
          onPressed: enable ? onPressed : null,
        ),
      );
}

mixin SettingSubPageStateMixin<T extends Object, U extends StatefulWidget> on State<U> {
  T get newestSetting;

  List<Widget> get settingLines;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width - //
          (MediaQuery.of(context).padding + kDialogDefaultInsetPadding + kAlertDialogDefaultContentPadding).horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: settingLines,
      ),
    );
  }
}

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
        radius: (iconSize + padding.horizontal) / 2,
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

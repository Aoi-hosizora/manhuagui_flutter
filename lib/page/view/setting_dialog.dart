import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';

/// 与设置相关的 [SettingDialogView] 和各种 [_SettingView]，在 [ViewSettingSubPage] / [DlSettingSubPage] / [OtherSettingSubPage] 使用
class SettingDialogView extends StatelessWidget {
  const SettingDialogView({
    Key? key,
    required this.children,
  }) : super(key: key);

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width - //
          (MediaQuery.of(context).padding + kDialogDefaultInsetPadding + kAlertDialogDefaultContentPadding).horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

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

  Widget buildRightWidget(BuildContext context);

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
          child: buildRightWidget(context),
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
    required this.textBuilder,
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
  final String Function(T) textBuilder;
  final void Function(T) onChanged;

  @override
  Widget buildRightWidget(BuildContext context) => Stack(
        children: [
          DropdownButton<T>(
            value: value,
            selectedItemBuilder: (c) => [
              for (var v in values)
                DropdownMenuItem<T>(
                  value: v,
                  child: Padding(
                    padding: EdgeInsets.only(left: 2),
                    child: Text(textBuilder(v), style: Theme.of(context).textTheme.bodyText2),
                  ),
                )
            ],
            items: [
              for (var v in values)
                DropdownMenuItem<T>(
                  value: v,
                  child: Padding(
                    padding: EdgeInsets.only(left: 2),
                    child: Text(
                      textBuilder(v),
                      style: Theme.of(context).textTheme.bodyText2!.copyWith(
                            color: value == v ? Theme.of(context).primaryColor : null,
                          ),
                    ),
                  ),
                )
            ],
            isExpanded: true,
            underline: Container(),
            onChanged: enable ? (v) => v?.let((it) => onChanged.call(it)) : null,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 6,
            child: Container(
              height: 0.8,
              margin: EdgeInsets.only(right: 5),
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
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
  Widget buildRightWidget(BuildContext context) => Switch(
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
    this.buttonPadding = const EdgeInsets.fromLTRB(0, 4, 9, 4),
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
  Widget buildRightWidget(BuildContext context) => Padding(
        padding: buttonPadding,
        child: ElevatedButton(
          child: buttonChild,
          onPressed: enable ? onPressed : null,
        ),
      );
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

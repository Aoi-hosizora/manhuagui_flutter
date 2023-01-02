import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/page/view/simple_widgets.dart';

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
  Widget buildRightWidget(BuildContext context) => CustomCombobox<T>(
        value: value,
        items: [
          for (var v in values)
            CustomComboboxItem(
              value: v,
              text: textBuilder(v),
            ),
        ],
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

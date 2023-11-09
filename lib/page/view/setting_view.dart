import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/page/view/common_widgets.dart';

/// 与设置相关的 [SettingColumnView]，以及各种 [_SettingView]
/// 在 [ViewSettingSubPage] / [DlSettingSubPage] / [UiSettingSubPage] / [OtherSettingSubPage] / [ExportDataSubPage] 使用

class SettingColumnView extends StatelessWidget {
  const SettingColumnView({
    Key? key,
    required this.children,
  }) : super(key: key);

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}

enum SettingViewStyle {
  line, // for dialog
  tile, // for page
}

abstract class _SettingView extends StatelessWidget {
  const _SettingView({
    Key? key,
    required this.style,
    required this.title,
    this.hint,
    this.width,
    this.height,
  }) : super(key: key);

  final SettingViewStyle style;
  final String title;
  final String? hint;
  final double? width;
  final double? height;

  Widget buildRightWidget(BuildContext context);

  void Function()? getInkWellOnTap(BuildContext context) => null;

  @override
  Widget build(BuildContext context) {
    var left = Flexible(
      child: Row(
        children: [
          Flexible(
            child: Padding(
              padding: style == SettingViewStyle.line //
                  ? EdgeInsets.zero
                  : EdgeInsets.symmetric(vertical: 14),
              child: Text(
                title,
                style: style == SettingViewStyle.line //
                    ? Theme.of(context).textTheme.bodyText1?.copyWith(fontWeight: FontWeight.normal)
                    : Theme.of(context).textTheme.subtitle1?.copyWith(fontWeight: FontWeight.normal),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          if (hint != null)
            Padding(
              padding: EdgeInsets.only(left: 2),
              child: HelpIconView.forSettingDlg(
                title: title,
                hint: hint!,
              ),
            ),
        ],
      ),
    );

    var right = Container(
      height: height,
      width: width,
      margin: EdgeInsets.only(left: 4),
      child: buildRightWidget(context),
    );

    switch (style) {
      case SettingViewStyle.line:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [left, right],
        );
      case SettingViewStyle.tile:
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: getInkWellOnTap(context),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  left,
                  AbsorbPointer(absorbing: true, child: right),
                ],
              ),
            ),
          ),
        );
    }
  }
}

class SettingComboBoxView<T extends Object> extends _SettingView {
  const SettingComboBoxView({
    Key? key,
    required SettingViewStyle style,
    required String title,
    String? hint,
    double? width,
    double? height,
    this.enable = true,
    required this.value,
    required this.values,
    required this.textBuilder,
    required this.onChanged,
  }) : super(
          key: key,
          style: style,
          title: title,
          hint: hint,
          width: width ?? 120,
          height: height ?? (style == SettingViewStyle.line ? 38 : 45),
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
        enable: enable,
        onChanged: enable ? (v) => v?.let((it) => onChanged.call(it)) : null,
      );

  @override
  void Function()? getInkWellOnTap(BuildContext context) {
    if (!enable) {
      return null;
    }
    return () {
      showDialog(
        context: context,
        builder: (c) => SimpleDialog(
          title: Text(title),
          children: [
            for (var value in values)
              IconTextDialogOption(
                icon: this.value == value //
                    ? Icon(Icons.radio_button_checked, color: Theme.of(context).primaryColor)
                    : Icon(Icons.radio_button_unchecked),
                text: Text(
                  textBuilder(value),
                  style: Theme.of(context).textTheme.bodyText2,
                ),
                popWhenPress: c,
                onPressed: () => onChanged.call(value),
              ),
          ],
        ),
      );
    };
  }
}

class SettingSwitcherView extends _SettingView {
  const SettingSwitcherView({
    Key? key,
    required SettingViewStyle style,
    required String title,
    String? hint,
    double? width,
    double? height,
    this.enable = true,
    required this.value,
    required this.onChanged,
  }) : super(
          key: key,
          style: style,
          title: title,
          hint: hint,
          width: width,
          height: height ?? 38,
        );

  final bool enable;
  final bool value;
  final void Function(bool) onChanged;

  @override
  Widget buildRightWidget(BuildContext context) => Switch(
        value: value,
        onChanged: enable ? onChanged : null,
      );

  @override
  void Function()? getInkWellOnTap(BuildContext context) {
    if (!enable) {
      return null;
    }
    return () => onChanged.call(!value);
  }
}

class SettingButtonView extends _SettingView {
  const SettingButtonView({
    Key? key,
    required SettingViewStyle style,
    required String title,
    String? hint,
    double? width,
    double? height,
    this.enable = true,
    this.padding = const EdgeInsets.fromLTRB(0, 5, 9, 5),
    required this.child,
    required this.onPressed,
  }) : super(
          key: key,
          style: style,
          title: title,
          hint: hint,
          width: width,
          height: height ?? (style == SettingViewStyle.line ? 38 : 42),
        );

  final bool enable;
  final EdgeInsets padding;
  final Widget child;
  final void Function() onPressed;

  @override
  Widget buildRightWidget(BuildContext context) => Padding(
        padding: padding,
        child: ElevatedButton(
          child: DefaultTextStyle(
            style: Theme.of(context).textTheme.bodyText1!.copyWith(
                  fontWeight: FontWeight.normal,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
            child: child,
          ),
          onPressed: enable ? onPressed : null,
        ),
      );

  @override
  void Function()? getInkWellOnTap(BuildContext context) {
    return enable ? onPressed : null;
  }
}

class SettingTitleView extends StatelessWidget {
  const SettingTitleView({
    Key? key,
    required this.style,
    required this.title,
    this.color = Colors.transparent,
  }) : super(key: key);

  final SettingViewStyle style;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      padding: style == SettingViewStyle.line //
          ? EdgeInsets.symmetric(vertical: 5)
          : EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Text(
          '・$title・',
          style: style == SettingViewStyle.line //
              ? Theme.of(context).textTheme.bodyText1?.copyWith(fontWeight: FontWeight.normal)
              : Theme.of(context).textTheme.subtitle1?.copyWith(fontWeight: FontWeight.normal),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class SettingDividerView extends StatelessWidget {
  const SettingDividerView({
    Key? key,
    this.color = Colors.transparent,
  }) : super(key: key);

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Divider(height: 0, thickness: 1),
    );
  }
}

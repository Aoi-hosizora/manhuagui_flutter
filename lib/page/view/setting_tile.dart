import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/page/view/common_widgets.dart';

/// 与设置相关的 [SettingPageListView] 和各种 [_SettingTileView]，在 [ViewSettingPage] / [DlSettingPage] / [UiSettingPage] / [OtherSettingPage] 使用
class SettingPageListView extends StatelessWidget {
  const SettingPageListView({
    Key? key,
    required this.controller,
    this.listViewKey,
    required this.children,
  }) : super(key: key);

  final ScrollController controller;
  final GlobalKey? listViewKey;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ExtendedScrollbar(
      controller: controller,
      interactive: true,
      mainAxisMargin: 2,
      crossAxisMargin: 2,
      child: ListView(
        key: listViewKey,
        controller: controller,
        padding: EdgeInsets.zero,
        physics: AlwaysScrollableScrollPhysics(),
        children: children,
      ),
    );
  }
}

abstract class _SettingTileView extends StatelessWidget {
  const _SettingTileView({
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

  void Function()? getInkWellOnTap(BuildContext context);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: getInkWellOnTap(context),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 13),
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.subtitle1?.copyWith(fontWeight: FontWeight.normal),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
              ),
              Container(
                height: height,
                width: width,
                margin: EdgeInsets.only(left: 4),
                child: buildRightWidget(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingComboBoxTileView<T extends Object> extends _SettingTileView {
  const SettingComboBoxTileView({
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

class SettingSwitcherTileView extends _SettingTileView {
  const SettingSwitcherTileView({
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

  @override
  void Function()? getInkWellOnTap(BuildContext context) {
    if (!enable) {
      return null;
    }
    return () => onChanged.call(!value);
  }
}

class SettingButtonTileView extends _SettingTileView {
  const SettingButtonTileView({
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

  @override
  void Function()? getInkWellOnTap(BuildContext context) {
    return enable ? onPressed : null;
  }
}

class SettingPageDividerView extends StatelessWidget {
  const SettingPageDividerView({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Divider(height: 0, thickness: 1),
    );
  }
}

class SettingPageTitleView extends StatelessWidget {
  const SettingPageTitleView({
    Key? key,
    required this.title,
    this.padding = const EdgeInsets.symmetric(vertical: 13),
  }) : super(key: key);

  final String title;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Center(
        child: Text(
          '・$title・',
          style: Theme.of(context).textTheme.subtitle1?.copyWith(fontWeight: FontWeight.normal),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

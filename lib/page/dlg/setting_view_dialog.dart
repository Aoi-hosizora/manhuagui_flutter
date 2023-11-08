import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/app_setting.dart';
import 'package:manhuagui_flutter/page/setting_view.dart';
import 'package:manhuagui_flutter/page/view/custom_icons.dart';
import 'package:manhuagui_flutter/page/view/setting_line.dart';
import 'package:manhuagui_flutter/service/prefs/app_setting.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

/// 设置页-阅读设置 [showViewSettingDialog], [ViewSettingSubPage]

class ViewSettingSubPage extends StatefulWidget {
  const ViewSettingSubPage({
    Key? key,
    required this.action,
    required this.setting,
    this.navigateWrapper,
  }) : super(key: key);

  final ActionController action;
  final ViewSetting setting;
  final Future<bool?> Function(Future<bool?> Function())? navigateWrapper;

  @override
  State<ViewSettingSubPage> createState() => _ViewSettingSubPageState();
}

class _ViewSettingSubPageState extends State<ViewSettingSubPage> {
  @override
  void initState() {
    super.initState();
    widget.action.addAction(() => _newestSetting);
    widget.action.addAction('default', _setToDefault);
  }

  @override
  void dispose() {
    widget.action.removeAction();
    widget.action.removeAction('default');
    super.dispose();
  }

  late var _viewDirection = widget.setting.viewDirection;
  late var _showPageHint = widget.setting.showPageHint;
  late var _showClock = widget.setting.showClock;
  late var _showNetwork = widget.setting.showNetwork;
  late var _showBattery = widget.setting.showBattery;
  late var _enablePageSpace = widget.setting.enablePageSpace;
  late var _keepScreenOn = widget.setting.keepScreenOn;
  late var _fullscreen = widget.setting.fullscreen;

  ViewSetting get _newestSetting => ViewSetting(
        viewDirection: _viewDirection,
        showPageHint: _showPageHint,
        showClock: _showClock,
        showNetwork: _showNetwork,
        showBattery: _showBattery,
        enablePageSpace: _enablePageSpace,
        keepScreenOn: _keepScreenOn,
        fullscreen: _fullscreen,
        preloadCount: widget.setting.preloadCount,
        pageNoPosition: widget.setting.pageNoPosition,
        hideAppBarWhenEnter: widget.setting.hideAppBarWhenEnter,
        appBarSwitchBehavior: widget.setting.appBarSwitchBehavior,
        useChapterAssistant: widget.setting.useChapterAssistant,
        assistantActionSetting: widget.setting.assistantActionSetting,
      );

  void _setToDefault() {
    var setting = ViewSetting.defaultSetting;
    _viewDirection = setting.viewDirection;
    _showPageHint = setting.showPageHint;
    _showClock = setting.showClock;
    _showNetwork = setting.showNetwork;
    _showBattery = setting.showBattery;
    _enablePageSpace = setting.enablePageSpace;
    _keepScreenOn = setting.keepScreenOn;
    _fullscreen = setting.fullscreen;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SettingDialogView(
      children: [
        SettingComboBoxView<ViewDirection>(
          title: '阅读方向',
          width: 150,
          value: _viewDirection,
          values: const [ViewDirection.leftToRight, ViewDirection.rightToLeft, ViewDirection.topToBottom, ViewDirection.topToBottomRtl],
          textBuilder: (s) => s.toOptionTitle(),
          onChanged: (s) {
            _viewDirection = s;
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: '显示阅读页面提示',
          value: _showPageHint,
          onChanged: (b) {
            _showPageHint = b;
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: '显示当前时间提示',
          value: _showClock,
          enable: _showPageHint,
          onChanged: (b) {
            _showClock = b;
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: '显示网络状态提示',
          value: _showNetwork,
          enable: _showPageHint,
          onChanged: (b) {
            _showNetwork = b;
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: '显示电源余量提示',
          value: _showBattery,
          enable: _showPageHint,
          onChanged: (b) {
            _showBattery = b;
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: '显示页面间空白',
          value: _enablePageSpace,
          onChanged: (b) {
            _enablePageSpace = b;
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: '屏幕常亮',
          value: _keepScreenOn,
          onChanged: (b) {
            _keepScreenOn = b;
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: '全屏阅读',
          value: _fullscreen,
          onChanged: (b) {
            _fullscreen = b;
            if (mounted) setState(() {});
          },
        ),
        SettingButtonView(
          title: '查看更多设置',
          buttonChild: Text('设置'),
          onPressed: () async {
            var wrapper = widget.navigateWrapper ?? //
                (Future<bool?> Function() navigate) => navigate();
            var ok = await wrapper(
              () => Navigator.of(context).push<bool>(
                CustomPageRoute(
                  context: context,
                  builder: (c) => ViewSettingPage(
                    setting: widget.setting,
                  ),
                ),
              ),
            );
            if (ok == true) {
              Navigator.of(context).pop(true);
            }
          },
        ),
      ],
    );
  }
}

Future<bool> showViewSettingDialog({
  required BuildContext context,
  Widget Function(BuildContext)? anotherButtonBuilder,
  Future<bool?> Function(Future<bool?> Function())? navigateWrapper,
}) async {
  var action = ActionController();
  var ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: IconText(
        icon: Icon(CustomIcons.opened_book_cog, size: 26),
        text: Text('漫画阅读设置'),
        space: 12,
      ),
      scrollable: true,
      content: ViewSettingSubPage(
        action: action,
        setting: AppSetting.instance.view,
        navigateWrapper: navigateWrapper,
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              child: Text('恢复默认'),
              onPressed: () => action.invoke('default'),
            ),
            if (anotherButtonBuilder != null) //
              anotherButtonBuilder.call(c),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              child: Text('确定'),
              onPressed: () async {
                var setting = action.invoke<ViewSetting>();
                if (setting != null) {
                  AppSetting.instance.update(view: setting, alsoFireEvent: true);
                  await AppSettingPrefs.saveViewSetting();
                  Navigator.of(c).pop(true);
                }
              },
            ),
            TextButton(
              child: Text('取消'),
              onPressed: () => Navigator.of(c).pop(false),
            ),
          ],
        ),
      ],
    ),
  );
  return ok ?? false;
}

Future<void> updateViewSettingViewDirection(ViewDirection viewDirection) async {
  var setting = AppSetting.instance.view;
  var newSetting = setting.copyWith(viewDirection: viewDirection);
  AppSetting.instance.update(view: newSetting, alsoFireEvent: true);
  await AppSettingPrefs.saveViewSetting();
}

Future<void> updateViewSettingUseChapterAssistant(bool useChapterAssistant) async {
  var setting = AppSetting.instance.view;
  var newSetting = setting.copyWith(useChapterAssistant: useChapterAssistant);
  AppSetting.instance.update(view: newSetting, alsoFireEvent: true);
  await AppSettingPrefs.saveViewSetting();
}

class AssistantSettingSubPage extends StatefulWidget {
  const AssistantSettingSubPage({
    Key? key,
    required this.action,
    required this.setting,
  }) : super(key: key);

  final ActionController action;
  final AssistantActionSetting setting;

  @override
  State<AssistantSettingSubPage> createState() => _AssistantSettingSubPageState();
}

class _AssistantSettingSubPageState extends State<AssistantSettingSubPage> {
  @override
  void initState() {
    super.initState();
    widget.action.addAction(() => _newestSetting);
    widget.action.addAction('default', _setToDefault);
  }

  @override
  void dispose() {
    widget.action.removeAction();
    super.dispose();
  }

  late var _leftTop = widget.setting.leftTop;
  late var _rightTop = widget.setting.rightTop;
  late var _leftBottom = widget.setting.leftBottom;
  late var _rightBottom = widget.setting.rightBottom;
  late var _allowReverse = widget.setting.allowReverse;

  AssistantActionSetting get _newestSetting => AssistantActionSetting(
        leftTop: _leftTop,
        rightTop: _rightTop,
        leftBottom: _leftBottom,
        rightBottom: _rightBottom,
        allowReverse: _allowReverse,
      );

  void _setToDefault() {
    var setting = AssistantActionSetting.defaultSetting;
    _leftTop = setting.leftTop;
    _rightTop = setting.rightTop;
    _leftBottom = setting.leftBottom;
    _rightBottom = setting.rightBottom;
    _allowReverse = setting.allowReverse;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SettingDialogView(
      children: [
        for (var t in [
          Tuple3(_leftTop, (s) => _leftTop = s, !_allowReverse ? '左上角的按钮动作' : '"上一章节"上方的按钮动作'),
          Tuple3(_rightTop, (s) => _rightTop = s, !_allowReverse ? '右上角的按钮动作' : '"下一章节"上方的按钮动作'),
          Tuple3(_leftBottom, (s) => _leftBottom = s, !_allowReverse ? '左下角的按钮动作' : '"上一章节"下方的按钮动作'),
          Tuple3(_rightBottom, (s) => _rightBottom = s, !_allowReverse ? '右下角的按钮动作' : '"下一章节"下方的按钮动作'),
        ])
          SettingComboBoxView<AssistantAction>(
            title: t.item3,
            value: t.item1,
            values: AssistantAction.values,
            textBuilder: (s) => s.toOptionTitle(),
            onChanged: (s) {
              t.item2.call(s);
              if (mounted) setState(() {});
            },
          ),
        SettingSwitcherView(
          title: '允许随着左右变更修改按钮动作',
          value: _allowReverse,
          onChanged: (b) {
            _allowReverse = b;
            if (mounted) setState(() {});
          },
        ),
      ],
    );
  }
}

Future<AssistantActionSetting?> showAssistantSettingDialog({required BuildContext context, required AssistantActionSetting setting}) async {
  var action = ActionController();
  return await showDialog<AssistantActionSetting>(
    context: context,
    builder: (c) => AlertDialog(
      title: IconText(
        icon: Icon(MdiIcons.gestureTapButton, size: 26),
        text: Text('章节跳转助手设置'),
        space: 12,
      ),
      scrollable: true,
      content: AssistantSettingSubPage(
        action: action,
        setting: setting,
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          child: Text('恢复默认'),
          onPressed: () => action.invoke('default'),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              child: Text('确定'),
              onPressed: () => Navigator.of(c).pop(action.invoke<AssistantActionSetting>()),
            ),
            TextButton(
              child: Text('取消'),
              onPressed: () => Navigator.of(c).pop(null),
            ),
          ],
        ),
      ],
    ),
  );
}

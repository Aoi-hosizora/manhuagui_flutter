import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/app_setting.dart';
import 'package:manhuagui_flutter/page/view/custom_icons.dart';
import 'package:manhuagui_flutter/page/view/setting_dialog.dart';
import 'package:manhuagui_flutter/service/prefs/app_setting.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

/// 设置页-阅读设置 [showViewSettingDialog], [ViewSettingSubPage]

class ViewSettingSubPage extends StatefulWidget {
  const ViewSettingSubPage({
    Key? key,
    required this.action,
    required this.setting,
    required this.onSettingChanged,
  }) : super(key: key);

  final ActionController action;
  final ViewSetting setting;
  final void Function(ViewSetting) onSettingChanged;

  @override
  State<ViewSettingSubPage> createState() => _ViewSettingSubPageState();
}

class _ViewSettingSubPageState extends State<ViewSettingSubPage> {
  @override
  void initState() {
    super.initState();
    widget.action.addAction(_setToDefault);
  }

  @override
  void dispose() {
    widget.action.removeAction();
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
  late var _preloadCount = widget.setting.preloadCount;
  late var _pageNoPosition = widget.setting.pageNoPosition;
  late var _hideAppBarWhenEnter = widget.setting.hideAppBarWhenEnter;
  late var _appBarSwitchBehavior = widget.setting.appBarSwitchBehavior;
  late var _useChapterAssistant = widget.setting.useChapterAssistant;
  late var _assistantActionSetting = widget.setting.assistantActionSetting;

  ViewSetting get _newestSetting => ViewSetting(
        viewDirection: _viewDirection,
        showPageHint: _showPageHint,
        showClock: _showClock,
        showNetwork: _showNetwork,
        showBattery: _showBattery,
        enablePageSpace: _enablePageSpace,
        keepScreenOn: _keepScreenOn,
        fullscreen: _fullscreen,
        preloadCount: _preloadCount,
        pageNoPosition: _pageNoPosition,
        hideAppBarWhenEnter: _hideAppBarWhenEnter,
        appBarSwitchBehavior: _appBarSwitchBehavior,
        useChapterAssistant: _useChapterAssistant,
        assistantActionSetting: _assistantActionSetting,
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
    _preloadCount = setting.preloadCount;
    _pageNoPosition = setting.pageNoPosition;
    _hideAppBarWhenEnter = setting.hideAppBarWhenEnter;
    _appBarSwitchBehavior = setting.appBarSwitchBehavior;
    _useChapterAssistant = setting.useChapterAssistant;
    _assistantActionSetting = setting.assistantActionSetting;
    widget.onSettingChanged.call(_newestSetting);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SettingDialogView(
      children: [
        SettingGroupTitleView(
          title: '常规设置',
        ),
        SettingComboBoxView<ViewDirection>(
          title: '阅读方向',
          width: 150,
          value: _viewDirection,
          values: const [ViewDirection.leftToRight, ViewDirection.rightToLeft, ViewDirection.topToBottom, ViewDirection.topToBottomRtl],
          textBuilder: (s) => s.toOptionTitle(),
          onChanged: (s) {
            _viewDirection = s;
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: '显示阅读页面提示',
          value: _showPageHint,
          onChanged: (b) {
            _showPageHint = b;
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: '显示当前时间提示',
          value: _showClock,
          enable: _showPageHint,
          onChanged: (b) {
            _showClock = b;
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: '显示网络状态提示',
          value: _showNetwork,
          enable: _showPageHint,
          onChanged: (b) {
            _showNetwork = b;
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: '显示电源余量提示',
          value: _showBattery,
          enable: _showPageHint,
          onChanged: (b) {
            _showBattery = b;
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: '显示页面间空白',
          value: _enablePageSpace,
          onChanged: (b) {
            _enablePageSpace = b;
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: '屏幕常亮',
          value: _keepScreenOn,
          onChanged: (b) {
            _keepScreenOn = b;
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: '全屏阅读',
          value: _fullscreen,
          onChanged: (b) {
            _fullscreen = b;
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingGroupTitleView(
          title: '高级设置', // TODO hide advanced setting in dialog
        ),
        SettingComboBoxView<int>(
          title: '预加载章节页数',
          value: _preloadCount.clamp(0, 6),
          values: const [0, 1, 2, 3, 4, 5, 6],
          textBuilder: (s) => s == 0 ? '禁用预加载' : '前后$s页',
          onChanged: (c) {
            _preloadCount = c.clamp(0, 6);
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingComboBoxView<PageNoPosition>(
          title: '每页显示额外页码',
          value: _pageNoPosition,
          values: const [PageNoPosition.hide, PageNoPosition.topLeft, PageNoPosition.topCenter, PageNoPosition.topRight, PageNoPosition.bottomLeft, PageNoPosition.bottomCenter, PageNoPosition.bottomRight],
          enable: _viewDirection == ViewDirection.topToBottom || _viewDirection == ViewDirection.topToBottomRtl,
          textBuilder: (s) => s.toOptionTitle(),
          onChanged: (s) {
            _pageNoPosition = s;
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: '进入时隐藏标题栏',
          value: _hideAppBarWhenEnter,
          onChanged: (b) {
            _hideAppBarWhenEnter = b;
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingComboBoxView<AppBarSwitchBehavior>(
          title: '切换章节时标题栏行为',
          value: _appBarSwitchBehavior,
          values: const [AppBarSwitchBehavior.keep, AppBarSwitchBehavior.show, AppBarSwitchBehavior.hide],
          textBuilder: (s) => s.toOptionTitle(),
          onChanged: (s) {
            _appBarSwitchBehavior = s;
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: '显示单手章节跳转助手',
          value: _useChapterAssistant,
          onChanged: (b) {
            _useChapterAssistant = b;
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingButtonView(
          title: '章节跳转助手按钮动作',
          buttonChild: Text('设置'),
          enable: _useChapterAssistant,
          onPressed: () async {
            var result = await showAssistantSettingDialog(context: context, setting: _assistantActionSetting);
            if (result != null) {
              _assistantActionSetting = result;
              widget.onSettingChanged.call(_newestSetting);
              if (mounted) setState(() {});
            }
          },
        ),
      ],
    );
  }
}

Future<bool> showViewSettingDialog({required BuildContext context, Widget Function(BuildContext)? anotherButtonBuilder}) async {
  var action = ActionController();
  var setting = AppSetting.instance.view;
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
        setting: setting,
        onSettingChanged: (s) => setting = s,
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              child: Text('恢复默认'),
              onPressed: () => action.invoke(),
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
                AppSetting.instance.update(view: setting, alsoFireEvent: true);
                await AppSettingPrefs.saveViewSetting();
                Navigator.of(c).pop(true);
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
    required this.onSettingChanged,
  }) : super(key: key);

  final ActionController action;
  final AssistantActionSetting setting;
  final void Function(AssistantActionSetting) onSettingChanged;

  @override
  State<AssistantSettingSubPage> createState() => _AssistantSettingSubPageState();
}

class _AssistantSettingSubPageState extends State<AssistantSettingSubPage> {
  @override
  void initState() {
    super.initState();
    widget.action.addAction(_setToDefault);
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
    widget.onSettingChanged.call(_newestSetting);
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
              widget.onSettingChanged.call(_newestSetting);
              if (mounted) setState(() {});
            },
          ),
        SettingSwitcherView(
          title: '允许随着左右变更修改按钮动作',
          value: _allowReverse,
          onChanged: (b) {
            _allowReverse = b;
            widget.onSettingChanged.call(_newestSetting);
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
        onSettingChanged: (s) => setting = s,
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(child: Text('恢复默认'), onPressed: () => action.invoke()),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(child: Text('确定'), onPressed: () => Navigator.of(c).pop(setting)),
            TextButton(child: Text('取消'), onPressed: () => Navigator.of(c).pop(null)),
          ],
        ),
      ],
    ),
  );
}

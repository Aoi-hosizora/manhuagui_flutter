import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/app_setting.dart';
import 'package:manhuagui_flutter/page/dlg/setting_view_dialog.dart';
import 'package:manhuagui_flutter/page/setting_view.dart';
import 'package:manhuagui_flutter/page/view/setting_view.dart';

/// 设置-漫画阅读设置，用于 [ViewSettingPage] / [showViewSettingDialog] / [showAssistantSettingDialog]
class ViewSettingSubPage extends StatefulWidget {
  const ViewSettingSubPage({
    Key? key,
    required this.action,
    required this.setting,
    required this.style,
    this.navigateWrapper,
  }) : super(key: key);

  final ActionController action;
  final ViewSetting setting;
  final SettingViewStyle style;
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
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var map = <String, List<Widget>>{
      '常规设置': [
        SettingComboBoxView<ViewDirection>(
          style: widget.style,
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
          style: widget.style,
          title: '显示阅读页面提示',
          value: _showPageHint,
          onChanged: (b) {
            _showPageHint = b;
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          style: widget.style,
          title: '显示当前时间提示',
          value: _showClock,
          enable: _showPageHint,
          onChanged: (b) {
            _showClock = b;
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          style: widget.style,
          title: '显示网络状态提示',
          value: _showNetwork,
          enable: _showPageHint,
          onChanged: (b) {
            _showNetwork = b;
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          style: widget.style,
          title: '显示电源余量提示',
          value: _showBattery,
          enable: _showPageHint,
          onChanged: (b) {
            _showBattery = b;
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          style: widget.style,
          title: '显示页面间空白',
          value: _enablePageSpace,
          onChanged: (b) {
            _enablePageSpace = b;
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          style: widget.style,
          title: '屏幕常亮',
          value: _keepScreenOn,
          onChanged: (b) {
            _keepScreenOn = b;
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          style: widget.style,
          title: '全屏阅读',
          value: _fullscreen,
          onChanged: (b) {
            _fullscreen = b;
            if (mounted) setState(() {});
          },
        ),
      ],
      '高级设置': [
        SettingComboBoxView<int>(
          style: widget.style,
          title: '预加载章节页数',
          value: _preloadCount.clamp(0, 6),
          values: const [0, 1, 2, 3, 4, 5, 6],
          textBuilder: (s) => s == 0 ? '禁用预加载' : '前后$s页',
          onChanged: (c) {
            _preloadCount = c.clamp(0, 6);
            if (mounted) setState(() {});
          },
        ),
        SettingComboBoxView<PageNoPosition>(
          style: widget.style,
          title: '每页显示额外页码',
          value: _pageNoPosition,
          values: const [PageNoPosition.hide, PageNoPosition.topLeft, PageNoPosition.topCenter, PageNoPosition.topRight, PageNoPosition.bottomLeft, PageNoPosition.bottomCenter, PageNoPosition.bottomRight],
          enable: _viewDirection == ViewDirection.topToBottom || _viewDirection == ViewDirection.topToBottomRtl,
          textBuilder: (s) => s.toOptionTitle(),
          onChanged: (s) {
            _pageNoPosition = s;
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          style: widget.style,
          title: '进入时隐藏标题栏',
          value: _hideAppBarWhenEnter,
          onChanged: (b) {
            _hideAppBarWhenEnter = b;
            if (mounted) setState(() {});
          },
        ),
        SettingComboBoxView<AppBarSwitchBehavior>(
          style: widget.style,
          title: '切换章节时标题栏行为',
          value: _appBarSwitchBehavior,
          values: const [AppBarSwitchBehavior.keep, AppBarSwitchBehavior.show, AppBarSwitchBehavior.hide],
          textBuilder: (s) => s.toOptionTitle(),
          onChanged: (s) {
            _appBarSwitchBehavior = s;
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          style: widget.style,
          title: '显示单手章节跳转助手',
          value: _useChapterAssistant,
          onChanged: (b) {
            _useChapterAssistant = b;
            if (mounted) setState(() {});
          },
        ),
        SettingButtonView(
          style: widget.style,
          title: '章节跳转助手动作设置',
          buttonChild: Text('设置'),
          enable: _useChapterAssistant,
          onPressed: () async {
            var result = await showAssistantSettingDialog(
              context: context,
              setting: _assistantActionSetting,
            );
            if (result != null) {
              _assistantActionSetting = result;
              if (mounted) setState(() {});
            }
          },
        ),
      ],
    };

    var children = <Widget>[];
    if (widget.style == SettingViewStyle.line) {
      children.addAll(map['常规设置']!);
      children.add(
        SettingButtonView(
          style: widget.style,
          title: '查看更多阅读设置',
          buttonChild: Text('设置'),
          onPressed: () async {
            var wrapper = widget.navigateWrapper ?? (navigate) => navigate();
            var ok = await wrapper(
              () => Navigator.of(context).push<bool>(
                CustomPageRoute(
                  context: context,
                  builder: (c) => ViewSettingPage(),
                ),
              ),
            );
            if (ok == true) {
              Navigator.of(context).pop(true);
            }
          },
        ),
      );
    } else {
      for (var key in map.keys) {
        children.add(
          SettingTitleView(
            style: widget.style,
            title: key,
            color: widget.style == SettingViewStyle.line //
                ? Colors.transparent
                : Theme.of(context).scaffoldBackgroundColor,
          ),
        );
        children.addAll(
          map[key]!.separate(SettingDividerView()),
        );
      }
    }

    Widget view = SettingColumnView(children: children);
    if (widget.style == SettingViewStyle.tile) {
      view = DecoratedBox(
        decoration: BoxDecoration(color: Colors.white),
        child: view,
      );
    }
    return view;
  }
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
    widget.action.removeAction('default');
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
    var style = SettingViewStyle.line;
    return SettingColumnView(
      children: [
        for (var t in [
          Tuple3(_leftTop, (s) => _leftTop = s, !_allowReverse ? '左上角的按钮动作' : '"上一章节"上方的按钮动作'),
          Tuple3(_rightTop, (s) => _rightTop = s, !_allowReverse ? '右上角的按钮动作' : '"下一章节"上方的按钮动作'),
          Tuple3(_leftBottom, (s) => _leftBottom = s, !_allowReverse ? '左下角的按钮动作' : '"上一章节"下方的按钮动作'),
          Tuple3(_rightBottom, (s) => _rightBottom = s, !_allowReverse ? '右下角的按钮动作' : '"下一章节"下方的按钮动作'),
        ])
          SettingComboBoxView<AssistantAction>(
            style: style,
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
          style: style,
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

import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/app_setting.dart';
import 'package:manhuagui_flutter/page/dlg/setting_view_dialog.dart';
import 'package:manhuagui_flutter/page/view/fit_system_screenshot.dart';
import 'package:manhuagui_flutter/page/view/setting_tile.dart';
import 'package:manhuagui_flutter/service/prefs/app_setting.dart';

/// 漫画阅读设置页
class ViewSettingPage extends StatefulWidget {
  const ViewSettingPage({
    Key? key,
    required this.setting,
  }) : super(key: key);

  final ViewSetting setting;

  @override
  State<ViewSettingPage> createState() => _ViewSettingPageState();
}

class _ViewSettingPageState extends State<ViewSettingPage> with FitSystemScreenshotMixin {
  final _controller = ScrollController();
  final _listViewKey = GlobalKey();

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

  Future<void> _saveSetting() async {
    AppSetting.instance.update(view: _newestSetting, alsoFireEvent: true);
    await AppSettingPrefs.saveViewSetting();
    Navigator.of(context).pop(true);
  }

  @override
  FitSystemScreenshotData get fitSystemScreenshotData => FitSystemScreenshotData(
        scrollViewKey: _listViewKey,
        scrollController: _controller,
      );

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_newestSetting.equals(AppSetting.instance.view)) {
          return true;
        }
        var ok = await showYesNoAlertDialog(
          context: context,
          title: Text('漫画阅读设置'),
          content: Text('当前设置已修改，是否应用？'),
          yesText: Text('去保存'),
          noText: Text('不保存'),
        );
        return ok != true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('漫画阅读设置'),
          leading: AppBarActionButton.leading(context: context),
          actions: [
            AppBarActionButton(
              icon: Icon(Icons.settings_backup_restore),
              tooltip: '恢复默认',
              onPressed: _setToDefault,
            ),
            AppBarActionButton(
              icon: Icon(Icons.check),
              tooltip: '保存设置',
              onPressed: _saveSetting,
            ),
          ],
        ),
        body: SettingPageListView(
          controller: _controller,
          listViewKey: _listViewKey,
          children: [
            SettingPageTitleView(
              title: '常规设置',
            ),
            SettingComboBoxTileView<ViewDirection>(
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
            SettingPageDividerView(),
            SettingSwitcherTileView(
              title: '显示阅读页面提示',
              value: _showPageHint,
              onChanged: (b) {
                _showPageHint = b;
                if (mounted) setState(() {});
              },
            ),
            SettingPageDividerView(),
            SettingSwitcherTileView(
              title: '显示当前时间提示',
              value: _showClock,
              enable: _showPageHint,
              onChanged: (b) {
                _showClock = b;
                if (mounted) setState(() {});
              },
            ),
            SettingPageDividerView(),
            SettingSwitcherTileView(
              title: '显示网络状态提示',
              value: _showNetwork,
              enable: _showPageHint,
              onChanged: (b) {
                _showNetwork = b;
                if (mounted) setState(() {});
              },
            ),
            SettingPageDividerView(),
            SettingSwitcherTileView(
              title: '显示电源余量提示',
              value: _showBattery,
              enable: _showPageHint,
              onChanged: (b) {
                _showBattery = b;
                if (mounted) setState(() {});
              },
            ),
            SettingPageDividerView(),
            SettingSwitcherTileView(
              title: '显示页面间空白',
              value: _enablePageSpace,
              onChanged: (b) {
                _enablePageSpace = b;
                if (mounted) setState(() {});
              },
            ),
            SettingPageDividerView(),
            SettingSwitcherTileView(
              title: '屏幕常亮',
              value: _keepScreenOn,
              onChanged: (b) {
                _keepScreenOn = b;
                if (mounted) setState(() {});
              },
            ),
            SettingPageDividerView(),
            SettingSwitcherTileView(
              title: '全屏阅读',
              value: _fullscreen,
              onChanged: (b) {
                _fullscreen = b;
                if (mounted) setState(() {});
              },
            ),
            SettingPageTitleView(
              title: '高级设置',
            ),
            SettingComboBoxTileView<int>(
              title: '预加载章节页数',
              value: _preloadCount.clamp(0, 6),
              values: const [0, 1, 2, 3, 4, 5, 6],
              textBuilder: (s) => s == 0 ? '禁用预加载' : '前后$s页',
              onChanged: (c) {
                _preloadCount = c.clamp(0, 6);
                if (mounted) setState(() {});
              },
            ),
            SettingPageDividerView(),
            SettingComboBoxTileView<PageNoPosition>(
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
            SettingPageDividerView(),
            SettingSwitcherTileView(
              title: '进入时隐藏标题栏',
              value: _hideAppBarWhenEnter,
              onChanged: (b) {
                _hideAppBarWhenEnter = b;
                if (mounted) setState(() {});
              },
            ),
            SettingPageDividerView(),
            SettingComboBoxTileView<AppBarSwitchBehavior>(
              title: '切换章节时标题栏行为',
              value: _appBarSwitchBehavior,
              values: const [AppBarSwitchBehavior.keep, AppBarSwitchBehavior.show, AppBarSwitchBehavior.hide],
              textBuilder: (s) => s.toOptionTitle(),
              onChanged: (s) {
                _appBarSwitchBehavior = s;
                if (mounted) setState(() {});
              },
            ),
            SettingPageDividerView(),
            SettingSwitcherTileView(
              title: '显示单手章节跳转助手',
              value: _useChapterAssistant,
              onChanged: (b) {
                _useChapterAssistant = b;
                if (mounted) setState(() {});
              },
            ),
            SettingPageDividerView(),
            SettingButtonTileView(
              title: '章节跳转助手按钮动作',
              buttonChild: Text('设置'),
              enable: _useChapterAssistant,
              onPressed: () async {
                var result = await showAssistantSettingDialog(context: context, setting: _assistantActionSetting);
                if (result != null) {
                  _assistantActionSetting = result;
                  if (mounted) setState(() {});
                }
              },
            ),
          ],
        ).fitSystemScreenshot(this),
      ),
    );
  }
}

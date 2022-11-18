import 'package:flutter/material.dart';
import 'package:manhuagui_flutter/page/view/setting_dialog.dart';

/// 漫画章节阅读页-阅读设置

class ViewSetting {
  const ViewSetting({
    required this.viewDirection,
    required this.showPageHint,
    this.showClock = true,
    this.showNetwork = false,
    this.showBattery = false,
    required this.enablePageSpace,
    required this.keepScreenOn,
    required this.fullscreen,
    required this.preloadCount,
  });

  final ViewDirection viewDirection; // 阅读方向
  final bool showPageHint; // 显示页面提示
  final bool showClock; // 显示当前时间
  final bool showNetwork; // 显示网络状态
  final bool showBattery; // 显示电源余量
  final bool enablePageSpace; // 显示页面间空白
  final bool keepScreenOn; // 屏幕常亮
  final bool fullscreen; // 全屏阅读
  final int preloadCount; // 预加载页数

  ViewSetting.defaultSetting()
      : this(
          viewDirection: ViewDirection.leftToRight,
          showPageHint: true,
          showClock: true,
          showNetwork: false,
          showBattery: false,
          enablePageSpace: true,
          keepScreenOn: true,
          fullscreen: false,
          preloadCount: 2,
        );

  ViewSetting copyWith({
    ViewDirection? viewDirection,
    bool? showPageHint,
    bool? showClock,
    bool? showNetwork,
    bool? showBattery,
    bool? enablePageSpace,
    bool? keepScreenOn,
    bool? fullscreen,
    int? preloadCount,
  }) {
    return ViewSetting(
      viewDirection: viewDirection ?? this.viewDirection,
      showPageHint: showPageHint ?? this.showPageHint,
      enablePageSpace: enablePageSpace ?? this.enablePageSpace,
      showClock: showClock ?? this.showClock,
      showNetwork: showNetwork ?? this.showNetwork,
      showBattery: showBattery ?? this.showBattery,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
      fullscreen: fullscreen ?? this.fullscreen,
      preloadCount: preloadCount ?? this.preloadCount,
    );
  }
}

enum ViewDirection {
  leftToRight,
  rightToLeft,
  topToBottom,
}

extension ViewDirectionExtension on ViewDirection {
  int toInt() {
    if (this == ViewDirection.leftToRight) {
      return 0;
    }
    if (this == ViewDirection.rightToLeft) {
      return 1;
    }
    if (this == ViewDirection.topToBottom) {
      return 2;
    }
    return 0;
  }

  static ViewDirection fromInt(int i) {
    if (i == 0) {
      return ViewDirection.leftToRight;
    }
    if (i == 1) {
      return ViewDirection.rightToLeft;
    }
    if (i == 2) {
      return ViewDirection.topToBottom;
    }
    return ViewDirection.leftToRight;
  }
}

class ViewSettingSubPage extends StatefulWidget {
  const ViewSettingSubPage({
    Key? key,
    required this.setting,
    required this.onSettingChanged,
  }) : super(key: key);

  final ViewSetting setting;
  final void Function(ViewSetting) onSettingChanged;

  @override
  State<ViewSettingSubPage> createState() => _ViewSettingSubPageState();
}

class _ViewSettingSubPageState extends State<ViewSettingSubPage> with SettingSubPageStateMixin<ViewSetting, ViewSettingSubPage> {
  late var _viewDirection = widget.setting.viewDirection;
  late var _showPageHint = widget.setting.showPageHint;
  late var _showClock = widget.setting.showClock;
  late var _showNetwork = widget.setting.showNetwork;
  late var _showBattery = widget.setting.showBattery;
  late var _enablePageSpace = widget.setting.enablePageSpace;
  late var _keepScreenOn = widget.setting.keepScreenOn;
  late var _fullscreen = widget.setting.fullscreen;
  late var _preloadCount = widget.setting.preloadCount;

  @override
  ViewSetting get newestSetting => ViewSetting(
        viewDirection: _viewDirection,
        showPageHint: _showPageHint,
        showClock: _showClock,
        showNetwork: _showNetwork,
        showBattery: _showBattery,
        enablePageSpace: _enablePageSpace,
        keepScreenOn: _keepScreenOn,
        fullscreen: _fullscreen,
        preloadCount: _preloadCount,
      );

  @override
  List<Widget> get settingLines => [
        SettingComboBoxView<ViewDirection>(
          title: '阅读方向',
          value: _viewDirection,
          values: const [ViewDirection.leftToRight, ViewDirection.rightToLeft, ViewDirection.topToBottom],
          builder: (s) => Text(
            s == ViewDirection.leftToRight ? '从左往右' : (s == ViewDirection.rightToLeft ? '从右往左' : '从上往下'),
            style: Theme.of(context).textTheme.bodyText2,
          ),
          onChanged: (s) {
            _viewDirection = s;
            widget.onSettingChanged.call(newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: '显示页面提示文字',
          value: _showPageHint,
          onChanged: (b) {
            _showPageHint = b;
            widget.onSettingChanged.call(newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: '显示当前时间',
          value: _showClock,
          enable: _showPageHint,
          onChanged: (b) {
            _showClock = b;
            widget.onSettingChanged.call(newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: '显示网络状态',
          value: _showNetwork,
          enable: _showPageHint,
          onChanged: (b) {
            _showNetwork = b;
            widget.onSettingChanged.call(newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: '显示电源余量',
          value: _showBattery,
          enable: _showPageHint,
          onChanged: (b) {
            _showBattery = b;
            widget.onSettingChanged.call(newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: '显示页面间空白',
          value: _enablePageSpace,
          onChanged: (b) {
            _enablePageSpace = b;
            widget.onSettingChanged.call(newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: '屏幕常亮',
          value: _keepScreenOn,
          onChanged: (b) {
            _keepScreenOn = b;
            widget.onSettingChanged.call(newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: '全屏阅读',
          value: _fullscreen,
          onChanged: (b) {
            _fullscreen = b;
            widget.onSettingChanged.call(newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingComboBoxView<int>(
          title: '预加载页数',
          value: _preloadCount.clamp(0, 5),
          values: const [0, 1, 2, 3, 4, 5],
          builder: (s) => Text(
            s == 0 ? '禁用预加载' : '前后$s页',
            style: Theme.of(context).textTheme.bodyText2,
          ),
          onChanged: (c) {
            _preloadCount = c.clamp(0, 5);
            widget.onSettingChanged.call(newestSetting);
            if (mounted) setState(() {});
          },
        ),
      ];
}

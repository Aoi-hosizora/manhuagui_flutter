import 'package:flutter/material.dart';

/// 漫画章节阅读页-阅读设置

class ViewSetting {
  ViewSetting({
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

class _ViewSettingSubPageState extends State<ViewSettingSubPage> {
  late var _viewDirection = widget.setting.viewDirection;
  late var _showPageHint = widget.setting.showPageHint;
  late var _showClock = widget.setting.showClock;
  late var _showNetwork = widget.setting.showNetwork;
  late var _showBattery = widget.setting.showBattery;
  late var _enablePageSpace = widget.setting.enablePageSpace;
  late var _keepScreenOn = widget.setting.keepScreenOn;
  late var _fullscreen = widget.setting.fullscreen;
  late var _preloadCount = widget.setting.preloadCount;

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
      );

  Widget _buildComboBox<T>({
    required String title,
    double width = 120,
    required T value,
    required List<T> values,
    required Widget Function(T) builder,
    required void Function(T?) onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyText1,
        ),
        SizedBox(
          height: 38,
          width: width,
          child: DropdownButton<T>(
            value: value,
            items: values.map((s) => DropdownMenuItem<T>(child: builder(s), value: s)).toList(),
            underline: Container(color: Colors.white),
            isExpanded: true,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitcher({
    required String title,
    required bool value,
    required void Function(bool) onChanged,
    bool enable = true,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyText1,
        ),
        SizedBox(
          height: 38,
          child: Switch(
            value: value,
            onChanged: enable ? onChanged : null,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildComboBox<ViewDirection>(
          title: '阅读方向　　　　　　　　',
          value: _viewDirection,
          values: [ViewDirection.leftToRight, ViewDirection.rightToLeft, ViewDirection.topToBottom],
          builder: (s) => Text(
            s == ViewDirection.leftToRight ? '从左往右' : (s == ViewDirection.rightToLeft ? '从右往左' : '从上往下'),
            style: Theme.of(context).textTheme.bodyText2,
          ),
          onChanged: (s) {
            _viewDirection = s ?? ViewDirection.leftToRight;
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        _buildSwitcher(
          title: '显示页面提示文字',
          value: _showPageHint,
          onChanged: (b) {
            _showPageHint = b;
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        _buildSwitcher(
          title: '显示当前时间',
          value: _showClock,
          enable: _showPageHint,
          onChanged: (b) {
            _showClock = b;
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        _buildSwitcher(
          title: '显示网络状态',
          value: _showNetwork,
          enable: _showPageHint,
          onChanged: (b) {
            _showNetwork = b;
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        _buildSwitcher(
          title: '显示电源余量',
          value: _showBattery,
          enable: _showPageHint,
          onChanged: (b) {
            _showBattery = b;
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        _buildSwitcher(
          title: '显示页面间空白',
          value: _enablePageSpace,
          onChanged: (b) {
            _enablePageSpace = b;
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        _buildSwitcher(
          title: '屏幕常亮',
          value: _keepScreenOn,
          onChanged: (b) {
            _keepScreenOn = b;
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        _buildSwitcher(
          title: '全屏阅读',
          value: _fullscreen,
          onChanged: (b) {
            _fullscreen = b;
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        _buildComboBox<int>(
          title: '预加载页数',
          width: 80,
          value: _preloadCount.clamp(0, 5),
          values: [0, 1, 2, 3, 4, 5],
          builder: (s) => Text(
            s == 0 ? '禁用' : '前后$s页',
            style: Theme.of(context).textTheme.bodyText2,
          ),
          onChanged: (c) {
            _preloadCount = (c ?? 2).clamp(0, 5);
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
      ],
    );
  }
}

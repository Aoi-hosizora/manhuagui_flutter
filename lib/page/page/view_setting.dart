import 'package:flutter/material.dart';

enum ViewDirection {
  leftToRight,
  rightToLeft,
  topToBottom, // TODO
}

/// 漫画章节浏览页-设置对话框
class ViewSetting {
  ViewSetting({
    required this.reverseScroll,
    required this.showPageHint,
    this.showNowTime = true, // TODO
    this.showNetwork = false, // TODO
    this.showBattery = false, // TODO
    required this.enablePageSpace,
    required this.keepScreenOn,
    required this.preloadCount,
  });

  final bool reverseScroll; // 反向拖动
  final bool showPageHint; // 显示提示信息
  final bool showNowTime; // 显示当前时间
  final bool showNetwork; // 显示网络信息
  final bool showBattery; // 显示电源信息
  final bool enablePageSpace; // 显示页间空白
  final bool keepScreenOn; // 屏幕常亮
  final int preloadCount; // 预加载页数

  ViewSetting.defaultSetting()
      : this(
          reverseScroll: false,
          showPageHint: true,
          showNowTime: true,
          showNetwork: false,
          showBattery: false,
          enablePageSpace: true,
          keepScreenOn: true,
          preloadCount: 2,
        );

  ViewSetting copyWith({
    bool? reverseScroll,
    bool? showPageHint,
    bool? showNowTime,
    bool? showNetwork,
    bool? showBattery,
    bool? enablePageSpace,
    bool? keepScreenOn,
    int? preloadCount,
  }) {
    return ViewSetting(
      reverseScroll: reverseScroll ?? this.reverseScroll,
      showPageHint: showPageHint ?? this.showPageHint,
      enablePageSpace: enablePageSpace ?? this.enablePageSpace,
      showNowTime: showNowTime ?? this.showNowTime,
      showNetwork: showNetwork ?? this.showNetwork,
      showBattery: showBattery ?? this.showBattery,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
      preloadCount: preloadCount ?? this.preloadCount,
    );
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
  late bool _reverseScroll = widget.setting.reverseScroll;
  late bool _showPageHint = widget.setting.showPageHint;
  late bool _enablePageSpace = widget.setting.enablePageSpace;
  late bool _keepScreenOn = widget.setting.keepScreenOn;
  late int _preloadCount = widget.setting.preloadCount;

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
        Text(title),
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
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title),
        SizedBox(
          height: 38,
          child: Switch(
            value: value,
            onChanged: onChanged,
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
        _buildComboBox<bool>(
          title: '阅读方向',
          value: _reverseScroll,
          values: [false, true],
          builder: (s) => Text(
            s == false ? '从左往右' : '从右往左',
            style: Theme.of(context).textTheme.bodyText2,
          ),
          onChanged: (s) {
            _reverseScroll = s ?? true;
            var setting = widget.setting.copyWith(reverseScroll: _reverseScroll);
            widget.onSettingChanged.call(setting);
            if (mounted) setState(() {});
          },
        ),
        _buildSwitcher(
          title: '显示提示信息', // TODO
          value: _showPageHint,
          onChanged: (b) {
            _showPageHint = b;
            var setting = widget.setting.copyWith(showPageHint: b);
            widget.onSettingChanged.call(setting);
            if (mounted) setState(() {});
          },
        ),
        _buildSwitcher(
          title: '显示页间空白',
          value: _enablePageSpace,
          onChanged: (b) {
            _enablePageSpace = b;
            var setting = widget.setting.copyWith(enablePageSpace: b);
            widget.onSettingChanged.call(setting);
            if (mounted) setState(() {});
          },
        ),
        _buildSwitcher(
          title: '屏幕常亮',
          value: _keepScreenOn,
          onChanged: (b) {
            _keepScreenOn = b;
            var setting = widget.setting.copyWith(keepScreenOn: b);
            widget.onSettingChanged.call(setting);
            if (mounted) setState(() {});
          },
        ),
        _buildComboBox<int>(
          title: '预加载页数',
          width: 80,
          value: _preloadCount.clamp(0, 5),
          values: [0, 1, 2, 3, 4, 5],
          builder: (s) => Text(
            '$s页',
            style: Theme.of(context).textTheme.bodyText2,
          ),
          onChanged: (c) {
            _preloadCount = (c ?? 2).clamp(0, 5);
            var setting = widget.setting.copyWith(preloadCount: _preloadCount);
            widget.onSettingChanged.call(setting);
            if (mounted) setState(() {});
          },
        ),
      ],
    );
  }
}

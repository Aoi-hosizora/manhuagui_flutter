import 'package:flutter/material.dart';

/// 漫画章节浏览页-设置对话框
class ViewSetting {
  ViewSetting({
    required this.reverseScroll,
    required this.showPageHint,
    required this.useSwipeForChapter,
    required this.useClickForChapter,
    required this.needCheckForChapter,
    required this.enablePageSpace,
    required this.preloadCount,
  });

  final bool reverseScroll; // 反转拖动
  final bool showPageHint; // 显示页码提示
  final bool useSwipeForChapter; // 滑动跳转至章节
  final bool useClickForChapter; // 点击跳转至章节
  final bool needCheckForChapter; // 跳转章节时确认
  final bool enablePageSpace; // 显示页面间隔
  final int preloadCount; // 预加载页数

  ViewSetting.defaultSetting()
      : this(
          reverseScroll: false,
          showPageHint: true,
          useSwipeForChapter: true,
          useClickForChapter: true,
          needCheckForChapter: true,
          enablePageSpace: true,
          preloadCount: 2,
        );

  ViewSetting copyWith({
    bool? reverseScroll,
    bool? showPageHint,
    bool? useSwipeForChapter,
    bool? useClickForChapter,
    bool? needCheckForChapter,
    bool? enablePageSpace,
    int? preloadCount,
  }) {
    return ViewSetting(
      reverseScroll: reverseScroll ?? this.reverseScroll,
      showPageHint: showPageHint ?? this.showPageHint,
      useSwipeForChapter: useSwipeForChapter ?? this.useSwipeForChapter,
      useClickForChapter: useClickForChapter ?? this.useClickForChapter,
      needCheckForChapter: needCheckForChapter ?? this.needCheckForChapter,
      enablePageSpace: enablePageSpace ?? this.enablePageSpace,
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
  late bool _useSwipeForChapter = widget.setting.useSwipeForChapter;
  late bool _useClickForChapter = widget.setting.useClickForChapter;
  late bool _needCheckForChapter = widget.setting.needCheckForChapter;
  late bool _enablePageSpace = widget.setting.enablePageSpace;
  late int _preloadCount = widget.setting.preloadCount;

  Widget _buildCombo<T>({
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

  Widget _buildSlider({
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
        _buildCombo<bool>(
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
        _buildSlider(
          title: '显示页码',
          value: _showPageHint,
          onChanged: (b) {
            _showPageHint = b;
            var setting = widget.setting.copyWith(showPageHint: b);
            widget.onSettingChanged.call(setting);
            if (mounted) setState(() {});
          },
        ),
        _buildSlider(
          title: '滑动跳转至章节',
          value: _useSwipeForChapter,
          onChanged: (b) {
            _useSwipeForChapter = b;
            var setting = widget.setting.copyWith(useSwipeForChapter: b);
            widget.onSettingChanged.call(setting);
            if (mounted) setState(() {});
          },
        ),
        _buildSlider(
          title: '点击跳转至章节',
          value: _useClickForChapter,
          onChanged: (b) {
            _useClickForChapter = b;
            var setting = widget.setting.copyWith(useClickForChapter: b);
            widget.onSettingChanged.call(setting);
            if (mounted) setState(() {});
          },
        ),
        _buildSlider(
          title: '跳转章节时确认',
          value: _needCheckForChapter,
          onChanged: (b) {
            _needCheckForChapter = b;
            var setting = widget.setting.copyWith(needCheckForChapter: b);
            widget.onSettingChanged.call(setting);
            if (mounted) setState(() {});
          },
        ),
        _buildSlider(
          title: '显示页面间隔',
          value: _enablePageSpace,
          onChanged: (b) {
            _enablePageSpace = b;
            var setting = widget.setting.copyWith(enablePageSpace: b);
            widget.onSettingChanged.call(setting);
            if (mounted) setState(() {});
          },
        ),
        _buildCombo<int>(
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

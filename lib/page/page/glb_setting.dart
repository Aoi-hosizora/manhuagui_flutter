import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/page/log_console.dart';

/// 设置页-高级设置

class GlbSetting {
  const GlbSetting({
    required this.timeoutBehavior,
    required this.dlTimeoutBehavior,
    required this.enableLogger,
    required this.usingDownloadedPage,
  });

  final TimeoutBehavior timeoutBehavior; // 网络请求超时时间
  final TimeoutBehavior dlTimeoutBehavior; // 漫画下载超时时间
  final bool enableLogger; // 记录调试日志
  final bool usingDownloadedPage; // 阅读时载入已下载的页面

  GlbSetting.defaultSetting()
      : this(
          timeoutBehavior: TimeoutBehavior.normal,
          dlTimeoutBehavior: TimeoutBehavior.normal,
          enableLogger: false,
          usingDownloadedPage: true,
        );

  GlbSetting copyWith({
    TimeoutBehavior? timeoutBehavior,
    TimeoutBehavior? dlTimeoutBehavior,
    bool? enableLogger,
    bool? usingDownloadedPage,
  }) {
    return GlbSetting(
      timeoutBehavior: timeoutBehavior ?? this.timeoutBehavior,
      dlTimeoutBehavior: dlTimeoutBehavior ?? this.dlTimeoutBehavior,
      enableLogger: enableLogger ?? this.enableLogger,
      usingDownloadedPage: usingDownloadedPage ?? this.usingDownloadedPage,
    );
  }

  static GlbSetting global = GlbSetting.defaultSetting();

  static updateGlobalSetting(GlbSetting s) {
    global = s;
    if (!s.enableLogger) {
      LogConsolePage.finalize();
    } else if (!LogConsolePage.initialized) {
      LogConsolePage.initialize(globalLogger, bufferSize: 100);
      globalLogger.i('initialize LogConsolePage');
    }
  }
}

enum TimeoutBehavior {
  normal,
  long,
  disable,
}

extension TimeoutBehaviorExtension on TimeoutBehavior {
  int toInt() {
    if (this == TimeoutBehavior.normal) {
      return 0;
    }
    if (this == TimeoutBehavior.long) {
      return 1;
    }
    if (this == TimeoutBehavior.disable) {
      return 2;
    }
    return 0;
  }

  static TimeoutBehavior fromInt(int i) {
    if (i == 0) {
      return TimeoutBehavior.normal;
    }
    if (i == 1) {
      return TimeoutBehavior.long;
    }
    if (i == 2) {
      return TimeoutBehavior.disable;
    }
    return TimeoutBehavior.normal;
  }

  Duration? determineDuration({required Duration normal, required Duration long}) {
    if (this == TimeoutBehavior.normal) {
      return normal;
    }
    if (this == TimeoutBehavior.long) {
      return long;
    }
    if (this == TimeoutBehavior.disable) {
      return null;
    }
    return normal;
  }
}

class GlbSettingSubPage extends StatefulWidget {
  const GlbSettingSubPage({
    Key? key,
    required this.setting,
    required this.onSettingChanged,
  }) : super(key: key);

  final GlbSetting setting;
  final void Function(GlbSetting) onSettingChanged;

  @override
  State<GlbSettingSubPage> createState() => _GlbSettingSubPageState();
}

class _GlbSettingSubPageState extends State<GlbSettingSubPage> {
  late var _timeoutBehavior = widget.setting.timeoutBehavior;
  late var _dlTimeoutBehavior = widget.setting.dlTimeoutBehavior;
  late var _enableLogger = widget.setting.enableLogger;
  late var _usingDownloadedPage = widget.setting.usingDownloadedPage;

  GlbSetting get _newestSetting => GlbSetting(
        timeoutBehavior: _timeoutBehavior,
        dlTimeoutBehavior: _dlTimeoutBehavior,
        enableLogger: _enableLogger,
        usingDownloadedPage: _usingDownloadedPage,
      );

  Widget _buildComboBox<T>({
    required String title,
    double width = 120,
    required T value,
    required List<T> values,
    required Widget Function(T) builder,
    required void Function(T) onChanged,
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
            onChanged: (v) {
              if (v != null) {
                onChanged.call(v);
              }
            },
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
        _buildComboBox<TimeoutBehavior>(
          title: '网络请求超时时间　　　　',
          value: _timeoutBehavior,
          values: [TimeoutBehavior.normal, TimeoutBehavior.long, TimeoutBehavior.disable],
          builder: (s) => Text(
            s == TimeoutBehavior.normal ? '正常' : (s == TimeoutBehavior.long ? '较长' : '禁用'),
            style: Theme.of(context).textTheme.bodyText2,
          ),
          onChanged: (s) {
            _timeoutBehavior = s;
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        _buildComboBox<TimeoutBehavior>(
          title: '漫画下载超时时间',
          value: _dlTimeoutBehavior,
          values: [TimeoutBehavior.normal, TimeoutBehavior.long, TimeoutBehavior.disable],
          builder: (s) => Text(
            s == TimeoutBehavior.normal ? '正常' : (s == TimeoutBehavior.long ? '较长' : '禁用'),
            style: Theme.of(context).textTheme.bodyText2,
          ),
          onChanged: (s) {
            _dlTimeoutBehavior = s;
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        _buildSwitcher(
          title: '记录调试日志',
          value: _enableLogger,
          onChanged: (b) {
            _enableLogger = b;
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        _buildSwitcher(
          title: '阅读时载入已下载的页面',
          value: _usingDownloadedPage,
          onChanged: (b) {
            _usingDownloadedPage = b;
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
      ],
    );
  }
}

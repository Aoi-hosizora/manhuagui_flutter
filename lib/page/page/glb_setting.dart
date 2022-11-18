import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/page/log_console.dart';
import 'package:manhuagui_flutter/page/view/setting_dialog.dart';

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

class _GlbSettingSubPageState extends State<GlbSettingSubPage> with SettingSubPageStateMixin<GlbSetting, GlbSettingSubPage> {
  late var _timeoutBehavior = widget.setting.timeoutBehavior;
  late var _dlTimeoutBehavior = widget.setting.dlTimeoutBehavior;
  late var _enableLogger = widget.setting.enableLogger;
  late var _usingDownloadedPage = widget.setting.usingDownloadedPage;

  @override
  GlbSetting get newestSetting => GlbSetting(
        timeoutBehavior: _timeoutBehavior,
        dlTimeoutBehavior: _dlTimeoutBehavior,
        enableLogger: _enableLogger,
        usingDownloadedPage: _usingDownloadedPage,
      );

  @override
  List<Widget> get settingLines => [
        SettingComboBoxView<TimeoutBehavior>(
          title: '网络请求超时时间',
          hint: '当前设置对应的网络连接、发送请求、获取响应的超时时间为：' +
              (_timeoutBehavior == TimeoutBehavior.normal
                  ? '${CONNECT_TIMEOUT / 1000}s + ${SEND_TIMEOUT / 1000}s + ${RECEIVE_TIMEOUT / 1000}s'
                  : _timeoutBehavior == TimeoutBehavior.long
                      ? '${CONNECT_LTIMEOUT / 1000}s + ${SEND_LTIMEOUT / 1000}s + ${RECEIVE_LTIMEOUT / 1000}s'
                      : '无超时时间设置'),
          width: 75,
          value: _timeoutBehavior,
          values: const [TimeoutBehavior.normal, TimeoutBehavior.long, TimeoutBehavior.disable],
          builder: (s) => Text(
            s == TimeoutBehavior.normal ? '正常' : (s == TimeoutBehavior.long ? '较长' : '禁用'),
            style: Theme.of(context).textTheme.bodyText2,
          ),
          onChanged: (s) {
            _timeoutBehavior = s;
            widget.onSettingChanged.call(newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingComboBoxView<TimeoutBehavior>(
          title: '漫画下载超时时间',
          hint: '当前设置对应的漫画下载超时时间为：' +
              (_dlTimeoutBehavior == TimeoutBehavior.normal
                  ? '${DOWNLOAD_HEAD_TIMEOUT / 1000}s + ${DOWNLOAD_IMAGE_TIMEOUT / 1000}s'
                  : _timeoutBehavior == TimeoutBehavior.long
                      ? '${DOWNLOAD_HEAD_LTIMEOUT / 1000}s + ${DOWNLOAD_IMAGE_LTIMEOUT / 1000}s'
                      : '无超时时间设置'),
          width: 75,
          value: _dlTimeoutBehavior,
          values: const [TimeoutBehavior.normal, TimeoutBehavior.long, TimeoutBehavior.disable],
          builder: (s) => Text(
            s == TimeoutBehavior.normal ? '正常' : (s == TimeoutBehavior.long ? '较长' : '禁用'),
            style: Theme.of(context).textTheme.bodyText2,
          ),
          onChanged: (s) {
            _dlTimeoutBehavior = s;
            widget.onSettingChanged.call(newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: '记录调试日志',
          value: _enableLogger,
          onChanged: (b) {
            _enableLogger = b;
            widget.onSettingChanged.call(newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: '阅读时载入已下载的页面',
          hint: '部分安卓系统可能会因为文件访问权限的问题而出现无法阅读漫画的情况。\n\n若存在上述问题，请将此选项关闭，从而在阅读漫画时禁用文件访问。',
          value: _usingDownloadedPage,
          onChanged: (b) {
            _usingDownloadedPage = b;
            widget.onSettingChanged.call(newestSetting);
            if (mounted) setState(() {});
          },
        ),
      ];
}

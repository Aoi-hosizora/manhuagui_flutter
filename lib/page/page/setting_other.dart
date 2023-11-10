import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/app_setting.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/page/view/setting_view.dart';

/// 设置-其他设置，用于 [OtherSettingPage] / [showOtherSettingDialog]
class OtherSettingSubPage extends StatefulWidget {
  const OtherSettingSubPage({
    Key? key,
    required this.action,
    required this.setting,
    required this.style,
  }) : super(key: key);

  final ActionController action;
  final OtherSetting setting;
  final SettingViewStyle style;

  @override
  State<OtherSettingSubPage> createState() => _OtherSettingSubPageState();
}

class _OtherSettingSubPageState extends State<OtherSettingSubPage> {
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

  late var _timeoutBehavior = widget.setting.timeoutBehavior;
  late var _dlTimeoutBehavior = widget.setting.dlTimeoutBehavior;
  late var _imgTimeoutBehavior = widget.setting.imgTimeoutBehavior;
  late var _enableLogger = widget.setting.enableLogger;
  late var _showDebugErrorMsg = widget.setting.showDebugErrorMsg;
  late var _useNativeShareSheet = widget.setting.useNativeShareSheet;
  late var _useHttpForImage = widget.setting.useHttpForImage;
  late var _useEmulatedLongScreenshot = widget.setting.useEmulatedLongScreenshot;

  OtherSetting get _newestSetting => OtherSetting(
        timeoutBehavior: _timeoutBehavior,
        dlTimeoutBehavior: _dlTimeoutBehavior,
        imgTimeoutBehavior: _imgTimeoutBehavior,
        enableLogger: _enableLogger,
        showDebugErrorMsg: _showDebugErrorMsg,
        useNativeShareSheet: _useNativeShareSheet,
        useHttpForImage: _useHttpForImage,
        useEmulatedLongScreenshot: _useEmulatedLongScreenshot,
      );

  void _setToDefault() {
    var setting = OtherSetting.defaultSetting;
    _timeoutBehavior = setting.timeoutBehavior;
    _dlTimeoutBehavior = setting.dlTimeoutBehavior;
    _imgTimeoutBehavior = setting.imgTimeoutBehavior;
    _enableLogger = setting.enableLogger;
    _showDebugErrorMsg = setting.showDebugErrorMsg;
    _useNativeShareSheet = setting.useNativeShareSheet;
    _useHttpForImage = setting.useHttpForImage;
    _useEmulatedLongScreenshot = setting.useEmulatedLongScreenshot;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var map = <String, List<Widget>>{
      '列表显示设置': [
        SettingComboBoxView<TimeoutBehavior>(
          style: widget.style,
          title: '网络请求超时时间',
          hint: '当前设置对应的网络连接、发送请求、获取响应的超时时间为：' + //
              (_timeoutBehavior.determineValue(
                    normal: [CONNECT_TIMEOUT, SEND_TIMEOUT, RECEIVE_TIMEOUT],
                    long: [CONNECT_LTIMEOUT, SEND_LTIMEOUT, RECEIVE_LTIMEOUT],
                    longLong: [CONNECT_LLTIMEOUT, SEND_LLTIMEOUT, RECEIVE_LLTIMEOUT],
                  )?.let((l) => '${l[0] / 1000}s + ${l[1] / 1000}s + ${l[2] / 1000}s') ??
                  '无超时时间设置'),
          width: 75,
          value: _timeoutBehavior,
          values: const [TimeoutBehavior.normal, TimeoutBehavior.long, TimeoutBehavior.longLong, TimeoutBehavior.disable],
          textBuilder: (s) => s.toOptionTitle(),
          onChanged: (s) {
            _timeoutBehavior = s;
            if (mounted) setState(() {});
          },
        ),
        SettingComboBoxView<TimeoutBehavior>(
          style: widget.style,
          title: '漫画下载超时时间',
          hint: '当前设置对应的漫画下载超时时间为：' + //
              (_dlTimeoutBehavior.determineValue(
                    normal: [DOWNLOAD_HEAD_TIMEOUT, DOWNLOAD_IMAGE_TIMEOUT],
                    long: [DOWNLOAD_HEAD_LTIMEOUT, DOWNLOAD_IMAGE_LTIMEOUT],
                    longLong: [DOWNLOAD_HEAD_LLTIMEOUT, DOWNLOAD_IMAGE_LLTIMEOUT],
                  )?.let((l) => '${l[0] / 1000}s + ${l[1] / 1000}s') ??
                  '无超时时间设置'),
          width: 75,
          value: _dlTimeoutBehavior,
          values: const [TimeoutBehavior.normal, TimeoutBehavior.long, TimeoutBehavior.longLong, TimeoutBehavior.disable],
          textBuilder: (s) => s.toOptionTitle(),
          onChanged: (s) {
            _dlTimeoutBehavior = s;
            if (mounted) setState(() {});
          },
        ),
        SettingComboBoxView<TimeoutBehavior>(
          style: widget.style,
          title: '图片浏览超时时间',
          hint: '当前设置对应的图片浏览 (即浏览章节页面) 超时时间为：' + //
              (_imgTimeoutBehavior
                      .determineValue(
                        normal: GALLERY_IMAGE_TIMEOUT,
                        long: GALLERY_IMAGE_LTIMEOUT,
                        longLong: GALLERY_IMAGE_LLTIMEOUT,
                      )
                      ?.let((l) => '${l / 1000}s') ??
                  '无超时时间设置'),
          width: 75,
          value: _imgTimeoutBehavior,
          values: const [TimeoutBehavior.normal, TimeoutBehavior.long, TimeoutBehavior.longLong, TimeoutBehavior.disable],
          textBuilder: (s) => s.toOptionTitle(),
          onChanged: (s) {
            _imgTimeoutBehavior = s;
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          style: widget.style,
          title: '记录调试日志',
          hint: '启用该选项会在出现网络异常等错误时记录日志，可在【设置-查看调试日志】查看，目前应用最多仅保留 $LOG_CONSOLE_BUFFER 条调试日志。',
          value: _enableLogger,
          onChanged: (b) {
            _enableLogger = b;
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          style: widget.style,
          title: '使用更详细的错误信息',
          hint: '该选项所指的更详细的错误信息包括 "未格式化的异常信息" 以及 "出错的源代码信息"。\n\n'
              '此外，一些 "服务器错误" 会附带错误细节，可以在调试日志中的 "WrapError" 块内查看。',
          value: _showDebugErrorMsg,
          onChanged: (b) {
            _showDebugErrorMsg = b;
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          style: widget.style,
          title: '使用原生的分享菜单',
          hint: '该选项仅针对第三方安卓ROM。由于部分安卓系统不支持手动启用或禁用原生的分享菜单，所以该选项在一些系统中可能不起作用。',
          value: _useNativeShareSheet,
          onChanged: (b) {
            _useNativeShareSheet = b;
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          style: widget.style,
          title: '禁用HTTPS加载图片',
          hint: '较低版本的 Android 系统可能无法正常访问漫画柜的图片，如果在阅读漫画时出现 HTTPS error (certificate has expired) 错误，请启用该选项。',
          value: _useHttpForImage,
          onChanged: (b) {
            _useHttpForImage = b;
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          style: widget.style,
          title: '开启模拟的长截图功能',
          hint: '本应用在一些安卓设备上可能不支持原生的长截图功能，可以通过开启该选项来解决这个问题，但注意该功能可能会降低列表的显示性能。',
          value: _useEmulatedLongScreenshot,
          onChanged: (b) {
            _useEmulatedLongScreenshot = b;
            if (mounted) setState(() {});
          },
        ),
      ],
    };

    var children = <Widget>[];
    for (var key in map.keys) {
      children.addAll(
        widget.style == SettingViewStyle.line //
            ? map[key]!
            : map[key]!.separate(SettingDividerView()),
      );
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
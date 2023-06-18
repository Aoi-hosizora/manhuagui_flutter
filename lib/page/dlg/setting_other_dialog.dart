import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/app_setting.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/page/view/setting_dialog.dart';
import 'package:manhuagui_flutter/service/prefs/app_setting.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

/// 设置页-其他设置 [showOtherSettingDialog], [OtherSettingSubPage]

class OtherSettingSubPage extends StatefulWidget {
  const OtherSettingSubPage({
    Key? key,
    required this.action,
    required this.setting,
    required this.onSettingChanged,
  }) : super(key: key);

  final ActionController action;
  final OtherSetting setting;
  final void Function(OtherSetting) onSettingChanged;

  @override
  State<OtherSettingSubPage> createState() => _OtherSettingSubPageState();
}

class _OtherSettingSubPageState extends State<OtherSettingSubPage> {
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

  late var _timeoutBehavior = widget.setting.timeoutBehavior;
  late var _dlTimeoutBehavior = widget.setting.dlTimeoutBehavior;
  late var _imgTimeoutBehavior = widget.setting.imgTimeoutBehavior;
  late var _enableLogger = widget.setting.enableLogger;
  late var _showDebugErrorMsg = widget.setting.showDebugErrorMsg;
  late var _useNativeShareSheet = widget.setting.useNativeShareSheet;
  late var _useHttpForImage = widget.setting.useHttpForImage;

  OtherSetting get _newestSetting => OtherSetting(
        timeoutBehavior: _timeoutBehavior,
        dlTimeoutBehavior: _dlTimeoutBehavior,
        imgTimeoutBehavior: _imgTimeoutBehavior,
        enableLogger: _enableLogger,
        showDebugErrorMsg: _showDebugErrorMsg,
        useNativeShareSheet: _useNativeShareSheet,
        useHttpForImage: _useHttpForImage,
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
    widget.onSettingChanged.call(_newestSetting);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SettingDialogView(
      children: [
        SettingComboBoxView<TimeoutBehavior>(
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
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingComboBoxView<TimeoutBehavior>(
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
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingComboBoxView<TimeoutBehavior>(
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
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: '记录调试日志',
          hint: '启用该选项会在出现网络异常等错误时记录日志，可在【设置-查看调试日志】查看，目前应用最多仅保留 $LOG_CONSOLE_BUFFER 条调试日志。',
          value: _enableLogger,
          onChanged: (b) {
            _enableLogger = b;
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: '使用更详细的错误信息',
          hint: '该选项所指的更详细的错误信息包括 "未格式化的异常信息" 以及 "出错的源代码信息"。\n\n'
              '此外，一些 "服务器错误" 会附带错误细节，可以在调试日志中的 "WrapError" 块内查看。',
          value: _showDebugErrorMsg,
          onChanged: (b) {
            _showDebugErrorMsg = b;
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: '使用原生的分享菜单',
          hint: '该选项仅针对第三方安卓ROM。由于部分安卓系统不支持手动启用或禁用原生的分享菜单，所以该选项在一些系统中可能不起作用。',
          value: _useNativeShareSheet,
          onChanged: (b) {
            _useNativeShareSheet = b;
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: '禁用HTTPS加载图片',
          hint: '较低版本的 Android 系统可能无法正常访问漫画柜的图片，如果在阅读漫画时出现 HTTPS error (certificate has expired) 错误，请启用该选项。',
          value: _useHttpForImage,
          onChanged: (b) {
            _useHttpForImage = b;
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
      ],
    );
  }
}

Future<bool> showOtherSettingDialog({required BuildContext context}) async {
  var action = ActionController();
  var setting = AppSetting.instance.other;
  var ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: IconText(
        icon: Icon(MdiIcons.cogs, size: 26),
        text: Text('其他设置'),
        space: 12,
      ),
      scrollable: true,
      content: OtherSettingSubPage(
        action: action,
        setting: setting,
        onSettingChanged: (s) => setting = s,
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          child: Text('恢复默认'),
          onPressed: () => action.invoke(),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              child: Text('确定'),
              onPressed: () async {
                AppSetting.instance.update(other: setting, alsoFireEvent: true);
                await AppSettingPrefs.saveOtherSetting();
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

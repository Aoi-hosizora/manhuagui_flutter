import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/model/app_setting.dart';
import 'package:manhuagui_flutter/model/order.dart';
import 'package:manhuagui_flutter/page/view/setting_dialog.dart';
import 'package:manhuagui_flutter/service/prefs/app_setting.dart';

/// 设置页-其他设置
class OtherSettingSubPage extends StatefulWidget {
  const OtherSettingSubPage({
    Key? key,
    required this.setting,
    required this.onSettingChanged,
  }) : super(key: key);

  final OtherSetting setting;
  final void Function(OtherSetting) onSettingChanged;

  @override
  State<OtherSettingSubPage> createState() => _OtherSettingSubPageState();
}

class _OtherSettingSubPageState extends State<OtherSettingSubPage> {
  late var _timeoutBehavior = widget.setting.timeoutBehavior;
  late var _dlTimeoutBehavior = widget.setting.dlTimeoutBehavior;
  late var _enableLogger = widget.setting.enableLogger;
  late var _usingDownloadedPage = widget.setting.usingDownloadedPage;
  late var _defaultMangaOrder = widget.setting.defaultMangaOrder;
  late var _defaultAuthorOrder = widget.setting.defaultAuthorOrder;

  OtherSetting get newestSetting => OtherSetting(
        timeoutBehavior: _timeoutBehavior,
        dlTimeoutBehavior: _dlTimeoutBehavior,
        enableLogger: _enableLogger,
        usingDownloadedPage: _usingDownloadedPage,
        defaultMangaOrder: _defaultMangaOrder,
        defaultAuthorOrder: _defaultAuthorOrder,
      );

  @override
  Widget build(BuildContext context) {
    return SettingSubPage(
      children: [
        SettingComboBoxView<TimeoutBehavior>(
          title: '网络请求超时时间',
          hint: '当前设置对应的网络连接、发送请求、获取响应的超时时间为：' + //
              (_timeoutBehavior.determineValue(normal: [CONNECT_TIMEOUT, SEND_TIMEOUT, RECEIVE_TIMEOUT], long: [CONNECT_LTIMEOUT, SEND_LTIMEOUT, RECEIVE_LTIMEOUT])?.let((l) => //
                  '${l[0] / 1000}s + ${l[1] / 1000}s + ${l[2] / 1000}s') ?? '无超时时间设置'),
          width: 75,
          value: _timeoutBehavior,
          values: const [TimeoutBehavior.normal, TimeoutBehavior.long, TimeoutBehavior.disable],
          builder: (s) => Text(s.toOptionTitle()),
          onChanged: (s) {
            _timeoutBehavior = s;
            widget.onSettingChanged.call(newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingComboBoxView<TimeoutBehavior>(
          title: '漫画下载超时时间',
          hint: '当前设置对应的漫画下载超时时间为：' + //
              (_timeoutBehavior.determineValue(normal: [DOWNLOAD_HEAD_TIMEOUT, DOWNLOAD_IMAGE_TIMEOUT], long: [DOWNLOAD_HEAD_LTIMEOUT, DOWNLOAD_IMAGE_LTIMEOUT])?.let((l) => //
                  '${l[0] / 1000}s + ${l[1] / 1000}s') ?? '无超时时间设置'),
          width: 75,
          value: _dlTimeoutBehavior,
          values: const [TimeoutBehavior.normal, TimeoutBehavior.long, TimeoutBehavior.disable],
          builder: (s) => Text(s.toOptionTitle()),
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
        SettingComboBoxView<MangaOrder>(
          title: '漫画默认排序方式',
          value: _defaultMangaOrder,
          values: const [MangaOrder.byPopular, MangaOrder.byNew, MangaOrder.byUpdate],
          builder: (s) => Text(s.toTitle()),
          onChanged: (s) {
            _defaultMangaOrder = s;
            widget.onSettingChanged.call(newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingComboBoxView<AuthorOrder>(
          title: '漫画作者默认排序方式',
          value: _defaultAuthorOrder,
          values: const [AuthorOrder.byPopular, AuthorOrder.byComic, AuthorOrder.byNew],
          builder: (s) => Text(s.toTitle()),
          onChanged: (s) {
            _defaultAuthorOrder = s;
            widget.onSettingChanged.call(newestSetting);
            if (mounted) setState(() {});
          },
        ),
      ],
    );
  }
}

Future<bool> showOtherSettingDialog({required BuildContext context}) async {
  var setting = AppSetting.instance.other;
  var ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text('其他设置'),
      scrollable: true,
      content: OtherSettingSubPage(
        setting: setting,
        onSettingChanged: (s) => setting = s,
      ),
      actions: [
        TextButton(
          child: Text('确定'),
          onPressed: () async {
            AppSetting.instance.update(other: setting);
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
  );
  return ok ?? false;
}

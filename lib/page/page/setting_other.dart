import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/model/app_setting.dart';
import 'package:manhuagui_flutter/model/order.dart';
import 'package:manhuagui_flutter/page/view/setting_dialog.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
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
  late var _clickToSearch = widget.setting.clickToSearch;
  late var _enableCornerIcons = widget.setting.enableCornerIcons;
  late var _regularGroupRows = widget.setting.regularGroupRows;
  late var _otherGroupRows = widget.setting.otherGroupRows;

  OtherSetting get _newestSetting => OtherSetting(
        timeoutBehavior: _timeoutBehavior,
        dlTimeoutBehavior: _dlTimeoutBehavior,
        enableLogger: _enableLogger,
        usingDownloadedPage: _usingDownloadedPage,
        defaultMangaOrder: _defaultMangaOrder,
        defaultAuthorOrder: _defaultAuthorOrder,
        clickToSearch: _clickToSearch,
        enableCornerIcons: _enableCornerIcons,
        regularGroupRows: _regularGroupRows,
        otherGroupRows: _otherGroupRows,
      );

  @override
  Widget build(BuildContext context) {
    return SettingDialogView(
      children: [
        SettingComboBoxView<TimeoutBehavior>(
          title: '网络请求超时时间',
          hint: '当前设置对应的网络连接、发送请求、获取响应的超时时间为：' + //
              (_timeoutBehavior.determineValue(normal: [CONNECT_TIMEOUT, SEND_TIMEOUT, RECEIVE_TIMEOUT], long: [CONNECT_LTIMEOUT, SEND_LTIMEOUT, RECEIVE_LTIMEOUT])?.let((l) => //
                  '${l[0] / 1000}s + ${l[1] / 1000}s + ${l[2] / 1000}s') ?? '无超时时间设置'),
          width: 75,
          value: _timeoutBehavior,
          values: const [TimeoutBehavior.normal, TimeoutBehavior.long, TimeoutBehavior.disable],
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
              (_dlTimeoutBehavior.determineValue(normal: [DOWNLOAD_HEAD_TIMEOUT, DOWNLOAD_IMAGE_TIMEOUT], long: [DOWNLOAD_HEAD_LTIMEOUT, DOWNLOAD_IMAGE_LTIMEOUT])?.let((l) => //
                  '${l[0] / 1000}s + ${l[1] / 1000}s') ?? '无超时时间设置'),
          width: 75,
          value: _dlTimeoutBehavior,
          values: const [TimeoutBehavior.normal, TimeoutBehavior.long, TimeoutBehavior.disable],
          textBuilder: (s) => s.toOptionTitle(),
          onChanged: (s) {
            _dlTimeoutBehavior = s;
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: '记录调试日志',
          value: _enableLogger,
          onChanged: (b) {
            _enableLogger = b;
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: '阅读时载入已下载的页面',
          hint: '部分安卓系统可能会因为文件访问权限的问题而出现无法阅读漫画的情况。\n\n若存在上述问题，请将此选项关闭，从而在阅读漫画时禁用文件访问。',
          value: _usingDownloadedPage,
          onChanged: (b) {
            _usingDownloadedPage = b;
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingComboBoxView<MangaOrder>(
          title: '漫画默认排序方式',
          value: _defaultMangaOrder,
          values: const [MangaOrder.byPopular, MangaOrder.byNew, MangaOrder.byUpdate],
          textBuilder: (s) => s.toTitle(),
          onChanged: (s) {
            _defaultMangaOrder = s;
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingComboBoxView<AuthorOrder>(
          title: '漫画作者默认排序方式',
          value: _defaultAuthorOrder,
          values: const [AuthorOrder.byPopular, AuthorOrder.byComic, AuthorOrder.byNew],
          textBuilder: (s) => s.toTitle(),
          onChanged: (s) {
            _defaultAuthorOrder = s;
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: '点击搜索历史执行搜索',
          value: _clickToSearch,
          onChanged: (b) {
            _clickToSearch = b;
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: '列表显示右下角图标',
          hint: '漫画列表右下角图标有："在下载列表中"、"在我的书架上"、"在本地收藏中"、"已被阅读或浏览"，其中书架信息源自于本地同步的书架记录。\n\n漫画作者列表右下角图标仅有："在本地收藏中"。',
          value: _enableCornerIcons,
          onChanged: (b) {
            _enableCornerIcons = b;
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingComboBoxView<int>(
          title: '单话分组章节显示行数',
          width: 75,
          value: _regularGroupRows.clamp(1, 8),
          values: const [1, 2, 3, 4, 5, 6, 7, 8],
          textBuilder: (s) => '$s行',
          onChanged: (c) {
            _regularGroupRows = c.clamp(1, 8);
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingComboBoxView<int>(
          title: '其他分组章节显示行数',
          width: 75,
          value: _otherGroupRows.clamp(1, 5),
          values: const [1, 2, 3, 4, 5],
          textBuilder: (s) => '$s行',
          onChanged: (c) {
            _otherGroupRows = c.clamp(1, 5);
            widget.onSettingChanged.call(_newestSetting);
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
            EventBusManager.instance.fire(AppSettingChangedEvent());
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

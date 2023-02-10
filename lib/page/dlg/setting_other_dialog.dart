import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/model/app_setting.dart';
import 'package:manhuagui_flutter/model/order.dart';
import 'package:manhuagui_flutter/page/view/setting_dialog.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
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
  late var _enableLogger = widget.setting.enableLogger;
  late var _showDebugErrorMsg = widget.setting.showDebugErrorMsg;
  late var _useNativeShareSheet = widget.setting.useNativeShareSheet;
  late var _usingDownloadedPage = widget.setting.usingDownloadedPage;
  late var _defaultMangaOrder = widget.setting.defaultMangaOrder;
  late var _defaultAuthorOrder = widget.setting.defaultAuthorOrder;
  late var _clickToSearch = widget.setting.clickToSearch;
  late var _enableCornerIcons = widget.setting.enableCornerIcons;
  late var _showMangaReadIcon = widget.setting.showMangaReadIcon;
  late var _regularGroupRows = widget.setting.regularGroupRows;
  late var _otherGroupRows = widget.setting.otherGroupRows;
  late var _useLocalDataInShelf = widget.setting.useLocalDataInShelf;
  late var _includeUnreadInHome = widget.setting.includeUnreadInHome;

  OtherSetting get _newestSetting => OtherSetting(
        timeoutBehavior: _timeoutBehavior,
        dlTimeoutBehavior: _dlTimeoutBehavior,
        enableLogger: _enableLogger,
        showDebugErrorMsg: _showDebugErrorMsg,
        useNativeShareSheet: _useNativeShareSheet,
        usingDownloadedPage: _usingDownloadedPage,
        defaultMangaOrder: _defaultMangaOrder,
        defaultAuthorOrder: _defaultAuthorOrder,
        clickToSearch: _clickToSearch,
        enableCornerIcons: _enableCornerIcons,
        showMangaReadIcon: _showMangaReadIcon,
        regularGroupRows: _regularGroupRows,
        otherGroupRows: _otherGroupRows,
        useLocalDataInShelf: _useLocalDataInShelf,
        includeUnreadInHome: _includeUnreadInHome,
      );

  void _setToDefault() {
    var setting = OtherSetting.defaultSetting;
    _timeoutBehavior = setting.timeoutBehavior;
    _dlTimeoutBehavior = setting.dlTimeoutBehavior;
    _enableLogger = setting.enableLogger;
    _showDebugErrorMsg = setting.showDebugErrorMsg;
    _useNativeShareSheet = setting.useNativeShareSheet;
    _usingDownloadedPage = setting.usingDownloadedPage;
    _defaultMangaOrder = setting.defaultMangaOrder;
    _defaultAuthorOrder = setting.defaultAuthorOrder;
    _clickToSearch = setting.clickToSearch;
    _enableCornerIcons = setting.enableCornerIcons;
    _showMangaReadIcon = setting.showMangaReadIcon;
    _regularGroupRows = setting.regularGroupRows;
    _otherGroupRows = setting.otherGroupRows;
    _useLocalDataInShelf = setting.useLocalDataInShelf;
    _includeUnreadInHome = setting.includeUnreadInHome;
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
          title: '显示更详细的错误信息',
          hint: '该选项所指的更详细的错误信息包括 "未格式化的异常信息" 以及 "首个有效的 trace frame 信息"。\n\n'
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
          title: '列表内显示右下角图标',
          hint: '该选项影响漫画列表与漫画作者列表，其中：\n\n'
              '1. 漫画列表右下角图标含义分别为："在下载列表中"、"在我的书架上"、"在本地收藏中"、"已被阅读或浏览"；\n'
              '2. 漫画作者列表右下角图标含义为："在本地收藏中"。\n\n'
              '提示：上述信息都来源于本地记录或同步的数据，显示这些图标并不会增加网络请求次数。',
          value: _enableCornerIcons,
          onChanged: (b) {
            _enableCornerIcons = b;
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: '漫画列表内显示阅读图标',
          value: _showMangaReadIcon,
          enable: _enableCornerIcons,
          onChanged: (b) {
            _showMangaReadIcon = b;
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
        SettingSwitcherView(
          title: '书架上显示本地阅读历史',
          hint: '该选项默认关闭，即书架上默认显示在线的阅读记录 (跨设备同步)，开启该选项可使得书架上显示本地的阅读记录 (跨设备不同步)。',
          value: _useLocalDataInShelf,
          onChanged: (b) {
            _useLocalDataInShelf = b;
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: '首页历史显示未阅读漫画',
          value: _includeUnreadInHome,
          onChanged: (b) {
            _includeUnreadInHome = b;
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
      ],
    ),
  );
  return ok ?? false;
}
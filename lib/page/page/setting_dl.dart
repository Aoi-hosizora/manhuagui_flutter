import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/app_setting.dart';
import 'package:manhuagui_flutter/page/view/setting_view.dart';
import 'package:manhuagui_flutter/service/native/android.dart';
import 'package:manhuagui_flutter/service/native/clipboard.dart';
import 'package:manhuagui_flutter/service/storage/download.dart';

/// 设置-漫画下载设置，用于 [DlSettingPage] / [showDlSettingDialog]
class DlSettingSubPage extends StatefulWidget {
  const DlSettingSubPage({
    Key? key,
    required this.action,
    required this.setting,
    required this.style,
  }) : super(key: key);

  final ActionController action;
  final DlSetting setting;
  final SettingViewStyle style;

  @override
  State<DlSettingSubPage> createState() => _DlSettingSubPageState();
}

class _DlSettingSubPageState extends State<DlSettingSubPage> {
  bool? _lowerThanAndroidR;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      _lowerThanAndroidR = await lowerThanAndroidR();
      if (mounted) setState(() {});
    });
    widget.action.addAction(() => _newestSetting);
    widget.action.addAction('default', _setToDefault);
  }

  @override
  void dispose() {
    widget.action.removeAction();
    widget.action.removeAction('default');
    super.dispose();
  }

  late var _invertDownloadOrder = widget.setting.invertDownloadOrder;
  late var _defaultToDeleteFiles = widget.setting.defaultToDeleteFiles;
  late var _downloadPagesTogether = widget.setting.downloadPagesTogether;
  late var _defaultToOnlineMode = widget.setting.defaultToOnlineMode;
  late var _usingDownloadedPage = widget.setting.usingDownloadedPage;

  DlSetting get _newestSetting => DlSetting(
        invertDownloadOrder: _invertDownloadOrder,
        defaultToDeleteFiles: _defaultToDeleteFiles,
        downloadPagesTogether: _downloadPagesTogether,
        defaultToOnlineMode: _defaultToOnlineMode,
        usingDownloadedPage: _usingDownloadedPage,
      );

  void _setToDefault() {
    var setting = DlSetting.defaultSetting;
    _invertDownloadOrder = setting.invertDownloadOrder;
    _defaultToDeleteFiles = setting.defaultToDeleteFiles;
    _downloadPagesTogether = setting.downloadPagesTogether;
    _defaultToOnlineMode = setting.defaultToOnlineMode;
    _usingDownloadedPage = setting.usingDownloadedPage;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var map = <String, List<Widget>>{
      '': [
        SettingComboBoxView<bool>(
          style: widget.style,
          title: '漫画章节下载顺序',
          value: _invertDownloadOrder,
          values: const [false, true],
          textBuilder: (s) => !s ? '正序 (旧到新)' : '逆序 (新到旧)',
          onChanged: (c) {
            _invertDownloadOrder = c;
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          style: widget.style,
          title: '默认删除已下载的文件',
          value: _defaultToDeleteFiles,
          onChanged: (b) {
            _defaultToDeleteFiles = b;
            if (mounted) setState(() {});
          },
        ),
        SettingComboBoxView<int>(
          style: widget.style,
          title: '同时下载的页面数量',
          hint: '本应用为第三方漫画柜客户端，请不要同时下载过多页面，避免因短时间内的频繁访问而导致当前IP被漫画柜封禁。',
          width: 75,
          value: _downloadPagesTogether.clamp(1, 6),
          values: const [1, 2, 3, 4, 5, 6],
          textBuilder: (s) => '$s页',
          onChanged: (c) {
            _downloadPagesTogether = c.clamp(1, 6);
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          style: widget.style,
          title: '默认以在线模式阅读',
          hint: '从下载列表中阅读章节时，若使用"在线模式"则会通过网络在线获取最新的章节数据，若使用"离线模式"则会使用下载时保存的章节数据。',
          value: _defaultToOnlineMode,
          onChanged: (b) {
            _defaultToOnlineMode = b;
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          style: widget.style,
          title: '在线阅读载入已下载页面',
          hint: '处于在线模式阅读已下载的章节时，部分安卓系统可能会因没有文件访问权限而出现无法阅读漫画的问题。\n\n若存在该问题，请将此选项关闭，从而在阅读漫画时禁止载入已下载的页面文件。',
          value: _usingDownloadedPage,
          onChanged: (b) {
            _usingDownloadedPage = b;
            if (mounted) setState(() {});
          },
        ),
        SettingButtonView(
          style: widget.style,
          title: '漫画下载存储路径',
          hint: _lowerThanAndroidR == null || _lowerThanAndroidR == true
              ? null //
              : '当前设备搭载着 Android 11 或以上版本的系统。\n\n由于 Android 系统限制，漫画将被下载至应用私有沙盒存储中。若需要在卸载本应用时保留已下载的漫画，请选择保留本应用的数据。',
          child: Text('查看'),
          onPressed: () async {
            var directoryPath = await getDownloadedMangaDirectoryPath();
            if (directoryPath == null) {
              Fluttertoast.showToast(msg: '无法打开漫画下载的存储路径');
            } else {
              showDialog(
                context: context,
                builder: (c) => AlertDialog(
                  title: Text('漫画下载存储路径'),
                  content: SelectableText(directoryPath),
                  actions: [
                    TextButton(
                      child: Text('复制'),
                      onPressed: () => copyText(directoryPath, showToast: true),
                    ),
                    TextButton(
                      child: Text('关闭'),
                      onPressed: () => Navigator.of(c).pop(),
                    ),
                  ],
                ),
              );
            }
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

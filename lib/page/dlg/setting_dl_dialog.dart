import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/app_setting.dart';
import 'package:manhuagui_flutter/page/view/custom_icons.dart';
import 'package:manhuagui_flutter/page/view/setting_line.dart';
import 'package:manhuagui_flutter/service/native/android.dart';
import 'package:manhuagui_flutter/service/native/clipboard.dart';
import 'package:manhuagui_flutter/service/prefs/app_setting.dart';
import 'package:manhuagui_flutter/service/storage/download.dart';

/// 设置页-下载设置 [showDlSettingDialog], [DlSettingSubPage]

class DlSettingSubPage extends StatefulWidget {
  const DlSettingSubPage({
    Key? key,
    required this.action,
    required this.setting,
  }) : super(key: key);

  final ActionController action;
  final DlSetting setting;

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
    return SettingDialogView(
      children: [
        SettingComboBoxView<bool>(
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
          title: '默认删除已下载的文件',
          value: _defaultToDeleteFiles,
          onChanged: (b) {
            _defaultToDeleteFiles = b;
            if (mounted) setState(() {});
          },
        ),
        SettingComboBoxView<int>(
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
          title: '默认以在线模式阅读',
          hint: '从下载列表中阅读章节时，若使用"在线模式"则会通过网络在线获取最新的章节数据，若使用"离线模式"则会使用下载时保存的章节数据。',
          value: _defaultToOnlineMode,
          onChanged: (b) {
            _defaultToOnlineMode = b;
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: '在线阅读载入已下载页面',
          hint: '处于在线模式阅读已下载的章节时，部分安卓系统可能会因没有文件访问权限而出现无法阅读漫画的问题。\n\n若存在该问题，请将此选项关闭，从而在阅读漫画时禁止载入已下载的页面文件。',
          value: _usingDownloadedPage,
          onChanged: (b) {
            _usingDownloadedPage = b;
            if (mounted) setState(() {});
          },
        ),
        SettingButtonView(
          title: '漫画下载存储路径',
          hint: _lowerThanAndroidR == null || _lowerThanAndroidR == true
              ? null //
              : '当前设备搭载着 Android 11 或以上版本的系统。\n\n由于 Android 系统限制，漫画将被下载至应用私有沙盒存储中。若需要在卸载本应用时保留已下载的漫画，请选择保留本应用的数据。',
          buttonChild: Text('查看'),
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
    );
  }
}

Future<bool> showDlSettingDialog({required BuildContext context}) async {
  var action = ActionController();
  var ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: IconText(
        icon: Icon(CustomIcons.download_cog, size: 26),
        text: Text('漫画下载设置'),
        space: 12,
      ),
      scrollable: true,
      content: DlSettingSubPage(
        action: action,
        setting: AppSetting.instance.dl,
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
                var setting = action.invoke<DlSetting>();
                if (setting != null) {
                  AppSetting.instance.update(dl: setting, alsoFireEvent: true);
                  await AppSettingPrefs.saveDlSetting();
                  Navigator.of(c).pop(true);
                }
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

Future<void> updateDlSettingDefaultToDeleteFiles(bool alsoDeleteFile) async {
  var setting = AppSetting.instance.dl;
  var newSetting = setting.copyWith(defaultToDeleteFiles: alsoDeleteFile);
  AppSetting.instance.update(dl: newSetting, alsoFireEvent: true);
  await AppSettingPrefs.saveDlSetting();
}

Future<void> updateDlSettingDefaultToOnlineMode(bool onlineMode) async {
  var setting = AppSetting.instance.dl;
  var newSetting = setting.copyWith(defaultToOnlineMode: onlineMode);
  AppSetting.instance.update(dl: newSetting, alsoFireEvent: true);
  await AppSettingPrefs.saveDlSetting();
}

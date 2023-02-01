import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/app_setting.dart';
import 'package:manhuagui_flutter/page/view/setting_dialog.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:manhuagui_flutter/service/native/android.dart';
import 'package:manhuagui_flutter/service/native/clipboard.dart';
import 'package:manhuagui_flutter/service/prefs/app_setting.dart';
import 'package:manhuagui_flutter/service/storage/download.dart';

/// 下载列表页-下载设置
class DlSettingSubPage extends StatefulWidget {
  const DlSettingSubPage({
    Key? key,
    required this.setting,
    required this.onSettingChanged,
  }) : super(key: key);

  final DlSetting setting;
  final void Function(DlSetting) onSettingChanged;

  @override
  State<DlSettingSubPage> createState() => _DlSettingSubPageState();
}

class _DlSettingSubPageState extends State<DlSettingSubPage> {
  late var _invertDownloadOrder = widget.setting.invertDownloadOrder;
  late var _defaultToDeleteFiles = widget.setting.defaultToDeleteFiles;
  late var _downloadPagesTogether = widget.setting.downloadPagesTogether;
  late var _defaultToOnlineMode = widget.setting.defaultToOnlineMode;

  DlSetting get _newestSetting => DlSetting(
        invertDownloadOrder: _invertDownloadOrder,
        defaultToDeleteFiles: _defaultToDeleteFiles,
        downloadPagesTogether: _downloadPagesTogether,
        defaultToOnlineMode: _defaultToOnlineMode,
      );

  bool? _lowerThanAndroidR;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      _lowerThanAndroidR = await lowerThanAndroidR();
      if (mounted) setState(() {});
    });
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
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: '默认删除已下载的文件',
          value: _defaultToDeleteFiles,
          onChanged: (b) {
            _defaultToDeleteFiles = b;
            widget.onSettingChanged.call(_newestSetting);
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
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: '默认以在线模式阅读',
          value: _defaultToOnlineMode,
          onChanged: (b) {
            _defaultToOnlineMode = b;
            widget.onSettingChanged.call(_newestSetting);
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
                      child: Text('确定'),
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
  var setting = AppSetting.instance.dl;
  var ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text('漫画下载设置'),
      scrollable: true,
      content: DlSettingSubPage(
        setting: setting,
        onSettingChanged: (s) => setting = s,
      ),
      actions: [
        TextButton(
          child: Text('确定'),
          onPressed: () async {
            AppSetting.instance.update(dl: setting);
            await AppSettingPrefs.saveDlSetting();
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

Future<void> updateDlSettingDefaultToDeleteFiles(bool alsoDeleteFile) async {
  var setting = AppSetting.instance.dl;
  var newSetting = setting.copyWith(defaultToDeleteFiles: alsoDeleteFile);
  AppSetting.instance.update(dl: newSetting);
  await AppSettingPrefs.saveDlSetting();
  EventBusManager.instance.fire(AppSettingChangedEvent());
}

Future<void> updateDlSettingDefaultToOnlineMode(bool onlineMode) async {
  var setting = AppSetting.instance.dl;
  var newSetting = setting.copyWith(defaultToOnlineMode: onlineMode);
  AppSetting.instance.update(dl: newSetting);
  await AppSettingPrefs.saveDlSetting();
  EventBusManager.instance.fire(AppSettingChangedEvent());
}

import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/app_setting.dart';
import 'package:manhuagui_flutter/page/page/setting_dl.dart';
import 'package:manhuagui_flutter/page/view/custom_icons.dart';
import 'package:manhuagui_flutter/page/view/setting_view.dart';
import 'package:manhuagui_flutter/service/prefs/app_setting.dart';

/// 下载列表页/选择下载章节页/下载管理页-漫画下载设置 [showDlSettingDialog]
/// 下载列表页/下载管理页-删除漫画 [updateDlSettingDefaultToDeleteFiles]
/// 下载管理页-在线离线模式 [updateDlSettingDefaultToOnlineMode]

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
      content: SizedBox(
        width: getDialogContentMaxWidth(context),
        child: DlSettingSubPage(
          action: action,
          setting: AppSetting.instance.dl,
          style: SettingViewStyle.line,
        ),
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

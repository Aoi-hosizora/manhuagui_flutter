import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/app_setting.dart';
import 'package:manhuagui_flutter/page/page/setting_ui.dart';
import 'package:manhuagui_flutter/page/view/custom_icons.dart';
import 'package:manhuagui_flutter/page/view/setting_view.dart';
import 'package:manhuagui_flutter/service/prefs/app_setting.dart';

/// 暂无-界面与交互设置 [showUiSettingDialog]
/// 我的页-自动登录签到 [updateUiSettingEnableAutoCheckin]

Future<bool> showUiSettingDialog({required BuildContext context}) async {
  var action = ActionController();
  var ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: IconText(
        icon: Icon(CustomIcons.application_star_cog, size: 26),
        text: Text('界面与交互设置'),
        space: 12,
      ),
      scrollable: true,
      content: SizedBox(
        width: getDialogContentMaxWidth(context),
        child: UiSettingSubPage(
          action: action,
          setting: AppSetting.instance.ui,
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
                var setting = action.invoke<UiSetting>();
                if (setting != null) {
                  AppSetting.instance.update(ui: setting, alsoFireEvent: true);
                  await AppSettingPrefs.saveUiSetting();
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

Future<void> updateUiSettingEnableAutoCheckin(bool enableAutoCheckin) async {
  var setting = AppSetting.instance.ui;
  var newSetting = setting.copyWith(enableAutoCheckin: enableAutoCheckin);
  AppSetting.instance.update(ui: newSetting, alsoFireEvent: true);
  await AppSettingPrefs.saveDlSetting();
}

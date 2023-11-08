import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/app_setting.dart';
import 'package:manhuagui_flutter/page/page/setting_other.dart';
import 'package:manhuagui_flutter/page/view/setting_view.dart';
import 'package:manhuagui_flutter/service/prefs/app_setting.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

/// 暂无-其他设置 [showOtherSettingDialog]

Future<bool> showOtherSettingDialog({required BuildContext context}) async {
  var action = ActionController();
  var ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: IconText(
        icon: Icon(MdiIcons.cogs, size: 26),
        text: Text('其他设置'),
        space: 12,
      ),
      scrollable: true,
      content: SizedBox(
        width: getDialogContentMaxWidth(context),
        child: OtherSettingSubPage(
          action: action,
          setting: AppSetting.instance.other,
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
                var setting = action.invoke<OtherSetting>();
                if (setting != null) {
                  AppSetting.instance.update(other: setting, alsoFireEvent: true);
                  await AppSettingPrefs.saveOtherSetting();
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

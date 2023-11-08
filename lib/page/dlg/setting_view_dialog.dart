import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/app_setting.dart';
import 'package:manhuagui_flutter/page/page/setting_view.dart';
import 'package:manhuagui_flutter/page/setting_view.dart';
import 'package:manhuagui_flutter/page/view/custom_icons.dart';
import 'package:manhuagui_flutter/page/view/setting_view.dart';
import 'package:manhuagui_flutter/service/prefs/app_setting.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

/// 漫画章节阅读页-漫画阅读设置 [showViewSettingDialog]
/// 漫画阅读设置页-章节跳转助手动作设置 [showAssistantSettingDialog]
/// 漫画章节阅读页-左右翻转阅读方向 [updateViewSettingViewDirection]
/// 漫画章节阅读页-禁用章节跳转助手 [updateViewSettingUseChapterAssistant]

Future<bool> showViewSettingDialog({
  required BuildContext context,
  List<Tuple3<String, String, VoidCallback>> Function(BuildContext)? extraButtonsBuilder,
  Future<bool?> Function(Future<bool?> Function())? navigateWrapper,
}) async {
  var action = ActionController();
  var ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: IconText(
        icon: Icon(CustomIcons.opened_book_cog, size: 26),
        text: Text('漫画阅读设置'),
        space: 12,
      ),
      scrollable: true,
      content: SizedBox(
        width: getDialogContentMaxWidth(context),
        child: ViewSettingSubPage(
          action: action,
          setting: AppSetting.instance.view,
          style: SettingViewStyle.line,
          extraButtonsBuilder: (c) => [
            if (extraButtonsBuilder != null) //
              ...extraButtonsBuilder.call(c),
            Tuple3(
              '查看更多阅读设置',
              '设置',
              () async {
                var wrapper = navigateWrapper ?? (navigate) => navigate();
                var ok = await wrapper(
                  () => Navigator.of(context).push<bool>(
                    CustomPageRoute(context: context, builder: (c) => ViewSettingPage()),
                  ),
                );
                if (ok == true) {
                  await Future.delayed(Duration(milliseconds: 75));
                  Navigator.of(context).pop(ok);
                }
              },
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          child: Text('恢复默认'),
          onPressed: () => action.invoke('default'),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              child: Text('确定'),
              onPressed: () async {
                var setting = action.invoke<ViewSetting>();
                if (setting != null) {
                  AppSetting.instance.update(view: setting, alsoFireEvent: true);
                  await AppSettingPrefs.saveViewSetting();
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

Future<AssistantActionSetting?> showAssistantSettingDialog({
  required BuildContext context,
  required AssistantActionSetting setting,
}) async {
  var action = ActionController();
  return await showDialog<AssistantActionSetting>(
    context: context,
    builder: (c) => AlertDialog(
      title: IconText(
        icon: Icon(MdiIcons.gestureTapButton, size: 26),
        text: Text('章节跳转助手设置'),
        space: 12,
      ),
      scrollable: true,
      content: SizedBox(
        width: getDialogContentMaxWidth(context),
        child: AssistantSettingSubPage(
          action: action,
          setting: setting,
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          child: Text('恢复默认'),
          onPressed: () => action.invoke('default'),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              child: Text('确定'),
              onPressed: () => Navigator.of(c).pop(action.invoke<AssistantActionSetting>()),
            ),
            TextButton(
              child: Text('取消'),
              onPressed: () => Navigator.of(c).pop(null),
            ),
          ],
        ),
      ],
    ),
  );
}

Future<void> updateViewSettingViewDirection(ViewDirection viewDirection) async {
  var setting = AppSetting.instance.view;
  var newSetting = setting.copyWith(viewDirection: viewDirection);
  AppSetting.instance.update(view: newSetting, alsoFireEvent: true);
  await AppSettingPrefs.saveViewSetting();
}

Future<void> updateViewSettingUseChapterAssistant(bool useChapterAssistant) async {
  var setting = AppSetting.instance.view;
  var newSetting = setting.copyWith(useChapterAssistant: useChapterAssistant);
  AppSetting.instance.update(view: newSetting, alsoFireEvent: true);
  await AppSettingPrefs.saveViewSetting();
}

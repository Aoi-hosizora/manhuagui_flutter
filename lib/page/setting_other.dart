import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/app_setting.dart';
import 'package:manhuagui_flutter/page/page/setting_other.dart';
import 'package:manhuagui_flutter/page/view/fit_system_screenshot.dart';
import 'package:manhuagui_flutter/page/view/setting_view.dart';
import 'package:manhuagui_flutter/service/prefs/app_setting.dart';

/// 设置页-其他设置页
class OtherSettingPage extends StatefulWidget {
  const OtherSettingPage({
    Key? key,
  }) : super(key: key);

  @override
  State<OtherSettingPage> createState() => _OtherSettingPageState();
}

class _OtherSettingPageState extends State<OtherSettingPage> with FitSystemScreenshotMixin {
  final _action = ActionController();
  final _controller = ScrollController();
  final _listViewKey = GlobalKey();

  @override
  FitSystemScreenshotData get fitSystemScreenshotData => FitSystemScreenshotData(
        scrollViewKey: _listViewKey,
        scrollController: _controller,
      );

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        var setting = _action.invoke<OtherSetting>();
        if (setting == null || setting.equals(AppSetting.instance.other)) {
          return true;
        }
        var ok = await showYesNoAlertDialog(
          context: context,
          title: Text('其他设置'),
          content: Text('当前设置已修改，是否保存并应用？'),
          yesText: Text('去保存'),
          noText: Text('不保存'),
        );
        return ok != true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('其他设置'),
          leading: AppBarActionButton.leading(context: context),
          actions: [
            AppBarActionButton(
              icon: Icon(Icons.settings_backup_restore),
              tooltip: '恢复默认',
              onPressed: () => _action.invoke('default'),
            ),
            AppBarActionButton(
              icon: Icon(Icons.check),
              tooltip: '保存设置',
              onPressed: () async {
                var setting = _action.invoke<OtherSetting>();
                if (setting != null) {
                  AppSetting.instance.update(other: setting, alsoFireEvent: true);
                  await AppSettingPrefs.saveOtherSetting();
                  Navigator.of(context).pop(true);
                }
              },
            ),
          ],
        ),
        body: ExtendedScrollbar(
          controller: _controller,
          interactive: true,
          mainAxisMargin: 2,
          crossAxisMargin: 2,
          child: ListView(
            key: _listViewKey,
            controller: _controller,
            padding: EdgeInsets.zero,
            physics: AlwaysScrollableScrollPhysics(),
            children: [
              OtherSettingSubPage(
                action: _action,
                setting: AppSetting.instance.other,
                style: SettingViewStyle.tile,
              ),
            ],
          ).fitSystemScreenshot(this),
        ),
      ),
    );
  }
}

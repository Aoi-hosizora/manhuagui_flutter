import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/app_setting.dart';
import 'package:manhuagui_flutter/page/page/setting_view.dart';
import 'package:manhuagui_flutter/page/view/fit_system_screenshot.dart';
import 'package:manhuagui_flutter/page/view/setting_view.dart';
import 'package:manhuagui_flutter/service/prefs/app_setting.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

/// 设置页-漫画阅读设置页
class ViewSettingPage extends StatefulWidget {
  const ViewSettingPage({
    Key? key,
  }) : super(key: key);

  @override
  State<ViewSettingPage> createState() => _ViewSettingPageState();
}

class _ViewSettingPageState extends State<ViewSettingPage> with FitSystemScreenshotMixin {
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
        var setting = _action.invoke<ViewSetting>();
        if (setting == null) {
          return false;
        }
        if (setting.equals(AppSetting.instance.view)) {
          return true;
        }
        var ok = await showYesNoAlertDialog(
          context: context,
          title: Text('漫画阅读设置'),
          content: Text('当前设置已修改，是否保存并应用？'),
          yesText: Text('离开'),
          noText: Text('去保存'),
        );
        if (ok != true) {
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('漫画阅读设置'),
          leading: AppBarActionButton.leading(context: context),
          actions: [
            AppBarActionButton(
              icon: Icon(MdiIcons.restore),
              tooltip: '恢复默认',
              onPressed: () => _action.invoke('default'),
            ),
            AppBarActionButton(
              icon: Icon(Icons.check),
              tooltip: '保存设置',
              onPressed: () async {
                var setting = _action.invoke<ViewSetting>();
                if (setting != null) {
                  AppSetting.instance.update(view: setting, alsoFireEvent: true);
                  await AppSettingPrefs.saveViewSetting();
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
              ViewSettingSubPage(
                action: _action,
                setting: AppSetting.instance.view,
                style: SettingViewStyle.tile,
              ),
            ],
          ).fitSystemScreenshot(this),
        ),
      ),
    );
  }
}

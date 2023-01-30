import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/page/log_console.dart';
import 'package:manhuagui_flutter/page/page/dl_setting.dart';
import 'package:manhuagui_flutter/page/page/setting_data.dart';
import 'package:manhuagui_flutter/page/page/setting_other.dart';
import 'package:manhuagui_flutter/page/page/view_setting.dart';
import 'package:manhuagui_flutter/page/view/app_drawer.dart';
import 'package:manhuagui_flutter/service/native/browser.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

/// 设置页
class SettingPage extends StatefulWidget {
  const SettingPage({Key? key}) : super(key: key);

  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  Widget _item({required String title, required IconData icon, required void Function() action}) {
    return Material(
      color: Colors.white,
      child: InkWell(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: IconText(
            icon: Icon(icon, color: Colors.black54),
            text: Text(title, style: Theme.of(context).textTheme.subtitle1),
            space: 14,
          ),
        ),
        onTap: action,
      ),
    );
  }

  Widget _divider() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Divider(height: 0, thickness: 1),
    );
  }

  Widget _spacer() {
    return SizedBox(height: 15);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('设置'),
        leading: AppBarActionButton.leading(context: context, allowDrawerButton: false),
      ),
      drawer: AppDrawer(
        currentSelection: DrawerSelection.setting,
      ),
      drawerEdgeDragWidth: MediaQuery.of(context).size.width,
      body: ListView(
        padding: EdgeInsets.zero,
        physics: AlwaysScrollableScrollPhysics(),
        children: [
          // *******************************************************
          _spacer(),
          Align(
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('${ASSETS_PREFIX}logo_xxhdpi.png', height: 60, width: 60),
                SizedBox(width: 15),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      APP_NAME,
                      style: Theme.of(context).textTheme.headline6?.copyWith(fontWeight: FontWeight.normal),
                    ),
                    Text(
                      APP_VERSION,
                      style: Theme.of(context).textTheme.subtitle2?.copyWith(fontWeight: FontWeight.normal),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // *******************************************************
          _spacer(),
          _item(
            icon: MdiIcons.fileCog,
            title: '漫画阅读设置',
            action: () => showViewSettingDialog(context: context),
          ),
          _divider(),
          _item(
            icon: MdiIcons.contentSaveCog,
            title: '漫画下载设置',
            action: () => showDlSettingDialog(context: context),
          ),
          _divider(),
          _item(
            title: '其他设置',
            icon: MdiIcons.cogs,
            action: () async {
              var ok = await showOtherSettingDialog(context: context);
              if (ok) {
                if (mounted) setState(() {});
              }
            },
          ),
          // *******************************************************
          _spacer(),
          _item(
            title: '导出数据到外部存储',
            icon: MdiIcons.databaseExport,
            action: () => showExportDataDialog(context: context),
          ),
          _divider(),
          _item(
            title: '从外部存储导入数据',
            icon: MdiIcons.databaseImport,
            action: () async {
              await showImportDataDialog(context: context);
              if (mounted) setState(() {});
            },
          ),
          _divider(),
          _item(
            title: '清除图像缓存',
            icon: Icons.cached,
            action: () => showClearCacheDialog(context: context),
          ),
          if (LogConsolePage.initialized) ...[
            _divider(),
            _item(
              title: '查看调试日志',
              icon: Icons.bug_report,
              action: () => Navigator.of(context).push(
                CustomPageRoute(
                  context: context,
                  builder: (c) => LogConsolePage(),
                ),
              ),
            ),
          ],
          // *******************************************************
          _spacer(),
          _item(
            title: '漫画柜/看漫画官网',
            icon: Icons.open_in_browser,
            action: () => launchInBrowser(context: context, url: WEB_HOMEPAGE_URL),
          ),
          _divider(),
          _item(
            title: '本应用源代码',
            icon: Icons.code,
            action: () => launchInBrowser(context: context, url: SOURCE_CODE_URL),
          ),
          // *******************************************************
          _spacer(),
          _item(
            title: '反馈及联系作者',
            icon: Icons.feedback,
            action: () => launchInBrowser(context: context, url: FEEDBACK_URL),
          ),
          _divider(),
          _item(
            title: '检查更新',
            icon: Icons.update,
            action: () => showDialog(
              context: context,
              builder: (c) => AlertDialog(
                title: Text('检查更新'),
                content: Text('当前 $APP_NAME 版本为 $APP_VERSION。\n\n是否用浏览器打开 GitHub Release 页面手动检查更新？'),
                actions: [
                  TextButton(
                    child: Text('打开'),
                    onPressed: () {
                      Navigator.of(c).pop();
                      launchInBrowser(context: context, url: RELEASE_URL);
                    },
                  ),
                  TextButton(
                    child: Text('取消'),
                    onPressed: () => Navigator.of(c).pop(),
                  ),
                ],
              ),
            ),
          ),
          _divider(),
          _item(
            title: '关于本应用',
            icon: Icons.info,
            action: () => showAboutDialog(
              context: context,
              useRootNavigator: false,
              applicationName: APP_NAME,
              applicationVersion: APP_VERSION,
              applicationLegalese: APP_LEGALESE,
              applicationIcon: Image.asset('${ASSETS_PREFIX}logo_xxhdpi.png', height: 60, width: 60),
              children: [
                SizedBox(height: 20),
                SelectableText(
                  APP_DESCRIPTION,
                  style: Theme.of(context).textTheme.subtitle1,
                ),
              ],
            ),
          ),
          // *******************************************************
          _spacer(),
          Align(
            alignment: Alignment.center,
            child: Text(
              APP_LEGALESE,
              style: TextStyle(color: Colors.grey),
            ),
          ),
          _spacer(),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/page/dlg/setting_data_dialog.dart';
import 'package:manhuagui_flutter/page/dlg/setting_dl_dialog.dart';
import 'package:manhuagui_flutter/page/dlg/setting_other_dialog.dart';
import 'package:manhuagui_flutter/page/dlg/setting_ui_dialog.dart';
import 'package:manhuagui_flutter/page/dlg/setting_view_dialog.dart';
import 'package:manhuagui_flutter/page/log_console.dart';
import 'package:manhuagui_flutter/page/login.dart';
import 'package:manhuagui_flutter/page/message.dart';
import 'package:manhuagui_flutter/page/resource_detail.dart';
import 'package:manhuagui_flutter/page/view/app_drawer.dart';
import 'package:manhuagui_flutter/page/view/custom_icons.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:manhuagui_flutter/service/native/browser.dart';
import 'package:manhuagui_flutter/service/prefs/auth.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

/// 设置页
class SettingPage extends StatefulWidget {
  const SettingPage({Key? key}) : super(key: key);

  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  final _cancelHandlers = <VoidCallback>[];

  @override
  void initState() {
    super.initState();
    _cancelHandlers.add(EventBusManager.instance.listen<AppSettingChangedEvent>((_) => mountedSetState(() {})));
    _cancelHandlers.add(EventBusManager.instance.listen<AuthChangedEvent>((_) => mountedSetState(() {})));
  }

  @override
  void dispose() {
    _cancelHandlers.forEach((c) => c.call());
    super.dispose();
  }

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
          if (!AuthManager.instance.logined)
            _item(
              icon: Icons.login,
              title: '登录漫画柜',
              action: () => Navigator.of(context).push(CustomPageRoute(context: context, builder: (c) => LoginPage())),
            ),
          if (AuthManager.instance.logined)
            _item(
              icon: Icons.logout,
              title: '退出登录',
              action: () => showDialog(
                context: context,
                builder: (c) => AlertDialog(
                  title: Text('退出登录'),
                  content: Text('确定要退出登录吗？'),
                  actions: [
                    TextButton(
                      child: Text('确定'),
                      onPressed: () async {
                        Navigator.of(c).pop();
                        await AuthPrefs.setToken('');
                        AuthManager.instance.record(username: '', token: '');
                        AuthManager.instance.notify(logined: false);
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
            icon: Icons.notifications,
            title: '查看应用消息',
            action: () => Navigator.of(context).push(
              CustomPageRoute(
                context: context,
                builder: (c) => MessagePage(),
              ),
            ),
          ),
          // *******************************************************
          _spacer(),
          _item(
            icon: CustomIcons.opened_book_cog,
            title: '漫画阅读设置',
            action: () => showViewSettingDialog(context: context), // TODO change to use separated page
          ),
          _divider(),
          _item(
            icon: CustomIcons.download_cog,
            title: '漫画下载设置',
            action: () => showDlSettingDialog(context: context),
          ),
          _divider(),
          _item(
            title: '界面与交互设置',
            icon: CustomIcons.application_star_cog,
            action: () => showUiSettingDialog(context: context),
          ),
          _divider(),
          _item(
            title: '其他设置',
            icon: MdiIcons.cogs,
            action: () => showOtherSettingDialog(context: context),
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
            action: () => showImportDataDialog(context: context),
          ),
          _divider(),
          _item(
            title: '清除图像缓存',
            icon: MdiIcons.imageRemove,
            action: () => showClearCacheDialog(context: context),
          ),
          _divider(),
          _item(
            title: '清理无用的下载文件',
            icon: MdiIcons.fileRemove,
            action: () => showClearUnusedDlDialog(context: context),
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
            title: '打开漫画柜官网',
            icon: Icons.open_in_browser,
            action: () => launchInBrowser(context: context, url: WEB_HOMEPAGE_URL),
          ),
          _divider(),
          _item(
            title: '查看本应用源代码',
            icon: Icons.code,
            action: () => launchInBrowser(context: context, url: PROJECT_HOMEPAGE_URL),
          ),
          _divider(),
          _item(
            title: '查看资源访问详情',
            icon: Icons.bar_chart,
            action: () => Navigator.of(context).push(
              CustomPageRoute(
                context: context,
                builder: (c) => ResourceDetailPage(),
              ),
            ),
          ),
          _divider(),
          _item(
            title: '使用小贴士',
            icon: MdiIcons.lightbulbMultipleOutline,
            action: () {}, // TODO add tips to setting page
          ),
          // *******************************************************
          _spacer(),
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
            title: '反馈及联系作者',
            icon: Icons.feedback,
            action: () => showDialog(
              context: context,
              builder: (c) => SimpleDialog(
                title: Text('反馈及联系作者'),
                children: [
                  IconTextDialogOption(
                    icon: Icon(MdiIcons.github),
                    text: Text('通过 GitHub 联系'),
                    onPressed: () => launchInBrowser(context: context, url: FEEDBACK_URL),
                  ),
                  IconTextDialogOption(
                    icon: Icon(Icons.email),
                    text: Text('通过邮件联系'),
                    onPressed: () => launchInEmail(email: AUTHOR_EMAIL, subject: '$APP_NAME 反馈'),
                  ),
                ],
              ),
            ),
          ),
          _divider(),
          _item(
            title: '查看相关开源协议',
            icon: MdiIcons.package,
            action: () => Navigator.of(context).push(
              CustomPageRoute(
                context: context,
                builder: (c) => LicensePage(
                  applicationName: APP_NAME,
                  applicationVersion: APP_VERSION,
                  applicationLegalese: APP_LEGALESE,
                  applicationIcon: Image.asset('${ASSETS_PREFIX}logo_xxhdpi.png', height: 60, width: 60),
                ),
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

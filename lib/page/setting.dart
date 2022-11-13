import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/page/log_console.dart';
import 'package:manhuagui_flutter/page/page/glb_setting.dart';
import 'package:manhuagui_flutter/page/page/dl_setting.dart';
import 'package:manhuagui_flutter/page/page/view_setting.dart';
import 'package:manhuagui_flutter/page/view/app_drawer.dart';
import 'package:manhuagui_flutter/service/native/browser.dart';
import 'package:manhuagui_flutter/service/prefs/dl_setting.dart';
import 'package:manhuagui_flutter/service/prefs/glb_setting.dart';
import 'package:manhuagui_flutter/service/prefs/view_setting.dart';
import 'package:manhuagui_flutter/service/storage/storage.dart';

/// 设置页
class SettingPage extends StatefulWidget {
  const SettingPage({Key? key}) : super(key: key);

  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  Widget _item({required String title, required void Function() action}) {
    return Material(
      color: Colors.white,
      child: InkWell(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          child: Text(title, style: Theme.of(context).textTheme.subtitle1),
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
                Image.asset('${ASSETS_PREFIX}ic_launcher_xxhdpi.png', height: 60, width: 60),
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
            title: '漫画阅读设置',
            action: () async {
              var setting = await ViewSettingPrefs.getSetting();
              await showDialog(
                context: context,
                builder: (c) => AlertDialog(
                  title: Text('漫画阅读设置'),
                  scrollable: true,
                  content: ViewSettingSubPage(
                    setting: setting,
                    onSettingChanged: (s) => setting = s,
                  ),
                  actions: [
                    TextButton(
                      child: Text('确定'),
                      onPressed: () async {
                        Navigator.of(c).pop();
                        await ViewSettingPrefs.setSetting(setting);
                      },
                    ),
                    TextButton(
                      child: Text('取消'),
                      onPressed: () => Navigator.of(c).pop(),
                    ),
                  ],
                ),
              );
            },
          ),
          _divider(),
          _item(
            title: '漫画下载设置',
            action: () async {
              var setting = await DlSettingPrefs.getSetting();
              await showDialog(
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
                        Navigator.of(c).pop();
                        await DlSettingPrefs.setSetting(setting);
                      },
                    ),
                    TextButton(
                      child: Text('取消'),
                      onPressed: () => Navigator.of(c).pop(),
                    ),
                  ],
                ),
              );
            },
          ),
          _divider(),
          _item(
            title: '高级设置',
            action: () async {
              var setting = await GlbSettingPrefs.getSetting();
              await showDialog(
                context: context,
                builder: (c) => AlertDialog(
                  title: Text('高级设置'),
                  scrollable: true,
                  content: GlbSettingSubPage(
                    setting: setting,
                    onSettingChanged: (s) => setting = s,
                  ),
                  actions: [
                    TextButton(
                      child: Text('确定'),
                      onPressed: () async {
                        Navigator.of(c).pop();
                        await GlbSettingPrefs.setSetting(setting);
                        GlbSetting.updateGlobalSetting(setting);
                        if (mounted) setState(() {});
                      },
                    ),
                    TextButton(
                      child: Text('取消'),
                      onPressed: () => Navigator.of(c).pop(),
                    ),
                  ],
                ),
              );
            },
          ),
          // *******************************************************
          _spacer(),
          if (LogConsolePage.initialized) ...[
            _item(
              title: '查看调试日志',
              action: () => Navigator.of(context).push(
                CustomPageRoute(
                  context: context,
                  builder: (c) => LogConsolePage(),
                ),
              ),
            ),
            _divider(),
          ],
          _item(
            title: '清除图像缓存',
            action: () async {
              var cachedBytes = await getDefaultCacheManagerDirectoryBytes();
              await showDialog(
                context: context,
                builder: (c) => AlertDialog(
                  title: Text('清除图像缓存'),
                  content: Text('当前图像缓存共占用 ${filesize(cachedBytes)} 空间，是否清除？\n\n注意：该操作仅清除图像缓存，并不影响阅读历史、搜索历史等数据。'),
                  actions: [
                    TextButton(
                      child: Text('清除'),
                      onPressed: () async {
                        Navigator.of(c).pop();
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (c) => const AlertDialog(
                            contentPadding: EdgeInsets.zero,
                            content: CircularProgressDialogOption(
                              progress: CircularProgressIndicator(),
                              child: Text('清除图像缓存...'),
                            ),
                          ),
                        );
                        await Future.delayed(Duration(milliseconds: 500));
                        await DefaultCacheManager().store.emptyCache();
                        Navigator.of(context).pop();
                        Fluttertoast.showToast(msg: '已清除所有图像缓存');
                      },
                    ),
                    TextButton(
                      child: Text('取消'),
                      onPressed: () {
                        Navigator.of(c).pop();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          // *******************************************************
          _spacer(),
          _item(
            title: '漫画柜/看漫画官网',
            action: () => launchInBrowser(context: context, url: WEB_HOMEPAGE_URL),
          ),
          _divider(),
          _item(
            title: '本应用源代码',
            action: () => launchInBrowser(context: context, url: SOURCE_CODE_URL),
          ),
          // *******************************************************
          _spacer(),
          _item(
            title: '反馈及联系作者',
            action: () => launchInBrowser(context: context, url: FEEDBACK_URL),
          ),
          _divider(),
          _item(
            title: '检查更新',
            action: () => showDialog(
              context: context,
              builder: (c) => AlertDialog(
                title: Text('检查更新'),
                content: Text('当前 $APP_NAME 版本为 $APP_VERSION。是否打开 GitHub Release 页面手动检查更新？'),
                actions: [
                  TextButton(
                    child: Text('打开'),
                    onPressed: () => launchInBrowser(
                      context: context,
                      url: RELEASE_URL,
                    ),
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
            action: () => showAboutDialog(
              context: context,
              useRootNavigator: false,
              applicationName: APP_NAME,
              applicationVersion: APP_VERSION,
              applicationLegalese: APP_LEGALESE,
              applicationIcon: Image.asset('${ASSETS_PREFIX}ic_launcher_xxhdpi.png', height: 60, width: 60),
              children: [
                SizedBox(height: 20),
                for (var description in APP_DESCRIPTIONS)
                  Text(
                    description,
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
        ],
      ),
    );
  }
}

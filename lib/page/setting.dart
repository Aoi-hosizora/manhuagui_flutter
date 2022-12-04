import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/page/log_console.dart';
import 'package:manhuagui_flutter/page/page/dl_setting.dart';
import 'package:manhuagui_flutter/page/page/other_setting.dart';
import 'package:manhuagui_flutter/page/page/export_import.dart';
import 'package:manhuagui_flutter/page/page/view_setting.dart';
import 'package:manhuagui_flutter/page/view/app_drawer.dart';
import 'package:manhuagui_flutter/service/native/browser.dart';
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
            title: '漫画阅读设置',
            action: () => showViewSettingDialog(context: context),
          ),
          _divider(),
          _item(
            title: '漫画下载设置',
            action: () => showDlSettingDialog(context: context),
          ),
          _divider(),
          _item(
            title: '其他设置',
            action: () async {
              var ok = await showOtherSettingDialog(context: context);
              if (ok) {
                if (mounted) setState(() {});
              }
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
          // _item(
          //   title: '从已下载漫画导入下载记录',
          //   action: () {},
          // ),
          // _divider(),
          _item(
            title: '导出数据到外部存储',
            action: () => showExportDataDialog(context: context),
          ),
          _divider(),
          _item(
            title: '从外部存储导入数据',
            action: () => showImportDataDialog(context: context),
          ),
          _divider(),
          _item(
            title: '清除图像缓存',
            action: () async {
              var cachedBytes = await getDefaultCacheManagerDirectoryBytes();
              if (cachedBytes < 1024) {
                Fluttertoast.showToast(msg: '当前不存在图像缓存。'); // <1MB
                return;
              }
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
        ],
      ),
    );
  }
}

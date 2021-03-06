import 'package:flutter/material.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/service/natives/browser.dart';

/// 设置页
class SettingPage extends StatefulWidget {
  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  Widget _item({@required String title, Function action}) {
    return Container(
      color: Colors.white,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            child: Text(
              title,
              style: Theme.of(context).textTheme.subtitle1,
            ),
          ),
          onTap: action ?? () {},
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(left: 10, right: 10),
      child: Divider(height: 1, thickness: 1),
    );
  }

  Widget _spacer() {
    return SizedBox(height: 15);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: 45,
        title: Text('设置'),
      ),
      body: ListView(
        children: [
          _spacer(),
          // *******************************************************
          _item(
            title: '漫画官网',
            action: () => launchInBrowser(
              context: context,
              url: WEB_HOMEPAGE_URL,
            ),
          ),
          _divider(),
          _item(
            title: '客户端源码',
            action: () => launchInBrowser(
              context: context,
              url: APP_HOMEPAGE_URL,
            ),
          ),
          _spacer(),
          // *******************************************************
          _item(
            title: '反馈及联系作者',
            action: () => launchInBrowser(
              context: context,
              url: FEEDBACK_URL,
            ),
          ),
          _divider(),
          _item(
            title: '检查更新',
            action: () => launchInBrowser(
              context: context,
              url: RELEASE_URL,
            ),
          ),
          _divider(),
          _item(
            title: '关于',
            action: () => showAboutDialog(
              context: context,
              useRootNavigator: false,
              applicationName: APP_NAME,
              applicationVersion: APP_VERSION,
              applicationIcon: SizedBox(
                height: 50,
                width: 50,
                child: Image.asset('lib/assets/ic_launcher_h.png'),
              ),
              applicationLegalese: '© 2020-2021 Aoi-hosizora',
              children: [
                SizedBox(height: 20),
                for (var r in APP_DESCRIPTIONS)
                  Text(
                    r,
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
              ],
            ),
          ),
          _spacer(),
          // *******************************************************
          Align(
            alignment: Alignment.center,
            child: Text(
              '© 2020-2021 Aoi-hosizora',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

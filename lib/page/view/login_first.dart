import 'package:flutter/material.dart';
import 'package:manhuagui_flutter/page/login.dart';
import 'package:manhuagui_flutter/page/setting.dart';

class LoginFirstView extends StatelessWidget {
  const LoginFirstView({
    Key? key,
    required this.checking,
    this.showSettingButton = false,
  }) : super(key: key);

  final bool checking;
  final bool showSettingButton;

  @override
  Widget build(BuildContext context) {
    if (checking) {
      return Center(
        child: SizedBox(
          height: 45,
          width: 45,
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_open,
            size: 50,
            color: Colors.grey,
          ),
          SizedBox(height: 10),
          Text(
            '当前未登录，请先登录 Manhuagui',
            style: TextStyle(fontSize: 20),
          ),
          SizedBox(height: 10),
          OutlinedButton(
            child: Text('登录'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (c) => LoginPage(),
              ),
            ),
          ),
          if (showSettingButton) ...[
            SizedBox(height: 10),
            OutlinedButton(
              child: Text('设置'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (c) => SettingPage(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

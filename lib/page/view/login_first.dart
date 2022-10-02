import 'package:flutter/material.dart';
import 'package:manhuagui_flutter/page/login.dart';

/// 登录提示，在 [ShelfSubPage] / [MineSubPage] 使用
class LoginFirstView extends StatelessWidget {
  const LoginFirstView({
    Key? key,
    required this.checking,
  }) : super(key: key);

  final bool checking;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (checking) ...[
            SizedBox(
              height: 45,
              width: 45,
              child: CircularProgressIndicator(),
            ),
            SizedBox(height: 10),
            Text(
              '检查登录状态中...',
              style: TextStyle(fontSize: 20),
            ),
          ],
          if (!checking) ...[
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
          ],
        ],
      ),
    );
  }
}

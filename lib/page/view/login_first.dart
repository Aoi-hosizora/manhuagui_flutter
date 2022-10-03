import 'package:flutter/material.dart';
import 'package:flutter_ahlib/widget.dart';
import 'package:manhuagui_flutter/page/login.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';

/// 登录提示，在 [ShelfSubPage] / [MineSubPage] 使用
class LoginFirstView extends StatelessWidget {
  const LoginFirstView({
    Key? key,
    required this.checking,
  }) : super(key: key);

  final bool checking;

  @override
  Widget build(BuildContext context) {
    return PlaceholderText(
      state: checking ? PlaceholderState.loading : PlaceholderState.error,
      childBuilder: (c) => SizedBox(height: 0),
      setting: PlaceholderSetting().copyWithChinese(
        loadingText: '检查登录状态中...',
        unknownErrorText: '当前未登录，请先登录 Manhuagui',
        retryText: '登录',
      ),
      onRefresh: () {
        if (AuthManager.instance.logined) {
          AuthManager.instance.notify();
          return;
        }
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (c) => LoginPage(),
          ),
        );
      },
    );
  }
}

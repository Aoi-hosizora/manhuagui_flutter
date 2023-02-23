import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/page/login.dart';
import 'package:manhuagui_flutter/service/evb/auth_manager.dart';

/// 登录提示，在 [ShelfSubPage] / [MineSubPage] 使用
class LoginFirstView extends StatelessWidget {
  const LoginFirstView({
    Key? key,
    required this.checking,
    this.error = '',
    this.onErrorRetry,
  }) : super(key: key);

  final bool checking;
  final String error;
  final void Function()? onErrorRetry;

  @override
  Widget build(BuildContext context) {
    return PlaceholderText(
      state: checking ? PlaceholderState.loading : (error.isEmpty ? PlaceholderState.nothing : PlaceholderState.error),
      errorText: error.isEmpty ? '' : '无法检查登录状态\n$error',
      childBuilder: (c) => const SizedBox.shrink(),
      setting: PlaceholderSetting(
        nothingIcon: Icons.lock_open,
      ).copyWithChinese(
        loadingText: '检查登录状态中...',
        nothingText: '当前未登录，请先登录 Manhuagui',
        nothingRetryText: '登录',
        errorRetryText: '重试',
      ),
      onRetryForNothing: () {
        if (!AuthManager.instance.logined) {
          Navigator.of(context).push(
            CustomPageRoute.fromTheme(
              themeData: CustomPageRouteTheme.of(context),
              builder: (c) => LoginPage(),
            ),
          );
        } else {
          Fluttertoast.showToast(msg: '${AuthManager.instance.username} 登录成功');
          AuthManager.instance.notify(logined: true);
        }
      },
      onRetryForError: onErrorRetry,
    );
  }
}

import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/page/index.dart';
import 'package:manhuagui_flutter/page/splash.dart';
import 'package:manhuagui_flutter/service/native/system_ui.dart';

Future<void> main() async {
  globalLogger = ExtendedLogger(filter: ProductionFilter(), printer: PreferredPrinter());
  SplashPage.preserve(WidgetsFlutterBinding.ensureInitialized());
  await SplashPage.prepare();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    setDefaultSystemUIOverlayStyle();
    return MaterialApp(
      title: APP_NAME,
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        appBarTheme: AppBarTheme(
          centerTitle: true,
          toolbarHeight: 45,
        ),
        scaffoldBackgroundColor: Color.fromRGBO(245, 245, 245, 1.0),
        splashFactory: CustomInkRipple.preferredSplashFactory,
      ).withPreferredButtonStyles(),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ja', 'JP'),
        Locale('zh', 'CN'),
      ],
      home: SplashPage(home: IndexPage()),
      builder: (context, child) => CustomPageRouteTheme(
        data: CustomPageRouteThemeData(
          transitionDuration: Duration(milliseconds: 400),
          transitionsBuilder: NoPopGestureCupertinoPageTransitionsBuilder(),
          barrierColor: Colors.black38,
          barrierCurve: Curves.easeIn,
          disableCanTransitionTo: true,
        ),
        child: AppBarActionButtonTheme(
          data: AppBarActionButtonThemeData(
            splashRadius: 19,
          ),
          child: PlaceholderTextTheme(
            setting: PlaceholderSetting(
              useAnimatedSwitcher: true,
              switchDuration: Duration(milliseconds: 150),
            ).copyWithChinese(),
            child: child!,
          ),
        ),
      ),
    );
  }
}

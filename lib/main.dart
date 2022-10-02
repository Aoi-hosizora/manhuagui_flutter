import 'package:flutter/services.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/material.dart';
import 'package:manhuagui_flutter/page/index.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Manhuagui',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        appBarTheme: AppBarTheme(
          centerTitle: true,
          toolbarHeight: 45,
          systemOverlayStyle: SystemUiOverlayStyle(
            systemNavigationBarColor: Theme.of(context).scaffoldBackgroundColor,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
        ),
        pageTransitionsTheme: PageTransitionsTheme(
          builders: const {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
          },
        ),
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
      home: IndexPage(),
    );
  }
}

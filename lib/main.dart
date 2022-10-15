import 'package:flutter/services.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/material.dart';
import 'package:manhuagui_flutter/page/index.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color.fromRGBO(250, 250, 250, 1.0),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Manhuagui',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        appBarTheme: AppBarTheme(
          centerTitle: true,
          toolbarHeight: 45,
        ),
        scaffoldBackgroundColor: Color.fromRGBO(245, 245, 245, 1.0),
        pageTransitionsTheme: PageTransitionsTheme(
          builders: const {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
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

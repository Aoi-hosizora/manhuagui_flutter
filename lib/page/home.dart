import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/service/retrofit/dio_manager.dart';
import 'package:manhuagui_flutter/service/retrofit/retrofit.dart';
import 'package:permission_handler/permission_handler.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<bool> _checkPermission() async {
    if (!(await Permission.storage.status).isGranted) {
      var r = await Permission.storage.request();
      return r.isGranted;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    _checkPermission().then((ok) {
      if (!ok) {
        Fluttertoast.showToast(msg: 'Permission denied');
        SystemNavigator.pop();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Manhuagui'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: OutlineButton(
              child: Text('getHotSerialMangas'),
              onPressed: () {
                var dio = DioManager.getInstance().dio;
                var client = RestClient(dio);
                client.getHotSerialMangas().then((r) {
                  Fluttertoast.showToast(msg: r.data.topGroup.mangas.map((e) => '${e.title}|${e.newestChapter}').join(", "));
                }).catchError((e) {
                  Fluttertoast.showToast(msg: wrapError(e).text);
                });
              },
            ),
          ),
          Center(
            child: OutlineButton(
              child: Text('getGenres'),
              onPressed: () {
                var dio = DioManager.getInstance().dio;
                var client = RestClient(dio);
                client.getGenres().then((r) {
                  Fluttertoast.showToast(msg: r.data.data.map((e) => e.title).join(", "));
                }).catchError((e) {
                  Fluttertoast.showToast(msg: wrapError(e).text);
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

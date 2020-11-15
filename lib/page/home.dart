import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Hello world'),
          ],
        ),
      ),
    );
  }
}

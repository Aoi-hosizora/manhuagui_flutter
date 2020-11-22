import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/service/retrofit/dio_manager.dart';
import 'package:manhuagui_flutter/service/retrofit/retrofit.dart';

/// 首页推荐
class RecommendSubPage extends StatefulWidget {
  const RecommendSubPage({Key key}) : super(key: key);

  @override
  _RecommendSubPageState createState() => _RecommendSubPageState();
}

class _RecommendSubPageState extends State<RecommendSubPage> with AutomaticKeepAliveClientMixin {
  var _groups = <String>[];

  @override
  void initState() {
    super.initState();
    var dio = DioManager.getInstance().dio;
    var client = RestClient(dio);
    client.getHotSerialMangas().then((r) async {
      _groups.clear();
      if (mounted) setState(() {});
      await Future.delayed(Duration(milliseconds: 20));
      _groups = r.data.topGroup.mangas.map((g) => '${g.title} - ${g.newestChapter}').toList();
      if (mounted) setState(() {});
    }).catchError((e) {
      wrapError(e);
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: ListView(
        children: _groups
            .map(
              (s) => ListTile(
                title: Text(s),
                onTap: () {},
              ),
            )
            .toList(),
      ),
    );
  }
}

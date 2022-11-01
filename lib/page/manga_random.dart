import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/page/manga.dart';
import 'package:manhuagui_flutter/service/dio/dio_manager.dart';
import 'package:manhuagui_flutter/service/dio/retrofit.dart';
import 'package:manhuagui_flutter/service/dio/wrap_error.dart';

/// 随机漫画页，网络请求并展示 [RandomMangaInfo] 并跳转至 [MangaPage]
class MangaRandomPage extends StatefulWidget {
  const MangaRandomPage({Key? key}) : super(key: key);

  @override
  State<MangaRandomPage> createState() => _MangaRandomPageState();
}

class _MangaRandomPageState extends State<MangaRandomPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final client = RestClient(DioManager.instance.dio);
    try {
      var random = await client.getRandomManga();
      var mid = random.data.mid;
      var url = random.data.url;
      Navigator.of(context).pop();
      Navigator.of(context).push(
        CustomMaterialPageRoute(
          context: context,
          builder: (c) => MangaPage(
            id: mid,
            title: '漫画 mid: $mid',
            url: url,
          ),
        ),
      );
    } catch (e, s) {
      var we = wrapError(e, s);
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: Text('随机漫画'),
          content: Text('无法获取随机漫画：${we.text}。'),
          actions: [
            TextButton(
              child: Text('确定'),
              onPressed: () {
                Navigator.of(c).pop(); // 本对话框
                Navigator.of(context).pop(); // 本页
              },
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('随机漫画'),
        leading: AppBarActionButton.leading(context: context),
      ),
      body: Center(
        child: SizedBox(
          height: 50,
          width: 50,
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

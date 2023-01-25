import 'package:flutter/material.dart';

/// 已收藏漫画作者页，查询 [FavoriteAuthor] 列表并展示
class FavoriteAuthorPage extends StatefulWidget {
  const FavoriteAuthorPage({Key? key}) : super(key: key);

  @override
  State<FavoriteAuthorPage> createState() => _FavoriteAuthorPageState();
}

class _FavoriteAuthorPageState extends State<FavoriteAuthorPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('已收藏的漫画作者'),
      ),
      body: Center(
        child: Text('TODO'), // TODO FavoriteAuthorPage
      ),
    );
  }
}

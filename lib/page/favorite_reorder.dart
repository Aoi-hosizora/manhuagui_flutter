import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';

class FavoriteReorderPage extends StatefulWidget {
  const FavoriteReorderPage({
    Key? key,
    required this.groupName,
  }) : super(key: key);

  final String groupName;

  @override
  State<FavoriteReorderPage> createState() => _FavoriteReorderPageState();
}

class _FavoriteReorderPageState extends State<FavoriteReorderPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('调整收藏顺序'),
        leading: AppBarActionButton.leading(context: context),
      ),
      body: Center(
        child: Text('TODO'),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';

class ActionItem {
  const ActionItem({
    required this.text,
    required this.icon,
    required this.action,
    this.longPress,
    this.enable = true,
  });

  const ActionItem.simple(
    this.text,
    this.icon,
    this.action, [
    this.longPress,
    this.enable = true,
  ]);

  final String text;
  final IconData icon;
  final void Function()? action;
  final void Function()? longPress;
  final bool enable;
}

class ActionRowView extends StatelessWidget {
  const ActionRowView.four({
    Key? key,
    required this.action1,
    required this.action2,
    required this.action3,
    required this.action4,
  })  : action5 = null,
        super(key: key);

  const ActionRowView.five({
    Key? key,
    required this.action1,
    required this.action2,
    required this.action3,
    required this.action4,
    required ActionItem this.action5,
  }) : super(key: key);

  final ActionItem action1;
  final ActionItem action2;
  final ActionItem action3;
  final ActionItem action4;
  final ActionItem? action5;

  Widget _buildAction(ActionItem action) {
    return InkWell(
      onTap: action.enable ? action.action : null,
      onLongPress: action.enable ? action.longPress : null,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: IconText(
          alignment: IconTextAlignment.t2b,
          space: action5 == null
              ? 8 // four
              : 5 /* five */,
          icon: Icon(
            action.icon,
            color: action.enable ? Colors.black54 : Colors.grey,
          ),
          text: Text(
            action.text,
            style: TextStyle(
              color: action.enable ? Colors.black : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: action5 == null
            ? EdgeInsets.symmetric(horizontal: 35, vertical: 8) // four
            : EdgeInsets.symmetric(horizontal: 20, vertical: 5) /* five */,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildAction(action1),
            _buildAction(action2),
            _buildAction(action3),
            _buildAction(action4),
            if (action5 != null) // five
              _buildAction(action5!),
          ],
        ),
      ),
    );
  }
}

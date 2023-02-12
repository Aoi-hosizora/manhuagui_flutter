import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/service/db/query_helper.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

/// 漫画列表页/作者列表页-搜索关键词对话框 [showKeywordDialogForSearching]
/// 漫画列表页/作者列表页-排序对话框 [showSortMethodDialogForSorting]

// => called by pages which needs search items in list
Future<Tuple2<String, bool>?> showKeywordDialogForSearching({
  required BuildContext context,
  required String title,
  String textLabel = '搜索关键词',
  String textValue = '',
  String optionTitle = '仅搜索漫画标题',
  bool optionValue = true,
  String Function(bool)? optionHint,
  String emptyToast = '输入的搜索关键词为空',
  String sameToast = '输入的搜索关键词没有变更',
}) async {
  var controller = TextEditingController()..text = textValue;
  var shownOptionValue = optionValue;
  var ok = await showDialog(
    context: context,
    builder: (c) => StatefulBuilder(
      builder: (_, _setState) => AlertDialog(
        title: Text(title),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: getDialogContentMaxWidth(context),
              padding: EdgeInsets.only(left: 8, right: 12, bottom: 12),
              child: TextField(
                controller: controller,
                maxLines: 1,
                autofocus: true,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(vertical: 5),
                  labelText: textLabel,
                  icon: Icon(Icons.search),
                ),
              ),
            ),
            Container(
              width: getDialogContentMaxWidth(context),
              padding: EdgeInsets.only(top: 3),
              child: CheckboxListTile(
                title: Text(optionTitle),
                value: shownOptionValue,
                onChanged: (v) => _setState(() => shownOptionValue = v ?? false),
                visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            if (optionHint != null)
              Container(
                width: getDialogContentMaxWidth(context),
                padding: EdgeInsets.only(left: 8, right: 8, top: 8),
                child: Text(
                  '(提示: ${optionHint.call(shownOptionValue)})',
                  style: Theme.of(context).textTheme.bodyText2,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('确定'),
            onPressed: () {
              if (controller.text.trim().isEmpty) {
                Fluttertoast.showToast(msg: emptyToast);
              } else if (controller.text.trim() == textValue && shownOptionValue == optionValue) {
                Fluttertoast.showToast(msg: sameToast);
              } else {
                Navigator.of(c).pop(true);
              }
            },
          ),
          TextButton(
            child: Text('取消'),
            onPressed: () => Navigator.of(c).pop(false),
          ),
        ],
      ),
    ),
  );
  if (ok != true) {
    return null;
  }
  return Tuple2(
    controller.text.trim(), // search keyword, must be not empty
    shownOptionValue, // option value
  );
}

// => called by pages which needs sort items in list
Future<SortMethod?> showSortMethodDialogForSorting({
  required BuildContext context,
  required String title,
  SortMethod currValue = SortMethod.byTimeDesc,
  required String? idTitle,
  required String? nameTitle,
  required String? timeTitle,
  required String? orderTitle,
  required SortMethod defaultMethod,
}) async {
  var value = currValue.toAsc();
  var desc = currValue.isDesc();
  var ok = await showDialog(
    context: context,
    builder: (c) => StatefulBuilder(
      builder: (_, _setState) => AlertDialog(
        title: Text(title),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var tuple in [
              if (idTitle != null) Tuple2(idTitle, SortMethod.byIdAsc),
              if (nameTitle != null) Tuple2(nameTitle, SortMethod.byNameAsc),
              if (timeTitle != null) Tuple2(timeTitle, SortMethod.byTimeAsc),
              if (orderTitle != null) Tuple2(orderTitle, SortMethod.byOrderAsc),
            ])
              Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: RadioListTile<SortMethod>(
                  title: Text('按${tuple.item1}${desc ? '逆序' : '正序'}排序'),
                  value: tuple.item2,
                  groupValue: value,
                  onChanged: (v) => v?.let((v) => _setState(() => value = v)),
                  visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            CheckboxListTile(
              title: Text('逆序排序'),
              value: desc,
              onChanged: (v) => _setState(() => desc = v ?? false),
              visualDensity: VisualDensity(horizontal: -4, vertical: -4),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            child: Text('默认'),
            onPressed: () {
              desc = defaultMethod.isDesc();
              value = defaultMethod.toAsc();
              Navigator.of(c).pop(true);
            },
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(child: Text('确定'), onPressed: () => Navigator.of(c).pop(true)),
              TextButton(child: Text('取消'), onPressed: () => Navigator.of(c).pop(false)),
            ],
          ),
        ],
      ),
    ),
  );
  if (ok != true) {
    return null;
  }
  return !desc ? value.toAsc() : value.toDesc();
}

extension SortMethodExtension on SortMethod {
  IconData toIcon() {
    switch (this) {
      case SortMethod.byIdAsc:
        return MdiIcons.sortBoolAscending;
      case SortMethod.byIdDesc:
        return MdiIcons.sortBoolDescending;
      case SortMethod.byNameAsc:
        return MdiIcons.sortAlphabeticalAscending;
      case SortMethod.byNameDesc:
        return MdiIcons.sortAlphabeticalDescending;
      case SortMethod.byTimeAsc:
        return MdiIcons.sortCalendarAscending;
      case SortMethod.byTimeDesc:
        return MdiIcons.sortCalendarDescending;
      case SortMethod.byOrderAsc:
        return MdiIcons.sortNumericAscending;
      case SortMethod.byOrderDesc:
        return MdiIcons.sortNumericDescending;
    }
  }
}

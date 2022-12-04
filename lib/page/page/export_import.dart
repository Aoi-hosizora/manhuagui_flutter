import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/app_setting.dart';
import 'package:manhuagui_flutter/page/view/setting_dialog.dart';
import 'package:manhuagui_flutter/service/storage/export_import.dart';

/// 设置页-导出数据
class ExportDataSubPage extends StatefulWidget {
  const ExportDataSubPage({
    Key? key,
    required this.onTypesChanged,
  }) : super(key: key);

  final void Function(List<ExportDataType> types) onTypesChanged;

  @override
  State<ExportDataSubPage> createState() => _ExportDataSubPageState();
}

class _ExportDataSubPageState extends State<ExportDataSubPage> {
  var _readHistories = true;
  var _downloadRecords = true;
  var _searchHistories = true;
  var _appSetting = true;

  List<ExportDataType> get _newestTypes => [
        if (_readHistories) ExportDataType.readHistories,
        if (_downloadRecords) ExportDataType.downloadRecords,
        if (_searchHistories) ExportDataType.searchHistories,
        if (_appSetting) ExportDataType.appSetting,
      ];

  @override
  Widget build(BuildContext context) {
    return SettingSubPage(
      children: [
        SettingSwitcherView(
          title: '漫画阅读历史',
          value: _readHistories,
          onChanged: (b) {
            _readHistories = b;
            widget.onTypesChanged.call(_newestTypes);
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: '漫画下载记录',
          value: _downloadRecords,
          onChanged: (b) {
            _downloadRecords = b;
            widget.onTypesChanged.call(_newestTypes);
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: '漫画搜索历史',
          value: _searchHistories,
          onChanged: (b) {
            _searchHistories = b;
            widget.onTypesChanged.call(_newestTypes);
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: '所有设置',
          value: _appSetting,
          onChanged: (b) {
            _appSetting = b;
            widget.onTypesChanged.call(_newestTypes);
            if (mounted) setState(() {});
          },
        ),
      ],
    );
  }
}

Future<void> showExportDataDialog({required BuildContext context}) async {
  var types = ExportDataType.values.toList();
  var ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text('导出数据'),
      scrollable: true,
      content: ExportDataSubPage(
        onTypesChanged: (t) => types = t,
      ),
      actions: [
        TextButton(
          child: Text('导出'),
          onPressed: () {
            if (types.isEmpty) {
              Fluttertoast.showToast(msg: '没有指定需要导出的数据');
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
  );
  if (ok != true) {
    return;
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (c) => const AlertDialog(
      contentPadding: EdgeInsets.zero,
      content: CircularProgressDialogOption(
        progress: CircularProgressIndicator(),
        child: Text('导出数据中...'),
      ),
    ),
  );

  await Future.delayed(Duration(milliseconds: 500));
  var name = await exportData(types);
  Navigator.of(context).pop();
  if (name != null) {
    Fluttertoast.showToast(msg: '数据已导出至 "$name"，包括：${types.toTypeTitle()}');
  } else {
    Fluttertoast.showToast(msg: '导出数据失败');
  }
}

Future<void> showImportDataDialog({required BuildContext context}) async {
  var names = await getImportDataNames();
  if (names.isEmpty) {
    Fluttertoast.showToast(msg: '目前没有能够导入的数据');
    return;
  }

  var name = await showDialog<String>(
    context: context,
    builder: (c) => SimpleDialog(
      title: Text('导入数据'),
      children: [
        for (var name in names)
          TextDialogOption(
            text: Text(name),
            onPressed: () => Navigator.of(c).pop(name),
          ),
      ],
    ),
  );
  if (name == null || name.isEmpty) {
    return;
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (c) => const AlertDialog(
      contentPadding: EdgeInsets.zero,
      content: CircularProgressDialogOption(
        progress: CircularProgressIndicator(),
        child: Text('导入数据中...'),
      ),
    ),
  );

  await Future.delayed(Duration(milliseconds: 500));
  var types = await importData(name);
  Navigator.of(context).pop();
  if (types != null) {
    Fluttertoast.showToast(msg: '数据 "$name" 已导入，包括：${types.toTypeTitle()}');
  } else {
    Fluttertoast.showToast(msg: '导入数据失败');
  }
}

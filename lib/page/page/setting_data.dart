import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/app_setting.dart';
import 'package:manhuagui_flutter/page/view/setting_dialog.dart';
import 'package:manhuagui_flutter/service/storage/export_import.dart';
import 'package:manhuagui_flutter/service/storage/storage.dart';

/// 设置页-导出数据/导入数据/清除缓存

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

  await _showFakeProgressDialog(
    context: context,
    text: '导出数据中...',
  );
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

  var mergeData = false; // TODO replace or merge ???
  var name = await showDialog<String>(
    context: context,
    builder: (c) => SimpleDialog(
      title: Text('导入数据'),
      children: [
        CheckBoxDialogOption(
          initialValue: mergeData,
          onChanged: (b) => mergeData = b,
          text: '覆盖原有数据',
        ),
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

  await _showFakeProgressDialog(
    context: context,
    text: '导入数据中...',
  );
  var types = await importData(name);
  Navigator.of(context).pop();
  if (types != null) {
    if (types.isEmpty) {
      Fluttertoast.showToast(msg: '"$name" 内不包括数据');
    } else {
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: Text('导入数据'),
          content: Text('数据 "$name" 已导入。\n\n数据内包括：${types.toTypeTitle()}。'),
          actions: [
            TextButton(child: Text('确定'), onPressed: () => Navigator.of(c).pop()),
          ],
        ),
      );
    }
  } else {
    Fluttertoast.showToast(msg: '导入数据失败');
  }
}

Future<void> showClearCacheDialog({required BuildContext context}) async {
  var cachedBytes = await getDefaultCacheManagerDirectoryBytes();
  if (cachedBytes < 2048) {
    Fluttertoast.showToast(msg: '当前不存在图像缓存。'); // <2KB
    return;
  }
  await showDialog(
    context: context,
    builder: (c) => AlertDialog(
      title: Text('清除图像缓存'),
      content: Text('当前图像缓存共占用 ${filesize(cachedBytes)} 空间，是否清除？\n\n注意：该操作仅清除图像缓存，并不影响阅读历史、搜索历史等数据。'),
      actions: [
        TextButton(
          child: Text('清除'),
          onPressed: () async {
            Navigator.of(c).pop();
            await _showFakeProgressDialog(
              context: context,
              text: '清除图像缓存...',
            );
            await DefaultCacheManager().store.emptyCache();
            Navigator.of(context).pop();
            Fluttertoast.showToast(msg: '已清除所有图像缓存');
          },
        ),
        TextButton(
          child: Text('取消'),
          onPressed: () {
            Navigator.of(c).pop();
          },
        ),
      ],
    ),
  );
}

Future<void> _showFakeProgressDialog({required BuildContext context, required String text}) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (c) => AlertDialog(
      contentPadding: EdgeInsets.zero,
      content: CircularProgressDialogOption(
        progress: CircularProgressIndicator(),
        child: Text(text),
      ),
    ),
  );
  await Future.delayed(Duration(milliseconds: 300));
}

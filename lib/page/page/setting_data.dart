import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/model/app_setting.dart';
import 'package:manhuagui_flutter/page/view/common_widgets.dart';
import 'package:manhuagui_flutter/page/view/setting_dialog.dart';
import 'package:manhuagui_flutter/service/storage/export_import_data.dart';
import 'package:manhuagui_flutter/service/storage/storage.dart';

/// 设置页-导出数据 [showExportDataDialog], [ExportDataSubPage]
/// 设置页-导入数据 [showImportDataDialog]
/// 设置页-清除缓存 [showClearCacheDialog]

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
  var _favoriteMangas = true;
  var _favoriteAuthors = true;
  var _searchHistories = true;
  var _appSetting = true;

  List<ExportDataType> get _newestTypes => [
        if (_readHistories) ExportDataType.readHistories,
        if (_downloadRecords) ExportDataType.downloadRecords,
        if (_favoriteMangas) ExportDataType.favoriteMangas,
        if (_favoriteAuthors) ExportDataType.favoriteAuthors,
        if (_searchHistories) ExportDataType.searchHistories,
        if (_appSetting) ExportDataType.appSetting,
      ];

  @override
  Widget build(BuildContext context) {
    return SettingDialogView(
      children: [
        SettingSwitcherView(
          title: ExportDataType.readHistories.toTypeTitle(),
          value: _readHistories,
          onChanged: (b) {
            _readHistories = b;
            widget.onTypesChanged.call(_newestTypes);
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: ExportDataType.downloadRecords.toTypeTitle(),
          value: _downloadRecords,
          onChanged: (b) {
            _downloadRecords = b;
            widget.onTypesChanged.call(_newestTypes);
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: ExportDataType.favoriteMangas.toTypeTitle(),
          value: _favoriteMangas,
          onChanged: (b) {
            _favoriteMangas = b;
            widget.onTypesChanged.call(_newestTypes);
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: ExportDataType.favoriteAuthors.toTypeTitle(),
          value: _favoriteAuthors,
          onChanged: (b) {
            _favoriteAuthors = b;
            widget.onTypesChanged.call(_newestTypes);
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: ExportDataType.searchHistories.toTypeTitle(),
          value: _searchHistories,
          onChanged: (b) {
            _searchHistories = b;
            widget.onTypesChanged.call(_newestTypes);
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: ExportDataType.appSetting.toTypeTitle(),
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
  var allTypes = ExportDataType.values.toList();
  var ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text('导出数据'),
      scrollable: true,
      content: ExportDataSubPage(
        onTypesChanged: (t) => allTypes = t,
      ),
      actions: [
        TextButton(
          child: Text('导出'),
          onPressed: () {
            if (allTypes.isEmpty) {
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

  await _showFakeProgressDialog(context, '导出数据中...');
  var nameAndCounter = await exportData(allTypes);
  Navigator.of(context).pop(); // dismiss progress dialog
  if (nameAndCounter == null) {
    Fluttertoast.showToast(msg: '导出数据失败');
    return;
  }

  var name = nameAndCounter.item1;
  var counter = nameAndCounter.item2;
  var resultString = counter.formatToString(includeZero: true, includeTypes: allTypes);
  showDialog(
    context: context,
    builder: (c) => AlertDialog(
      title: Text('导出数据'),
      content: Text('数据已导出至 "$name"。\n\n数据内包括：\n$resultString。'),
      actions: [
        TextButton(child: Text('确定'), onPressed: () => Navigator.of(c).pop()),
      ],
    ),
  );
}

Future<void> showImportDataDialog({required BuildContext context}) async {
  var names = await getImportDataNames();
  if (names.isEmpty) {
    Fluttertoast.showToast(msg: '目前没有能够导入的数据');
    return;
  }

  var mergeData = true; // default to merge
  var name = await showDialog<String>(
    context: context,
    builder: (c) => StatefulBuilder(
      builder: (_, _setState) => SimpleDialog(
        title: Text('导入数据'),
        children: [
          for (var name in names)
            TextDialogOption(
              text: Text(name),
              onPressed: () async {
                var ok = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: Text('导入数据'),
                    content: Text('确定导入数据 "$name"，并' + (mergeData ? '与现有数据合并？' : '覆盖现有数据？')),
                    actions: [
                      TextButton(child: Text('导入'), onPressed: () => Navigator.of(c).pop(true)),
                      TextButton(child: Text('取消'), onPressed: () => Navigator.of(c).pop(false)),
                    ],
                  ),
                );
                if (ok == true) {
                  Navigator.of(c).pop(name);
                }
              },
              onLongPressed: () async {
                var ok = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: Text('删除数据'),
                    content: Text('是否删除导入数据 "$name"？'),
                    actions: [
                      TextButton(child: Text('删除'), onPressed: () => Navigator.of(c).pop(true)),
                      TextButton(child: Text('取消'), onPressed: () => Navigator.of(c).pop(false)),
                    ],
                  ),
                );
                if (ok == true) {
                  ok = await deleteImportData(name);
                  if (ok) {
                    names.remove(name);
                    _setState(() {});
                    Fluttertoast.showToast(msg: '"$name" 已删除');
                  } else {
                    Fluttertoast.showToast(msg: '"$name" 删除失败');
                  }
                }
              },
            ),
          Divider(thickness: 1),
          CheckBoxDialogOption(
            initialValue: mergeData,
            onChanged: (b) => mergeData = b,
            text: '与现有数据合并',
          ),
        ],
      ),
    ),
  );
  if (name == null || name.isEmpty) {
    return;
  }

  await _showFakeProgressDialog(context, '导入数据中...');
  var counter = await importData(name, merge: mergeData);
  Navigator.of(context).pop(); // dismiss progress dialog
  if (counter == null) {
    Fluttertoast.showToast(msg: '导入数据失败');
    return;
  }

  if (counter.isEmpty) {
    Fluttertoast.showToast(msg: '"$name" 内不包括数据');
  } else {
    var resultString = counter.formatToString(includeZero: false, includeTypes: ExportDataType.values);
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('导入数据'),
        content: Text('数据 "$name" 已导入。\n\n数据内包括：$resultString。'),
        actions: [
          TextButton(child: Text('确定'), onPressed: () => Navigator.of(c).pop()),
        ],
      ),
    );
  }
}

Future<void> showClearCacheDialog({required BuildContext context}) async {
  await _showFakeProgressDialog(context, '检查图像缓存中...');
  var cachedBytes = await getDefaultCacheManagerDirectoryBytes();
  Navigator.of(context).pop(); // dismiss progress dialog
  if (cachedBytes < 2048) {
    Fluttertoast.showToast(msg: '当前不存在图像缓存。'); // <2KB
    return;
  }

  var ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text('清除图像缓存'),
      content: Text('当前图像缓存共占用 ${filesize(cachedBytes)} 空间，是否清除？\n\n注意：该操作仅清除图像缓存，并不影响阅读历史、搜索历史等数据。'),
      actions: [
        TextButton(child: Text('清除'), onPressed: () => Navigator.of(c).pop(true)),
        TextButton(child: Text('取消'), onPressed: () => Navigator.of(c).pop(false)),
      ],
    ),
  );
  if (ok != true) {
    return;
  }

  await _showFakeProgressDialog(context, '清除图像缓存...');
  await DefaultCacheManager().store.emptyCache();
  Navigator.of(context).pop(); // dismiss progress dialog
  Fluttertoast.showToast(msg: '已清除所有图像缓存');
}

Future<void> _showFakeProgressDialog(BuildContext context, String text) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (c) => WillPopScope(
      onWillPop: () async => false,
      child: AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: CircularProgressDialogOption(
          progress: CircularProgressIndicator(),
          child: Text(text),
        ),
      ),
    ),
  );
  await Future.delayed(Duration(milliseconds: 300));
}

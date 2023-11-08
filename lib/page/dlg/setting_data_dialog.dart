import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:manhuagui_flutter/page/view/common_widgets.dart';
import 'package:manhuagui_flutter/page/view/setting_line.dart';
import 'package:manhuagui_flutter/service/storage/download.dart';
import 'package:manhuagui_flutter/service/storage/export_import_data.dart';
import 'package:manhuagui_flutter/service/storage/storage.dart';

/// 设置页-导出数据 [showExportDataDialog], [ExportDataSubPage]
/// 设置页-导入数据 [showImportDataDialog]
/// 设置页-清除缓存 [showClearCacheDialog]
/// 设置页-清理下载 [showClearUnusedDlDialog]

class ExportDataSubPage extends StatefulWidget {
  const ExportDataSubPage({
    Key? key,
    required this.action,
  }) : super(key: key);

  final ActionController action;

  @override
  State<ExportDataSubPage> createState() => _ExportDataSubPageState();
}

class _ExportDataSubPageState extends State<ExportDataSubPage> {
  @override
  void initState() {
    super.initState();
    widget.action.addAction(() => _newestTypes);
  }

  @override
  void dispose() {
    widget.action.removeAction();
    super.dispose();
  }

  var _readHistories = true;
  var _chapterFootprints = true;
  var _downloadRecords = true;
  var _favoriteMangas = true;
  var _favoriteAuthors = true;
  var _laterMangas = true;
  var _searchHistories = true;
  var _markedCategories = true;
  var _appSetting = true;

  List<ExportDataType> get _newestTypes => [
        if (_readHistories) ExportDataType.readHistories,
        if (_chapterFootprints) ExportDataType.chapterFootprints,
        if (_downloadRecords) ExportDataType.downloadRecords,
        if (_favoriteMangas) ExportDataType.favoriteMangas,
        if (_favoriteAuthors) ExportDataType.favoriteAuthors,
        if (_laterMangas) ExportDataType.laterMangas,
        if (_searchHistories) ExportDataType.searchHistories,
        if (_markedCategories) ExportDataType.markedCategories,
        if (_appSetting) ExportDataType.appSetting,
      ];

  @override
  Widget build(BuildContext context) {
    return SettingDialogView(
      children: [
        Text(
          '提醒：导出的数据可供当前版本或更新版本的APP导入使用，但无法导入至更老版本的APP。',
          style: Theme.of(context).textTheme.bodyText2,
        ),
        SizedBox(height: 8),
        SettingSwitcherView(
          title: ExportDataType.readHistories.toTypeTitle(),
          value: _readHistories,
          onChanged: (b) {
            _readHistories = b;
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: ExportDataType.chapterFootprints.toTypeTitle(),
          value: _chapterFootprints,
          onChanged: (b) {
            _chapterFootprints = b;
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: ExportDataType.downloadRecords.toTypeTitle(),
          value: _downloadRecords,
          onChanged: (b) {
            _downloadRecords = b;
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: ExportDataType.favoriteMangas.toTypeTitle(),
          value: _favoriteMangas,
          onChanged: (b) {
            _favoriteMangas = b;
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: ExportDataType.favoriteAuthors.toTypeTitle(),
          value: _favoriteAuthors,
          onChanged: (b) {
            _favoriteAuthors = b;
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: ExportDataType.laterMangas.toTypeTitle(),
          value: _laterMangas,
          onChanged: (b) {
            _laterMangas = b;
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: ExportDataType.searchHistories.toTypeTitle(),
          value: _searchHistories,
          onChanged: (b) {
            _searchHistories = b;
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: ExportDataType.markedCategories.toTypeTitle(),
          value: _markedCategories,
          onChanged: (b) {
            _markedCategories = b;
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: ExportDataType.appSetting.toTypeTitle(),
          value: _appSetting,
          onChanged: (b) {
            _appSetting = b;
            if (mounted) setState(() {});
          },
        ),
      ],
    );
  }
}

Future<void> showExportDataDialog({required BuildContext context}) async {
  List<ExportDataType>? typeList;
  var action = ActionController();
  var ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text('导出数据'),
      scrollable: true,
      content: ExportDataSubPage(
        action: action,
      ),
      actions: [
        TextButton(
          child: Text('导出'),
          onPressed: () {
            typeList = action.invoke<List<ExportDataType>>();
            if (typeList == null || typeList!.isEmpty) {
              Fluttertoast.showToast(msg: '没有指定需要导出的数据');
              typeList = null;
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
  if (ok != true || typeList == null || typeList!.isEmpty) {
    return;
  }

  await _showFakeProgressDialog(context, '导出数据中...');
  var nameAndCounter = await exportData(typeList!);
  Navigator.of(context).pop(); // dismiss progress dialog
  if (nameAndCounter == null) {
    Fluttertoast.showToast(msg: '导出数据失败');
    return;
  }

  var name = nameAndCounter.item1;
  var counter = nameAndCounter.item2;
  var resultString = counter.formatToString(includeZero: true, includeTypes: typeList!);
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
                    content: Text('是否导入数据 "$name"，并' + (mergeData ? '与现有数据合并？' : '覆盖现有数据？')),
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
      content: Text('当前图像缓存共占用 ${filesize(cachedBytes)} 空间，是否清除？\n\n注意：该操作仅清除图像缓存，不会对阅读历史、搜索历史等数据造成影响。'),
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

Future<void> showClearUnusedDlDialog({required BuildContext context}) async {
  var ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text('清理无用的下载文件'),
      content: Text('是否清理下载目录中不需要的文件？\n\n注意：该操作仅删除不下载任务中的漫画和章节文件，不会对下载目录中的其他文件造成影响。'),
      actions: [
        TextButton(child: Text('清理'), onPressed: () => Navigator.of(c).pop(true)),
        TextButton(child: Text('取消'), onPressed: () => Navigator.of(c).pop(false)),
      ],
    ),
  );
  if (ok != true) {
    return;
  }

  await _showFakeProgressDialog(context, '清除无用的下载文件...');
  var result = await deleteUnusedFilesInDownloadDirectory();
  Navigator.of(context).pop(); // dismiss progress dialog

  var successChapters = result.item1, failedChapters = result.item2, allChecked = result.item3;
  if (!allChecked) {
    Fluttertoast.showToast(msg: '清理文件时出错，已清理 $successChapters 个章节，剩余部分章节未检查');
  } else if (failedChapters == 0) {
    Fluttertoast.showToast(msg: '已成功清理 $successChapters 个章节');
  } else {
    Fluttertoast.showToast(msg: '已清理 $successChapters 个章节，有 $failedChapters 个章节清理失败');
  }
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
  await Future.delayed(Duration(milliseconds: 300)); // showing fake progress dialog
}

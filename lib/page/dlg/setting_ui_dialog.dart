import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/app_setting.dart';
import 'package:manhuagui_flutter/model/order.dart';
import 'package:manhuagui_flutter/page/view/custom_icons.dart';
import 'package:manhuagui_flutter/page/view/setting_dialog.dart';
import 'package:manhuagui_flutter/service/prefs/app_setting.dart';

/// 设置页-界面显示设置 [showUiSettingDialog], [UiSettingSubPage]

class UiSettingSubPage extends StatefulWidget {
  const UiSettingSubPage({
    Key? key,
    required this.action,
    required this.setting,
    required this.onSettingChanged,
  }) : super(key: key);

  final ActionController action;
  final UiSetting setting;
  final void Function(UiSetting) onSettingChanged;

  @override
  State<UiSettingSubPage> createState() => _UiSettingSubPageState();
}

class _UiSettingSubPageState extends State<UiSettingSubPage> {
  @override
  void initState() {
    super.initState();
    widget.action.addAction(_setToDefault);
  }

  @override
  void dispose() {
    widget.action.removeAction();
    super.dispose();
  }

  late var _defaultMangaOrder = widget.setting.defaultMangaOrder;
  late var _defaultAuthorOrder = widget.setting.defaultAuthorOrder;
  late var _enableCornerIcons = widget.setting.enableCornerIcons;
  late var _showMangaReadIcon = widget.setting.showMangaReadIcon;
  late var _regularGroupRows = widget.setting.regularGroupRows;
  late var _otherGroupRows = widget.setting.otherGroupRows;
  late var _clickToSearch = widget.setting.clickToSearch;
  late var _includeUnreadInHome = widget.setting.includeUnreadInHome;
  late var _audienceMangaRows = widget.setting.audienceRankingRows;
  late var _alwaysOpenNewListPage = widget.setting.alwaysOpenNewListPage;

  UiSetting get _newestSetting => UiSetting(
        defaultMangaOrder: _defaultMangaOrder,
        defaultAuthorOrder: _defaultAuthorOrder,
        enableCornerIcons: _enableCornerIcons,
        showMangaReadIcon: _showMangaReadIcon,
        regularGroupRows: _regularGroupRows,
        otherGroupRows: _otherGroupRows,
        clickToSearch: _clickToSearch,
        includeUnreadInHome: _includeUnreadInHome,
        audienceRankingRows: _audienceMangaRows,
        alwaysOpenNewListPage: _alwaysOpenNewListPage,
      );

  void _setToDefault() {
    var setting = UiSetting.defaultSetting;
    _defaultMangaOrder = setting.defaultMangaOrder;
    _defaultAuthorOrder = setting.defaultAuthorOrder;
    _enableCornerIcons = setting.enableCornerIcons;
    _showMangaReadIcon = setting.showMangaReadIcon;
    _regularGroupRows = setting.regularGroupRows;
    _otherGroupRows = setting.otherGroupRows;
    _clickToSearch = setting.clickToSearch;
    _includeUnreadInHome = setting.includeUnreadInHome;
    _audienceMangaRows = setting.audienceRankingRows;
    _alwaysOpenNewListPage = setting.alwaysOpenNewListPage;
    widget.onSettingChanged.call(_newestSetting);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SettingDialogView(
      children: [
        SettingComboBoxView<MangaOrder>(
          title: '漫画列表默认排序方式',
          value: _defaultMangaOrder,
          values: const [MangaOrder.byPopular, MangaOrder.byNew, MangaOrder.byUpdate],
          textBuilder: (s) => s.toTitle(),
          onChanged: (s) {
            _defaultMangaOrder = s;
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingComboBoxView<AuthorOrder>(
          title: '作者列表默认排序方式',
          value: _defaultAuthorOrder,
          values: const [AuthorOrder.byPopular, AuthorOrder.byComic, AuthorOrder.byNew],
          textBuilder: (s) => s.toTitle(),
          onChanged: (s) {
            _defaultAuthorOrder = s;
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: '列表内显示右下角图标',
          hint: '该选项影响漫画列表与漫画作者列表，其中：\n\n'
              '1. 漫画列表右下角图标含义分别为："在下载列表中"、"在我的书架上"、"在本地收藏中"、"已被阅读或浏览"；\n'
              '2. 漫画作者列表右下角图标含义为："在本地收藏中"。\n\n'
              '提示：上述信息都来源于本地记录或同步的数据，显示这些图标并不会增加网络请求次数。',
          value: _enableCornerIcons,
          onChanged: (b) {
            _enableCornerIcons = b;
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: '漫画列表内显示阅读图标',
          value: _showMangaReadIcon,
          enable: _enableCornerIcons,
          onChanged: (b) {
            _showMangaReadIcon = b;
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingComboBoxView<int>(
          title: '单话分组章节显示行数',
          width: 75,
          value: _regularGroupRows.clamp(1, 8),
          values: const [1, 2, 3, 4, 5, 6, 7, 8],
          textBuilder: (s) => '$s行',
          onChanged: (c) {
            _regularGroupRows = c.clamp(1, 8);
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingComboBoxView<int>(
          title: '其他分组章节显示行数',
          width: 75,
          value: _otherGroupRows.clamp(1, 5),
          values: const [1, 2, 3, 4, 5],
          textBuilder: (s) => '$s行',
          onChanged: (c) {
            _otherGroupRows = c.clamp(1, 5);
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: '点击搜索历史执行搜索',
          value: _clickToSearch,
          onChanged: (b) {
            _clickToSearch = b;
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: '首页历史显示未阅读漫画',
          value: _includeUnreadInHome,
          onChanged: (b) {
            _includeUnreadInHome = b;
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingComboBoxView<int>(
          title: '首页受众排行榜显示行数',
          width: 75,
          value: _audienceMangaRows.clamp(4, 10),
          values: const [4, 5, 6, 7, 8, 9, 10],
          textBuilder: (s) => '$s行',
          onChanged: (c) {
            _audienceMangaRows = c.clamp(4, 10);
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: '始终在新页面显示列表',
          hint: '该选项默认关闭，启用该选项后，当在 "推荐页面"、"用户页面"、"左侧菜单" 等地方点击查看漫画列表时，始终打开新页面显示。',
          value: _alwaysOpenNewListPage,
          onChanged: (b) {
            _alwaysOpenNewListPage = b;
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
      ],
    );
  }
}

Future<bool> showUiSettingDialog({required BuildContext context}) async {
  var action = ActionController();
  var setting = AppSetting.instance.ui;
  var ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: IconText(
        icon: Icon(CustomIcons.application_star_cog, size: 26),
        text: Text('界面显示设置'),
        space: 12,
      ),
      scrollable: true,
      content: UiSettingSubPage(
        action: action,
        setting: setting,
        onSettingChanged: (s) => setting = s,
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          child: Text('恢复默认'),
          onPressed: () => action.invoke(),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              child: Text('确定'),
              onPressed: () async {
                AppSetting.instance.update(ui: setting, alsoFireEvent: true);
                await AppSettingPrefs.saveUiSetting();
                Navigator.of(c).pop(true);
              },
            ),
            TextButton(
              child: Text('取消'),
              onPressed: () => Navigator.of(c).pop(false),
            ),
          ],
        ),
      ],
    ),
  );
  return ok ?? false;
}

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

  late var _showTwoColumns = widget.setting.showTwoColumns;
  late var _defaultMangaOrder = widget.setting.defaultMangaOrder;
  late var _defaultAuthorOrder = widget.setting.defaultAuthorOrder;
  late var _enableCornerIcons = widget.setting.enableCornerIcons;
  late var _showMangaReadIcon = widget.setting.showMangaReadIcon;
  late var _regularGroupRows = widget.setting.regularGroupRows;
  late var _otherGroupRows = widget.setting.otherGroupRows;
  late var _allowErrorToast = widget.setting.allowErrorToast;
  late var _overviewLoadAll = widget.setting.overviewLoadAll;
  late var _includeUnreadInHome = widget.setting.includeUnreadInHome;
  late var _audienceMangaRows = widget.setting.audienceRankingRows;
  late var _homepageFavorite = widget.setting.homepageFavorite;
  late var _homepageRefreshData = widget.setting.homepageRefreshData;
  late var _clickToSearch = widget.setting.clickToSearch;
  late var _alwaysOpenNewListPage = widget.setting.alwaysOpenNewListPage;

  UiSetting get _newestSetting => UiSetting(
        showTwoColumns: _showTwoColumns,
        defaultMangaOrder: _defaultMangaOrder,
        defaultAuthorOrder: _defaultAuthorOrder,
        enableCornerIcons: _enableCornerIcons,
        showMangaReadIcon: _showMangaReadIcon,
        regularGroupRows: _regularGroupRows,
        otherGroupRows: _otherGroupRows,
        allowErrorToast: _allowErrorToast,
        overviewLoadAll: _overviewLoadAll,
        includeUnreadInHome: _includeUnreadInHome,
        audienceRankingRows: _audienceMangaRows,
        homepageFavorite: _homepageFavorite,
        homepageRefreshData: _homepageRefreshData,
        clickToSearch: _clickToSearch,
        alwaysOpenNewListPage: _alwaysOpenNewListPage,
      );

  void _setToDefault() {
    var setting = UiSetting.defaultSetting;
    _showTwoColumns = setting.showTwoColumns;
    _defaultMangaOrder = setting.defaultMangaOrder;
    _defaultAuthorOrder = setting.defaultAuthorOrder;
    _enableCornerIcons = setting.enableCornerIcons;
    _showMangaReadIcon = setting.showMangaReadIcon;
    _regularGroupRows = setting.regularGroupRows;
    _otherGroupRows = setting.otherGroupRows;
    _allowErrorToast = setting.allowErrorToast;
    _overviewLoadAll = setting.overviewLoadAll;
    _includeUnreadInHome = setting.includeUnreadInHome;
    _audienceMangaRows = setting.audienceRankingRows;
    _homepageFavorite = setting.homepageFavorite;
    _homepageRefreshData = setting.homepageRefreshData;
    _clickToSearch = setting.clickToSearch;
    _alwaysOpenNewListPage = setting.alwaysOpenNewListPage;
    widget.onSettingChanged.call(_newestSetting);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SettingDialogView(
      children: [
        SettingGroupTitleView(
          title: '列表显示设置',
        ),
        SettingSwitcherView(
          title: '以双列风格显示列表',
          value: _showTwoColumns,
          onChanged: (b) {
            _showTwoColumns = b;
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
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
              '1. 漫画列表右下角图标含义为："在下载列表中"、"在我的书架上"、"在本地收藏中"、"已被阅读或浏览"；\n'
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
        SettingGroupTitleView(
          title: '漫画显示设置',
        ),
        SettingComboBoxView<int>(
          title: '单话章节分组显示行数',
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
          title: '其他章节分组显示行数',
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
          title: '允许弹出漫画错误提示',
          hint: '漫画错误信息包括："无法获取书架订阅情况"、"无法获取漫画章节列表"。',
          value: _allowErrorToast,
          onChanged: (b) {
            _allowErrorToast = b;
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: '章节一览页加载所有图片',
          hint: !_overviewLoadAll //
              ? '章节页面一览页将仅加载本地已缓存或已下载的图片，不会额外访问网络。'
              : ('章节页面一览页将加载所有页面图片，本地未缓存或未下载的图片会通过网络在线加载。\n\n'
                  '提示：如果加载所有图片，可能会让本应用在短时间内发出大量请求，有较低概率会导致当前IP被漫画柜封禁。'),
          value: _overviewLoadAll,
          onChanged: (b) {
            _overviewLoadAll = b;
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingGroupTitleView(
          title: '首页显示设置',
        ),
        SettingSwitcherView(
          title: '首页显示未阅读漫画历史',
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
        SettingComboBoxView<HomepageFavorite>(
          title: '首页收藏列表显示内容',
          width: 175,
          value: _homepageFavorite,
          values: HomepageFavorite.values,
          textBuilder: (s) => s.toOptionTitle(),
          onChanged: (s) {
            _homepageFavorite = s;
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingComboBoxView<HomepageRefreshData>(
          title: '首页需刷新的数据',
          width: 175,
          value: _homepageRefreshData,
          values: HomepageRefreshData.values,
          textBuilder: (s) => s.toOptionTitle(),
          onChanged: (s) {
            _homepageRefreshData = s;
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingGroupTitleView(
          title: '其他界面显示/交互设置',
        ),
        SettingSwitcherView(
          title: '点击搜索历史立即搜索',
          value: _clickToSearch,
          onChanged: (b) {
            _clickToSearch = b;
            widget.onSettingChanged.call(_newestSetting);
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          title: '始终在新页面打开列表',
          hint: '该选项默认关闭，启用该选项后，当在 "推荐页"、"用户页"、"左侧菜单" 等地方点击查看各种漫画列表时，始终打开新页面显示。',
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

import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/app_setting.dart';
import 'package:manhuagui_flutter/model/order.dart';
import 'package:manhuagui_flutter/page/view/setting_view.dart';

/// 设置-界面与交互设置，用于 [UiSettingPage] / [showUiSettingDialog]
class UiSettingSubPage extends StatefulWidget {
  const UiSettingSubPage({
    Key? key,
    required this.action,
    required this.setting,
    required this.style,
  }) : super(key: key);

  final ActionController action;
  final UiSetting setting;
  final SettingViewStyle style;

  @override
  State<UiSettingSubPage> createState() => _UiSettingSubPageState();
}

class _UiSettingSubPageState extends State<UiSettingSubPage> {
  @override
  void initState() {
    super.initState();
    widget.action.addAction(() => _newestSetting);
    widget.action.addAction('default', _setToDefault);
  }

  @override
  void dispose() {
    widget.action.removeAction();
    widget.action.removeAction('default');
    super.dispose();
  }

  late var _showTwoColumns = widget.setting.showTwoColumns;
  late var _defaultMangaOrder = widget.setting.defaultMangaOrder;
  late var _defaultAuthorOrder = widget.setting.defaultAuthorOrder;
  late var _enableCornerIcons = widget.setting.enableCornerIcons;
  late var _showMangaReadIcon = widget.setting.showMangaReadIcon;
  late var _highlightRecentMangas = widget.setting.highlightRecentMangas;
  late var _readGroupBehavior = widget.setting.readGroupBehavior;
  late var _regularGroupRows = widget.setting.regularGroupRows;
  late var _otherGroupRows = widget.setting.otherGroupRows;
  late var _showLastHistory = widget.setting.showLastHistory;
  late var _overviewLoadAll = widget.setting.overviewLoadAll;
  late var _homepageShowMoreMangas = widget.setting.homepageShowMoreMangas;
  late var _includeUnreadInHome = widget.setting.includeUnreadInHome;
  late var _audienceMangaRows = widget.setting.audienceRankingRows;
  late var _homepageFavorite = widget.setting.homepageFavorite;
  late var _homepageRefreshData = widget.setting.homepageRefreshData;
  late var _clickToSearch = widget.setting.clickToSearch;
  late var _alwaysOpenNewListPage = widget.setting.alwaysOpenNewListPage;
  late var _enableAutoCheckin = widget.setting.enableAutoCheckin;
  late var _allowErrorToast = widget.setting.allowErrorToast;
  late var _convertWebpWhenSave = widget.setting.convertWebpWhenSave;

  UiSetting get _newestSetting => UiSetting(
        showTwoColumns: _showTwoColumns,
        defaultMangaOrder: _defaultMangaOrder,
        defaultAuthorOrder: _defaultAuthorOrder,
        enableCornerIcons: _enableCornerIcons,
        showMangaReadIcon: _showMangaReadIcon,
        highlightRecentMangas: _highlightRecentMangas,
        readGroupBehavior: _readGroupBehavior,
        regularGroupRows: _regularGroupRows,
        otherGroupRows: _otherGroupRows,
        showLastHistory: _showLastHistory,
        overviewLoadAll: _overviewLoadAll,
        homepageShowMoreMangas: _homepageShowMoreMangas,
        includeUnreadInHome: _includeUnreadInHome,
        audienceRankingRows: _audienceMangaRows,
        homepageFavorite: _homepageFavorite,
        homepageRefreshData: _homepageRefreshData,
        clickToSearch: _clickToSearch,
        alwaysOpenNewListPage: _alwaysOpenNewListPage,
        enableAutoCheckin: _enableAutoCheckin,
        allowErrorToast: _allowErrorToast,
        convertWebpWhenSave: _convertWebpWhenSave,
      );

  void _setToDefault() {
    var setting = UiSetting.defaultSetting;
    _showTwoColumns = setting.showTwoColumns;
    _defaultMangaOrder = setting.defaultMangaOrder;
    _defaultAuthorOrder = setting.defaultAuthorOrder;
    _enableCornerIcons = setting.enableCornerIcons;
    _showMangaReadIcon = setting.showMangaReadIcon;
    _highlightRecentMangas = setting.highlightRecentMangas;
    _readGroupBehavior = setting.readGroupBehavior;
    _regularGroupRows = setting.regularGroupRows;
    _otherGroupRows = setting.otherGroupRows;
    _showLastHistory = setting.showLastHistory;
    _overviewLoadAll = setting.overviewLoadAll;
    _homepageShowMoreMangas = setting.homepageShowMoreMangas;
    _includeUnreadInHome = setting.includeUnreadInHome;
    _audienceMangaRows = setting.audienceRankingRows;
    _homepageFavorite = setting.homepageFavorite;
    _homepageRefreshData = setting.homepageRefreshData;
    _clickToSearch = setting.clickToSearch;
    _alwaysOpenNewListPage = setting.alwaysOpenNewListPage;
    _enableAutoCheckin = setting.enableAutoCheckin;
    _allowErrorToast = setting.allowErrorToast;
    _convertWebpWhenSave = setting.convertWebpWhenSave;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var map = <String, List<Widget>>{
      '列表页设置': [
        SettingSwitcherView(
          style: widget.style,
          title: '以双列风格显示列表',
          value: _showTwoColumns,
          onChanged: (b) {
            _showTwoColumns = b;
            if (mounted) setState(() {});
          },
        ),
        SettingComboBoxView<MangaOrder>(
          style: widget.style,
          title: '漫画列表默认排序方式',
          value: _defaultMangaOrder,
          values: const [MangaOrder.byPopular, MangaOrder.byNew, MangaOrder.byUpdate],
          textBuilder: (s) => s.toTitle(),
          onChanged: (s) {
            _defaultMangaOrder = s;
            if (mounted) setState(() {});
          },
        ),
        SettingComboBoxView<AuthorOrder>(
          style: widget.style,
          title: '作者列表默认排序方式',
          value: _defaultAuthorOrder,
          values: const [AuthorOrder.byPopular, AuthorOrder.byComic, AuthorOrder.byNew],
          textBuilder: (s) => s.toTitle(),
          onChanged: (s) {
            _defaultAuthorOrder = s;
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          style: widget.style,
          title: '列表内显示右下角图标',
          hint: '该选项影响漫画列表与漫画作者列表，其中：\n\n'
              '1. 漫画列表右下角图标含义为："在下载列表中"、"在我的书架上"、"在本地收藏中"、"在稍后阅读列表中"、"已被阅读或浏览"；\n'
              '2. 漫画作者列表右下角图标含义为："在本地收藏中"。\n\n'
              '提示：上述信息都来源于本地记录或同步的数据，显示这些图标并不会增加网络请求次数。',
          value: _enableCornerIcons,
          onChanged: (b) {
            _enableCornerIcons = b;
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          style: widget.style,
          title: '漫画列表内显示阅读图标',
          value: _showMangaReadIcon,
          enable: _enableCornerIcons,
          onChanged: (b) {
            _showMangaReadIcon = b;
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          style: widget.style,
          title: '高亮近两天更新的漫画',
          value: _highlightRecentMangas,
          enable: _enableCornerIcons,
          onChanged: (b) {
            _highlightRecentMangas = b;
            if (mounted) setState(() {});
          },
        ),
      ],
      '漫画页设置': [
        SettingComboBoxView<ReadGroupBehavior>(
          style: widget.style,
          title: '点击阅读章节分组行为',
          width: 150,
          hint: '该选项会影响选择阅读章节分组中某章节时的行为，其中：\n\n'
              '1. 不检查阅读情况：选择任何章节都会直接打开阅读页面，从上次读过的页面开始，继续阅读所选章节；\n'
              '2. 部分阅读时确认：选择已开始阅读但未阅读完的章节时，会弹出选择框，确认是否需要继续阅读还是从头阅读；\n'
              '3. 已阅读完时确认：选择已完成阅读的章节时，会弹出选择框，确认是否需要继续阅读、还是从头阅读、还是阅读下一章节。\n',
          value: _readGroupBehavior,
          values: const [ReadGroupBehavior.checkNotfinReading, ReadGroupBehavior.checkFinishReading, ReadGroupBehavior.noCheck],
          textBuilder: (s) => s.toOptionTitle(),
          onChanged: (s) {
            _readGroupBehavior = s;
            if (mounted) setState(() {});
          },
        ),
        SettingComboBoxView<int>(
          style: widget.style,
          title: '单话分组章节显示数量',
          width: 75,
          value: _regularGroupRows.clamp(1, 8),
          values: const [1, 2, 3, 4, 5, 6, 7, 8],
          textBuilder: (s) => '$s行',
          onChanged: (c) {
            _regularGroupRows = c.clamp(1, 8);
            if (mounted) setState(() {});
          },
        ),
        SettingComboBoxView<int>(
          style: widget.style,
          title: '其他分组章节显示数量',
          width: 75,
          value: _otherGroupRows.clamp(1, 5),
          values: const [1, 2, 3, 4, 5],
          textBuilder: (s) => '$s行',
          onChanged: (c) {
            _otherGroupRows = c.clamp(1, 5);
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          style: widget.style,
          title: '高亮上上次章节阅读历史',
          value: _showLastHistory,
          onChanged: (b) {
            _showLastHistory = b;
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          style: widget.style,
          title: '章节一览页加载所有图片',
          hint: !_overviewLoadAll //
              ? '章节页面一览页将仅加载本地已缓存或已下载的图片，不会额外访问网络。'
              : ('章节页面一览页将加载所有页面图片，本地未缓存或未下载的图片会通过网络在线加载。\n\n'
                  '提示：如果加载所有图片，可能会让本应用在短时间内发出大量请求，有一定概率会导致当前IP被漫画柜封禁。'),
          value: _overviewLoadAll,
          onChanged: (b) {
            _overviewLoadAll = b;
            if (mounted) setState(() {});
          },
        ),
      ],
      '首页设置': [
        SettingSwitcherView(
          style: widget.style,
          title: '首页显示更多漫画',
          value: _homepageShowMoreMangas,
          onChanged: (b) {
            _homepageShowMoreMangas = b;
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          style: widget.style,
          title: '首页显示未阅读漫画历史',
          value: _includeUnreadInHome,
          onChanged: (b) {
            _includeUnreadInHome = b;
            if (mounted) setState(() {});
          },
        ),
        SettingComboBoxView<int>(
          style: widget.style,
          title: '首页受众排行榜显示数量',
          width: 75,
          value: _audienceMangaRows.clamp(4, 10),
          values: const [4, 5, 6, 7, 8, 9, 10],
          textBuilder: (s) => '$s行',
          onChanged: (c) {
            _audienceMangaRows = c.clamp(4, 10);
            if (mounted) setState(() {});
          },
        ),
        SettingComboBoxView<HomepageFavorite>(
          style: widget.style,
          title: '首页收藏列表显示内容',
          width: 170,
          value: _homepageFavorite,
          values: HomepageFavorite.values,
          textBuilder: (s) => s.toOptionTitle(),
          onChanged: (s) {
            _homepageFavorite = s;
            if (mounted) setState(() {});
          },
        ),
        SettingComboBoxView<HomepageRefreshData>(
          style: widget.style,
          title: '首页下拉刷新行为',
          width: 210,
          value: _homepageRefreshData,
          values: HomepageRefreshData.values,
          textBuilder: (s) => s.toOptionTitle(),
          onChanged: (s) {
            _homepageRefreshData = s;
            if (mounted) setState(() {});
          },
        ),
      ],
      '其他页设置': [
        SettingSwitcherView(
          style: widget.style,
          title: '点击搜索历史立即搜索',
          value: _clickToSearch,
          onChanged: (b) {
            _clickToSearch = b;
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          style: widget.style,
          title: '始终在新页面打开列表',
          hint: '该选项默认关闭，启用该选项后，当在 "推荐页"、"用户页"、"左侧菜单" 等地方点击查看各种漫画列表时，始终打开新页面显示。',
          value: _alwaysOpenNewListPage,
          onChanged: (b) {
            _alwaysOpenNewListPage = b;
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          style: widget.style,
          title: '启用自动登录签到功能',
          hint: '只有在登录漫画柜时勾选 "保存密码" 才能自动登录签到。',
          value: _enableAutoCheckin,
          onChanged: (b) {
            _enableAutoCheckin = b;
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          style: widget.style,
          title: '允许后台弹出漫画错误提示',
          hint: '该选项涉及漫画页与章节阅读页，错误信息包括 "无法获取书架订阅情况" 与 "无法获取漫画章节列表"。',
          value: _allowErrorToast,
          onChanged: (b) {
            _allowErrorToast = b;
            if (mounted) setState(() {});
          },
        ),
        SettingSwitcherView(
          style: widget.style,
          title: '保存webp图片时转换格式',
          value: _convertWebpWhenSave,
          onChanged: (b) {
            _convertWebpWhenSave = b;
            if (mounted) setState(() {});
          },
        ),
      ],
    };

    var children = <Widget>[];
    for (var key in map.keys) {
      children.add(
        SettingTitleView(
          style: widget.style,
          title: key,
          color: widget.style == SettingViewStyle.line //
              ? Colors.transparent
              : Theme.of(context).scaffoldBackgroundColor,
        ),
      );
      children.addAll(
        widget.style == SettingViewStyle.line //
            ? map[key]!
            : map[key]!.separate(SettingDividerView()),
      );
    }

    Widget view = SettingColumnView(children: children);
    if (widget.style == SettingViewStyle.tile) {
      view = DecoratedBox(
        decoration: BoxDecoration(color: Colors.white),
        child: view,
      );
    }
    return view;
  }
}
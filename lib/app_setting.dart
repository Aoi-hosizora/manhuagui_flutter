import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/model/order.dart';
import 'package:manhuagui_flutter/page/log_console.dart';
import 'package:manhuagui_flutter/service/db/query_helper.dart';
import 'package:manhuagui_flutter/service/evb/evb_manager.dart';
import 'package:manhuagui_flutter/service/evb/events.dart';
import 'package:manhuagui_flutter/service/storage/download_task.dart';
import 'package:manhuagui_flutter/service/storage/queue_manager.dart';

class AppSetting {
  AppSetting._();

  static AppSetting? _instance;

  static AppSetting get instance {
    _instance ??= AppSetting._();
    return _instance!;
  }

  var _viewSetting = ViewSetting.defaultSetting;
  var _dlSetting = DlSetting.defaultSetting;
  var _uiSetting = UiSetting.defaultSetting;
  var _otherSetting = OtherSetting.defaultSetting;

  ViewSetting get view => _viewSetting;

  DlSetting get dl => _dlSetting;

  UiSetting get ui => _uiSetting;

  OtherSetting get other => _otherSetting;

  void update({ViewSetting? view, DlSetting? dl, UiSetting? ui, OtherSetting? other, bool alsoFireEvent = true}) {
    if (view != null) {
      _viewSetting = view;
    }

    if (dl != null) {
      _dlSetting = dl;

      // apply download setting
      for (var t in QueueManager.instance.getDownloadMangaQueueTasks()) {
        t.changeParallel(dl.downloadPagesTogether);
      }
    }

    if (ui != null) {
      _uiSetting = ui;
    }

    if (other != null) {
      _otherSetting = other;

      // apply other setting
      if (other.enableLogger) {
        LogConsolePage.initialize(globalLogger, bufferSize: LOG_CONSOLE_BUFFER);
      } else {
        LogConsolePage.finalize();
      }
    }

    if (alsoFireEvent && (view != null || dl != null || ui != null || other != null)) {
      EventBusManager.instance.fire(AppSettingChangedEvent());
    }
  }
}

// ===========
// ViewSetting
// ===========

class ViewSetting {
  const ViewSetting({
    required this.viewDirection,
    required this.showPageHint,
    required this.showClock,
    required this.showNetwork,
    required this.showBattery,
    required this.enablePageSpace,
    required this.keepScreenOn,
    required this.fullscreen,
    required this.preloadCount,
    required this.pageNoPosition,
    required this.showNotWifiHint,
    required this.hideAppBarWhenEnter,
    required this.appBarSwitchBehavior,
    required this.useChapterAssistant,
    required this.assistantActionSetting,
  });

  // 常规设置
  final ViewDirection viewDirection; // 阅读方向
  final bool showPageHint; // 显示阅读页面提示
  final bool showClock; // 显示当前时间提示
  final bool showNetwork; // 显示网络状态提示
  final bool showBattery; // 显示电源余量提示
  final bool enablePageSpace; // 显示页面间空白
  final bool keepScreenOn; // 屏幕常亮
  final bool fullscreen; // 全屏阅读
  // 高级设置
  final int preloadCount; // 预加载页数
  final PageNoPosition pageNoPosition; // 每页单独显示页码
  final bool showNotWifiHint; // 非WIFI网络阅读提醒
  final bool hideAppBarWhenEnter; // 进入时隐藏标题栏
  final AppBarSwitchBehavior appBarSwitchBehavior; // 切换章节时标题栏行为
  final bool useChapterAssistant; // 使用单手章节跳转助手
  final AssistantActionSetting assistantActionSetting; // 章节跳转助手动作设置

  static const defaultSetting = ViewSetting(
    viewDirection: ViewDirection.leftToRight,
    showPageHint: true,
    showClock: false,
    showNetwork: false,
    showBattery: false,
    enablePageSpace: true,
    keepScreenOn: true,
    fullscreen: false,
    preloadCount: 3,
    pageNoPosition: PageNoPosition.hide,
    showNotWifiHint: true,
    hideAppBarWhenEnter: true,
    appBarSwitchBehavior: AppBarSwitchBehavior.keep,
    useChapterAssistant: true,
    assistantActionSetting: AssistantActionSetting.defaultSetting,
  );

  ViewSetting copyWith({
    ViewDirection? viewDirection,
    bool? showPageHint,
    bool? showClock,
    bool? showNetwork,
    bool? showBattery,
    bool? enablePageSpace,
    bool? keepScreenOn,
    bool? fullscreen,
    int? preloadCount,
    PageNoPosition? pageNoPosition,
    bool? showNotWifiHint,
    bool? hideAppBarWhenEnter,
    AppBarSwitchBehavior? appBarSwitchBehavior,
    bool? useChapterAssistant,
    AssistantActionSetting? assistantActionSetting,
  }) {
    return ViewSetting(
      viewDirection: viewDirection ?? this.viewDirection,
      showPageHint: showPageHint ?? this.showPageHint,
      showClock: showClock ?? this.showClock,
      showNetwork: showNetwork ?? this.showNetwork,
      showBattery: showBattery ?? this.showBattery,
      enablePageSpace: enablePageSpace ?? this.enablePageSpace,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
      fullscreen: fullscreen ?? this.fullscreen,
      preloadCount: preloadCount ?? this.preloadCount,
      pageNoPosition: pageNoPosition ?? this.pageNoPosition,
      showNotWifiHint: showNotWifiHint ?? this.showNotWifiHint,
      hideAppBarWhenEnter: hideAppBarWhenEnter ?? this.hideAppBarWhenEnter,
      appBarSwitchBehavior: appBarSwitchBehavior ?? this.appBarSwitchBehavior,
      useChapterAssistant: useChapterAssistant ?? this.useChapterAssistant,
      assistantActionSetting: assistantActionSetting ?? this.assistantActionSetting,
    );
  }

  bool equals(ViewSetting other) {
    return viewDirection == other.viewDirection && //
        showPageHint == other.showPageHint &&
        showClock == other.showClock &&
        showNetwork == other.showNetwork &&
        showBattery == other.showBattery &&
        enablePageSpace == other.enablePageSpace &&
        keepScreenOn == other.keepScreenOn &&
        fullscreen == other.fullscreen &&
        preloadCount == other.preloadCount &&
        pageNoPosition == other.pageNoPosition &&
        showNotWifiHint == other.showNotWifiHint &&
        hideAppBarWhenEnter == other.hideAppBarWhenEnter &&
        appBarSwitchBehavior == other.appBarSwitchBehavior &&
        useChapterAssistant == other.useChapterAssistant &&
        assistantActionSetting.equals(other.assistantActionSetting);
  }
}

enum ViewDirection {
  leftToRight,
  rightToLeft,
  topToBottom,
  topToBottomRtl,
}

extension ViewDirectionExtension on ViewDirection {
  String toOptionTitle() {
    switch (this) {
      case ViewDirection.leftToRight:
        return '从左往右';
      case ViewDirection.rightToLeft:
        return '从右往左';
      case ViewDirection.topToBottom:
        return '从上往下';
      case ViewDirection.topToBottomRtl:
        return '从上往下 (右到左)';
    }
  }

  int toInt() {
    switch (this) {
      case ViewDirection.leftToRight:
        return 0;
      case ViewDirection.rightToLeft:
        return 1;
      case ViewDirection.topToBottom:
        return 2;
      case ViewDirection.topToBottomRtl:
        return 3;
    }
  }

  static ViewDirection fromInt(int i) {
    switch (i) {
      case 0:
        return ViewDirection.leftToRight;
      case 1:
        return ViewDirection.rightToLeft;
      case 2:
        return ViewDirection.topToBottom;
      case 3:
        return ViewDirection.topToBottomRtl;
    }
    return ViewDirection.leftToRight;
  }

  ViewDirection reverse() {
    switch (this) {
      case ViewDirection.leftToRight:
        return ViewDirection.rightToLeft;
      case ViewDirection.rightToLeft:
        return ViewDirection.leftToRight;
      case ViewDirection.topToBottom:
        return ViewDirection.topToBottomRtl;
      case ViewDirection.topToBottomRtl:
        return ViewDirection.topToBottom;
    }
  }
}

enum AssistantAction {
  none,
  toc,
  reverse,
  config,
  hideOnce,
  disable,
  pop,
}

extension AssistantActionExtension on AssistantAction {
  String toOptionTitle() {
    switch (this) {
      case AssistantAction.none:
        return '不显示';
      case AssistantAction.toc:
        return '漫画章节列表';
      case AssistantAction.reverse:
        return '左右翻转方向';
      case AssistantAction.config:
        return '阅读设置';
      case AssistantAction.hideOnce:
        return '暂时隐藏助手';
      case AssistantAction.disable:
        return '禁用助手';
      case AssistantAction.pop:
        return '结束阅读';
    }
  }

  int toInt() {
    switch (this) {
      case AssistantAction.none:
        return 0;
      case AssistantAction.toc:
        return 1;
      case AssistantAction.reverse:
        return 2;
      case AssistantAction.config:
        return 3;
      case AssistantAction.hideOnce:
        return 4;
      case AssistantAction.disable:
        return 5;
      case AssistantAction.pop:
        return 6;
    }
  }

  static AssistantAction fromInt(int i) {
    switch (i) {
      case 0:
        return AssistantAction.none;
      case 1:
        return AssistantAction.toc;
      case 2:
        return AssistantAction.reverse;
      case 3:
        return AssistantAction.config;
      case 4:
        return AssistantAction.hideOnce;
      case 5:
        return AssistantAction.disable;
      case 6:
        return AssistantAction.pop;
    }
    return AssistantAction.none;
  }
}

class AssistantActionSetting {
  const AssistantActionSetting({
    required this.leftTop,
    required this.rightTop,
    required this.leftBottom,
    required this.rightBottom,
    required this.allowReverse,
  });

  final AssistantAction leftTop; // 左上角的按钮动作
  final AssistantAction rightTop; // 右上角的按钮动作
  final AssistantAction leftBottom; // 左下角的按钮动作
  final AssistantAction rightBottom; // 右下角的按钮动作
  final bool allowReverse; // 允许随着左右变更调整按钮动作

  static const defaultSetting = AssistantActionSetting(
    leftTop: AssistantAction.none,
    rightTop: AssistantAction.none,
    leftBottom: AssistantAction.none,
    rightBottom: AssistantAction.none,
    allowReverse: false,
  );

  AssistantActionSetting copyWith({
    AssistantAction? leftTop,
    AssistantAction? rightTop,
    AssistantAction? leftBottom,
    AssistantAction? rightBottom,
    bool? allowReverse,
  }) {
    return AssistantActionSetting(
      leftTop: leftTop ?? this.leftTop,
      rightTop: rightTop ?? this.rightTop,
      leftBottom: leftBottom ?? this.leftBottom,
      rightBottom: rightBottom ?? this.rightBottom,
      allowReverse: allowReverse ?? this.allowReverse,
    );
  }

  bool equals(AssistantActionSetting other) {
    return leftTop == other.leftTop && //
        rightTop == other.rightTop &&
        leftBottom == other.leftBottom &&
        rightBottom == other.rightBottom &&
        allowReverse == other.allowReverse;
  }

  List<String> toStringList() {
    return [
      leftTop.toInt().toString(),
      rightTop.toInt().toString(),
      leftBottom.toInt().toString(),
      rightBottom.toInt().toString(),
      allowReverse ? '1' : '0',
    ];
  }

  static AssistantActionSetting fromStringList(List<String> list) {
    AssistantAction getFromList(List<String> list, int i, AssistantAction fallback) {
      if (list.length <= i) {
        return fallback;
      }
      return int.tryParse(list[i])?.let((n) => AssistantActionExtension.fromInt(n)) ?? fallback;
    }

    return AssistantActionSetting(
      leftTop: getFromList(list, 0, defaultSetting.leftTop),
      rightTop: getFromList(list, 1, defaultSetting.rightTop),
      leftBottom: getFromList(list, 2, defaultSetting.leftBottom),
      rightBottom: getFromList(list, 3, defaultSetting.rightBottom),
      allowReverse: list.length <= 4 ? false : list[4] == '1',
    );
  }

  T? decideAction<T>({
    bool leftTop = false,
    bool rightTop = false,
    bool leftBottom = false,
    bool rightBottom = false,
    bool rtlOperation = false,
    T? toc,
    T? reverse,
    T? config,
    T? hideOnce,
    T? disable,
    T? pop,
  }) {
    AssistantAction action;
    if (!rtlOperation || !allowReverse) {
      action = leftTop ? this.leftTop : (rightTop ? this.rightTop : (leftBottom ? this.leftBottom : (rightBottom ? this.rightBottom : AssistantAction.none)));
    } else {
      action = leftTop ? this.rightTop : (rightTop ? this.leftTop : (leftBottom ? this.rightBottom : (rightBottom ? this.leftBottom : AssistantAction.none)));
    }

    switch (action) {
      case AssistantAction.none:
        return null;
      case AssistantAction.toc:
        return toc;
      case AssistantAction.reverse:
        return reverse;
      case AssistantAction.config:
        return config;
      case AssistantAction.hideOnce:
        return hideOnce;
      case AssistantAction.disable:
        return disable;
      case AssistantAction.pop:
        return pop;
    }
  }
}

enum PageNoPosition {
  hide,
  topLeft,
  topCenter,
  topRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
}

extension PageNoPositionExtension on PageNoPosition {
  String toOptionTitle() {
    switch (this) {
      case PageNoPosition.hide:
        return '不显示';
      case PageNoPosition.topLeft:
        return '顶部左侧';
      case PageNoPosition.topCenter:
        return '顶部居中';
      case PageNoPosition.topRight:
        return '顶部右侧';
      case PageNoPosition.bottomLeft:
        return '底部左侧';
      case PageNoPosition.bottomCenter:
        return '底部居中';
      case PageNoPosition.bottomRight:
        return '底部右侧';
    }
  }

  int toInt() {
    switch (this) {
      case PageNoPosition.hide:
        return 0;
      case PageNoPosition.topLeft:
        return 1;
      case PageNoPosition.topCenter:
        return 2;
      case PageNoPosition.topRight:
        return 3;
      case PageNoPosition.bottomLeft:
        return 4;
      case PageNoPosition.bottomCenter:
        return 5;
      case PageNoPosition.bottomRight:
        return 6;
    }
  }

  static PageNoPosition fromInt(int i) {
    switch (i) {
      case 0:
        return PageNoPosition.hide;
      case 1:
        return PageNoPosition.topLeft;
      case 2:
        return PageNoPosition.topCenter;
      case 3:
        return PageNoPosition.topRight;
      case 4:
        return PageNoPosition.bottomLeft;
      case 5:
        return PageNoPosition.bottomCenter;
      case 6:
        return PageNoPosition.bottomRight;
    }
    return PageNoPosition.hide;
  }
}

enum AppBarSwitchBehavior {
  keep,
  show,
  hide,
}

extension AppBarSwitchBehaviorExtension on AppBarSwitchBehavior {
  String toOptionTitle() {
    switch (this) {
      case AppBarSwitchBehavior.keep:
        return '保持显示状态';
      case AppBarSwitchBehavior.show:
        return '显示标题栏';
      case AppBarSwitchBehavior.hide:
        return '隐藏标题栏';
    }
  }

  int toInt() {
    switch (this) {
      case AppBarSwitchBehavior.keep:
        return 0;
      case AppBarSwitchBehavior.show:
        return 1;
      case AppBarSwitchBehavior.hide:
        return 2;
    }
  }

  static AppBarSwitchBehavior fromInt(int i) {
    switch (i) {
      case 0:
        return AppBarSwitchBehavior.keep;
      case 1:
        return AppBarSwitchBehavior.show;
      case 2:
        return AppBarSwitchBehavior.hide;
    }
    return AppBarSwitchBehavior.keep;
  }
}

// =========
// DlSetting
// =========

class DlSetting {
  const DlSetting({
    required this.invertDownloadOrder,
    required this.defaultToDeleteFiles,
    required this.downloadPagesTogether,
    required this.defaultToOnlineMode,
    required this.usingDownloadedPage,
  });

  final bool invertDownloadOrder; // 漫画章节下载顺序
  final bool defaultToDeleteFiles; // 默认删除已下载的文件
  final int downloadPagesTogether; // 同时下载的页面数量
  final bool defaultToOnlineMode; // 默认以在线模式阅读
  final bool usingDownloadedPage; // 在线阅读载入已下载页面

  static const defaultSetting = DlSetting(
    invertDownloadOrder: false,
    defaultToDeleteFiles: false,
    downloadPagesTogether: 3,
    defaultToOnlineMode: true,
    usingDownloadedPage: true,
  );

  DlSetting copyWith({
    bool? invertDownloadOrder,
    bool? defaultToDeleteFiles,
    int? downloadPagesTogether,
    bool? defaultToOnlineMode,
    bool? usingDownloadedPage,
  }) {
    return DlSetting(
      invertDownloadOrder: invertDownloadOrder ?? this.invertDownloadOrder,
      defaultToDeleteFiles: defaultToDeleteFiles ?? this.defaultToDeleteFiles,
      downloadPagesTogether: downloadPagesTogether ?? this.downloadPagesTogether,
      defaultToOnlineMode: defaultToOnlineMode ?? this.defaultToOnlineMode,
      usingDownloadedPage: usingDownloadedPage ?? this.usingDownloadedPage,
    );
  }

  bool equals(DlSetting other) {
    return invertDownloadOrder == other.invertDownloadOrder && //
        defaultToDeleteFiles == other.defaultToDeleteFiles &&
        downloadPagesTogether == other.downloadPagesTogether &&
        defaultToOnlineMode == other.defaultToOnlineMode &&
        usingDownloadedPage == other.usingDownloadedPage;
  }
}

// =========
// UiSetting
// =========

class UiSetting {
  const UiSetting({
    required this.showTwoColumns,
    required this.defaultMangaOrder,
    required this.defaultAuthorOrder,
    required this.enableCornerIcons,
    required this.showMangaReadIcon,
    required this.highlightRecentMangas,
    required this.readGroupBehavior,
    required this.regularGroupRows,
    required this.otherGroupRows,
    required this.showLastHistory,
    required this.allowErrorToast,
    required this.overviewLoadAll,
    required this.homepageShowMoreMangas,
    required this.includeUnreadInHome,
    required this.audienceRankingRows,
    required this.homepageFavorite,
    required this.homepageRefreshData,
    required this.clickToSearch,
    required this.alwaysOpenNewListPage,
    required this.enableAutoCheckin,
  });

  // 列表显示设置
  final bool showTwoColumns; // 以双列风格显示列表
  final MangaOrder defaultMangaOrder; // 漫画列表默认排序方式
  final AuthorOrder defaultAuthorOrder; // 作者列表默认排序方式
  final bool enableCornerIcons; // 列表内显示右下角图标
  final bool showMangaReadIcon; // 漫画列表内显示阅读图标
  final bool highlightRecentMangas; // 高亮最近更新的漫画
  // 漫画显示设置
  final ReadGroupBehavior readGroupBehavior; // 点击阅读章节分组行为
  final int regularGroupRows; // 单话分组章节显示数量
  final int otherGroupRows; // 其他分组章节显示数量
  final bool showLastHistory; // 显示上上次章节阅读历史
  final bool overviewLoadAll; // 章节一览页加载所有图片
  // 首页显示设置
  final bool homepageShowMoreMangas; // 首页显示更多漫画
  final bool includeUnreadInHome; // 首页显示未阅读漫画历史
  final int audienceRankingRows; // 首页受众排行榜显示数量
  final HomepageFavorite homepageFavorite; // 首页收藏列表显示内容
  final HomepageRefreshData homepageRefreshData; // 首页下拉刷新行为
  // 用户交互设置
  final bool clickToSearch; // 点击搜索历史立即搜索
  final bool alwaysOpenNewListPage; // 始终在新页面打开列表
  final bool enableAutoCheckin; // 启用自动登录签到功能
  final bool allowErrorToast; // 阅读时允许弹出错误提示

  static const defaultSetting = UiSetting(
    showTwoColumns: false,
    defaultMangaOrder: MangaOrder.byPopular,
    defaultAuthorOrder: AuthorOrder.byPopular,
    enableCornerIcons: true,
    showMangaReadIcon: true,
    highlightRecentMangas: true,
    readGroupBehavior: ReadGroupBehavior.checkFinishReading,
    regularGroupRows: 3,
    otherGroupRows: 1,
    showLastHistory: true,
    overviewLoadAll: false,
    homepageShowMoreMangas: false,
    includeUnreadInHome: true,
    audienceRankingRows: 5,
    homepageFavorite: HomepageFavorite.defaultAscOrder,
    homepageRefreshData: HomepageRefreshData.includeListIfEmpty,
    clickToSearch: true,
    alwaysOpenNewListPage: false,
    enableAutoCheckin: false,
    allowErrorToast: true,
  );

  UiSetting copyWith({
    bool? showTwoColumns,
    MangaOrder? defaultMangaOrder,
    AuthorOrder? defaultAuthorOrder,
    bool? enableCornerIcons,
    bool? showMangaReadIcon,
    bool? highlightRecentMangas,
    ReadGroupBehavior? readGroupBehavior,
    int? regularGroupRows,
    int? otherGroupRows,
    bool? showLastHistory,
    bool? overviewLoadAll,
    bool? homepageShowMoreMangas,
    bool? includeUnreadInHome,
    int? audienceRankingRows,
    HomepageFavorite? homepageFavorite,
    HomepageRefreshData? homepageRefreshData,
    bool? clickToSearch,
    bool? alwaysOpenNewListPage,
    bool? enableAutoCheckin,
    bool? allowErrorToast,
  }) {
    return UiSetting(
      showTwoColumns: showTwoColumns ?? this.showTwoColumns,
      defaultMangaOrder: defaultMangaOrder ?? this.defaultMangaOrder,
      defaultAuthorOrder: defaultAuthorOrder ?? this.defaultAuthorOrder,
      enableCornerIcons: enableCornerIcons ?? this.enableCornerIcons,
      showMangaReadIcon: showMangaReadIcon ?? this.showMangaReadIcon,
      highlightRecentMangas: highlightRecentMangas ?? this.highlightRecentMangas,
      readGroupBehavior: readGroupBehavior ?? this.readGroupBehavior,
      regularGroupRows: regularGroupRows ?? this.regularGroupRows,
      otherGroupRows: otherGroupRows ?? this.otherGroupRows,
      showLastHistory: showLastHistory ?? this.showLastHistory,
      overviewLoadAll: overviewLoadAll ?? this.overviewLoadAll,
      homepageShowMoreMangas: homepageShowMoreMangas ?? this.homepageShowMoreMangas,
      includeUnreadInHome: includeUnreadInHome ?? this.includeUnreadInHome,
      audienceRankingRows: audienceRankingRows ?? this.audienceRankingRows,
      homepageFavorite: homepageFavorite ?? this.homepageFavorite,
      homepageRefreshData: homepageRefreshData ?? this.homepageRefreshData,
      clickToSearch: clickToSearch ?? this.clickToSearch,
      alwaysOpenNewListPage: alwaysOpenNewListPage ?? this.alwaysOpenNewListPage,
      enableAutoCheckin: enableAutoCheckin ?? this.enableAutoCheckin,
      allowErrorToast: allowErrorToast ?? this.allowErrorToast,
    );
  }

  bool equals(UiSetting other) {
    return showTwoColumns == other.showTwoColumns && //
        defaultMangaOrder == other.defaultMangaOrder &&
        defaultAuthorOrder == other.defaultAuthorOrder &&
        enableCornerIcons == other.enableCornerIcons &&
        showMangaReadIcon == other.showMangaReadIcon &&
        highlightRecentMangas == other.highlightRecentMangas &&
        readGroupBehavior == other.readGroupBehavior &&
        regularGroupRows == other.regularGroupRows &&
        otherGroupRows == other.otherGroupRows &&
        showLastHistory == other.showLastHistory &&
        allowErrorToast == other.allowErrorToast &&
        overviewLoadAll == other.overviewLoadAll &&
        homepageShowMoreMangas == other.homepageShowMoreMangas &&
        includeUnreadInHome == other.includeUnreadInHome &&
        audienceRankingRows == other.audienceRankingRows &&
        homepageFavorite == other.homepageFavorite &&
        homepageRefreshData == other.homepageRefreshData &&
        clickToSearch == other.clickToSearch &&
        alwaysOpenNewListPage == other.alwaysOpenNewListPage &&
        enableAutoCheckin == other.enableAutoCheckin;
  }
}

enum ReadGroupBehavior {
  noCheck,
  checkNotfinReading,
  checkFinishReading,
}

extension ReadGroupBehaviorExtension on ReadGroupBehavior {
  String toOptionTitle() {
    switch (this) {
      case ReadGroupBehavior.noCheck:
        return '不检查阅读情况';
      case ReadGroupBehavior.checkNotfinReading:
        return '部分阅读时确认';
      case ReadGroupBehavior.checkFinishReading:
        return '已阅读完时确认';
    }
  }

  int toInt() {
    switch (this) {
      case ReadGroupBehavior.noCheck:
        return 0;
      case ReadGroupBehavior.checkNotfinReading:
        return 1;
      case ReadGroupBehavior.checkFinishReading:
        return 2;
    }
  }

  static ReadGroupBehavior fromInt(int i) {
    switch (i) {
      case 0:
        return ReadGroupBehavior.noCheck;
      case 1:
        return ReadGroupBehavior.checkNotfinReading;
      case 2:
        return ReadGroupBehavior.checkFinishReading;
    }
    return ReadGroupBehavior.noCheck;
  }

  bool needCheckNotfin({required int? currentPage, required int? totalPage}) {
    return (currentPage != null && totalPage != null) &&
        currentPage > 0 && // 第一页也被视为"已开始阅读"
        // currentPage > 1 && // 第二页以后才视为"已开始阅读"
        currentPage < totalPage && // 最后一页视为"已阅读完"，本函数不返回 true
        this == ReadGroupBehavior.checkNotfinReading; // 仅针对"部分阅读时弹出提示"
  }

  bool needCheckFinish({required int? currentPage, required int? totalPage}) {
    return (currentPage != null && totalPage != null) &&
        currentPage >= totalPage && // 阅读到最后一页，视为"已阅读完"
        (this == ReadGroupBehavior.checkNotfinReading || this == ReadGroupBehavior.checkFinishReading);
  }
}

enum HomepageFavorite {
  defaultAscOrder,
  defaultDescOrder,
  defaultAscTime,
  defaultDescTime,
  allAscTime,
  allDescTime,
}

extension HomepageFavoriteExtension on HomepageFavorite {
  String toOptionTitle() {
    switch (this) {
      case HomepageFavorite.defaultAscOrder:
        return '默认分组 (收藏正序)';
      case HomepageFavorite.defaultDescOrder:
        return '默认分组 (收藏逆序)';
      case HomepageFavorite.defaultAscTime:
        return '默认分组 (时间正序)';
      case HomepageFavorite.defaultDescTime:
        return '默认分组 (时间逆序)';
      case HomepageFavorite.allAscTime:
        return '所有收藏 (时间正序)';
      case HomepageFavorite.allDescTime:
        return '所有收藏 (时间逆序)';
    }
  }

  int toInt() {
    switch (this) {
      case HomepageFavorite.defaultAscOrder:
        return 0;
      case HomepageFavorite.defaultDescOrder:
        return 1;
      case HomepageFavorite.defaultAscTime:
        return 2;
      case HomepageFavorite.defaultDescTime:
        return 3;
      case HomepageFavorite.allAscTime:
        return 4;
      case HomepageFavorite.allDescTime:
        return 5;
    }
  }

  static HomepageFavorite fromInt(int i) {
    switch (i) {
      case 0:
        return HomepageFavorite.defaultAscOrder;
      case 1:
        return HomepageFavorite.defaultDescOrder;
      case 2:
        return HomepageFavorite.defaultAscTime;
      case 3:
        return HomepageFavorite.defaultDescTime;
      case 4:
        return HomepageFavorite.allAscTime;
      case 5:
        return HomepageFavorite.allDescTime;
    }
    return HomepageFavorite.defaultAscOrder;
  }

  Tuple2<String?, SortMethod> determineQueryCondition() {
    switch (this) {
      case HomepageFavorite.defaultAscOrder:
        return Tuple2('', SortMethod.byOrderAsc);
      case HomepageFavorite.defaultDescOrder:
        return Tuple2('', SortMethod.byOrderDesc);
      case HomepageFavorite.defaultAscTime:
        return Tuple2('', SortMethod.byTimeAsc);
      case HomepageFavorite.defaultDescTime:
        return Tuple2('', SortMethod.byTimeDesc);
      case HomepageFavorite.allAscTime:
        return Tuple2(null, SortMethod.byTimeAsc);
      case HomepageFavorite.allDescTime:
        return Tuple2(null, SortMethod.byTimeDesc);
    }
  }
}

enum HomepageRefreshData {
  onlyRecommend,
  includeListIfEmpty,
  allData,
}

extension HomepageRefreshDatarExtension on HomepageRefreshData {
  String toOptionTitle() {
    switch (this) {
      case HomepageRefreshData.onlyRecommend:
        return '仅刷新日排行、推荐漫画';
      case HomepageRefreshData.includeListIfEmpty:
        return '刷新日排行、空列表、推荐漫画';
      case HomepageRefreshData.allData:
        return '刷新首页所有数据';
    }
  }

  int toInt() {
    switch (this) {
      case HomepageRefreshData.onlyRecommend:
        return 0;
      case HomepageRefreshData.includeListIfEmpty:
        return 1;
      case HomepageRefreshData.allData:
        return 2;
    }
  }

  static HomepageRefreshData fromInt(int i) {
    switch (i) {
      case 0:
        return HomepageRefreshData.onlyRecommend;
      case 1:
        return HomepageRefreshData.includeListIfEmpty;
      case 2:
        return HomepageRefreshData.allData;
    }
    return HomepageRefreshData.onlyRecommend;
  }
}

// ============
// OtherSetting
// ============

class OtherSetting {
  const OtherSetting({
    required this.timeoutBehavior,
    required this.dlTimeoutBehavior,
    required this.imgTimeoutBehavior,
    required this.enableLogger,
    required this.showDebugErrorMsg,
    required this.useNativeShareSheet,
    required this.useHttpForImage,
    required this.useEmulatedLongScreenshot,
  });

  final TimeoutBehavior timeoutBehavior; // 网络请求超时时间
  final TimeoutBehavior dlTimeoutBehavior; // 漫画下载超时时间
  final TimeoutBehavior imgTimeoutBehavior; // 图片浏览超时时间
  final bool enableLogger; // 记录调试日志
  final bool showDebugErrorMsg; // 使用更详细的错误信息
  final bool useNativeShareSheet; // 使用原生的分享菜单
  final bool useHttpForImage; // 禁用HTTPS加载图片
  final bool useEmulatedLongScreenshot; // 开启模拟的长截图功能

  static const defaultSetting = OtherSetting(
    timeoutBehavior: TimeoutBehavior.normal,
    dlTimeoutBehavior: TimeoutBehavior.normal,
    imgTimeoutBehavior: TimeoutBehavior.normal,
    enableLogger: false,
    showDebugErrorMsg: false,
    useNativeShareSheet: true,
    useHttpForImage: false,
    useEmulatedLongScreenshot: false,
  );

  OtherSetting copyWith({
    TimeoutBehavior? timeoutBehavior,
    TimeoutBehavior? dlTimeoutBehavior,
    TimeoutBehavior? imgTimeoutBehavior,
    bool? enableLogger,
    bool? showDebugErrorMsg,
    bool? useNativeShareSheet,
    bool? reverseDialogActions,
    bool? useHttpForImage,
    bool? useEmulatedLongScreenshot,
  }) {
    return OtherSetting(
      timeoutBehavior: timeoutBehavior ?? this.timeoutBehavior,
      dlTimeoutBehavior: dlTimeoutBehavior ?? this.dlTimeoutBehavior,
      imgTimeoutBehavior: imgTimeoutBehavior ?? this.imgTimeoutBehavior,
      enableLogger: enableLogger ?? this.enableLogger,
      showDebugErrorMsg: showDebugErrorMsg ?? this.showDebugErrorMsg,
      useNativeShareSheet: useNativeShareSheet ?? this.useNativeShareSheet,
      useHttpForImage: useHttpForImage ?? this.useHttpForImage,
      useEmulatedLongScreenshot: useEmulatedLongScreenshot ?? this.useEmulatedLongScreenshot,
    );
  }

  bool equals(OtherSetting other) {
    return timeoutBehavior == other.timeoutBehavior && //
        dlTimeoutBehavior == other.dlTimeoutBehavior &&
        imgTimeoutBehavior == other.imgTimeoutBehavior &&
        enableLogger == other.enableLogger &&
        showDebugErrorMsg == other.showDebugErrorMsg &&
        useNativeShareSheet == other.useNativeShareSheet &&
        useHttpForImage == other.useHttpForImage &&
        useEmulatedLongScreenshot == other.useEmulatedLongScreenshot;
  }
}

enum TimeoutBehavior {
  normal,
  long,
  longLong,
  disable,
}

extension TimeoutBehaviorExtension on TimeoutBehavior {
  String toOptionTitle() {
    switch (this) {
      case TimeoutBehavior.normal:
        return '正常';
      case TimeoutBehavior.long:
        return '较长';
      case TimeoutBehavior.longLong:
        return '长';
      case TimeoutBehavior.disable:
        return '禁用';
    }
  }

  int toInt() {
    switch (this) {
      case TimeoutBehavior.normal:
        return 0;
      case TimeoutBehavior.long:
        return 1;
      case TimeoutBehavior.longLong:
        return 3; // <<<
      case TimeoutBehavior.disable:
        return 2;
    }
  }

  static TimeoutBehavior fromInt(int i) {
    switch (i) {
      case 0:
        return TimeoutBehavior.normal;
      case 1:
        return TimeoutBehavior.long;
      case 3: // <<<
        return TimeoutBehavior.longLong;
      case 2:
        return TimeoutBehavior.disable;
    }
    return TimeoutBehavior.normal;
  }

  T? determineValue<T>({required T normal, required T long, required T longLong, T? disable}) {
    switch (this) {
      case TimeoutBehavior.normal:
        return normal;
      case TimeoutBehavior.long:
        return long;
      case TimeoutBehavior.longLong:
        return longLong;
      case TimeoutBehavior.disable:
        return disable;
    }
  }
}

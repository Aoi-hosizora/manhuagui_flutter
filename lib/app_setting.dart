import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/model/order.dart';
import 'package:manhuagui_flutter/page/log_console.dart';
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
    required this.overviewLoadAll,
  });

  final ViewDirection viewDirection; // 阅读方向
  final bool showPageHint; // 显示阅读页面提示
  final bool showClock; // 显示当前时间提示
  final bool showNetwork; // 显示网络状态提示
  final bool showBattery; // 显示电源余量提示
  final bool enablePageSpace; // 显示页面间空白
  final bool keepScreenOn; // 屏幕常亮
  final bool fullscreen; // 全屏阅读
  final int preloadCount; // 预加载页数
  final bool overviewLoadAll; // 一览加载所有图片

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
    overviewLoadAll: false,
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
    bool? overviewLoadAll,
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
      overviewLoadAll: overviewLoadAll ?? this.overviewLoadAll,
    );
  }
}

enum ViewDirection {
  leftToRight,
  rightToLeft,
  topToBottom,
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
    }
    return ViewDirection.leftToRight;
  }
}

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
}

class UiSetting {
  const UiSetting({
    required this.defaultMangaOrder,
    required this.defaultAuthorOrder,
    required this.enableCornerIcons,
    required this.showMangaReadIcon,
    required this.regularGroupRows,
    required this.otherGroupRows,
    required this.clickToSearch,
    required this.includeUnreadInHome,
    required this.audienceRankingRows,
    required this.alwaysOpenNewListPage,
  });

  final MangaOrder defaultMangaOrder; // 漫画列表默认排序方式
  final AuthorOrder defaultAuthorOrder; // 作者列表默认排序方式
  final bool enableCornerIcons; // 列表内显示右下角图标
  final bool showMangaReadIcon; // 漫画列表内显示阅读图标
  final int regularGroupRows; // 单话分组章节显示行数
  final int otherGroupRows; // 其他分组章节显示行数
  final bool clickToSearch; // 点击搜索历史执行搜索
  final bool includeUnreadInHome; // 首页历史显示未阅读漫画
  final int audienceRankingRows; // 首页受众排行榜显示行数
  final bool alwaysOpenNewListPage; // 始终在新页面显示列表

  static const defaultSetting = UiSetting(
    defaultMangaOrder: MangaOrder.byPopular,
    defaultAuthorOrder: AuthorOrder.byPopular,
    enableCornerIcons: true,
    showMangaReadIcon: true,
    regularGroupRows: 3,
    otherGroupRows: 1,
    clickToSearch: false,
    includeUnreadInHome: true,
    audienceRankingRows: 5,
    alwaysOpenNewListPage: false,
  );

  UiSetting copyWith({
    MangaOrder? defaultMangaOrder,
    AuthorOrder? defaultAuthorOrder,
    bool? enableCornerIcons,
    bool? showMangaReadIcon,
    int? regularGroupRows,
    int? otherGroupRows,
    bool? clickToSearch,
    bool? includeUnreadInHome,
    int? audienceRankingRows,
    bool? alwaysOpenNewListPage,
  }) {
    return UiSetting(
      defaultMangaOrder: defaultMangaOrder ?? this.defaultMangaOrder,
      defaultAuthorOrder: defaultAuthorOrder ?? this.defaultAuthorOrder,
      enableCornerIcons: enableCornerIcons ?? this.enableCornerIcons,
      showMangaReadIcon: showMangaReadIcon ?? this.showMangaReadIcon,
      regularGroupRows: regularGroupRows ?? this.regularGroupRows,
      otherGroupRows: otherGroupRows ?? this.otherGroupRows,
      clickToSearch: clickToSearch ?? this.clickToSearch,
      includeUnreadInHome: includeUnreadInHome ?? this.includeUnreadInHome,
      audienceRankingRows: audienceRankingRows ?? this.audienceRankingRows,
      alwaysOpenNewListPage: alwaysOpenNewListPage ?? this.alwaysOpenNewListPage,
    );
  }
}

class OtherSetting {
  const OtherSetting({
    required this.timeoutBehavior,
    required this.dlTimeoutBehavior,
    required this.imgTimeoutBehavior,
    required this.enableLogger,
    required this.showDebugErrorMsg,
    required this.useNativeShareSheet,
  });

  final TimeoutBehavior timeoutBehavior; // 网络请求超时时间
  final TimeoutBehavior dlTimeoutBehavior; // 漫画下载超时时间
  final TimeoutBehavior imgTimeoutBehavior; // 图片浏览超时时间
  final bool enableLogger; // 记录调试日志
  final bool showDebugErrorMsg; // 使用更详细的错误信息
  final bool useNativeShareSheet; // 使用原生的分享菜单

  static const defaultSetting = OtherSetting(
    timeoutBehavior: TimeoutBehavior.normal,
    dlTimeoutBehavior: TimeoutBehavior.normal,
    imgTimeoutBehavior: TimeoutBehavior.normal,
    enableLogger: false,
    showDebugErrorMsg: false,
    useNativeShareSheet: true,
  );

  OtherSetting copyWith({
    TimeoutBehavior? timeoutBehavior,
    TimeoutBehavior? dlTimeoutBehavior,
    TimeoutBehavior? imgTimeoutBehavior,
    bool? enableLogger,
    bool? showDebugErrorMsg,
    bool? useNativeShareSheet,
    bool? reverseDialogActions,
  }) {
    return OtherSetting(
      timeoutBehavior: timeoutBehavior ?? this.timeoutBehavior,
      dlTimeoutBehavior: dlTimeoutBehavior ?? this.dlTimeoutBehavior,
      imgTimeoutBehavior: imgTimeoutBehavior ?? this.imgTimeoutBehavior,
      enableLogger: enableLogger ?? this.enableLogger,
      showDebugErrorMsg: showDebugErrorMsg ?? this.showDebugErrorMsg,
      useNativeShareSheet: useNativeShareSheet ?? this.useNativeShareSheet,
    );
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
        return 3;
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
      case 3:
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

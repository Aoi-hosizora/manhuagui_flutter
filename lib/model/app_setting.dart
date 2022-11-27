import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/config.dart';
import 'package:manhuagui_flutter/model/order.dart';
import 'package:manhuagui_flutter/page/log_console.dart';
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
  var _otherSetting = OtherSetting.defaultSetting;

  ViewSetting get view => _viewSetting;

  DlSetting get dl => _dlSetting;

  OtherSetting get other => _otherSetting;

  void update({ViewSetting? view, DlSetting? dl, OtherSetting? other}) {
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

    if (other != null) {
      _otherSetting = other;

      // apply other setting
      if (other.enableLogger) {
        LogConsolePage.initialize(globalLogger, bufferSize: LOG_CONSOLE_BUFFER);
      } else {
        LogConsolePage.finalize();
      }
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
  });

  final ViewDirection viewDirection; // 阅读方向
  final bool showPageHint; // 显示阅读页面提示
  final bool showClock; // 显示当前时间
  final bool showNetwork; // 显示网络状态
  final bool showBattery; // 显示电源余量
  final bool enablePageSpace; // 显示页面间空白
  final bool keepScreenOn; // 屏幕常亮
  final bool fullscreen; // 全屏阅读
  final int preloadCount; // 预加载页数

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
  }) {
    return ViewSetting(
      viewDirection: viewDirection ?? this.viewDirection,
      showPageHint: showPageHint ?? this.showPageHint,
      enablePageSpace: enablePageSpace ?? this.enablePageSpace,
      showClock: showClock ?? this.showClock,
      showNetwork: showNetwork ?? this.showNetwork,
      showBattery: showBattery ?? this.showBattery,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
      fullscreen: fullscreen ?? this.fullscreen,
      preloadCount: preloadCount ?? this.preloadCount,
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
  });

  final bool invertDownloadOrder; // 漫画章节下载顺序
  final bool defaultToDeleteFiles; // 默认删除已下载的文件
  final int downloadPagesTogether; // 同时下载的页面数量

  static const defaultSetting = DlSetting(
    invertDownloadOrder: false,
    defaultToDeleteFiles: false,
    downloadPagesTogether: 3,
  );

  DlSetting copyWith({
    bool? invertDownloadOrder,
    bool? defaultToDeleteFiles,
    int? downloadPagesTogether,
  }) {
    return DlSetting(
      invertDownloadOrder: invertDownloadOrder ?? this.invertDownloadOrder,
      defaultToDeleteFiles: defaultToDeleteFiles ?? this.defaultToDeleteFiles,
      downloadPagesTogether: downloadPagesTogether ?? this.downloadPagesTogether,
    );
  }
}

class OtherSetting {
  const OtherSetting({
    required this.timeoutBehavior,
    required this.dlTimeoutBehavior,
    required this.enableLogger,
    required this.usingDownloadedPage,
    required this.defaultMangaOrder,
    required this.defaultAuthorOrder,
  });

  final TimeoutBehavior timeoutBehavior; // 网络请求超时时间
  final TimeoutBehavior dlTimeoutBehavior; // 漫画下载超时时间
  final bool enableLogger; // 记录调试日志
  final bool usingDownloadedPage; // 阅读时载入已下载的页面
  final MangaOrder defaultMangaOrder; // 漫画默认排序方式
  final AuthorOrder defaultAuthorOrder; // 漫画作者默认排序方式

  static const defaultSetting = OtherSetting(
    timeoutBehavior: TimeoutBehavior.normal,
    dlTimeoutBehavior: TimeoutBehavior.normal,
    enableLogger: false,
    usingDownloadedPage: true,
    defaultMangaOrder: MangaOrder.byPopular,
    defaultAuthorOrder: AuthorOrder.byPopular,
  );

  OtherSetting copyWith({
    TimeoutBehavior? timeoutBehavior,
    TimeoutBehavior? dlTimeoutBehavior,
    bool? enableLogger,
    bool? usingDownloadedPage,
    MangaOrder? defaultMangaOrder,
    AuthorOrder? defaultAuthorOrder,
  }) {
    return OtherSetting(
      timeoutBehavior: timeoutBehavior ?? this.timeoutBehavior,
      dlTimeoutBehavior: dlTimeoutBehavior ?? this.dlTimeoutBehavior,
      enableLogger: enableLogger ?? this.enableLogger,
      usingDownloadedPage: usingDownloadedPage ?? this.usingDownloadedPage,
      defaultMangaOrder: defaultMangaOrder ?? this.defaultMangaOrder,
      defaultAuthorOrder: defaultAuthorOrder ?? this.defaultAuthorOrder,
    );
  }
}

enum TimeoutBehavior {
  normal,
  long,
  disable,
}

extension TimeoutBehaviorExtension on TimeoutBehavior {
  String toOptionTitle() {
    switch (this) {
      case TimeoutBehavior.normal:
        return '正常';
      case TimeoutBehavior.long:
        return '较长';
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
      case 2:
        return TimeoutBehavior.disable;
    }
    return TimeoutBehavior.normal;
  }

  T? determineValue<T>({required T normal, required T long, T? disable}) {
    switch (this) {
      case TimeoutBehavior.normal:
        return normal;
      case TimeoutBehavior.long:
        return long;
      case TimeoutBehavior.disable:
        return disable;
    }
  }
}

import 'dart:io';

import 'package:fit_system_screenshot/fit_system_screenshot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';
import 'package:manhuagui_flutter/app_setting.dart';

// References:
// - https://pub.dev/packages/fit_system_screenshot
// - https://github.com/YangLang116/fit_system_screenshot/blob/main/example/lib/case/nest_scroll_usage_page.dart
// - https://stackoverflow.com/questions/70116389/flutter-how-to-listen-for-navigation-event

// Used in MyApp.
void initFitSystemScreenshot() {
  fitSystemScreenshot.init();
}

// Used in MyApp.
void releaseFitSystemScreenshot() {
  fitSystemScreenshot.release();
}

// Used by FitSystemScreenshotMixin.
final fitSystemScreenshotObserver = RouteObserver<PageRoute>();

// Used by FitSystemScreenshotMixin.
class FitSystemScreenshotData {
  const FitSystemScreenshotData({
    required this.scrollViewKey,
    required this.scrollController,
    this.isNestedScrollView = false,
    this.headerSliverHeight = 0.0,
  });

  final GlobalKey<State<StatefulWidget>> scrollViewKey;
  final ScrollController scrollController;
  final bool isNestedScrollView;
  final double headerSliverHeight;

  ScrollController? get outerScrollController {
    if (!isNestedScrollView) {
      return null;
    }

    var state = scrollViewKey.currentState;
    if (state == null) {
      return null;
    }

    if (scrollViewKey.currentState is NestedScrollViewState) {
      return (scrollViewKey.currentState as NestedScrollViewState?)?.outerController;
    }
    if (scrollViewKey.currentState is ExtendedNestedScrollViewState) {
      return (scrollViewKey.currentState as ExtendedNestedScrollViewState?)?.outerController;
    }
    return null;
  }

  ScrollController? get innerScrollController {
    if (!isNestedScrollView) {
      return null;
    }

    var state = scrollViewKey.currentState;
    if (state == null) {
      return null;
    }

    if (scrollViewKey.currentState is NestedScrollViewState) {
      return (scrollViewKey.currentState as NestedScrollViewState?)?.innerController;
    }
    if (scrollViewKey.currentState is ExtendedNestedScrollViewState) {
      return (scrollViewKey.currentState as ExtendedNestedScrollViewState?)?.activeInnerController;
    }
    return null;
  }
}

mixin FitSystemScreenshotMixin<T extends StatefulWidget> on State<T> implements RouteAware {
  FitSystemScreenshotData get fitSystemScreenshotData;

  Dispose? _screenshotDisposer;

  ModalRoute? get _route {
    try {
      return ModalRoute.of(context);
    } on Exception {
      return null;
    } on Error {
      return null;
    }
  }

  void updatePageAttaching() {
    if (!AppSetting.instance.other.useEmulatedLongScreenshot) {
      return; // 开启模拟的长截图功能
    }

    // 1. 当A页面的数据加载完成后，需要重新调用该方法
    // 2. 当A页面打开B页面再退回到A页面时，需要重新调用该方法
    disposeScreenshot(); // dispose first
    _screenshotDisposer = _attachToNativePage();
  }

  void disposeScreenshot() {
    _screenshotDisposer?.call();
    _screenshotDisposer = null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      var route = _route;
      if (route != null && route is PageRoute) {
        fitSystemScreenshotObserver.subscribe(this, route);
      }
      await Future.delayed(Duration(milliseconds: 500)); // <<< CustomPageRouteThemeData.transitionDuration
      updatePageAttaching();
    });
  }

  @override
  void dispose() {
    // => DO NOT call `disposeScreenshot` here! DO this through `didPopNext`!
    fitSystemScreenshotObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPush() {
    // pass
  }

  @override
  void didPushNext() {
    var scrollAreaRect = _getScrollAreaRectFromKey(fitSystemScreenshotData.scrollViewKey);
    if (scrollAreaRect != null) {
      disposeScreenshot();
    }
  }

  @override
  void didPopNext() {
    var scrollAreaRect = _getScrollAreaRectFromKey(fitSystemScreenshotData.scrollViewKey);
    if (scrollAreaRect != null) {
      updatePageAttaching();
    }
  }

  @override
  void didPop() {
    // pass
  }

  // =========
  // callbacks
  // =========

  double? _lastScrollLength;
  double? _lastScrollOffset;

  void _updateScrollLength() {
    double scrollLength;
    var data = fitSystemScreenshotData;
    if (!data.isNestedScrollView) {
      if (!data.scrollController.hasClients) return;
      var position = data.scrollController.position;
      scrollLength = position.viewportDimension + position.maxScrollExtent;
    } else if (data.outerScrollController != null && data.innerScrollController != null) {
      if (!data.outerScrollController!.hasClients) return;
      if (!data.innerScrollController!.hasClients) return;
      var outerPosition = data.outerScrollController!.position;
      var innerPosition = data.innerScrollController!.position;
      scrollLength = innerPosition.viewportDimension + innerPosition.maxScrollExtent + outerPosition.maxScrollExtent;
    } else {
      return;
    }

    scrollLength = scrollLength.round().toDouble();
    if (_lastScrollLength == null || _lastScrollLength != scrollLength) {
      _lastScrollLength = scrollLength;
      fitSystemScreenshot.updateScrollLength(scrollLength);
    }
  }

  void _updateScrollOffset() {
    var data = fitSystemScreenshotData;
    double scrollOffset;
    if (!data.isNestedScrollView) {
      if (!data.scrollController.hasClients) return;
      scrollOffset = data.scrollController.offset;
    } else if (data.outerScrollController != null && data.innerScrollController != null) {
      if (!data.outerScrollController!.hasClients) return;
      if (!data.innerScrollController!.hasClients) return;
      if (!data.outerScrollController!.position.atBottomEdge()) {
        scrollOffset = data.outerScrollController!.offset;
      } else {
        scrollOffset = data.innerScrollController!.offset + data.headerSliverHeight;
      }
    } else {
      return;
    }

    scrollOffset = scrollOffset.round().toDouble();
    if (_lastScrollOffset == null || _lastScrollOffset != scrollOffset) {
      if (!fitSystemScreenshot.isScreenShot) {
        fitSystemScreenshot.updateScrollPosition(scrollOffset);
      }
    }
  }

  void _screenshotScroll(double offset) {
    var data = fitSystemScreenshotData;
    ScrollController controller;
    if (!data.isNestedScrollView) {
      if (!data.scrollController.hasClients) return;
      controller = data.scrollController;
    } else {
      if (offset <= data.headerSliverHeight) {
        if (data.outerScrollController == null || !data.outerScrollController!.hasClients) return;
        controller = data.outerScrollController!;
      } else {
        if (data.innerScrollController == null || !data.innerScrollController!.hasClients) return;
        controller = data.innerScrollController!;
        offset -= data.headerSliverHeight;
      }
    }
    if (controller.hasClients) {
      offset = offset.clamp(controller.position.minScrollExtent, controller.position.maxScrollExtent);
      controller.jumpTo(offset);
    }
  }

  void _scrollListener() {
    _updateScrollLength(); // fitSystemScreenshot.updateScrollLength
    _updateScrollOffset(); // fitSystemScreenshot.updateScrollPosition
  }

  // ==============
  // attach to page
  // ==============

  Dispose _attachToNativePage<S extends State<StatefulWidget>>() {
    if (!Platform.isAndroid) {
      return () {};
    }

    Future.delayed(Duration(milliseconds: 200)).then((_) {
      // wait for scroll controller position binding
      _lastScrollLength = null; // remember to reset these states
      _lastScrollOffset = null;
      fitSystemScreenshot.onScreenShotScroll = _screenshotScroll;
      var data = fitSystemScreenshotData;
      _updateScrollArea(data.scrollViewKey);
      _scrollListener(); // _updateScrollLength and _updateScrollOffset
      if (!data.isNestedScrollView) {
        if (data.scrollController.hasClients) {
          data.scrollController.position.addListener(_scrollListener);
        }
      } else if (data.outerScrollController != null && data.innerScrollController != null) {
        if (data.outerScrollController!.hasClients) {
          data.outerScrollController!.position.addListener(_scrollListener);
        }
        if (data.innerScrollController!.hasClients) {
          data.innerScrollController!.position.addListener(_scrollListener);
        }
      }
    });

    return () {
      _lastScrollLength = null; // remember to reset these states
      _lastScrollOffset = null;
      fitSystemScreenshot.onScreenShotScroll = null;
      var data = fitSystemScreenshotData;
      if (!data.isNestedScrollView) {
        if (data.scrollController.hasClients) {
          data.scrollController.position.removeListener(_scrollListener);
        }
      } else if (data.outerScrollController != null && data.innerScrollController != null) {
        if (data.outerScrollController!.hasClients) {
          data.outerScrollController!.position.removeListener(_scrollListener);
        }
        if (data.innerScrollController!.hasClients) {
          data.innerScrollController!.position.removeListener(_scrollListener);
        }
      }
    };
  }

  Rect? _getScrollAreaRectFromKey(GlobalKey scrollAreaKey) {
    var renderBox = scrollAreaKey.currentContext?.findRenderBox();
    if (renderBox == null) {
      return null;
    }

    var size = renderBox.size;
    var offset = renderBox.localToGlobal(Offset.zero);
    var rect = offset & size;

    if (!rect.isFinite || rect.isEmpty) {
      return null; // this can also be used to check navigation `didPushNext` and `didPopNext`
    }
    return rect;
  }

  void _updateScrollArea(GlobalKey scrollAreaKey) {
    if (!Platform.isAndroid) {
      return;
    }
    var scrollAreaRect = _getScrollAreaRectFromKey(scrollAreaKey);
    if (scrollAreaRect != null) {
      fitSystemScreenshot.updateScrollArea(scrollAreaRect);
    }
  }
}

// Used for FitSystemScreenshotMixin.
extension FitSystemScreenshotExtension on Widget {
  Widget fitSystemScreenshot(FitSystemScreenshotMixin mixin) {
    return _FitSystemScreenshotListener(
      child: this,
      mixin: mixin,
      onNotification: (isInit) {
        WidgetsBinding.instance?.addPostFrameCallback((_) async {
          if (isInit) {
            await Future.delayed(Duration(milliseconds: 500)); // <<< CustomPageRouteThemeData.transitionDuration
          }
          mixin.updatePageAttaching();
        });
      },
    );
  }
}

// Used for FitSystemScreenshotMixin.
class _FitSystemScreenshotListener extends StatefulWidget {
  const _FitSystemScreenshotListener({
    Key? key,
    required this.child,
    required this.mixin,
    this.onNotification,
  }) : super(key: key);

  final Widget child;
  final FitSystemScreenshotMixin mixin;
  final void Function(bool isInit)? onNotification;

  @override
  State<_FitSystemScreenshotListener> createState() => _FitSystemScreenshotListenerState();
}

class _FitSystemScreenshotListenerState extends State<_FitSystemScreenshotListener> {
  bool? _lastCanScrollDown;

  bool _onNotification(Notification n) {
    if (n is! ScrollMetricsNotification && n is! ScrollUpdateNotification) {
      return false;
    }

    var data = widget.mixin.fitSystemScreenshotData;
    bool canScrollDown;
    if (!data.isNestedScrollView) {
      if (!data.scrollController.hasClients) return false;
      canScrollDown = !data.scrollController.position.atBottomEdge();
    } else if (data.outerScrollController != null && data.innerScrollController != null) {
      if (!data.outerScrollController!.hasClients) return false;
      if (!data.innerScrollController!.hasClients) return false;
      canScrollDown = !data.outerScrollController!.position.atBottomEdge() || !data.innerScrollController!.position.atBottomEdge();
    } else {
      return false;
    }

    if (_lastCanScrollDown == null || _lastCanScrollDown != canScrollDown) {
      _lastCanScrollDown = canScrollDown;
      widget.onNotification?.call(_lastCanScrollDown == null);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener(
      child: widget.child,
      onNotification: _onNotification,
    );
  }
}

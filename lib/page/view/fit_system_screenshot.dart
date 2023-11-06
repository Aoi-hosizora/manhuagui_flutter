import 'dart:io';

import 'package:fit_system_screenshot/fit_system_screenshot.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_ahlib/flutter_ahlib.dart';

// References:
// - https://pub.dev/packages/fit_system_screenshot
// - https://stackoverflow.com/questions/70116389/flutter-how-to-listen-for-navigation-event

void initFitSystemScreenshot() {
  fitSystemScreenshot.init();
}

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
  });

  final GlobalKey<State<StatefulWidget>> scrollViewKey;
  final ScrollController scrollController;
}

mixin FitSystemScreenshotMixin<T extends StatefulWidget> on State<T> implements RouteAware {
  FitSystemScreenshotData? get fitSystemScreenshotData => null;

  Dispose? _screenshotDisposer;

  void updatePageAttaching([FitSystemScreenshotData? data]) {
    disposeScreenshot(); // dispose first

    // 1. 当A页面的数据加载完成后，需要重新调用该方法
    // 2. 当A页面打开B页面再退回到A页面时，需要重新调用该方法
    var data = fitSystemScreenshotData;
    if (data != null && data.scrollController.hasClients) {
      _screenshotDisposer = _attachToPage(
        data.scrollViewKey,
        data.scrollController,
        (offset) {
          offset = offset.clamp(
            data.scrollController.position.minScrollExtent,
            data.scrollController.position.maxScrollExtent,
          );
          data.scrollController.jumpTo(offset);
        },
      );
    }
  }

  void disposeScreenshot() {
    _screenshotDisposer?.call();
    _screenshotDisposer = null;
  }

  @override
  void initState() {
    super.initState();
    updatePageAttaching(); // TODO maybe need to be called in widgets
    var route = ModalRoute.of(context);
    if (route != null && route is PageRoute) {
      fitSystemScreenshotObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    fitSystemScreenshotObserver.unsubscribe(this);
    disposeScreenshot();
    super.dispose();
  }

  @override
  void didPush() {
    // pass
  }

  @override
  void didPushNext() {
    disposeScreenshot();
  }

  @override
  void didPopNext() {
    updatePageAttaching();
  }

  @override
  void didPop() {
    // pass
  }

  Dispose _attachToPage<S extends State<StatefulWidget>>(
    GlobalKey<S> scrollAreaKey,
    ScrollController scrollController,
    OnScreenShotScroll onScreenShotScroll,
  ) {
    if (!Platform.isAndroid) return () {};
    bool isNestedScrollView = S.toString() == 'NestedScrollViewState';
    bool isExtendedNestedScrollView = S.toString() == 'ExtendedNestedScrollViewState';
    double currentScrollLength = 0;
    final refreshScrollLength = () {
      double newLength = 0;
      if (isNestedScrollView || isExtendedNestedScrollView) {
        ScrollPosition innerPos, outPos;
        if (isNestedScrollView) {
          var nestedState = scrollAreaKey.currentState as NestedScrollViewState?;
          if (nestedState == null) return;
          innerPos = nestedState.innerController.position;
          outPos = nestedState.outerController.position;
        } else {
          var nestedState = scrollAreaKey.currentState as ExtendedNestedScrollViewState?;
          if (nestedState == null) return;
          innerPos = nestedState.innerControllers[nestedState.widget.activeControllerIndex].position;
          outPos = nestedState.outerController.position;
        }
        newLength += innerPos.viewportDimension + innerPos.maxScrollExtent + outPos.maxScrollExtent;
      } else {
        ScrollPosition position = scrollController.position;
        newLength = position.viewportDimension + position.maxScrollExtent;
      }
      if (currentScrollLength == newLength) return;
      currentScrollLength = newLength;
      fitSystemScreenshot.updateScrollLength(newLength);
    };
    final onScrollListener = () {
      refreshScrollLength();
      if (!fitSystemScreenshot.isScreenShot) fitSystemScreenshot.updateScrollPosition(scrollController.offset);
    };
    SchedulerBinding.instance?.addPostFrameCallback((timeStamp) {
      fitSystemScreenshot.onScreenShotScroll = onScreenShotScroll;
      fitSystemScreenshot.updateScrollAreaWithKey(scrollAreaKey);
      refreshScrollLength();
      fitSystemScreenshot.updateScrollPosition(scrollController.offset);
      scrollController.position.addListener(onScrollListener);
    });
    return () {
      fitSystemScreenshot.onScreenShotScroll = null;
      if (scrollController.hasClients) {
        scrollController.position.removeListener(onScrollListener);
      }
    };
  }
}

// Used for FitSystemScreenshotMixin.
extension FitSystemScreenshotExtension on Widget {
  Widget fitSystemScreenshot(FitSystemScreenshotMixin mixin) {
    return MaxScrollExtentListener(
      child: this,
      onNotification: (maxScrollExtent) {
        mixin.updatePageAttaching();
      },
    );
  }
}

// Used for FitSystemScreenshotMixin.
class MaxScrollExtentListener extends StatefulWidget {
  const MaxScrollExtentListener({
    Key? key,
    required this.child,
    this.onNotification,
  }) : super(key: key);

  final Widget child;
  final void Function(double maxScrollExtent)? onNotification;

  @override
  State<MaxScrollExtentListener> createState() => _MaxScrollExtentListenerState();
}

class _MaxScrollExtentListenerState extends State<MaxScrollExtentListener> {
  var _lastMaxScrollExtent = -1.0;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollMetricsNotification>(
      child: widget.child,
      onNotification: (n) {
        var maxScrollExtent = n.metrics.maxScrollExtent;
        if (_lastMaxScrollExtent < 0 || _lastMaxScrollExtent != maxScrollExtent) {
          _lastMaxScrollExtent = maxScrollExtent;
          widget.onNotification?.call(maxScrollExtent);
        }
        return false;
      },
    );
  }
}

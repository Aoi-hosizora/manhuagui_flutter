import 'package:manhuagui_flutter/service/natives/prefs.dart';

enum ScrollDirection {
  l2r, // 从左往右
  r2l, // 从右往左
}

const _SCROLL_DIRECTION = 'SCROLL_DIRECTION';
const _SHOW_PAGE_HINT = 'SHOW_PAGE_HINT';
const _USE_SWIPE_FOR_CHAPTER = 'USE_SWIPE_FOR_CHAPTER';
const _USE_CLICK_FOR_CHAPTER = 'USE_CLICK_FOR_CHAPTER';
const _NEED_CHECK_FOR_CHAPTER = 'NEED_CHECK_FOR_CHAPTER';
const _ENABLE_PAGE_SPACE = 'ENABLE_PAGE_SPACE';

class CategoryViewSetting {
  CategoryViewSetting();

  ScrollDirection scrollDirection; // 拖动方向
  bool showPageHint; // 显示页码提示
  bool useSwipeForChapter; // 滑动跳转至章节
  bool useClickForChapter; // 点击跳转至章节
  bool needCheckForChapter; // 跳转章节时弹出提示
  bool enablePageSpace; // 显示页面间隔

  Future<bool> existed() async {
    var prefs = await getPrefs();
    return prefs.containsKey(_SCROLL_DIRECTION);
  }

  CategoryViewSetting.defaultSetting() {
    scrollDirection = ScrollDirection.l2r;
    showPageHint = true;
    useSwipeForChapter = true;
    useClickForChapter = true;
    needCheckForChapter = true;
    enablePageSpace = true;
  }

  Future<void> load() async {
    var def = CategoryViewSetting.defaultSetting();
    var prefs = await getPrefs();
    scrollDirection = (prefs.getBool(_SCROLL_DIRECTION) ?? true) ? ScrollDirection.l2r : ScrollDirection.r2l;
    showPageHint = prefs.getBool(_SHOW_PAGE_HINT) ?? def.showPageHint;
    useSwipeForChapter = prefs.getBool(_USE_SWIPE_FOR_CHAPTER) ?? def.useSwipeForChapter;
    useClickForChapter = prefs.getBool(_USE_CLICK_FOR_CHAPTER) ?? def.useClickForChapter;
    needCheckForChapter = prefs.getBool(_NEED_CHECK_FOR_CHAPTER) ?? def.needCheckForChapter;
    enablePageSpace = prefs.getBool(_ENABLE_PAGE_SPACE) ?? def.enablePageSpace;
  }

  Future<void> save() async {
    var prefs = await getPrefs();
    prefs.setBool(_SCROLL_DIRECTION, scrollDirection == ScrollDirection.l2r);
    prefs.setBool(_SHOW_PAGE_HINT, showPageHint);
    prefs.setBool(_USE_SWIPE_FOR_CHAPTER, useSwipeForChapter);
    prefs.setBool(_USE_CLICK_FOR_CHAPTER, useClickForChapter);
    prefs.setBool(_NEED_CHECK_FOR_CHAPTER, needCheckForChapter);
    prefs.setBool(_ENABLE_PAGE_SPACE, enablePageSpace);
  }
}

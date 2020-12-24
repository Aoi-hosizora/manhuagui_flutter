import 'package:manhuagui_flutter/service/natives/prefs.dart';

const _SCROLL_DIRECTION = 'SCROLL_DIRECTION';
const _SHOW_PAGE_HINT = 'SHOW_PAGE_HINT';
const _USE_SWIPE_FOR_CHAPTER = 'USE_SWIPE_FOR_CHAPTER';
const _USE_CLICK_FOR_CHAPTER = 'USE_CLICK_FOR_CHAPTER';
const _NEED_CHECK_FOR_CHAPTER = 'NEED_CHECK_FOR_CHAPTER';
const _ENABLE_PAGE_SPACE = 'ENABLE_PAGE_SPACE';
const _PRELOAD_COUNT = 'PRELOAD_COUNT';

class CategoryViewSetting {
  CategoryViewSetting();

  bool reverseScroll; // 反转拖动
  bool showPageHint; // 显示页码提示
  bool useSwipeForChapter; // 滑动跳转至章节
  bool useClickForChapter; // 点击跳转至章节
  bool needCheckForChapter; // 跳转章节时弹出提示
  bool enablePageSpace; // 显示页面间隔
  int preloadCount; // 预加载页数

  Future<bool> existed() async {
    var prefs = await getPrefs();
    return prefs.containsKey(_SCROLL_DIRECTION);
  }

  CategoryViewSetting.defaultSetting() {
    reverseScroll = false;
    showPageHint = true;
    useSwipeForChapter = true;
    useClickForChapter = true;
    needCheckForChapter = true;
    enablePageSpace = true;
    preloadCount = 2;
  }

  Future<void> load() async {
    var def = CategoryViewSetting.defaultSetting();
    var prefs = await getPrefs();
    reverseScroll = prefs.getBool(_SCROLL_DIRECTION) ?? def.reverseScroll;
    showPageHint = prefs.getBool(_SHOW_PAGE_HINT) ?? def.showPageHint;
    useSwipeForChapter = prefs.getBool(_USE_SWIPE_FOR_CHAPTER) ?? def.useSwipeForChapter;
    useClickForChapter = prefs.getBool(_USE_CLICK_FOR_CHAPTER) ?? def.useClickForChapter;
    needCheckForChapter = prefs.getBool(_NEED_CHECK_FOR_CHAPTER) ?? def.needCheckForChapter;
    enablePageSpace = prefs.getBool(_ENABLE_PAGE_SPACE) ?? def.enablePageSpace;
    preloadCount = prefs.getInt(_PRELOAD_COUNT) ?? def.preloadCount;
  }

  Future<void> save() async {
    var prefs = await getPrefs();
    await prefs.setBool(_SCROLL_DIRECTION, reverseScroll);
    await prefs.setBool(_SHOW_PAGE_HINT, showPageHint);
    await prefs.setBool(_USE_SWIPE_FOR_CHAPTER, useSwipeForChapter);
    await prefs.setBool(_USE_CLICK_FOR_CHAPTER, useClickForChapter);
    await prefs.setBool(_NEED_CHECK_FOR_CHAPTER, needCheckForChapter);
    await prefs.setBool(_ENABLE_PAGE_SPACE, enablePageSpace);
    await prefs.setInt(_PRELOAD_COUNT, preloadCount);
  }
}

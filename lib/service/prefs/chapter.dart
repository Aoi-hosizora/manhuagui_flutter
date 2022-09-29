import 'package:manhuagui_flutter/service/prefs/prefs_manager.dart';

const _scrollDirection = 'SCROLL_DIRECTION'; // bool
const _showPageHint = 'SHOW_PAGE_HINT'; // bool
const _useSwipeForChapter = 'USE_SWIPE_FOR_CHAPTER'; // bool
const _useClickForChapter = 'USE_CLICK_FOR_CHAPTER'; // bool
const _needCheckForChapter = 'NEED_CHECK_FOR_CHAPTER'; // bool
const _enablePageSpace = 'ENABLE_PAGE_SPACE'; // bool
const _preloadCount = 'PRELOAD_COUNT'; // int

class ChapterPageSetting {
  ChapterPageSetting();

  bool reverseScroll = false; // 反转拖动
  bool showPageHint = true; // 显示页码提示
  bool useSwipeForChapter = true; // 滑动跳转至章节
  bool useClickForChapter = true; // 点击跳转至章节
  bool needCheckForChapter = true; // 跳转章节时弹出提示
  bool enablePageSpace = true; // 显示页面间隔
  int preloadCount = 2; // 预加载页数

  ChapterPageSetting.defaultSetting() {
    reverseScroll = false;
    showPageHint = true;
    useSwipeForChapter = true;
    useClickForChapter = true;
    needCheckForChapter = true;
    enablePageSpace = true;
    preloadCount = 2;
  }

  Future<bool> existed() async {
    var prefs = await PrefsManager.instance.loadPrefs();
    return prefs.containsKey(_scrollDirection);
  }

  Future<void> load() async {
    var def = ChapterPageSetting.defaultSetting();
    var prefs = await PrefsManager.instance.loadPrefs();
    reverseScroll = prefs.getBool(_scrollDirection) ?? def.reverseScroll;
    showPageHint = prefs.getBool(_showPageHint) ?? def.showPageHint;
    useSwipeForChapter = prefs.getBool(_useSwipeForChapter) ?? def.useSwipeForChapter;
    useClickForChapter = prefs.getBool(_useClickForChapter) ?? def.useClickForChapter;
    needCheckForChapter = prefs.getBool(_needCheckForChapter) ?? def.needCheckForChapter;
    enablePageSpace = prefs.getBool(_enablePageSpace) ?? def.enablePageSpace;
    preloadCount = prefs.getInt(_preloadCount) ?? def.preloadCount;
  }

  Future<void> save() async {
    var prefs = await PrefsManager.instance.loadPrefs();
    await prefs.setBool(_scrollDirection, reverseScroll);
    await prefs.setBool(_showPageHint, showPageHint);
    await prefs.setBool(_useSwipeForChapter, useSwipeForChapter);
    await prefs.setBool(_useClickForChapter, useClickForChapter);
    await prefs.setBool(_needCheckForChapter, needCheckForChapter);
    await prefs.setBool(_enablePageSpace, enablePageSpace);
    await prefs.setInt(_preloadCount, preloadCount);
  }
}

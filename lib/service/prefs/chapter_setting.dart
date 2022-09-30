import 'package:manhuagui_flutter/service/prefs/prefs_manager.dart';

class ChapterSetting {
  ChapterSetting({
    required this.reverseScroll,
    required this.showPageHint,
    required this.useSwipeForChapter,
    required this.useClickForChapter,
    required this.needCheckForChapter,
    required this.enablePageSpace,
    required this.preloadCount,
  });

  final bool reverseScroll; // 反转拖动
  final bool showPageHint; // 显示页码提示
  final bool useSwipeForChapter; // 滑动跳转至章节
  final bool useClickForChapter; // 点击跳转至章节
  final bool needCheckForChapter; // 跳转章节时弹出提示
  final bool enablePageSpace; // 显示页面间隔
  final int preloadCount; // 预加载页数

  ChapterSetting.defaultSetting()
      : this(
          reverseScroll: false,
          showPageHint: true,
          useSwipeForChapter: true,
          useClickForChapter: true,
          needCheckForChapter: true,
          enablePageSpace: true,
          preloadCount: 2,
        );

  ChapterSetting copyWith({
    bool? reverseScroll,
    bool? showPageHint,
    bool? useSwipeForChapter,
    bool? useClickForChapter,
    bool? needCheckForChapter,
    bool? enablePageSpace,
    int? preloadCount,
  }) {
    return ChapterSetting(
      reverseScroll: reverseScroll ?? this.reverseScroll,
      showPageHint: showPageHint ?? this.showPageHint,
      useSwipeForChapter: useSwipeForChapter ?? this.useSwipeForChapter,
      useClickForChapter: useClickForChapter ?? this.useClickForChapter,
      needCheckForChapter: needCheckForChapter ?? this.needCheckForChapter,
      enablePageSpace: enablePageSpace ?? this.enablePageSpace,
      preloadCount: preloadCount ?? this.preloadCount,
    );
  }
}

class ChapterSettingPrefs {
  ChapterSettingPrefs._();

  static const _scrollDirectionKey = 'SCROLL_DIRECTION'; // bool
  static const _showPageHintKey = 'SHOW_PAGE_HINT'; // bool
  static const _useSwipeForChapterKey = 'USE_SWIPE_FOR_CHAPTER'; // bool
  static const _useClickForChapterKey = 'USE_CLICK_FOR_CHAPTER'; // bool
  static const _needCheckForChapterKey = 'NEED_CHECK_FOR_CHAPTER'; // bool
  static const _enablePageSpaceKey = 'ENABLE_PAGE_SPACE'; // bool
  static const _preloadCountKey = 'PRELOAD_COUNT'; // int

  static Future<ChapterSetting> load() async {
    var def = ChapterSetting.defaultSetting();
    final prefs = await PrefsManager.instance.loadPrefs();
    return ChapterSetting(
      reverseScroll: prefs.getBool(_scrollDirectionKey) ?? def.reverseScroll,
      showPageHint: prefs.getBool(_showPageHintKey) ?? def.showPageHint,
      useSwipeForChapter: prefs.getBool(_useSwipeForChapterKey) ?? def.useSwipeForChapter,
      useClickForChapter: prefs.getBool(_useClickForChapterKey) ?? def.useClickForChapter,
      needCheckForChapter: prefs.getBool(_needCheckForChapterKey) ?? def.needCheckForChapter,
      enablePageSpace: prefs.getBool(_enablePageSpaceKey) ?? def.enablePageSpace,
      preloadCount: prefs.getInt(_preloadCountKey) ?? def.preloadCount,
    );
  }

  static Future<void> save(ChapterSetting setting) async {
    final prefs = await PrefsManager.instance.loadPrefs();
    await prefs.setBool(_scrollDirectionKey, setting.reverseScroll);
    await prefs.setBool(_showPageHintKey, setting.showPageHint);
    await prefs.setBool(_useSwipeForChapterKey, setting.useSwipeForChapter);
    await prefs.setBool(_useClickForChapterKey, setting.useClickForChapter);
    await prefs.setBool(_needCheckForChapterKey, setting.needCheckForChapter);
    await prefs.setBool(_enablePageSpaceKey, setting.enablePageSpace);
    await prefs.setInt(_preloadCountKey, setting.preloadCount);
  }
}

import 'package:manhuagui_flutter/service/prefs/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  static const _scrollDirectionKey = 'ChapterSettingPrefs_scrollDirection'; // bool
  static const _showPageHintKey = 'ChapterSettingPrefs_showPageHint'; // bool
  static const _useSwipeForChapterKey = 'ChapterSettingPrefs_useSwipeForChapter'; // bool
  static const _useClickForChapterKey = 'ChapterSettingPrefs_useClickForChapter'; // bool
  static const _needCheckForChapterKey = 'ChapterSettingPrefs_needCheckForChapter'; // bool
  static const _enablePageSpaceKey = 'ChapterSettingPrefs_enablePageSpace'; // bool
  static const _preloadCountKey = 'ChapterSettingPrefs_preloadCount'; // int

  static Future<ChapterSetting> getSetting() async {
    final prefs = await PrefsManager.instance.loadPrefs();
    var def = ChapterSetting.defaultSetting();
    return ChapterSetting(
      reverseScroll: prefs.safeGetBool(_scrollDirectionKey) ?? def.reverseScroll,
      showPageHint: prefs.safeGetBool(_showPageHintKey) ?? def.showPageHint,
      useSwipeForChapter: prefs.safeGetBool(_useSwipeForChapterKey) ?? def.useSwipeForChapter,
      useClickForChapter: prefs.safeGetBool(_useClickForChapterKey) ?? def.useClickForChapter,
      needCheckForChapter: prefs.safeGetBool(_needCheckForChapterKey) ?? def.needCheckForChapter,
      enablePageSpace: prefs.safeGetBool(_enablePageSpaceKey) ?? def.enablePageSpace,
      preloadCount: prefs.safeGetInt(_preloadCountKey) ?? def.preloadCount,
    );
  }

  static Future<void> setSetting(ChapterSetting setting) async {
    final prefs = await PrefsManager.instance.loadPrefs();
    await prefs.setBool(_scrollDirectionKey, setting.reverseScroll);
    await prefs.setBool(_showPageHintKey, setting.showPageHint);
    await prefs.setBool(_useSwipeForChapterKey, setting.useSwipeForChapter);
    await prefs.setBool(_useClickForChapterKey, setting.useClickForChapter);
    await prefs.setBool(_needCheckForChapterKey, setting.needCheckForChapter);
    await prefs.setBool(_enablePageSpaceKey, setting.enablePageSpace);
    await prefs.setInt(_preloadCountKey, setting.preloadCount);
  }

  static Future<void> upgradeFromVer1To2(SharedPreferences prefs) async {
    var def = ChapterSetting.defaultSetting();
    await prefs.migrateBool(oldKey: 'SCROLL_DIRECTION', newKey: _scrollDirectionKey, defaultValue: def.reverseScroll);
    await prefs.migrateBool(oldKey: 'SHOW_PAGE_HINT', newKey: _showPageHintKey, defaultValue: def.showPageHint);
    await prefs.migrateBool(oldKey: 'USE_SWIPE_FOR_CHAPTER', newKey: _useSwipeForChapterKey, defaultValue: def.useSwipeForChapter);
    await prefs.migrateBool(oldKey: 'USE_CLICK_FOR_CHAPTER', newKey: _useClickForChapterKey, defaultValue: def.useClickForChapter);
    await prefs.migrateBool(oldKey: 'NEED_CHECK_FOR_CHAPTER', newKey: _needCheckForChapterKey, defaultValue: def.needCheckForChapter);
    await prefs.migrateBool(oldKey: 'ENABLE_PAGE_SPACE', newKey: _enablePageSpaceKey, defaultValue: def.enablePageSpace);
    await prefs.migrateInt(oldKey: 'PRELOAD_COUNT', newKey: _preloadCountKey, defaultValue: def.preloadCount);
  }
}

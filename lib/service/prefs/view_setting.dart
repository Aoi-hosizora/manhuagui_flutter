import 'package:manhuagui_flutter/page/page/view_setting.dart';
import 'package:manhuagui_flutter/service/prefs/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ViewSettingPrefs {
  ViewSettingPrefs._();

  static const _scrollDirectionKey = 'ChapterSettingPrefs_scrollDirection'; // bool
  static const _showPageHintKey = 'ChapterSettingPrefs_showPageHint'; // bool
  static const _useSwipeForChapterKey = 'ChapterSettingPrefs_useSwipeForChapter'; // bool
  static const _useClickForChapterKey = 'ChapterSettingPrefs_useClickForChapter'; // bool
  static const _needCheckForChapterKey = 'ChapterSettingPrefs_needCheckForChapter'; // bool
  static const _enablePageSpaceKey = 'ChapterSettingPrefs_enablePageSpace'; // bool
  static const _preloadCountKey = 'ChapterSettingPrefs_preloadCount'; // int

  static Future<ViewSetting> getSetting() async {
    final prefs = await PrefsManager.instance.loadPrefs();
    var def = ViewSetting.defaultSetting();
    return ViewSetting(
      reverseScroll: prefs.safeGetBool(_scrollDirectionKey) ?? def.reverseScroll,
      showPageHint: prefs.safeGetBool(_showPageHintKey) ?? def.showPageHint,
      useSwipeForChapter: prefs.safeGetBool(_useSwipeForChapterKey) ?? def.useSwipeForChapter,
      useClickForChapter: prefs.safeGetBool(_useClickForChapterKey) ?? def.useClickForChapter,
      needCheckForChapter: prefs.safeGetBool(_needCheckForChapterKey) ?? def.needCheckForChapter,
      enablePageSpace: prefs.safeGetBool(_enablePageSpaceKey) ?? def.enablePageSpace,
      preloadCount: prefs.safeGetInt(_preloadCountKey) ?? def.preloadCount,
    );
  }

  static Future<void> setSetting(ViewSetting setting) async {
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
    var def = ViewSetting.defaultSetting();
    await prefs.migrateBool(oldKey: 'SCROLL_DIRECTION', newKey: _scrollDirectionKey, defaultValue: def.reverseScroll);
    await prefs.migrateBool(oldKey: 'SHOW_PAGE_HINT', newKey: _showPageHintKey, defaultValue: def.showPageHint);
    await prefs.migrateBool(oldKey: 'USE_SWIPE_FOR_CHAPTER', newKey: _useSwipeForChapterKey, defaultValue: def.useSwipeForChapter);
    await prefs.migrateBool(oldKey: 'USE_CLICK_FOR_CHAPTER', newKey: _useClickForChapterKey, defaultValue: def.useClickForChapter);
    await prefs.migrateBool(oldKey: 'NEED_CHECK_FOR_CHAPTER', newKey: _needCheckForChapterKey, defaultValue: def.needCheckForChapter);
    await prefs.migrateBool(oldKey: 'ENABLE_PAGE_SPACE', newKey: _enablePageSpaceKey, defaultValue: def.enablePageSpace);
    await prefs.migrateInt(oldKey: 'PRELOAD_COUNT', newKey: _preloadCountKey, defaultValue: def.preloadCount);
  }
}

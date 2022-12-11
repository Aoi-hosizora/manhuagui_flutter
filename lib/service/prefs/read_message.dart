import 'package:manhuagui_flutter/service/prefs/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReadMessagePrefs {
  ReadMessagePrefs._();

  static const _readMessagesKey = StringListKey('ReadMessagePrefs_readMessageIds');

  static Future<List<int>> getReadMessages() async {
    final prefs = await PrefsManager.instance.loadPrefs();
    return prefs.safeGet<List<String>>(_readMessagesKey)?.map((e) => int.tryParse(e) ?? 0).toList() ?? [];
  }

  static Future<void> clearReadMessages() async {
    final prefs = await PrefsManager.instance.loadPrefs();
    await prefs.safeSet<List<String>>(_readMessagesKey, []);
  }

  static Future<List<int>> addReadMessages(List<int> mids) async {
    final prefs = await PrefsManager.instance.loadPrefs();
    var data = await getReadMessages();
    data.removeWhere((el) => mids.contains(el));
    data.addAll(mids);
    await prefs.safeSet<List<String>>(_readMessagesKey, data.map((e) => e.toString()).toList());
    return data;
  }

  static Future<List<int>> addReadMessage(int mid) async {
    return await addReadMessages([mid]);
  }

  static Future<List<int>> removeReadMessage(int mid) async {
    final prefs = await PrefsManager.instance.loadPrefs();
    var data = await getReadMessages();
    data.removeWhere((h) => h == mid);
    await prefs.safeSet<List<String>>(_readMessagesKey, data.map((e) => e.toString()).toList());
    return data;
  }

  static Future<void> upgradeFromVer1To2(SharedPreferences prefs) async {
    // pass
  }

  static Future<void> upgradeFromVer2To3(SharedPreferences prefs) async {
    await prefs.safeMigrate<List<String>>('MessagePrefs_readMessageIds', _readMessagesKey, defaultValue: []);
  }
}

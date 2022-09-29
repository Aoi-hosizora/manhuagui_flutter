import 'package:shared_preferences/shared_preferences.dart';

class PrefsManager {
  PrefsManager._();

  static PrefsManager? _instance;

  static PrefsManager get instance {
    _instance ??= PrefsManager._();
    return _instance!;
  }

  SharedPreferences? _prefs; // global SharedPreferences instance

  Future<SharedPreferences> loadPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<SharedPreferences> reloadPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    return _prefs!;
  }
}

import 'package:shared_preferences/shared_preferences.dart';

/// Хранит id текущего пользователя между запусками (SharedPreferences).
class SessionLocalDataSource {
  SessionLocalDataSource(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'current_user_id';

  int? getCurrentUserId() => _prefs.getInt(_key);

  Future<void> setCurrentUserId(int? id) async {
    if (id == null) {
      await _prefs.remove(_key);
    } else {
      await _prefs.setInt(_key, id);
    }
  }
}

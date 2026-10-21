import 'package:shared_preferences/shared_preferences.dart';

class SessionStore {
  SessionStore(this._prefs);

  static const _tokenKey = 'badrgo_session_token';

  final SharedPreferences _prefs;

  String? get token => _prefs.getString(_tokenKey);

  Future<void> saveToken(String token) => _prefs.setString(_tokenKey, token);

  Future<void> clear() => _prefs.remove(_tokenKey);
}

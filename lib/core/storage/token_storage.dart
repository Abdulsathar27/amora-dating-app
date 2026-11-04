import 'package:shared_preferences/shared_preferences.dart';

/// Persists auth tokens. Swap for flutter_secure_storage before release.
class TokenStorage {
  TokenStorage(this._prefs);

  final SharedPreferences _prefs;

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  String? get accessToken => _prefs.getString(_accessKey);
  String? get refreshToken => _prefs.getString(_refreshKey);
  bool get hasSession => accessToken != null;

  Future<void> save({required String accessToken, required String refreshToken}) async {
    await _prefs.setString(_accessKey, accessToken);
    await _prefs.setString(_refreshKey, refreshToken);
  }

  Future<void> clear() async {
    await _prefs.remove(_accessKey);
    await _prefs.remove(_refreshKey);
  }
}

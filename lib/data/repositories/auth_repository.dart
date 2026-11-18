import '../../core/network/api_endpoints.dart';
import '../../core/network/dio_client.dart';
import '../../core/storage/token_storage.dart';
import '../models/user.dart';

class AuthRepository {
  AuthRepository(this._client, this._tokens);

  final DioClient _client;
  final TokenStorage _tokens;

  bool get hasSession => _tokens.hasSession;

  Stream<void> get onSessionExpired => _client.authInterceptor.onSessionExpired;

  /// Sends an SMS code. Returns how many seconds until a new code may be requested.
  Future<int> startPhone(String phone) async {
    final json = await _client.post(ApiEndpoints.phoneStart, data: {'phone': phone});
    return (json['resend_in'] as num?)?.toInt() ?? 30;
  }

  Future<AppUser> verifyPhone({required String phone, required String code}) async {
    final json = await _client.post(ApiEndpoints.phoneVerify, data: {'phone': phone, 'code': code});
    return _store(AuthSession.fromJson(json as Map<String, dynamic>));
  }

  Future<AppUser> login({required String email, required String password}) async {
    final json = await _client.post(ApiEndpoints.login, data: {'email': email, 'password': password});
    return _store(AuthSession.fromJson(json as Map<String, dynamic>));
  }

  Future<AppUser> currentUser() async {
    final json = await _client.get(ApiEndpoints.me);
    return AppUser.fromJson(json as Map<String, dynamic>);
  }

  Future<void> logout() async {
    try {
      await _client.post(ApiEndpoints.logout, data: {'refresh_token': _tokens.refreshToken});
    } finally {
      await _tokens.clear();
    }
  }

  Future<void> deleteAccount() async {
    try {
      await _client.delete(ApiEndpoints.account);
    } finally {
      await _tokens.clear();
    }
  }

  Future<AppUser> _store(AuthSession session) async {
    await _tokens.save(accessToken: session.accessToken, refreshToken: session.refreshToken);
    return session.user;
  }
}

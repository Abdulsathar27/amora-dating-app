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

  Future<AppUser> login({required String email, required String password}) async {
    final json = await _client.post(ApiEndpoints.login, data: {'email': email, 'password': password});
    return _store(AuthSession.fromJson(json as Map<String, dynamic>));
  }

  Future<AppUser> register({required String name, required String email, required String password}) async {
    final json = await _client.post(
      ApiEndpoints.register,
      data: {'name': name, 'email': email, 'password': password},
    );
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

  Future<AppUser> _store(AuthSession session) async {
    await _tokens.save(accessToken: session.accessToken, refreshToken: session.refreshToken);
    return session.user;
  }
}

import 'dart:async';

import 'package:dio/dio.dart';

import '../storage/token_storage.dart';
import 'api_endpoints.dart';

/// Adds the bearer token and transparently refreshes it once on a 401.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({required this.tokenStorage, required this.dio});

  final TokenStorage tokenStorage;

  /// The main Dio instance, used to replay the original request after a refresh.
  final Dio dio;

  final _sessionExpired = StreamController<void>.broadcast();

  /// AuthBloc listens to this and logs the user out.
  Stream<void> get onSessionExpired => _sessionExpired.stream;

  static const _retriedKey = 'auth_retried';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = tokenStorage.accessToken;
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final isAuthCall = err.requestOptions.path.startsWith('/auth/');
    final alreadyRetried = err.requestOptions.extra[_retriedKey] == true;
    final refreshToken = tokenStorage.refreshToken;

    if (err.response?.statusCode != 401 || isAuthCall || alreadyRetried || refreshToken == null) {
      if (err.response?.statusCode == 401 && !isAuthCall) await _expire();
      return handler.next(err);
    }

    try {
      final res = await dio.post(ApiEndpoints.refresh, data: {'refresh_token': refreshToken});
      await tokenStorage.save(
        accessToken: res.data['access_token'] as String,
        refreshToken: (res.data['refresh_token'] ?? refreshToken) as String,
      );
      final retry = err.requestOptions..extra[_retriedKey] = true;
      final response = await dio.fetch(retry);
      handler.resolve(response);
    } catch (_) {
      await _expire();
      handler.next(err);
    }
  }

  Future<void> _expire() async {
    await tokenStorage.clear();
    _sessionExpired.add(null);
  }
}

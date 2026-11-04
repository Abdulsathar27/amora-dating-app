import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';
import 'auth_interceptor.dart';
import 'mock_interceptor.dart';

/// Thin wrapper over Dio. Repositories only ever see JSON or an [ApiException].
class DioClient {
  DioClient({required TokenStorage tokenStorage, Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConfig.baseUrl,
                connectTimeout: AppConfig.connectTimeout,
                receiveTimeout: AppConfig.receiveTimeout,
                contentType: Headers.jsonContentType,
                responseType: ResponseType.json,
              ),
            ) {
    authInterceptor = AuthInterceptor(tokenStorage: tokenStorage, dio: _dio);
    _dio.interceptors.add(authInterceptor);
    if (AppConfig.useMockApi) _dio.interceptors.add(MockInterceptor());
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: false, logPrint: (o) => debugPrint(o.toString())));
    }
  }

  final Dio _dio;
  late final AuthInterceptor authInterceptor;

  Dio get raw => _dio;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _guard(() => _dio.get(path, queryParameters: query));

  Future<dynamic> post(String path, {Object? data}) => _guard(() => _dio.post(path, data: data));

  Future<dynamic> put(String path, {Object? data}) => _guard(() => _dio.put(path, data: data));

  Future<dynamic> patch(String path, {Object? data}) => _guard(() => _dio.patch(path, data: data));

  Future<dynamic> delete(String path, {Object? data}) => _guard(() => _dio.delete(path, data: data));

  Future<dynamic> _guard(Future<Response<dynamic>> Function() call) async {
    try {
      final res = await call();
      return res.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

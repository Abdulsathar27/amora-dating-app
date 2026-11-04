import 'package:dio/dio.dart';

/// Single error type surfaced from the data layer to the ViewModels (Blocs).
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401;

  factory ApiException.fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const ApiException('The server took too long to respond. Try again.');
      case DioExceptionType.connectionError:
        return const ApiException('No internet connection.');
      case DioExceptionType.cancel:
        return const ApiException('Request cancelled.');
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        final data = e.response?.data;
        // FastAPI returns {"detail": "..."}; also accept {"message": "..."}.
        String? msg;
        if (data is Map) {
          final detail = data['detail'] ?? data['message'];
          if (detail is String) msg = detail;
          if (detail is List && detail.isNotEmpty && detail.first is Map) {
            msg = (detail.first as Map)['msg']?.toString();
          }
        }
        return ApiException(msg ?? 'Something went wrong ($code).', statusCode: code);
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        if (e.error is ApiException) return e.error as ApiException;
        return ApiException(e.message ?? 'Unexpected error.');
    }
  }

  @override
  String toString() => message;
}

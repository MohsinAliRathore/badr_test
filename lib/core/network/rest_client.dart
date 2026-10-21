import 'package:dio/dio.dart';

import '../config/env.dart';
import '../errors/app_exception.dart';
import 'auth_session.dart';

class RestClient {
  RestClient({
    required AuthSession session,
    Dio? dio,
  }) : _session = session,
       _dio = dio ??
           Dio(
             BaseOptions(
               baseUrl: Env.apiUrl,
               connectTimeout: const Duration(seconds: 15),
               receiveTimeout: const Duration(seconds: 30),
               headers: {'Content-Type': 'application/json'},
               validateStatus: (_) => true,
             ),
           ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _session.token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          _handleStatus(response);
          handler.next(response);
        },
      ),
    );
  }

  final AuthSession _session;
  final Dio _dio;

  Dio get raw => _dio;

  void _handleStatus(Response<dynamic> response) {
    final code = response.statusCode ?? 0;
    if (code >= 200 && code < 300) return;

    final data = response.data;
    AppException exception;
    if (data is Map<String, dynamic>) {
      if (data['error'] is Map<String, dynamic>) {
        exception = AppException.fromJson(data, statusCode: code);
      } else if (code == 503 || data['maintenance'] == true) {
        exception = AppException(
          code: 'MAINTENANCE',
          message: data['message']?.toString() ?? 'API under maintenance',
          details: data,
          statusCode: code,
        );
      } else {
        exception = AppException.fromJson(data, statusCode: code);
      }
    } else {
      exception = AppException(
        code: code == 503 ? 'MAINTENANCE' : 'HTTP_$code',
        message: 'Request failed with status $code',
        statusCode: code,
      );
    }

    if (exception.isUnauthenticated) {
      _session.notifyUnauthorized();
    } else if (exception.isForbidden) {
      _session.notifyForbidden();
    }
    throw exception;
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) =>
      _dio.get<T>(path, queryParameters: queryParameters);

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) =>
      _dio.post<T>(path, data: data, queryParameters: queryParameters);

  Future<Response<T>> patch<T>(
    String path, {
    Object? data,
  }) =>
      _dio.patch<T>(path, data: data);

  Future<Response<T>> delete<T>(String path) => _dio.delete<T>(path);
}

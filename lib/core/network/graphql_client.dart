import 'package:dio/dio.dart';

import '../errors/app_exception.dart';
import 'auth_session.dart';
import 'rest_client.dart';

class GraphqlClient {
  GraphqlClient({
    required RestClient rest,
    required AuthSession session,
  })  : _rest = rest,
        _session = session;

  final RestClient _rest;
  final AuthSession _session;

  Future<Map<String, dynamic>> query({
    required String document,
    Map<String, dynamic>? variables,
    String? operationName,
  }) async {
    final Response<dynamic> response;
    try {
      response = await _rest.post<dynamic>(
        '/graphql',
        data: {
          'query': document,
          if (variables != null) 'variables': variables,
          if (operationName != null) 'operationName': operationName,
        },
      );
    } on AppException {
      rethrow;
    }

    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw const AppException(
        code: 'INVALID_RESPONSE',
        message: 'GraphQL returned a non-object body',
      );
    }

    final errors = body['errors'];
    if (errors is List && errors.isNotEmpty) {
      final first = errors.first;
      String code = 'GRAPHQL_ERROR';
      String message = 'GraphQL error';
      Object? details;
      if (first is Map<String, dynamic>) {
        message = first['message']?.toString() ?? message;
        final extensions = first['extensions'];
        if (extensions is Map<String, dynamic>) {
          code = extensions['code']?.toString() ?? code;
          details = extensions;
        }
      }
      final exception = AppException(
        code: code,
        message: message,
        details: details,
        statusCode: code == 'UNAUTHENTICATED'
            ? 401
            : code == 'FORBIDDEN'
                ? 403
                : code == 'NOT_FOUND'
                    ? 404
                    : null,
      );
      if (exception.isUnauthenticated) {
        _session.notifyUnauthorized();
      }
      throw exception;
    }

    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    throw const AppException(
      code: 'INVALID_RESPONSE',
      message: 'GraphQL response missing data',
    );
  }
}

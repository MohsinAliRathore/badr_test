import '../../../../core/network/rest_client.dart';
import '../../../../generated/openapi_models.dart';

abstract class UserRepository {
  Future<ApiPage<ApiUser>> list({int page = 1, int pageSize = 20});
  Future<ApiUser> create(CreateUserInput input);
  Future<ApiUser> update(String id, UpdateUserInput input);
  Future<void> ban(String id, String reason);
  Future<void> unban(String id);
}

class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(this._rest);
  final RestClient _rest;

  @override
  Future<ApiPage<ApiUser>> list({int page = 1, int pageSize = 20}) async {
    final response = await _rest.get<Map<String, dynamic>>(
      '/api/users',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    final body = response.data ?? {};
    final data = (body['data'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ApiUser.fromJson)
        .toList();
    return ApiPage(
      data: data,
      page: (body['page'] as num?)?.toInt() ?? page,
      pageSize: (body['pageSize'] as num?)?.toInt() ?? pageSize,
      total: (body['total'] as num?)?.toInt() ?? data.length,
      totalPages: (body['totalPages'] as num?)?.toInt() ?? 1,
    );
  }

  @override
  Future<ApiUser> create(CreateUserInput input) async {
    final response = await _rest.post<Map<String, dynamic>>(
      '/api/users',
      data: input.toJson(),
    );
    return ApiUser.fromJson(response.data ?? {});
  }

  @override
  Future<ApiUser> update(String id, UpdateUserInput input) async {
    final response = await _rest.patch<Map<String, dynamic>>(
      '/api/users/$id',
      data: input.toJson(),
    );
    return ApiUser.fromJson(response.data ?? {});
  }

  @override
  Future<void> ban(String id, String reason) async {
    await _rest.post<dynamic>('/api/users/$id/ban', data: {'reason': reason});
  }

  @override
  Future<void> unban(String id) async {
    await _rest.post<dynamic>('/api/users/$id/unban', data: {});
  }
}

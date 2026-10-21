import '../../../../core/network/graphql_client.dart';
import '../../../../core/network/rest_client.dart';
import '../../../../generated/graphql_operations.dart';
import '../../../../generated/openapi_models.dart';

abstract class RiderAdminRepository {
  Future<List<ApiRider>> list({String? search});
  Future<ApiRider> create(CreateRiderInput input);
  Future<ApiRider> update(String id, UpdateRiderInput input);
  Future<List<({String id, String name})>> cities();
}

class RiderAdminRepositoryImpl implements RiderAdminRepository {
  RiderAdminRepositoryImpl({
    required GraphqlClient graphql,
    required RestClient rest,
  })  : _graphql = graphql,
        _rest = rest;

  final GraphqlClient _graphql;
  final RestClient _rest;

  @override
  Future<List<ApiRider>> list({String? search}) async {
    final data = await _graphql.query(
      document: GqlOps.riders,
      variables: {
        'first': 50,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    final nodes = (data['riders'] as Map?)?['nodes'] as List? ?? const [];
    return nodes.whereType<Map<String, dynamic>>().map(ApiRider.fromJson).toList();
  }

  @override
  Future<ApiRider> create(CreateRiderInput input) async {
    final response =
        await _rest.post<Map<String, dynamic>>('/api/riders', data: input.toJson());
    return ApiRider.fromJson(response.data ?? {});
  }

  @override
  Future<ApiRider> update(String id, UpdateRiderInput input) async {
    final response = await _rest.patch<Map<String, dynamic>>(
      '/api/riders/$id',
      data: input.toJson(),
    );
    return ApiRider.fromJson(response.data ?? {});
  }

  @override
  Future<List<({String id, String name})>> cities() async {
    final data = await _graphql.query(document: GqlOps.cities);
    final list = data['cities'] as List? ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map((c) => (id: c['id']?.toString() ?? '', name: c['name']?.toString() ?? ''))
        .toList();
  }
}

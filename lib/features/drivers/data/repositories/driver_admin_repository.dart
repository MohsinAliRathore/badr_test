import '../../../../core/network/graphql_client.dart';
import '../../../../core/network/rest_client.dart';
import '../../../../generated/graphql_operations.dart';
import '../../../../generated/openapi_models.dart';

abstract class DriverAdminRepository {
  Future<List<ApiDriver>> list({String? search});
  Future<ApiDriver> create(CreateDriverInput input);
  Future<ApiDriver> update(String id, UpdateDriverInput input);
  Future<List<({String id, String name})>> cities();
}

class DriverAdminRepositoryImpl implements DriverAdminRepository {
  DriverAdminRepositoryImpl({
    required GraphqlClient graphql,
    required RestClient rest,
  })  : _graphql = graphql,
        _rest = rest;

  final GraphqlClient _graphql;
  final RestClient _rest;

  @override
  Future<List<ApiDriver>> list({String? search}) async {
    final data = await _graphql.query(
      document: GqlOps.drivers,
      variables: {
        'first': 50,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    final nodes = (data['drivers'] as Map?)?['nodes'] as List? ?? const [];
    return nodes.whereType<Map<String, dynamic>>().map(ApiDriver.fromJson).toList();
  }

  @override
  Future<ApiDriver> create(CreateDriverInput input) async {
    final response =
        await _rest.post<Map<String, dynamic>>('/api/drivers', data: input.toJson());
    return ApiDriver.fromJson(response.data ?? {});
  }

  @override
  Future<ApiDriver> update(String id, UpdateDriverInput input) async {
    final response = await _rest.patch<Map<String, dynamic>>(
      '/api/drivers/$id',
      data: input.toJson(),
    );
    return ApiDriver.fromJson(response.data ?? {});
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

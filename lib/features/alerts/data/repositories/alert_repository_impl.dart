import '../../../../core/network/graphql_client.dart';
import '../../../../core/network/rest_client.dart';
import '../../../../generated/graphql_operations.dart';
import '../../domain/entities/alert.dart';
import '../../domain/repositories/alert_repository.dart';
import '../models/alert_mapper.dart';

class AlertRepositoryImpl implements AlertRepository {
  AlertRepositoryImpl({
    required GraphqlClient graphql,
    required RestClient rest,
  })  : _graphql = graphql,
        _rest = rest;

  final GraphqlClient _graphql;
  final RestClient _rest;

  static const _query = GqlOps.alerts;

  @override
  Future<List<OpsAlert>> listAlerts({int first = 30}) async {
    final data = await _graphql.query(
      document: _query,
      variables: {'first': first},
    );
    final connection = data['alerts'] as Map<String, dynamic>? ?? {};
    return (connection['nodes'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(mapAlertJson)
        .toList();
  }

  @override
  Future<OpsAlert> acknowledge(String id) async {
    final response = await _rest.post<Map<String, dynamic>>(
      '/api/alerts/$id/acknowledge',
    );
    return mapAlertJson(response.data ?? {});
  }
}

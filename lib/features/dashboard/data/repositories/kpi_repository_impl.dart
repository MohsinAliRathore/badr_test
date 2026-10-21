import '../../../../core/network/graphql_client.dart';
import '../../../../generated/graphql_operations.dart';
import '../../domain/entities/kpi_snapshot.dart';
import '../../domain/repositories/kpi_repository.dart';
import '../models/kpi_mapper.dart';

class KpiRepositoryImpl implements KpiRepository {
  KpiRepositoryImpl(this._graphql);

  final GraphqlClient _graphql;

  @override
  Future<KpiSnapshot> fetchKpis({
    required KpiRange range,
    String? cityId,
  }) async {
    final data = await _graphql.query(
      document: GqlOps.kpis,
      variables: {
        'range': range.graphql,
        if (cityId != null) 'cityId': cityId,
      },
    );
    final kpis = data['kpis'] as Map<String, dynamic>;
    return mapKpiJson(kpis, fallbackRange: range);
  }
}

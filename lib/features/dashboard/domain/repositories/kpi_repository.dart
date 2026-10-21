import '../entities/kpi_snapshot.dart';

abstract class KpiRepository {
  Future<KpiSnapshot> fetchKpis({required KpiRange range, String? cityId});
}

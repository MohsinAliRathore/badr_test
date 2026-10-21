import '../../domain/entities/kpi_snapshot.dart';

KpiSnapshot mapKpiJson(Map<String, dynamic> json, {KpiRange? fallbackRange}) {
  final trips = json['trips'] as Map<String, dynamic>? ?? {};
  final drivers = json['drivers'] as Map<String, dynamic>? ?? {};
  final seriesRaw = json['series'] as List<dynamic>? ?? const [];
  final revenueRaw = json['revenue'] as List<dynamic>? ?? const [];

  return KpiSnapshot(
    range: fallbackRange ?? KpiRangeX.parse(json['range']?.toString()),
    generatedAt: DateTime.tryParse(json['generatedAt']?.toString() ?? '') ??
        DateTime.now().toUtc(),
    trips: TripCounts(
      active: _int(trips['active']),
      completed: _int(trips['completed']),
      cancelled: _int(trips['cancelled']),
      cancellationRate: _double(trips['cancellationRate']),
      requested: _int(trips['requested']),
      assigned: _int(trips['assigned']),
      inProgress: _int(trips['inProgress']),
    ),
    drivers: DriverCounts(
      available: _int(drivers['available']),
      onTrip: _int(drivers['onTrip']),
      offline: _int(drivers['offline']),
      total: _int(drivers['total']),
    ),
    revenue: revenueRaw
        .whereType<Map<String, dynamic>>()
        .map(
          (m) => MoneyAmount(
            amount: _double(m['amount']),
            currency: m['currency']?.toString() ?? '',
          ),
        )
        .toList(),
    openAlerts: _int(json['openAlerts']),
    series: seriesRaw.whereType<Map<String, dynamic>>().map((m) {
      return SeriesPoint(
        bucket: DateTime.tryParse(m['bucket']?.toString() ?? '') ??
            DateTime.now().toUtc(),
        total: _int(m['total']),
        completed: _int(m['completed']),
        cancelled: _int(m['cancelled']),
      );
    }).toList(),
  );
}

int _int(Object? v) => (v is num) ? v.toInt() : int.tryParse('$v') ?? 0;

double _double(Object? v) =>
    (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0;

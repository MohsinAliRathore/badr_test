class MoneyAmount {
  const MoneyAmount({required this.amount, required this.currency});

  final double amount;
  final String currency;

  String get formatted => '${amount.toStringAsFixed(2)} $currency';
}

class TripCounts {
  const TripCounts({
    required this.active,
    required this.completed,
    required this.cancelled,
    required this.cancellationRate,
    this.requested = 0,
    this.assigned = 0,
    this.inProgress = 0,
  });

  final int active;
  final int completed;
  final int cancelled;
  final double cancellationRate;
  final int requested;
  final int assigned;
  final int inProgress;
}

class DriverCounts {
  const DriverCounts({
    required this.available,
    required this.onTrip,
    required this.offline,
    required this.total,
  });

  final int available;
  final int onTrip;
  final int offline;
  final int total;
}

class SeriesPoint {
  const SeriesPoint({
    required this.bucket,
    required this.total,
    required this.completed,
    required this.cancelled,
  });

  final DateTime bucket;
  final int total;
  final int completed;
  final int cancelled;
}

enum KpiRange { last24h, last7d }

extension KpiRangeX on KpiRange {
  String get graphql => switch (this) {
        KpiRange.last24h => 'LAST_24H',
        KpiRange.last7d => 'LAST_7D',
      };

  String get label => switch (this) {
        KpiRange.last24h => 'Last 24h',
        KpiRange.last7d => 'Last 7 days',
      };

  static KpiRange parse(String? raw) {
    switch (raw?.toUpperCase()) {
      case 'LAST_7D':
      case 'LAST_7_DAYS':
        return KpiRange.last7d;
      default:
        return KpiRange.last24h;
    }
  }
}

class KpiSnapshot {
  const KpiSnapshot({
    required this.range,
    required this.generatedAt,
    required this.trips,
    required this.drivers,
    required this.revenue,
    required this.openAlerts,
    required this.series,
  });

  final KpiRange range;
  final DateTime generatedAt;
  final TripCounts trips;
  final DriverCounts drivers;
  final List<MoneyAmount> revenue;
  final int openAlerts;
  final List<SeriesPoint> series;
}

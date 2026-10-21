part of 'dashboard_bloc.dart';

class DashboardState extends Equatable {
  const DashboardState({
    this.loading = false,
    this.snapshot,
    this.error,
    this.range = KpiRange.last24h,
    this.live = false,
  });

  final bool loading;
  final KpiSnapshot? snapshot;
  final String? error;
  final KpiRange range;
  final bool live;

  DashboardState copyWith({
    bool? loading,
    KpiSnapshot? snapshot,
    String? error,
    KpiRange? range,
    bool? live,
    bool clearError = false,
  }) {
    return DashboardState(
      loading: loading ?? this.loading,
      snapshot: snapshot ?? this.snapshot,
      error: clearError ? null : (error ?? this.error),
      range: range ?? this.range,
      live: live ?? this.live,
    );
  }

  @override
  List<Object?> get props => [loading, snapshot, error, range, live];
}

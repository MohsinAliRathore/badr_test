part of 'alerts_bloc.dart';

class AlertsState extends Equatable {
  const AlertsState({
    this.loading = false,
    this.alerts = const [],
    this.error,
    this.canAcknowledge = false,
    this.criticalBanner,
  });

  final bool loading;
  final List<OpsAlert> alerts;
  final String? error;
  final bool canAcknowledge;
  final OpsAlert? criticalBanner;

  AlertsState copyWith({
    bool? loading,
    List<OpsAlert>? alerts,
    String? error,
    bool? canAcknowledge,
    OpsAlert? criticalBanner,
    bool clearError = false,
    bool clearCritical = false,
  }) {
    return AlertsState(
      loading: loading ?? this.loading,
      alerts: alerts ?? this.alerts,
      error: clearError ? null : (error ?? this.error),
      canAcknowledge: canAcknowledge ?? this.canAcknowledge,
      criticalBanner:
          clearCritical ? null : (criticalBanner ?? this.criticalBanner),
    );
  }

  @override
  List<Object?> get props =>
      [loading, alerts, error, canAcknowledge, criticalBanner];
}

part of 'connectivity_bloc.dart';

class ConnectivityState extends Equatable {
  const ConnectivityState({
    this.apiUp = true,
    this.maintenance = false,
    this.maintenanceReason,
    this.maintenanceMessage,
    this.maintenanceSince,
    this.retryAfterSeconds,
    this.sseHint = false,
    this.wsHint = false,
    this.offline = false,
  });

  final bool apiUp;
  final bool maintenance;
  final String? maintenanceReason;
  final String? maintenanceMessage;
  final DateTime? maintenanceSince;
  final int? retryAfterSeconds;
  final bool sseHint;
  final bool wsHint;
  final bool offline;

  bool get showLightReconnect =>
      !maintenance && !offline && (sseHint || wsHint);

  ConnectivityState copyWith({
    bool? apiUp,
    bool? maintenance,
    String? maintenanceReason,
    String? maintenanceMessage,
    DateTime? maintenanceSince,
    int? retryAfterSeconds,
    bool? sseHint,
    bool? wsHint,
    bool? offline,
    bool clearMaintenance = false,
  }) {
    return ConnectivityState(
      apiUp: apiUp ?? this.apiUp,
      maintenance: clearMaintenance ? false : (maintenance ?? this.maintenance),
      maintenanceReason:
          clearMaintenance ? null : (maintenanceReason ?? this.maintenanceReason),
      maintenanceMessage: clearMaintenance
          ? null
          : (maintenanceMessage ?? this.maintenanceMessage),
      maintenanceSince:
          clearMaintenance ? null : (maintenanceSince ?? this.maintenanceSince),
      retryAfterSeconds:
          clearMaintenance ? null : (retryAfterSeconds ?? this.retryAfterSeconds),
      sseHint: sseHint ?? this.sseHint,
      wsHint: wsHint ?? this.wsHint,
      offline: offline ?? this.offline,
    );
  }

  @override
  List<Object?> get props => [
        apiUp,
        maintenance,
        maintenanceReason,
        maintenanceMessage,
        maintenanceSince,
        retryAfterSeconds,
        sseHint,
        wsHint,
        offline,
      ];
}

part of 'connectivity_bloc.dart';

sealed class ConnectivityEvent extends Equatable {
  const ConnectivityEvent();
  @override
  List<Object?> get props => [];
}

class ConnectivityStarted extends ConnectivityEvent {
  const ConnectivityStarted();
}

class ConnectivityHealthTick extends ConnectivityEvent {
  const ConnectivityHealthTick();
}

class ConnectivitySseHint extends ConnectivityEvent {
  const ConnectivitySseHint(this.state);
  final String state;
  @override
  List<Object?> get props => [state];
}

class ConnectivityWsHint extends ConnectivityEvent {
  const ConnectivityWsHint(this.state);
  final WsConnectionState state;
  @override
  List<Object?> get props => [state];
}

class ConnectivityMaintenanceDetected extends ConnectivityEvent {
  const ConnectivityMaintenanceDetected({
    required this.reason,
    required this.message,
    this.since,
    this.retryAfterSeconds,
  });

  final String reason;
  final String message;
  final DateTime? since;
  final int? retryAfterSeconds;

  @override
  List<Object?> get props => [reason, message, since, retryAfterSeconds];
}

class ConnectivityOfflineChanged extends ConnectivityEvent {
  const ConnectivityOfflineChanged(this.offline);
  final bool offline;
  @override
  List<Object?> get props => [offline];
}

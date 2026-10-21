part of 'alerts_bloc.dart';

sealed class AlertsEvent extends Equatable {
  const AlertsEvent();
  @override
  List<Object?> get props => [];
}

class AlertsStarted extends AlertsEvent {
  const AlertsStarted();
}

class AlertsRefreshRequested extends AlertsEvent {
  const AlertsRefreshRequested();
}

class AlertsSseReceived extends AlertsEvent {
  const AlertsSseReceived({required this.type, required this.data});
  final String type;
  final Map<String, dynamic> data;
  @override
  List<Object?> get props => [type, data];
}

class AlertAcknowledgeRequested extends AlertsEvent {
  const AlertAcknowledgeRequested(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}

class AlertCriticalDismissed extends AlertsEvent {
  const AlertCriticalDismissed();
}

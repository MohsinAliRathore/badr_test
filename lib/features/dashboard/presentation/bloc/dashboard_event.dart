part of 'dashboard_bloc.dart';

sealed class DashboardEvent extends Equatable {
  const DashboardEvent();
  @override
  List<Object?> get props => [];
}

class DashboardStarted extends DashboardEvent {
  const DashboardStarted();
}

class DashboardRangeChanged extends DashboardEvent {
  const DashboardRangeChanged(this.range);
  final KpiRange range;
  @override
  List<Object?> get props => [range];
}

class DashboardSseKpiReceived extends DashboardEvent {
  const DashboardSseKpiReceived(this.data);
  final Map<String, dynamic> data;
  @override
  List<Object?> get props => [data];
}

class DashboardRefreshRequested extends DashboardEvent {
  const DashboardRefreshRequested();
}

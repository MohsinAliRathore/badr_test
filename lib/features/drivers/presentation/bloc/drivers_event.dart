part of 'drivers_bloc.dart';

sealed class DriversEvent extends Equatable {
  const DriversEvent();
  @override
  List<Object?> get props => [];
}

class DriversStarted extends DriversEvent {
  const DriversStarted();
}

class DriversRefreshRequested extends DriversEvent {
  const DriversRefreshRequested();
}

class DriverCreateRequested extends DriversEvent {
  const DriverCreateRequested(this.input);
  final CreateDriverInput input;
  @override
  List<Object?> get props => [input];
}

class DriverUpdateRequested extends DriversEvent {
  const DriverUpdateRequested(this.id, this.input);
  final String id;
  final UpdateDriverInput input;
  @override
  List<Object?> get props => [id, input];
}

part of 'riders_bloc.dart';

sealed class RidersEvent extends Equatable {
  const RidersEvent();
  @override
  List<Object?> get props => [];
}

class RidersStarted extends RidersEvent {
  const RidersStarted();
}

class RidersRefreshRequested extends RidersEvent {
  const RidersRefreshRequested();
}

class RiderCreateRequested extends RidersEvent {
  const RiderCreateRequested(this.input);
  final CreateRiderInput input;
  @override
  List<Object?> get props => [input];
}

class RiderUpdateRequested extends RidersEvent {
  const RiderUpdateRequested(this.id, this.input);
  final String id;
  final UpdateRiderInput input;
  @override
  List<Object?> get props => [id, input];
}

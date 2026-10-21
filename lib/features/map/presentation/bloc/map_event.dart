part of 'map_bloc.dart';

sealed class MapEvent extends Equatable {
  const MapEvent();
  @override
  List<Object?> get props => [];
}

class MapStarted extends MapEvent {
  const MapStarted();
}

class MapWsFrameReceived extends MapEvent {
  const MapWsFrameReceived(this.frame);
  final WsFrame frame;
  @override
  List<Object?> get props => [frame.type, frame.payload];
}

class MapWsStateChanged extends MapEvent {
  const MapWsStateChanged(this.state);
  final WsConnectionState state;
  @override
  List<Object?> get props => [state];
}

class MapDriverSelected extends MapEvent {
  const MapDriverSelected(this.driverId);
  final String driverId;
  @override
  List<Object?> get props => [driverId];
}

class MapDriverDetailsRequested extends MapEvent {
  const MapDriverDetailsRequested(this.driverId);
  final String driverId;
  @override
  List<Object?> get props => [driverId];
}

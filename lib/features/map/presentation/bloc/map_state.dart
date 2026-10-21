part of 'map_bloc.dart';

class MapState extends Equatable {
  const MapState({
    this.drivers = const [],
    this.selected,
    this.selectedDetails,
    this.connection = WsConnectionState.disconnected,
    this.lastUpdate,
  });

  final List<LiveDriver> drivers;
  final LiveDriver? selected;
  final Map<String, dynamic>? selectedDetails;
  final WsConnectionState connection;
  final DateTime? lastUpdate;

  bool get isReconnecting =>
      connection == WsConnectionState.reconnecting ||
      connection == WsConnectionState.connecting;

  MapState copyWith({
    List<LiveDriver>? drivers,
    LiveDriver? selected,
    Map<String, dynamic>? selectedDetails,
    WsConnectionState? connection,
    DateTime? lastUpdate,
    bool clearDetails = false,
    bool clearSelected = false,
  }) {
    return MapState(
      drivers: drivers ?? this.drivers,
      selected: clearSelected ? null : (selected ?? this.selected),
      selectedDetails:
          clearDetails ? null : (selectedDetails ?? this.selectedDetails),
      connection: connection ?? this.connection,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }

  @override
  List<Object?> get props =>
      [drivers, selected, selectedDetails, connection, lastUpdate];
}

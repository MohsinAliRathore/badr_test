class LiveDriver {
  const LiveDriver({
    required this.id,
    required this.name,
    required this.status,
    required this.lat,
    required this.lng,
    this.cityId,
    this.heading,
    this.lastSeenAt,
    this.currentTripId,
  });

  final String id;
  final String name;
  final String status;
  final double lat;
  final double lng;
  final String? cityId;
  final double? heading;
  final DateTime? lastSeenAt;
  final String? currentTripId;

  factory LiveDriver.fromJson(Map<String, dynamic> json) {
    return LiveDriver(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      status: (json['status']?.toString() ?? '').toLowerCase(),
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0,
      cityId: json['cityId']?.toString(),
      heading: (json['heading'] as num?)?.toDouble(),
      lastSeenAt: DateTime.tryParse(json['lastSeenAt']?.toString() ?? ''),
      currentTripId: json['currentTripId']?.toString() ??
          (json['currentTrip'] is Map
              ? json['currentTrip']['id']?.toString()
              : null),
    );
  }
}

import '../../../auth/domain/entities/session_user.dart';
import '../../../dashboard/domain/entities/kpi_snapshot.dart';
import '../../domain/entities/trip.dart';

Trip mapTripJson(Map<String, dynamic> json) {
  final city = json['city'] as Map<String, dynamic>? ?? {};
  final rider = json['rider'] as Map<String, dynamic>? ?? {};
  final driver = json['driver'] as Map<String, dynamic>?;
  final pickup = json['pickup'] as Map<String, dynamic>? ?? {};
  final dropoff = json['dropoff'] as Map<String, dynamic>? ?? {};
  final fare = json['fare'] as Map<String, dynamic>? ?? {};
  final refunded = json['refunded'] as Map<String, dynamic>? ?? {};
  final timeline = json['timeline'] as List<dynamic>? ?? const [];

  return Trip(
    id: json['id']?.toString() ?? '',
    status: _normalizeStatus(json['status']?.toString()),
    city: CityRef(
      id: city['id']?.toString() ?? json['cityId']?.toString() ?? '',
      name: city['name']?.toString() ?? '',
    ),
    rider: mapPersonJson(rider),
    driver: driver == null ? null : mapPersonJson(driver),
    pickup: _mapPlace(pickup),
    dropoff: _mapPlace(dropoff),
    distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
    fare: MoneyAmount(
      amount: (fare['amount'] as num?)?.toDouble() ?? 0,
      currency: fare['currency']?.toString() ?? '',
    ),
    refunded: MoneyAmount(
      amount: (refunded['amount'] as num?)?.toDouble() ?? 0,
      currency: refunded['currency']?.toString() ?? fare['currency']?.toString() ?? '',
    ),
    refundReason: json['refundReason']?.toString(),
    cancelReason: json['cancelReason']?.toString(),
    cancelledBy: json['cancelledBy']?.toString(),
    requestedAt: _dt(json['requestedAt']) ?? DateTime.now().toUtc(),
    assignedAt: _dt(json['assignedAt']),
    startedAt: _dt(json['startedAt']),
    completedAt: _dt(json['completedAt']),
    cancelledAt: _dt(json['cancelledAt']),
    timeline: timeline.whereType<Map<String, dynamic>>().map((e) {
      return TripEvent(
        status: _normalizeStatus(e['status']?.toString()),
        at: _dt(e['at']) ?? DateTime.now().toUtc(),
      );
    }).toList(),
  );
}

/// Maps a compact SSE trip payload into a partial update shape.
Trip? mapTripEventPayload(Map<String, dynamic> json) {
  if (json['id'] == null && json['tripId'] == null) return null;
  // Prefer full nested GraphQL-shaped payloads; otherwise build a stub.
  if (json['rider'] is Map<String, dynamic>) {
    return mapTripJson(json);
  }
  return null;
}

PersonRef mapPersonJson(Map<String, dynamic> json) {
  final vehicle = json['vehicle'] as Map<String, dynamic>?;
  return PersonRef(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    phone: json['phone']?.toString() ?? '',
    email: json['email']?.toString(),
    rating: (json['rating'] as num?)?.toDouble(),
    status: json['status'] == null
        ? null
        : _normalizeStatus(json['status'].toString()),
    vehicle: vehicle == null
        ? null
        : VehicleInfo(
            make: vehicle['make']?.toString() ?? '',
            model: vehicle['model']?.toString() ?? '',
            plate: vehicle['plate']?.toString() ?? '',
            color: vehicle['color']?.toString() ?? '',
          ),
  );
}

PlaceRef _mapPlace(Map<String, dynamic> json) {
  final loc = json['location'] as Map<String, dynamic>? ?? {};
  return PlaceRef(
    address: json['address']?.toString() ?? '',
    location: GeoPoint(
      lat: (loc['lat'] as num?)?.toDouble() ?? 0,
      lng: (loc['lng'] as num?)?.toDouble() ?? 0,
    ),
  );
}

DateTime? _dt(Object? v) =>
    v == null ? null : DateTime.tryParse(v.toString());

String _normalizeStatus(String? raw) {
  if (raw == null || raw.isEmpty) return '';
  final s = raw.trim();
  // GraphQL: IN_PROGRESS / REST & SSE: in_progress or inProgress
  final withUnderscores = s
      .replaceAllMapped(
        RegExp(r'([a-z0-9])([A-Z])'),
        (m) => '${m[1]}_${m[2]}',
      )
      .replaceAll('-', '_')
      .toLowerCase();
  return withUnderscores;
}

String toGraphqlTripStatus(String status) {
  switch (status.toLowerCase()) {
    case 'requested':
      return 'REQUESTED';
    case 'assigned':
      return 'ASSIGNED';
    case 'in_progress':
      return 'IN_PROGRESS';
    case 'completed':
      return 'COMPLETED';
    case 'cancelled':
      return 'CANCELLED';
    default:
      return status.toUpperCase();
  }
}

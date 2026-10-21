import '../../../dashboard/domain/entities/kpi_snapshot.dart';
import '../../../auth/domain/entities/session_user.dart';

class VehicleInfo {
  const VehicleInfo({
    required this.make,
    required this.model,
    required this.plate,
    required this.color,
  });

  final String make;
  final String model;
  final String plate;
  final String color;
}

class PersonRef {
  const PersonRef({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.rating,
    this.status,
    this.vehicle,
    this.city,
  });

  final String id;
  final String name;
  final String phone;
  final String? email;
  final double? rating;
  final String? status;
  final VehicleInfo? vehicle;
  final CityRef? city;
}

class PlaceRef {
  const PlaceRef({required this.address, required this.location});

  final String address;
  final GeoPoint location;
}

class TripEvent {
  const TripEvent({required this.status, required this.at});

  final String status;
  final DateTime at;
}

class Trip {
  const Trip({
    required this.id,
    required this.status,
    required this.city,
    required this.rider,
    required this.pickup,
    required this.dropoff,
    required this.distanceKm,
    required this.fare,
    required this.refunded,
    required this.requestedAt,
    required this.timeline,
    this.driver,
    this.refundReason,
    this.cancelReason,
    this.cancelledBy,
    this.assignedAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
  });

  final String id;
  final String status;
  final CityRef city;
  final PersonRef rider;
  final PersonRef? driver;
  final PlaceRef pickup;
  final PlaceRef dropoff;
  final double distanceKm;
  final MoneyAmount fare;
  final MoneyAmount refunded;
  final String? refundReason;
  final String? cancelReason;
  final String? cancelledBy;
  final DateTime requestedAt;
  final DateTime? assignedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final List<TripEvent> timeline;

  double get remainingRefundable =>
      (fare.amount - refunded.amount).clamp(0, double.infinity);

  Trip copyWith({
    String? status,
    PersonRef? driver,
    MoneyAmount? refunded,
    String? refundReason,
    String? cancelReason,
    List<TripEvent>? timeline,
  }) {
    return Trip(
      id: id,
      status: status ?? this.status,
      city: city,
      rider: rider,
      driver: driver ?? this.driver,
      pickup: pickup,
      dropoff: dropoff,
      distanceKm: distanceKm,
      fare: fare,
      refunded: refunded ?? this.refunded,
      refundReason: refundReason ?? this.refundReason,
      cancelReason: cancelReason ?? this.cancelReason,
      cancelledBy: cancelledBy,
      requestedAt: requestedAt,
      assignedAt: assignedAt,
      startedAt: startedAt,
      completedAt: completedAt,
      cancelledAt: cancelledAt,
      timeline: timeline ?? this.timeline,
    );
  }
}

class TripPage {
  const TripPage({
    required this.nodes,
    required this.hasNextPage,
    this.endCursor,
    this.totalCount = 0,
  });

  final List<Trip> nodes;
  final bool hasNextPage;
  final String? endCursor;
  final int totalCount;
}

class TripFilter {
  const TripFilter({
    this.statuses,
    this.from,
    this.to,
    this.search,
  });

  final List<String>? statuses;
  final DateTime? from;
  final DateTime? to;
  final String? search;

  TripFilter copyWith({
    List<String>? statuses,
    DateTime? from,
    DateTime? to,
    String? search,
    bool clearDates = false,
  }) {
    return TripFilter(
      statuses: statuses ?? this.statuses,
      from: clearDates ? null : (from ?? this.from),
      to: clearDates ? null : (to ?? this.to),
      search: search ?? this.search,
    );
  }
}

import '../../../auth/domain/entities/session_user.dart';

class OpsAlert {
  const OpsAlert({
    required this.id,
    required this.type,
    required this.severity,
    required this.message,
    required this.createdAt,
    required this.city,
    this.tripId,
    this.driverId,
    this.acknowledgedAt,
    this.acknowledgedBy,
  });

  final String id;
  final String type;
  final String severity;
  final String message;
  final DateTime createdAt;
  final CityRef city;
  final String? tripId;
  final String? driverId;
  final DateTime? acknowledgedAt;
  final String? acknowledgedBy;

  bool get isCritical =>
      severity.toLowerCase() == 'critical' || type.toUpperCase() == 'SOS';

  bool get isAcknowledged => acknowledgedAt != null;

  OpsAlert copyWith({
    DateTime? acknowledgedAt,
    String? acknowledgedBy,
  }) {
    return OpsAlert(
      id: id,
      type: type,
      severity: severity,
      message: message,
      createdAt: createdAt,
      city: city,
      tripId: tripId,
      driverId: driverId,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      acknowledgedBy: acknowledgedBy ?? this.acknowledgedBy,
    );
  }
}

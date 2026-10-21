import '../../../auth/domain/entities/session_user.dart';
import '../../domain/entities/alert.dart';

OpsAlert mapAlertJson(Map<String, dynamic> json) {
  final city = json['city'] as Map<String, dynamic>?;
  final trip = json['trip'] as Map<String, dynamic>?;
  final driver = json['driver'] as Map<String, dynamic>?;
  return OpsAlert(
    id: json['id']?.toString() ?? '',
    type: json['type']?.toString() ?? '',
    severity: json['severity']?.toString() ?? '',
    message: json['message']?.toString() ?? '',
    createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
        DateTime.now().toUtc(),
    city: CityRef(
      id: city?['id']?.toString() ?? json['cityId']?.toString() ?? '',
      name: city?['name']?.toString() ?? '',
    ),
    tripId: trip?['id']?.toString() ?? json['tripId']?.toString(),
    driverId: driver?['id']?.toString() ?? json['driverId']?.toString(),
    acknowledgedAt: DateTime.tryParse(json['acknowledgedAt']?.toString() ?? ''),
    acknowledgedBy: json['acknowledgedBy']?.toString(),
  );
}

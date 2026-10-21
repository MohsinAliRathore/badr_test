import '../../../../core/permissions/permission.dart';
import '../../domain/entities/session_user.dart';

SessionProfile mapMeResponse(Map<String, dynamic> json) {
  final user = json['user'] as Map<String, dynamic>? ?? json;
  final cityJson = json['city'] as Map<String, dynamic>?;
  final permissionsJson = json['permissions'];

  late final PermissionSet permissions;
  if (permissionsJson is Map<String, dynamic>) {
    permissions = PermissionSet.fromJson(permissionsJson);
  } else if (permissionsJson is List) {
    permissions = PermissionSet.fromGraphqlList(permissionsJson);
  } else {
    permissions = const PermissionSet({});
  }

  return SessionProfile(
    id: user['id']?.toString() ?? '',
    name: user['name']?.toString() ?? '',
    email: user['email']?.toString() ?? '',
    role: json['role']?.toString() ?? user['role']?.toString() ?? '',
    roleDescription: json['roleDescription']?.toString() ?? '',
    permissions: permissions,
    city: cityJson == null
        ? null
        : CityRef(
            id: cityJson['id']?.toString() ?? '',
            name: cityJson['name']?.toString() ?? '',
            countryCode: cityJson['countryCode']?.toString(),
            currency: cityJson['currency']?.toString(),
            timezone: cityJson['timezone']?.toString(),
            center: cityJson['center'] is Map<String, dynamic>
                ? GeoPoint(
                    lat: (cityJson['center']['lat'] as num).toDouble(),
                    lng: (cityJson['center']['lng'] as num).toDouble(),
                  )
                : null,
          ),
  );
}

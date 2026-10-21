import 'package:badr_test/core/permissions/permission.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PermissionSet', () {
    test('reads nested REST permissions map', () {
      final permissions = PermissionSet.fromJson({
        'trip': ['read', 'assign'],
        'kpi': ['read'],
        'driver': ['track'],
        'alert': ['read'],
      });

      expect(permissions.canReadTrip, isTrue);
      expect(permissions.canAssignTrip, isTrue);
      expect(permissions.canCancelTrip, isFalse);
      expect(permissions.canReadKpi, isTrue);
      expect(permissions.canTrackDrivers, isTrue);
      expect(permissions.canAcknowledgeAlert, isFalse);
    });

    test('destination visibility follows permissions not role names', () {
      final viewer = PermissionSet.fromJson({
        'trip': ['read'],
        'kpi': ['read'],
        'alert': ['read'],
      });
      final support = PermissionSet.fromJson({
        'trip': ['read', 'refund'],
        'alert': ['read', 'acknowledge'],
        'rider': ['read'],
      });

      expect(AppDestination.dashboard.isAllowed(viewer), isTrue);
      expect(AppDestination.map.isAllowed(viewer), isFalse);
      expect(AppDestination.dashboard.isAllowed(support), isFalse);
      expect(AppDestination.map.isAllowed(support), isFalse);
      expect(AppDestination.trips.isAllowed(support), isTrue);
      expect(AppDestination.alerts.isAllowed(support), isTrue);
    });
  });
}

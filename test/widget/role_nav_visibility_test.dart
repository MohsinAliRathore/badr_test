import 'package:badr_test/core/permissions/permission.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('support role has no dashboard or map destinations', () {
    final support = PermissionSet.fromJson({
      'trip': ['read', 'refund'],
      'alert': ['read', 'acknowledge'],
      'rider': ['read', 'update'],
      'driver': ['read'],
      'city': ['read'],
      'pii': ['read'],
    });

    expect(AppDestination.dashboard.isAllowed(support), isFalse);
    expect(AppDestination.map.isAllowed(support), isFalse);
    expect(AppDestination.trips.isAllowed(support), isTrue);
    expect(AppDestination.alerts.isAllowed(support), isTrue);
    expect(support.canAssignTrip, isFalse);
    expect(support.canRefundTrip, isTrue);
  });

  test('viewer has read surfaces but no write actions', () {
    final viewer = PermissionSet.fromJson({
      'trip': ['read'],
      'kpi': ['read'],
      'alert': ['read'],
      'driver': ['read'],
      'rider': ['read'],
      'city': ['read'],
    });

    expect(AppDestination.dashboard.isAllowed(viewer), isTrue);
    expect(AppDestination.trips.isAllowed(viewer), isTrue);
    expect(AppDestination.map.isAllowed(viewer), isFalse);
    expect(viewer.canAssignTrip, isFalse);
    expect(viewer.canCancelTrip, isFalse);
    expect(viewer.canRefundTrip, isFalse);
    expect(viewer.canAcknowledgeAlert, isFalse);
    expect(viewer.canReadPii, isFalse);
  });

  test('dispatcher can assign/cancel and track drivers', () {
    final dispatcher = PermissionSet.fromJson({
      'trip': ['read', 'assign', 'cancel'],
      'kpi': ['read'],
      'alert': ['read', 'acknowledge'],
      'driver': ['read', 'track'],
      'rider': ['read'],
      'city': ['read'],
      'pii': ['read'],
    });

    expect(AppDestination.map.isAllowed(dispatcher), isTrue);
    expect(dispatcher.canAssignTrip, isTrue);
    expect(dispatcher.canCancelTrip, isTrue);
    expect(dispatcher.canRefundTrip, isFalse);
  });

  test('super_admin user admin permissions unlock users destination', () {
    final admin = PermissionSet.fromJson({
      'user': ['list', 'create', 'set-role', 'ban'],
      'kpi': ['read'],
      'trip': ['read'],
      'driver': ['read', 'track', 'message', 'create', 'update'],
      'rider': ['read', 'create', 'update'],
      'alert': ['read'],
    });

    expect(AppDestination.users.isAllowed(admin), isTrue);
    expect(AppDestination.drivers.isAllowed(admin), isTrue);
    expect(AppDestination.riders.isAllowed(admin), isTrue);
    expect(admin.canMessageDriver, isTrue);
    expect(admin.canBanUser, isTrue);
  });
}

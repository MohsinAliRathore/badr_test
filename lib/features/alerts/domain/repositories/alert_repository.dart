import '../entities/alert.dart';

abstract class AlertRepository {
  Future<List<OpsAlert>> listAlerts({int first = 30});

  Future<OpsAlert> acknowledge(String id);
}

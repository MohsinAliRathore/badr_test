import '../../../../core/network/rest_client.dart';
import '../../../../generated/openapi_models.dart';
import '../../../realtime/data/realtime_hub.dart';

abstract class ChatRepository {
  Future<List<ApiDriverMessage>> history(String driverId);
  void subscribe();
  void unsubscribe();
  void send({required String driverId, required String body});
  Stream<ApiDriverMessage> get incoming;
}

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({
    required RestClient rest,
    required RealtimeHub hub,
  })  : _rest = rest,
        _hub = hub;

  final RestClient _rest;
  final RealtimeHub _hub;

  @override
  Future<List<ApiDriverMessage>> history(String driverId) async {
    final response =
        await _rest.get<dynamic>('/api/drivers/$driverId/messages');
    final body = response.data;
    List<dynamic> list;
    if (body is List) {
      list = body;
    } else if (body is Map<String, dynamic>) {
      list = body['data'] as List? ?? body['messages'] as List? ?? const [];
    } else {
      list = const [];
    }
    return list
        .whereType<Map<String, dynamic>>()
        .map(ApiDriverMessage.fromJson)
        .toList();
  }

  @override
  void subscribe() => _hub.ws.subscribe('driver.messages');

  @override
  void unsubscribe() => _hub.ws.unsubscribe('driver.messages');

  @override
  void send({required String driverId, required String body}) {
    _hub.ws.sendCommand('driver.message.send', {
      'driverId': driverId,
      'body': body,
    });
  }

  @override
  Stream<ApiDriverMessage> get incoming => _hub.wsMessages
      .where((f) => f.type == 'driver.message' || f.type == 'driver.messages')
      .map((f) {
        final payload = f.payload;
        if (payload['message'] is Map<String, dynamic>) {
          return ApiDriverMessage.fromJson(
            payload['message'] as Map<String, dynamic>,
          );
        }
        return ApiDriverMessage.fromJson(payload);
      });
}

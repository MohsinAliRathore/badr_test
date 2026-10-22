import 'dart:async';

import '../../../core/network/sse_client.dart';
import '../../../core/network/ws_client.dart';

class RealtimeHub {
  RealtimeHub({
    required SseClient sse,
    required WsClient ws,
  })  : _sse = sse,
        _ws = ws;

  final SseClient _sse;
  final WsClient _ws;

  Stream<SseEvent> get sseEvents => _sse.events;
  Stream<WsFrame> get wsMessages => _ws.messages;
  Stream<WsConnectionState> get wsState => _ws.connectionState;

  SseClient get sse => _sse;
  WsClient get ws => _ws;

  void restartTransports() {
    _sse.restart();
    _ws.stop();
    _ws.start();
  }
}

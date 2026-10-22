import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/env.dart';
import 'auth_session.dart';

enum WsConnectionState { disconnected, connecting, connected, reconnecting }

class WsClient {
  WsClient({required AuthSession session}) : _session = session;

  final AuthSession _session;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  StreamSubscription<void>? _unauthorizedSub;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  int _attempt = 0;
  int _idCounter = 0;
  bool _disposed = false;
  bool _shouldRun = false;
  final Set<String> _desiredChannels = {};

  final _messages = StreamController<WsFrame>.broadcast();
  final _state = StreamController<WsConnectionState>.broadcast();
  WsConnectionState _current = WsConnectionState.disconnected;

  Stream<WsFrame> get messages => _messages.stream;
  Stream<WsConnectionState> get connectionState => _state.stream;
  WsConnectionState get state => _current;

  void start() {
    _unauthorizedSub ??= _session.unauthorized.listen((_) => stop());
    _shouldRun = true;
    _connect();
  }

  void stop() {
    _shouldRun = false;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _subscription?.cancel();
    _subscription = null;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    _setState(WsConnectionState.disconnected);
  }

  void subscribe(String channel) {
    _desiredChannels.add(channel);
    if (_current == WsConnectionState.connected) {
      _send({
        'type': 'subscribe',
        'id': _nextId(),
        'payload': {'channel': channel},
      });
    }
  }

  void unsubscribe(String channel) {
    _desiredChannels.remove(channel);
    if (_current == WsConnectionState.connected) {
      _send({
        'type': 'unsubscribe',
        'id': _nextId(),
        'payload': {'channel': channel},
      });
    }
  }

  void sendCommand(String type, Map<String, dynamic> payload) {
    _send({'type': type, 'id': _nextId(), 'payload': payload});
  }

  void _connect() {
    if (_disposed || !_shouldRun) return;
    final token = _session.token;
    if (token == null || token.isEmpty) return;

    _setState(
      _attempt == 0
          ? WsConnectionState.connecting
          : WsConnectionState.reconnecting,
    );

    final uri = Env.wsUri.replace(queryParameters: {'token': token});
    try {
      final channel = WebSocketChannel.connect(uri);
      _channel = channel;
      _subscription = channel.stream.listen(
        _onMessage,
        onError: (_) => _scheduleReconnect(),
        onDone: _scheduleReconnect,
        cancelOnError: true,
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic raw) {
    if (raw is! String) return;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final frame = WsFrame.fromJson(json);
      if (frame.type == 'welcome') {
        _attempt = 0;
        _setState(WsConnectionState.connected);
        _startPing();
        for (final channel in _desiredChannels) {
          _send({
            'type': 'subscribe',
            'id': _nextId(),
            'payload': {'channel': channel},
          });
        }
      } else if (frame.type == 'error') {
        final code = frame.payload['code']?.toString();
        if (code == 'UNAUTHENTICATED') {
          _session.notifyUnauthorized();
          stop();
          return;
        }
      }
      _messages.add(frame);
    } catch (_) {

    }
  }

  void _scheduleReconnect() {
    if (_disposed || !_shouldRun) return;
    _pingTimer?.cancel();
    _subscription?.cancel();
    _subscription = null;
    _channel = null;
    _setState(WsConnectionState.reconnecting);
    _attempt += 1;
    final seconds = min(30, pow(2, min(_attempt, 5)).toInt());
    final jitter = Random().nextDouble() * 0.4;
    final delay = Duration(milliseconds: ((seconds + jitter) * 1000).round());
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, _connect);
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      _send({'type': 'ping', 'id': _nextId()});
    });
  }

  void _send(Map<String, dynamic> frame) {
    final channel = _channel;
    if (channel == null) return;
    try {
      channel.sink.add(jsonEncode(frame));
    } catch (_) {
      _scheduleReconnect();
    }
  }

  String _nextId() => '${++_idCounter}';

  void _setState(WsConnectionState next) {
    if (_current == next) return;
    _current = next;
    _state.add(next);
  }

  void dispose() {
    _disposed = true;
    stop();
    _unauthorizedSub?.cancel();
    _messages.close();
    _state.close();
  }
}

class WsFrame {
  const WsFrame({
    required this.type,
    required this.payload,
    this.id,
  });

  final String type;
  final Map<String, dynamic> payload;
  final String? id;

  factory WsFrame.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'];
    return WsFrame(
      type: json['type']?.toString() ?? '',
      id: json['id']?.toString(),
      payload: payload is Map<String, dynamic>
          ? payload
          : <String, dynamic>{},
    );
  }
}

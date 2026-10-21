import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web/web.dart' as web;

import '../config/env.dart';
import '../errors/app_exception.dart';
import 'auth_session.dart';

/// Server-Sent Events client for Flutter web using `package:web` EventSource.
///
/// Chosen because browsers cannot set Authorization headers on EventSource,
/// so we pass `?token=` as required by the API. EventSource also resumes with
/// the `Last-Event-ID` header on native reconnect; we additionally persist the
/// last id and pass `lastEventId` on fresh connects (B4).
class SseClient {
  SseClient({
    required AuthSession session,
    SharedPreferences? prefs,
  })  : _session = session,
        _prefs = prefs;

  static const _lastIdKey = 'badrgo_sse_last_event_id';

  final AuthSession _session;
  final SharedPreferences? _prefs;

  web.EventSource? _source;
  final _controller = StreamController<SseEvent>.broadcast();
  StreamSubscription<void>? _unauthorizedSub;
  bool _intentionalClose = false;
  String? _lastEventId;

  Stream<SseEvent> get events => _controller.stream;

  bool get isConnected =>
      _source != null && _source!.readyState == web.EventSource.OPEN;

  String? get lastEventId => _lastEventId ?? _prefs?.getString(_lastIdKey);

  void start() {
    _unauthorizedSub ??= _session.unauthorized.listen((_) => stop());
    _lastEventId ??= _prefs?.getString(_lastIdKey);
    _connect();
  }

  void stop() {
    _intentionalClose = true;
    _source?.close();
    _source = null;
  }

  void restart() {
    stop();
    _intentionalClose = false;
    _connect();
  }

  void _connect() {
    final token = _session.token;
    if (token == null || token.isEmpty) return;

    _intentionalClose = false;
    final params = <String, String>{'token': token};
    final resumeId = lastEventId;
    if (resumeId != null && resumeId.isNotEmpty) {
      params['lastEventId'] = resumeId;
    }
    final uri =
        Env.baseUri.replace(path: '/api/events', queryParameters: params);

    final source = web.EventSource(uri.toString());
    _source = source;

    void handleNamed(String type, web.Event event) {
      final message = event as web.MessageEvent;
      final id = message.lastEventId;
      if (id.isNotEmpty) {
        _lastEventId = id;
        _prefs?.setString(_lastIdKey, id);
      }
      final raw = message.data;
      final dataString = raw?.dartify()?.toString();
      if (dataString == null) return;
      try {
        final decoded = jsonDecode(dataString);
        _controller.add(
          SseEvent(
            type: type,
            data: decoded is Map<String, dynamic>
                ? decoded
                : <String, dynamic>{'value': decoded},
            id: id.isEmpty ? null : id,
          ),
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('SSE parse error ($type): $e');
        }
      }
    }

    for (final type in const [
      'ready',
      'kpi',
      'trip.created',
      'trip.updated',
      'alert.created',
      'alert.acknowledged',
      'driver.updated',
      'ping',
      'error',
    ]) {
      source.addEventListener(
        type,
        (web.Event event) {
          handleNamed(type, event);
        }.toJS,
      );
    }

    source.onerror = (web.Event event) {
      if (_intentionalClose) return;
      _controller.add(
        const SseEvent(type: '_connection', data: {'state': 'error'}),
      );
      if (source.readyState == web.EventSource.CLOSED) {
        _session.notifyUnauthorized();
      }
    }.toJS;

    source.onopen = (web.Event event) {
      _controller.add(
        const SseEvent(type: '_connection', data: {'state': 'open'}),
      );
    }.toJS;
  }

  void dispose() {
    stop();
    _unauthorizedSub?.cancel();
    _controller.close();
  }
}

class SseEvent {
  const SseEvent({
    required this.type,
    required this.data,
    this.id,
  });

  final String type;
  final Map<String, dynamic> data;
  final String? id;
}

class SseException extends AppException {
  const SseException(String message)
      : super(code: 'SSE_ERROR', message: message);
}

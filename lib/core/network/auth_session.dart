import 'dart:async';

/// Holds the current bearer token and broadcasts auth-loss (401) events
/// so every transport can tear down without looping.
class AuthSession {
  AuthSession({String? initialToken}) : _token = initialToken;

  String? _token;
  final _tokenController = StreamController<String?>.broadcast();
  final _unauthorizedController = StreamController<void>.broadcast();
  final _forbiddenController = StreamController<void>.broadcast();
  bool _unauthorizedSignaled = false;

  String? get token => _token;

  Stream<String?> get tokenChanges => _tokenController.stream;

  Stream<void> get unauthorized => _unauthorizedController.stream;

  /// Fired on 403 so the shell can refresh `/api/me` (role changes).
  Stream<void> get forbidden => _forbiddenController.stream;

  void setToken(String? token) {
    _token = token;
    _unauthorizedSignaled = false;
    _tokenController.add(token);
  }

  void notifyUnauthorized() {
    if (_unauthorizedSignaled) return;
    _unauthorizedSignaled = true;
    _token = null;
    _tokenController.add(null);
    _unauthorizedController.add(null);
  }

  void notifyForbidden() {
    _forbiddenController.add(null);
  }

  void dispose() {
    _tokenController.close();
    _unauthorizedController.close();
    _forbiddenController.close();
  }
}

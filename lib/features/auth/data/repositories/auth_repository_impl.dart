import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/auth_session.dart';
import '../../../../core/network/rest_client.dart';
import '../../../../core/network/session_store.dart';
import '../../domain/entities/session_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/session_mapper.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required RestClient rest,
    required SessionStore store,
    required AuthSession session,
  })  : _rest = rest,
        _store = store,
        _session = session;

  final RestClient _rest;
  final SessionStore _store;
  final AuthSession _session;

  @override
  String? get currentToken => _session.token;

  @override
  Future<SessionProfile> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _rest.post<Map<String, dynamic>>(
        '/api/auth/sign-in/email',
        data: {'email': email, 'password': password},
      );
      final data = response.data ?? {};
      final token = data['token']?.toString();
      if (token == null || token.isEmpty) {
        throw const AppException(
          code: 'INVALID_RESPONSE',
          message: 'Sign-in response missing token',
        );
      }
      await _store.saveToken(token);
      _session.setToken(token);
      return fetchMe();
    } on AppException {
      // Banned users arrive as 403 with a useful message.
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      if (_session.token != null) {
        await _rest.post<dynamic>('/api/auth/sign-out', data: {});
      }
    } on AppException {
      // Always clear local session even if revoke fails.
    } finally {
      await _store.clear();
      _session.setToken(null);
    }
  }

  @override
  Future<SessionProfile?> restoreSession() async {
    final token = _store.token;
    if (token == null || token.isEmpty) return null;
    _session.setToken(token);
    try {
      return await fetchMe();
    } on AppException catch (e) {
      if (e.isUnauthenticated || e.isForbidden) {
        await _store.clear();
        _session.setToken(null);
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<SessionProfile> fetchMe() async {
    final response = await _rest.get<Map<String, dynamic>>('/api/me');
    return mapMeResponse(response.data ?? {});
  }
}

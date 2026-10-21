import '../entities/session_user.dart';

abstract class AuthRepository {
  Future<SessionProfile> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<SessionProfile?> restoreSession();

  Future<SessionProfile> fetchMe();

  String? get currentToken;
}

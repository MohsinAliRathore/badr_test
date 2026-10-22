import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/auth_session.dart';
import '../../../../core/network/sse_client.dart';
import '../../../../core/network/ws_client.dart';
import '../../domain/entities/session_user.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required AuthRepository authRepository,
    required AuthSession authSession,
    required SseClient sseClient,
    required WsClient wsClient,
  })  : _authRepository = authRepository,
        _authSession = authSession,
        _sseClient = sseClient,
        _wsClient = wsClient,
        super(const AuthState.unknown()) {
    on<AuthBootstrapRequested>(_onBootstrap);
    on<AuthSignInSubmitted>(_onSignIn);
    on<AuthSignOutRequested>(_onSignOut);
    on<AuthUnauthorizedReceived>(_onUnauthorized);
    on<AuthProfileRefreshRequested>(_onRefresh);
    on<AuthForbiddenReceived>(_onForbidden);

    _unauthorizedSub = _authSession.unauthorized.listen((_) {
      add(const AuthUnauthorizedReceived());
    });
    _forbiddenSub = _authSession.forbidden.listen((_) {
      add(const AuthForbiddenReceived());
    });
  }

  final AuthRepository _authRepository;
  final AuthSession _authSession;
  final SseClient _sseClient;
  final WsClient _wsClient;
  StreamSubscription<void>? _unauthorizedSub;
  StreamSubscription<void>? _forbiddenSub;

  Future<void> _onBootstrap(
    AuthBootstrapRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    try {
      final profile = await _authRepository.restoreSession();
      if (profile == null) {
        emit(const AuthState.unauthenticated());
        return;
      }
      _startRealtime();
      emit(AuthState.authenticated(profile));
    } on AppException catch (e) {
      if (e.isMaintenance) {

        emit(state.copyWith(
          status: AuthStatus.authenticated,
          errorMessage: e.message,
        ));
        return;
      }
      emit(AuthState.unauthenticated(errorMessage: e.message));
    } catch (e) {
      emit(AuthState.unauthenticated(errorMessage: e.toString()));
    }
  }

  Future<void> _onSignIn(
    AuthSignInSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    try {
      final profile = await _authRepository.signIn(
        email: event.email.trim(),
        password: event.password,
      );
      _startRealtime();
      emit(AuthState.authenticated(profile));
    } on AppException catch (e) {
      emit(AuthState.unauthenticated(errorMessage: e.message));
    } catch (e) {
      emit(AuthState.unauthenticated(errorMessage: e.toString()));
    }
  }

  Future<void> _onSignOut(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    _stopRealtime();
    await _authRepository.signOut();
    emit(const AuthState.unauthenticated());
  }

  Future<void> _onUnauthorized(
    AuthUnauthorizedReceived event,
    Emitter<AuthState> emit,
  ) async {
    _stopRealtime();
    await _authRepository.signOut();
    emit(
      const AuthState.unauthenticated(
        errorMessage: 'Session expired. Please sign in again.',
      ),
    );
  }

  Future<void> _onForbidden(
    AuthForbiddenReceived event,
    Emitter<AuthState> emit,
  ) async {
    if (!state.isAuthenticated) return;

    try {
      final profile = await _authRepository.fetchMe();
      emit(AuthState.authenticated(profile));

      _stopRealtime();
      _startRealtime();
    } on AppException catch (e) {
      if (e.isUnauthenticated || e.isForbidden) {

        add(const AuthUnauthorizedReceived());
      }
    }
  }

  Future<void> _onRefresh(
    AuthProfileRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (!state.isAuthenticated) return;
    try {
      final profile = await _authRepository.fetchMe();
      emit(AuthState.authenticated(profile));
    } on AppException catch (e) {
      if (e.isUnauthenticated || e.isForbidden) {
        add(const AuthUnauthorizedReceived());
      }
    }
  }

  void _startRealtime() {
    _sseClient.start();
    _wsClient.start();
  }

  void _stopRealtime() {
    _sseClient.stop();
    _wsClient.stop();
  }

  @override
  Future<void> close() {
    _unauthorizedSub?.cancel();
    _forbiddenSub?.cancel();
    return super.close();
  }
}

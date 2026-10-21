import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../generated/openapi_models.dart';
import '../../data/repositories/chat_repository.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc({required ChatRepository repository})
      : _repo = repository,
        super(const ChatState()) {
    on<ChatOpened>(_onOpened);
    on<ChatClosed>(_onClosed);
    on<ChatSendRequested>(_onSend);
    on<ChatMessageReceived>(_onReceived);
  }

  final ChatRepository _repo;
  StreamSubscription<ApiDriverMessage>? _sub;

  Future<void> _onOpened(ChatOpened event, Emitter<ChatState> emit) async {
    _repo.subscribe();
    _sub ??= _repo.incoming.listen((m) => add(ChatMessageReceived(m)));
    emit(state.copyWith(driverId: event.driverId, driverName: event.driverName, loading: true));
    try {
      final history = await _repo.history(event.driverId);
      emit(state.copyWith(loading: false, messages: history, open: true));
    } on AppException catch (e) {
      emit(state.copyWith(loading: false, error: e.message, open: true));
    }
  }

  void _onClosed(ChatClosed event, Emitter<ChatState> emit) {
    emit(const ChatState());
  }

  void _onSend(ChatSendRequested event, Emitter<ChatState> emit) {
    final driverId = state.driverId;
    if (driverId == null || event.body.trim().isEmpty) return;
    _repo.send(driverId: driverId, body: event.body.trim());
    // Optimistic local echo for to_driver
    final optimistic = ApiDriverMessage(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      driverId: driverId,
      direction: 'to_driver',
      body: event.body.trim(),
      createdAt: DateTime.now().toUtc(),
      sentBy: 'me',
    );
    emit(state.copyWith(messages: [...state.messages, optimistic]));
  }

  void _onReceived(ChatMessageReceived event, Emitter<ChatState> emit) {
    if (state.driverId != null && event.message.driverId != state.driverId) {
      return;
    }
    final exists = state.messages.any((m) => m.id == event.message.id);
    if (exists) return;
    emit(state.copyWith(messages: [...state.messages, event.message]));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}

part of 'chat_bloc.dart';

class ChatState extends Equatable {
  const ChatState({
    this.open = false,
    this.loading = false,
    this.driverId,
    this.driverName,
    this.messages = const [],
    this.error,
  });

  final bool open;
  final bool loading;
  final String? driverId;
  final String? driverName;
  final List<ApiDriverMessage> messages;
  final String? error;

  ChatState copyWith({
    bool? open,
    bool? loading,
    String? driverId,
    String? driverName,
    List<ApiDriverMessage>? messages,
    String? error,
  }) {
    return ChatState(
      open: open ?? this.open,
      loading: loading ?? this.loading,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      messages: messages ?? this.messages,
      error: error,
    );
  }

  @override
  List<Object?> get props =>
      [open, loading, driverId, driverName, messages, error];
}

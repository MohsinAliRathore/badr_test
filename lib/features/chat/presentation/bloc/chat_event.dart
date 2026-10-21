part of 'chat_bloc.dart';

sealed class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object?> get props => [];
}

class ChatOpened extends ChatEvent {
  const ChatOpened({required this.driverId, required this.driverName});
  final String driverId;
  final String driverName;
  @override
  List<Object?> get props => [driverId, driverName];
}

class ChatClosed extends ChatEvent {
  const ChatClosed();
}

class ChatSendRequested extends ChatEvent {
  const ChatSendRequested(this.body);
  final String body;
  @override
  List<Object?> get props => [body];
}

class ChatMessageReceived extends ChatEvent {
  const ChatMessageReceived(this.message);
  final ApiDriverMessage message;
  @override
  List<Object?> get props => [message];
}

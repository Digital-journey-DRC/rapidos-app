abstract class MessageState {}

class MessageInitial extends MessageState {}

class MessageLoading extends MessageState {}

class ConversationsLoaded extends MessageState {
  final List<dynamic> conversations;
  ConversationsLoaded(this.conversations);
}

class ConversationMessagesLoaded extends MessageState {
  final List<dynamic> messages;
  final bool hasMore;
  ConversationMessagesLoaded(this.messages, this.hasMore);
}

class MessageSuccess extends MessageState {
  final String message;
  MessageSuccess(this.message);
}

class MessageError extends MessageState {
  final String error;
  MessageError(this.error);
}

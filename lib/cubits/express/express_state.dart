abstract class ExpressState {}

class ExpressInitial extends ExpressState {}

class ExpressLoading extends ExpressState {}

class ClientsLoaded extends ExpressState {
  final List<Map<String, dynamic>> clients;
  ClientsLoaded(this.clients);
}

class ClientCreated extends ExpressState {
  final String clientId;
  ClientCreated(this.clientId);
}

class ExpressOrderCreated extends ExpressState {
  final String orderId;
  ExpressOrderCreated(this.orderId);
}

class ExpressError extends ExpressState {
  final String message;
  ExpressError(this.message);
}

class ExpressOrdersLoaded extends ExpressState {
  final List<Map<String, dynamic>> orders;
  ExpressOrdersLoaded(this.orders);
} 
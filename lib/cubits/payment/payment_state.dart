abstract class PaymentState {}

class PaymentInitial extends PaymentState {}

class PaymentLoading extends PaymentState {}

class PaymentSuccess extends PaymentState {
  final Map<String, dynamic> paymentData;
  
  PaymentSuccess(this.paymentData);
}

class PaymentError extends PaymentState {
  final String message;
  
  PaymentError(this.message);
}

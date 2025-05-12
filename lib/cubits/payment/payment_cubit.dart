import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/rentbook_service.dart';
import '../../services/payment_storage_service.dart';
import 'payment_state.dart';
import 'dart:developer' as developer;

class PaymentCubit extends Cubit<PaymentState> {
  final RentbookService _rentbookService = RentbookService();
  
  PaymentCubit() : super(PaymentInitial());
  
  Future<void> makePayment({
    required String rentbookId,
    required double amount,
    required String paymentMethod,
    String? comment,
    required String token,
  }) async {
    try {
      emit(PaymentLoading());
      
      developer.log('Tentative de paiement pour le rentbook: $rentbookId');
      developer.log('Montant: $amount, Type: ${amount.runtimeType}, Méthode: $paymentMethod');
      
      // S'assurer que amount est bien un double
      final double safeAmount = amount is int ? (amount as int).toDouble() : amount;
      
      final result = await _rentbookService.makeRentbookPayment(
        rentbookId: rentbookId,
        amount: safeAmount,
        paymentMethod: paymentMethod,
        comment: comment,
        token: token,
      );
      
      developer.log('Paiement réussi: $result');
      
      // Générer et sauvegarder les informations du prochain paiement
      final nextPayment = PaymentStorageService.generateNextPayment(safeAmount, DateTime.now());
      await PaymentStorageService.saveNextPayment(rentbookId, nextPayment);
      
      // Récupérer l'historique des paiements existant
      final existingPayments = PaymentStorageService.getPaymentHistory(rentbookId);
      
      // Ajouter le nouveau paiement à l'historique
      final newPayment = {
        'id': result['_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'amount': safeAmount,
        'paymentMethod': paymentMethod,
        'status': 'Payé',
        'date': DateTime.now().toIso8601String(),
        'month': _getCurrentMonth(),
        'reference': result['reference'] ?? '',
      };
      
      existingPayments.add(newPayment);
      
      // Sauvegarder l'historique mis à jour
      await PaymentStorageService.savePaymentHistory(rentbookId, existingPayments);
      
      emit(PaymentSuccess(result));
    } catch (e) {
      developer.log('Erreur de paiement: $e', error: e);
      emit(PaymentError(e.toString()));
    }
  }
  
  String _getCurrentMonth() {
    final now = DateTime.now();
    final months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return '${months[now.month - 1]} ${now.year}';
  }
  
  void resetState() {
    emit(PaymentInitial());
  }
}

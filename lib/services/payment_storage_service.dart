import 'package:hive_flutter/hive_flutter.dart';
import 'dart:developer' as developer;

class PaymentStorageService {
  static const String _paymentBoxName = 'payments';
  static const String _nextPaymentBoxName = 'nextPayment';
  
  // Initialiser Hive et ouvrir les boîtes
  static Future<void> init() async {
    try {
      // Ouvrir les boîtes Hive
      await Hive.openBox(_paymentBoxName);
      await Hive.openBox(_nextPaymentBoxName);
      developer.log('PaymentStorageService: Hive boxes initialized successfully');
    } catch (e) {
      developer.log('PaymentStorageService: Error initializing Hive boxes', error: e);
    }
  }
  
  // Sauvegarder l'historique des paiements
  static Future<void> savePaymentHistory(String rentbookId, List<Map<String, dynamic>> payments) async {
    try {
      final box = Hive.box(_paymentBoxName);
      await box.put(rentbookId, payments);
      developer.log('PaymentStorageService: Payment history saved for rentbook $rentbookId');
    } catch (e) {
      developer.log('PaymentStorageService: Error saving payment history', error: e);
    }
  }
  
  // Récupérer l'historique des paiements
  static List<Map<String, dynamic>> getPaymentHistory(String rentbookId) {
    try {
      final box = Hive.box(_paymentBoxName);
      final data = box.get(rentbookId);
      
      if (data != null && data is List) {
        return List<Map<String, dynamic>>.from(
          data.map((item) => Map<String, dynamic>.from(item))
        );
      }
      
      return [];
    } catch (e) {
      developer.log('PaymentStorageService: Error getting payment history', error: e);
      return [];
    }
  }
  
  // Sauvegarder les informations du prochain paiement
  static Future<void> saveNextPayment(String rentbookId, Map<String, dynamic> nextPayment) async {
    try {
      final box = Hive.box(_nextPaymentBoxName);
      await box.put(rentbookId, nextPayment);
      developer.log('PaymentStorageService: Next payment saved for rentbook $rentbookId');
    } catch (e) {
      developer.log('PaymentStorageService: Error saving next payment', error: e);
    }
  }
  
  // Récupérer les informations du prochain paiement
  static Map<String, dynamic>? getNextPayment(String rentbookId) {
    try {
      final box = Hive.box(_nextPaymentBoxName);
      final data = box.get(rentbookId);
      
      if (data != null && data is Map) {
        return Map<String, dynamic>.from(data);
      }
      
      return null;
    } catch (e) {
      developer.log('PaymentStorageService: Error getting next payment', error: e);
      return null;
    }
  }
  
  // Générer les informations du prochain paiement après un paiement réussi
  static Map<String, dynamic> generateNextPayment(double amount, DateTime currentDate, {int numberOfPaymentsMade = 0}) {
    // Récupérer le jour actuel pour l'utiliser comme jour d'échéance
    final int dayOfMonth = currentDate.day;
    
    // Calculer le mois suivant pour l'échéance en tenant compte du nombre de paiements déjà effectués
    final nextMonth = DateTime(
      currentDate.month + numberOfPaymentsMade >= 12 
          ? currentDate.year + ((currentDate.month + numberOfPaymentsMade) ~/ 12) 
          : currentDate.year,
      (currentDate.month + numberOfPaymentsMade) % 12 == 0 
          ? 12 
          : (currentDate.month + numberOfPaymentsMade) % 12,
      dayOfMonth, // Utilise le jour du mois actuel
    );
    
    final String month = _getMonthName(nextMonth);
    final String dueDate = '$dayOfMonth ${_getMonthName(nextMonth)}';
    
    return {
      'amount': amount,
      'month': month,
      'dueDate': dueDate,
      'status': 'En attente',
      'date': nextMonth.toIso8601String(),
    };
  }
  
  // Obtenir le nom du mois (méthode privée)
  static String _getMonthName(DateTime date) {
    final List<String> months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
  
  // Méthode publique pour obtenir le nom du mois
  static String getMonthName(DateTime date) {
    return _getMonthName(date);
  }
}

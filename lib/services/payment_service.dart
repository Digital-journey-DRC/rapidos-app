import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PaymentService {
  static const String baseUrl = 'http://68.183.30.146:8000';
  static const String tokenKey = 'auth_token';  // Use the same key as StorageService

  Future<Map<String, dynamic>> initiatePayment({
    required String rentBookId,
    required String type,
    required int amount,
    required String phone,
    required String devise,
    String? notes,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(tokenKey);  // Use tokenKey instead of 'token'

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/payments/initiate'),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'rentBookId': rentBookId,
          'type': type,
          'amount': amount,
          'phone': "243$phone",
          'devise': devise,
          'metadata': {
            'notes': notes ?? 'Paiement du mois'
          }
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to initiate payment: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error initiating payment: $e');
    }
  }

    Future<Map<String, dynamic>> initiatePaymentFacture({
    required String utilityBillId,
    required String type,
    required int amount,
    required String phone,
    required String devise,
    String? notes,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(tokenKey);  // Use tokenKey instead of 'token'

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/utility-bills/initiate-payment'),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'utilityBillId': utilityBillId,
          'type': type,
          'amount': amount,
          'phone': "243$phone",
          'devise': devise,
          'metadata': {
            'notes': notes ?? 'Paiement Facture'
          }
        }        
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to initiate payment: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error initiating payment: $e');
    }
  }

  
}

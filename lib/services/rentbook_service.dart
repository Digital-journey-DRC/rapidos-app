import 'dart:convert';
import 'package:http/http.dart' as http;

class RentbookService {
  static const String baseUrl = 'http://68.183.30.146:8000';

  Future<Map<String, dynamic>> createRentbook({
    required String apartmentId,
    required String tenantId,
    required DateTime leaseStartDate,
    required DateTime leaseEndDate,
    required double monthlyRent,
    required double securityDeposit,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/rentbooks'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'apartmentId': apartmentId,
          'tenantId': tenantId,
          'leaseStartDate': leaseStartDate.toIso8601String().split('T')[0],
          'leaseEndDate': leaseEndDate.toIso8601String().split('T')[0],
          'monthlyRent': monthlyRent,
          'securityDeposit': securityDeposit,
        }),
      );

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Erreur lors de la création du carnet de loyer');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }
  
  Future<Map<String, dynamic>> getOwnerRentbooks({
    required String token,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/rentbooks/owner?page=$page&limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to load rentbooks: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching rentbooks: $e');
    }
  }

  Future<Map<String, dynamic>> getTenantRentbooks({
    required String token,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/rentbooks/tenant?page=$page&limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to load tenant rentbooks: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching tenant rentbooks: $e');
    }
  }
  
  Future<Map<String, dynamic>> makeRentbookPayment({
    required String rentbookId,
    required double amount,
    required String paymentMethod,
    String? comment,
    required String token,
  }) async {
    try {
      // Générer une référence unique pour le paiement
      final String reference = 'PAY-${DateTime.now().millisecondsSinceEpoch}-${rentbookId.substring(0, 5)}';
      
      // S'assurer que amount est bien un double
      final double safeAmount = amount is int ? (amount as int).toDouble() : amount;
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/rentbooks/$rentbookId/payment'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'amount': safeAmount,
          'paymentMethod': paymentMethod,
          'reference': reference,
          'comment': comment ?? 'Paiement de loyer',
        }),
      );

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Erreur lors du paiement');
      }
    } catch (e) {
      throw Exception('Erreur de paiement: $e');
    }
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';

class PaymentMethodService {
  final String baseUrl = 'http://24.144.87.127:3333';

  /// Récupère tous les moyens de paiement disponibles (templates)
  /// Endpoint: GET /payment-methods/templates
  /// Authentification: NON REQUISE (Public)
  Future<Map<String, dynamic>> getPaymentMethodTemplates() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/payment-methods/templates'),
        headers: {
          'Content-Type': 'application/json',
          'accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: La connexion au serveur a pris trop de temps');
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'paymentMethods': responseData['paymentMethods'] ?? [],
          'message': responseData['message'] ?? 'Moyens de paiement récupérés avec succès',
        };
      } else {
        final errorData = jsonDecode(response.body);
        print(errorData);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Erreur lors de la récupération des moyens de paiement',
          'paymentMethods': [],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion: $e',
        'paymentMethods': [],
      };
    }
  }

  /// Récupère tous les moyens de paiement du vendeur connecté
  /// Endpoint: GET /payment-methods
  /// Authentification: REQUISE (Vendeur uniquement)
  Future<Map<String, dynamic>> getVendeurPaymentMethods() async {
    try {
      final token = await StorageService().getToken();
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Token d\'authentification manquant',
          'paymentMethods': [],
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/payment-methods'),
        headers: {
          'Content-Type': 'application/json',
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: La connexion au serveur a pris trop de temps');
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'paymentMethods': responseData['paymentMethods'] ?? [],
          'message': responseData['message'] ?? 'Moyens de paiement récupérés avec succès',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Erreur lors de la récupération des moyens de paiement',
          'paymentMethods': [],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion: $e',
        'paymentMethods': [],
      };
    }
  }

  /// Active un moyen de paiement pour le vendeur connecté
  /// Endpoint: POST /payment-methods/activate-template
  /// Authentification: REQUISE (Vendeur uniquement)
  Future<Map<String, dynamic>> activatePaymentMethodTemplate({
    required int templateId,
    required String numeroCompte,
    required String nomTitulaire,
    required bool isDefault,
  }) async {
    try {
      final token = await StorageService().getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Token d\'authentification manquant',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/payment-methods/activate-template'),
        headers: {
          'Content-Type': 'application/json',
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'templateId': templateId,
          'numeroCompte': numeroCompte,
          'nomTitulaire': nomTitulaire,
          'isDefault': isDefault,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: La connexion au serveur a pris trop de temps');
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Moyen de paiement activé avec succès',
          'paymentMethod': responseData['paymentMethod'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Erreur lors de l\'activation du moyen de paiement',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion: $e',
      };
    }
  }

  /// Active un moyen de paiement désactivé
  /// Endpoint: PATCH /payment-methods/:id/activate
  /// Authentification: REQUISE (Vendeur uniquement)
  Future<Map<String, dynamic>> activatePaymentMethod(int id) async {
    try {
      final token = await StorageService().getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Token d\'authentification manquant',
        };
      }

      final response = await http.patch(
        Uri.parse('$baseUrl/payment-methods/$id/activate'),
        headers: {
          'Content-Type': 'application/json',
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: La connexion au serveur a pris trop de temps');
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Moyen de paiement activé avec succès',
          'paymentMethod': responseData['paymentMethod'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Erreur lors de l\'activation du moyen de paiement',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion: $e',
      };
    }
  }

  /// Désactive un moyen de paiement (sauf le défaut)
  /// Endpoint: PATCH /payment-methods/:id/deactivate
  /// Authentification: REQUISE (Vendeur uniquement)
  Future<Map<String, dynamic>> deactivatePaymentMethod(int id) async {
    try {
      final token = await StorageService().getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Token d\'authentification manquant',
        };
      }

      final response = await http.patch(
        Uri.parse('$baseUrl/payment-methods/$id/deactivate'),
        headers: {
          'Content-Type': 'application/json',
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: La connexion au serveur a pris trop de temps');
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Moyen de paiement désactivé avec succès',
          'paymentMethod': responseData['paymentMethod'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Erreur lors de la désactivation du moyen de paiement',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion: $e',
      };
    }
  }

  /// Modifie les informations d'un moyen de paiement
  /// Endpoint: PUT /payment-methods/:id
  /// Authentification: REQUISE (Vendeur uniquement)
  Future<Map<String, dynamic>> updatePaymentMethod({
    required int id,
    required String numeroCompte,
    required String nomTitulaire,
    required bool isDefault,
  }) async {
    try {
      final token = await StorageService().getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Token d\'authentification manquant',
        };
      }

      final response = await http.put(
        Uri.parse('$baseUrl/payment-methods/$id'),
        headers: {
          'Content-Type': 'application/json',
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'numeroCompte': numeroCompte,
          'nomTitulaire': nomTitulaire,
          'isDefault': isDefault,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: La connexion au serveur a pris trop de temps');
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Moyen de paiement modifié avec succès',
          'paymentMethod': responseData['paymentMethod'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Erreur lors de la modification du moyen de paiement',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion: $e',
      };
    }
  }
}


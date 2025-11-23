import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';
import '../models/vendeur.dart';

class MerchantService {
  static const String baseUrl = 'http://24.144.87.127:3333';

  /// Récupère le détail d'un vendeur avec ses produits et horaires
  /// Endpoint: GET /vendeurs/:id
  /// Accessible à: Tous utilisateurs authentifiés
  Future<Map<String, dynamic>> getVendeurById(int vendeurId) async {
    try {
      print('🔍 merchant_service.getVendeurById - Récupération du vendeur: $vendeurId');
      print('🔍 merchant_service.getVendeurById - URL: $baseUrl/vendeurs/$vendeurId');

      final token = await StorageService().getToken();

      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/vendeurs/$vendeurId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: La connexion au serveur a pris trop de temps');
        },
      );

      print('🔍 merchant_service.getVendeurById - Status code: ${response.statusCode}');
      final responseData = jsonDecode(response.body);
      print('🔍 merchant_service.getVendeurById - Response keys: ${responseData.keys.toList()}');

      if (response.statusCode == 200) {
        // Construire l'objet Vendeur à partir de la réponse
        final vendeurJson = responseData['vendeur'] as Map<String, dynamic>;
        final profilJson = responseData['profil'] as Map<String, dynamic>?;
        final mediaJson = responseData['media'] as Map<String, dynamic>?;
        final horairesJson = responseData['horairesOuverture'] as List<dynamic>?;
        final productsJson = responseData['products'] as List<dynamic>?;
        final totalProducts = responseData['totalProducts'] as int?;

        // Fusionner les données pour créer un Vendeur complet
        final vendeurData = {
          ...vendeurJson,
          if (profilJson != null) 'profil': profilJson,
          if (mediaJson != null) 'media': mediaJson,
          if (horairesJson != null) 'horairesOuverture': horairesJson,
          if (productsJson != null) 'products': productsJson,
          if (totalProducts != null) 'totalProducts': totalProducts,
        };

        final vendeur = Vendeur.fromJson(vendeurData);

        print('🔍 merchant_service.getVendeurById - Vendeur récupéré avec succès: ${vendeur.fullName}');

        return {
          'success': true,
          'vendeur': vendeur,
          'message': responseData['message'] ?? 'Vendeur récupéré avec succès',
        };
      } else {
        throw Exception(
          responseData['message'] ??
              'Erreur lors de la récupération du vendeur: ${response.statusCode}',
        );
      }
    } on http.ClientException catch (e) {
      print('🔍 merchant_service.getVendeurById - ClientException: $e');
      return {
        'success': false,
        'error': 'Impossible de se connecter au serveur. Vérifiez votre connexion internet.',
      };
    } catch (e) {
      print('🔍 merchant_service.getVendeurById - Exception: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}


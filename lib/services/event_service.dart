import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';

/// Service pour enregistrer les événements utilisateur en background
/// Ces événements sont utilisés pour améliorer les recommandations de produits
class EventService {
  final String baseUrl = 'http://24.144.87.127:3333';

  /// Enregistre un événement de visualisation de produit
  /// POST /api/events/view-product
  Future<void> trackProductView({
    required int productId,
    required int userId,
  }) async {
    try {
      final token = await StorageService().getToken();
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/events/view-product'),
        headers: {
          'Authorization': token != null ? 'Bearer $token' : '',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'productId': productId,
          'userId': userId,
        }),
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          // Timeout silencieux - ne pas bloquer l'UI
          return http.Response('', 408);
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ EventService.trackProductView - Succès: productId=$productId, userId=$userId');
      } else {
        print('⚠️ EventService.trackProductView - Erreur HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      // Erreur silencieuse - ne pas bloquer l'UI
      print('⚠️ EventService.trackProductView - Erreur: $e');
    }
  }

  /// Enregistre un événement d'ajout au panier
  /// POST /api/events/add-to-cart
  Future<void> trackAddToCart({
    required int productId,
    required int userId,
  }) async {
    try {
      final token = await StorageService().getToken();
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/events/add-to-cart'),
        headers: {
          'Authorization': token != null ? 'Bearer $token' : '',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'productId': productId,
          'userId': userId,
        }),
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          // Timeout silencieux - ne pas bloquer l'UI
          return http.Response('', 408);
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ EventService.trackAddToCart - Succès: productId=$productId, userId=$userId');
      } else {
        print('⚠️ EventService.trackAddToCart - Erreur HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      // Erreur silencieuse - ne pas bloquer l'UI
      print('⚠️ EventService.trackAddToCart - Erreur: $e');
    }
  }

  /// Enregistre un événement d'achat
  /// POST /api/events/purchase
  Future<void> trackPurchase({
    required int productId,
    required int userId,
  }) async {
    try {
      final token = await StorageService().getToken();
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/events/purchase'),
        headers: {
          'Authorization': token != null ? 'Bearer $token' : '',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'productId': productId,
          'userId': userId,
        }),
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          // Timeout silencieux - ne pas bloquer l'UI
          return http.Response('', 408);
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ EventService.trackPurchase - Succès: productId=$productId, userId=$userId');
      } else {
        print('⚠️ EventService.trackPurchase - Erreur HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      // Erreur silencieuse - ne pas bloquer l'UI
      print('⚠️ EventService.trackPurchase - Erreur: $e');
    }
  }

  /// Enregistre un événement de recherche
  /// POST /api/events/search
  Future<void> trackSearch({
    required String searchQuery,
    required int userId,
  }) async {
    try {
      final token = await StorageService().getToken();
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/events/search'),
        headers: {
          'Authorization': token != null ? 'Bearer $token' : '',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'searchQuery': searchQuery,
          'userId': userId,
        }),
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          // Timeout silencieux - ne pas bloquer l'UI
          return http.Response('', 408);
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ EventService.trackSearch - Succès: searchQuery="$searchQuery", userId=$userId');
      } else {
        print('⚠️ EventService.trackSearch - Erreur HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      // Erreur silencieuse - ne pas bloquer l'UI
      print('⚠️ EventService.trackSearch - Erreur: $e');
    }
  }
}


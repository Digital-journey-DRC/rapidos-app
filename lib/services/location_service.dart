import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';

class LocationService {
  final String baseUrl = 'http://24.144.87.127:3333';

  /// Enregistre ou met à jour la localisation de l'utilisateur
  /// Endpoint: POST /users/location
  /// Authentification: REQUISE
  Future<Map<String, dynamic>> saveLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final token = await StorageService().getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Token d\'authentification manquant',
        };
      }

      // Valider les coordonnées
      if (latitude < -90 || latitude > 90) {
        return {
          'success': false,
          'message': 'La latitude doit être entre -90 et 90',
        };
      }

      if (longitude < -180 || longitude > 180) {
        return {
          'success': false,
          'message': 'La longitude doit être entre -180 et 180',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/users/location'),
        headers: {
          'Content-Type': 'application/json',
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
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
          'message': responseData['message'] ?? 'Localisation enregistrée avec succès',
          'location': responseData['location'] ?? responseData,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Erreur lors de l\'enregistrement de la localisation',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion: $e',
      };
    }
  }

  /// Récupère la localisation de l'utilisateur connecté
  /// Endpoint: GET /users/location
  /// Authentification: REQUISE
  Future<Map<String, dynamic>> getLocation() async {
    try {
      final token = await StorageService().getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Token d\'authentification manquant',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/users/location'),
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
          'location': responseData['location'] ?? responseData,
          'message': responseData['message'] ?? 'Localisation récupérée avec succès',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Erreur lors de la récupération de la localisation',
          'location': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur de connexion: $e',
        'location': null,
      };
    }
  }
}


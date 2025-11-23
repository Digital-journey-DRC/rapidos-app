import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';

class MerchantHoursService {
  // URL de base pour l'API
  static const String baseUrl = 'http://24.144.87.127:3333';

  /// Crée ou met à jour un horaire d'ouverture
  /// 
  /// [jour] : lundi, mardi, mercredi, jeudi, vendredi, samedi, dimanche
  /// [heureOuverture] : Format HH:MM (ex: "08:00")
  /// [heureFermeture] : Format HH:MM (ex: "18:00")
  /// [estOuvert] : true/false
  Future<Map<String, dynamic>> createOrUpdateHoraire({
    required String jour,
    String? heureOuverture,
    String? heureFermeture,
    required bool estOuvert,
  }) async {
    try {
      print('🔍 merchant_hours_service.createOrUpdateHoraire - jour: $jour, estOuvert: $estOuvert');
      
      final token = await StorageService().getToken();
      
      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      final body = <String, dynamic>{
        'jour': jour,
        'estOuvert': estOuvert,
      };

      if (heureOuverture != null && heureOuverture.isNotEmpty) {
        body['heureOuverture'] = heureOuverture;
      }
      if (heureFermeture != null && heureFermeture.isNotEmpty) {
        body['heureFermeture'] = heureFermeture;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/vendeurs/horaires'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: La connexion au serveur a pris trop de temps');
        },
      );

      print('🔍 merchant_hours_service.createOrUpdateHoraire - Status code: ${response.statusCode}');
      final responseData = jsonDecode(response.body);
      print('🔍 merchant_hours_service.createOrUpdateHoraire - Response: $responseData');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Horaire enregistré avec succès',
          'horaire': responseData['horaire'],
        };
      } else {
        throw Exception(
          responseData['message'] ?? 
          'Erreur lors de l\'enregistrement de l\'horaire: ${response.statusCode}'
        );
      }
    } on http.ClientException catch (e) {
      print('🔍 merchant_hours_service.createOrUpdateHoraire - ClientException: $e');
      return {
        'success': false,
        'error': 'Impossible de se connecter au serveur. Vérifiez votre connexion internet.',
      };
    } catch (e) {
      print('🔍 merchant_hours_service.createOrUpdateHoraire - Exception: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Récupère tous les horaires du vendeur connecté
  Future<Map<String, dynamic>> getAllHoraires() async {
    try {
      print('🔍 merchant_hours_service.getAllHoraires - Récupération de tous les horaires');
      
      final token = await StorageService().getToken();
      
      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/vendeurs/horaires'),
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

      print('🔍 merchant_hours_service.getAllHoraires - Status code: ${response.statusCode}');
      final responseData = jsonDecode(response.body);
      print('🔍 merchant_hours_service.getAllHoraires - Response keys: ${responseData.keys.toList()}');

      if (response.statusCode == 200) {
        final List<dynamic> horairesJson = responseData['horaires'] ?? [];
        print('🔍 merchant_hours_service.getAllHoraires - Nombre d\'horaires: ${horairesJson.length}');
        
        return {
          'success': true,
          'horaires': horairesJson,
        };
      } else {
        throw Exception(
          responseData['message'] ?? 
          'Erreur lors de la récupération des horaires: ${response.statusCode}'
        );
      }
    } on http.ClientException catch (e) {
      print('🔍 merchant_hours_service.getAllHoraires - ClientException: $e');
      return {
        'success': false,
        'error': 'Impossible de se connecter au serveur. Vérifiez votre connexion internet.',
        'horaires': <Map<String, dynamic>>[],
      };
    } catch (e) {
      print('🔍 merchant_hours_service.getAllHoraires - Exception: $e');
      return {
        'success': false,
        'error': e.toString(),
        'horaires': <Map<String, dynamic>>[],
      };
    }
  }

  /// Récupère l'horaire d'un jour spécifique
  /// 
  /// [jour] : lundi, mardi, mercredi, jeudi, vendredi, samedi, dimanche
  Future<Map<String, dynamic>> getHoraireByDay(String jour) async {
    try {
      print('🔍 merchant_hours_service.getHoraireByDay - jour: $jour');
      
      final token = await StorageService().getToken();
      
      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/vendeurs/horaires/$jour'),
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

      print('🔍 merchant_hours_service.getHoraireByDay - Status code: ${response.statusCode}');
      final responseData = jsonDecode(response.body);
      print('🔍 merchant_hours_service.getHoraireByDay - Response: $responseData');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'horaire': responseData['horaire'],
        };
      } else {
        throw Exception(
          responseData['message'] ?? 
          'Erreur lors de la récupération de l\'horaire: ${response.statusCode}'
        );
      }
    } on http.ClientException catch (e) {
      print('🔍 merchant_hours_service.getHoraireByDay - ClientException: $e');
      return {
        'success': false,
        'error': 'Impossible de se connecter au serveur. Vérifiez votre connexion internet.',
      };
    } catch (e) {
      print('🔍 merchant_hours_service.getHoraireByDay - Exception: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Met à jour un horaire d'ouverture
  /// 
  /// [jour] : lundi, mardi, mercredi, jeudi, vendredi, samedi, dimanche
  /// [heureOuverture] : Format HH:MM (optionnel)
  /// [heureFermeture] : Format HH:MM (optionnel)
  /// [estOuvert] : true/false (optionnel)
  Future<Map<String, dynamic>> updateHoraire({
    required String jour,
    String? heureOuverture,
    String? heureFermeture,
    bool? estOuvert,
  }) async {
    try {
      print('🔍 merchant_hours_service.updateHoraire - jour: $jour');
      
      final token = await StorageService().getToken();
      
      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      final body = <String, dynamic>{};
      if (heureOuverture != null) {
        body['heureOuverture'] = heureOuverture;
      }
      if (heureFermeture != null) {
        body['heureFermeture'] = heureFermeture;
      }
      if (estOuvert != null) {
        body['estOuvert'] = estOuvert;
      }

      final response = await http.put(
        Uri.parse('$baseUrl/vendeurs/horaires/$jour'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: La connexion au serveur a pris trop de temps');
        },
      );

      print('🔍 merchant_hours_service.updateHoraire - Status code: ${response.statusCode}');
      final responseData = jsonDecode(response.body);
      print('🔍 merchant_hours_service.updateHoraire - Response: $responseData');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Horaire mis à jour avec succès',
          'horaire': responseData['horaire'],
        };
      } else {
        throw Exception(
          responseData['message'] ?? 
          'Erreur lors de la mise à jour de l\'horaire: ${response.statusCode}'
        );
      }
    } on http.ClientException catch (e) {
      print('🔍 merchant_hours_service.updateHoraire - ClientException: $e');
      return {
        'success': false,
        'error': 'Impossible de se connecter au serveur. Vérifiez votre connexion internet.',
      };
    } catch (e) {
      print('🔍 merchant_hours_service.updateHoraire - Exception: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Supprime un horaire d'ouverture
  /// 
  /// [jour] : lundi, mardi, mercredi, jeudi, vendredi, samedi, dimanche
  Future<Map<String, dynamic>> deleteHoraire(String jour) async {
    try {
      print('🔍 merchant_hours_service.deleteHoraire - jour: $jour');
      
      final token = await StorageService().getToken();
      
      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/vendeurs/horaires/$jour'),
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

      print('🔍 merchant_hours_service.deleteHoraire - Status code: ${response.statusCode}');
      final responseData = jsonDecode(response.body);
      print('🔍 merchant_hours_service.deleteHoraire - Response: $responseData');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Horaire supprimé avec succès',
        };
      } else {
        throw Exception(
          responseData['message'] ?? 
          'Erreur lors de la suppression de l\'horaire: ${response.statusCode}'
        );
      }
    } on http.ClientException catch (e) {
      print('🔍 merchant_hours_service.deleteHoraire - ClientException: $e');
      return {
        'success': false,
        'error': 'Impossible de se connecter au serveur. Vérifiez votre connexion internet.',
      };
    } catch (e) {
      print('🔍 merchant_hours_service.deleteHoraire - Exception: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}


import 'dart:convert';
import 'package:http/http.dart' as http;

class UtilityBillService {
  final String baseUrl = 'http://68.183.30.146:8000';

  Future<Map<String, dynamic>> createUtilityBill({
    required String token,
    required String buildingId,
    required String type,
    required double value,
    required String currency,
  }) async {
    try {
      print('Envoi de la requête POST à $baseUrl/api/v1/utility-bills');
      print('Données: buildingId=$buildingId, type=$type, value=$value, currency=$currency');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/utility-bills'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'buildingId': buildingId,
          'type': type,
          'amount': {
            'value': value,
            'currency': currency,
          },
        }),
      );

      print('Statut de la réponse: ${response.statusCode}');
      print('Corps de la réponse: ${response.body}');

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Échec de la création de la facture: ${response.body}');
      }
    } catch (e) {
      print('Exception dans createUtilityBill: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getUtilityBills({
    required String token,
    required String buildingId,
  }) async {
    try {
      final url = '$baseUrl/api/v1/utility-bills/building/$buildingId';
      print('Envoi de la requête GET à $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('Statut de la réponse: ${response.statusCode}');
      print('Corps de la réponse: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic decodedResponse = jsonDecode(response.body);
        
        // Vérifier si la réponse est un objet avec une propriété "data"
        if (decodedResponse is Map && decodedResponse.containsKey('data')) {
          print('Réponse avec structure "data" détectée');
          final data = decodedResponse['data'];
          
          // Si data est une liste, la retourner directement
          if (data is List) {
            print('Données extraites avec succès (liste): ${data.length} éléments');
            return data;
          } 
          // Si data est un objet, le convertir en liste avec un seul élément
          else if (data is Map) {
            print('Données extraites avec succès (objet unique)');
            return [data];
          }
        }
        
        // Si la réponse est déjà une liste, la retourner directement
        if (decodedResponse is List) {
          print('Données extraites avec succès (liste directe): ${decodedResponse.length} éléments');
          return decodedResponse;
        }
        
        // Si aucun des formats attendus n'est détecté, retourner une liste vide
        print('Format de réponse non reconnu, retour d\'une liste vide');
        return [];
      } else {
        throw Exception('Échec de la récupération des factures: ${response.body}');
      }
    } catch (e) {
      print('Exception dans getUtilityBills: $e');
      rethrow;
    }
  }

    Future<List<dynamic>> getUtilityBillsByApartment({
    required String token,
    required String apartmentId,
  }) async {
    try {
      final url = '$baseUrl/api/v1/utility-bills/apartment/$apartmentId';
      print('Envoi de la requête GET à $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('Statut de la réponse: ${response.statusCode}');
      print('Corps de la réponse: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic decodedResponse = jsonDecode(response.body);
        
        // Vérifier si la réponse est un objet avec une propriété "data"
        if (decodedResponse is Map && decodedResponse.containsKey('utilityBills')) {
          print('Réponse avec structure "data" détectée');
          final data = decodedResponse['utilityBills'];
          
          // Si data est une liste, la retourner directement
          if (data is List) {
            print('Données extraites avec succès (liste): ${data.length} éléments');
            return data;
          } 
          // Si data est un objet, le convertir en liste avec un seul élément
          else if (data is Map) {
            print('Données extraites avec succès (objet unique)');
            return [data];
          }
        }
        
        // Si la réponse est déjà une liste, la retourner directement
        if (decodedResponse is List) {
          print('Données extraites avec succès (liste directe): ${decodedResponse.length} éléments');
          return decodedResponse;
        }
        
        // Si aucun des formats attendus n'est détecté, retourner une liste vide
        print('Format de réponse non reconnu, retour d\'une liste vide');
        return [];
      } else {
        throw Exception('Échec de la récupération des factures: ${response.body}');
      }
    } catch (e) {
      print('Exception dans getUtilityBills: $e');
      rethrow;
    }
  }
}
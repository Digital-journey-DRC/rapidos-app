import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';
import '../models/promotion.dart';

class PromotionService {
  // URL de base pour l'API - utiliser celle du code existant
  static const String baseUrl = 'http://24.144.87.127:3333';
  
  /// Récupère toutes les promotions actives
  Future<Map<String, dynamic>> getPromotions() async {
    try {
      final token = await StorageService().getToken();
      
      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/promotions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> promotionsJson = responseData['promotions'] ?? [];
        final List<Promotion> promotions = promotionsJson
            .map((json) => Promotion.fromJson(json))
            .toList();
        
        return {
          'success': true,
          'promotions': promotions,
        };
      } else {
        throw Exception(
          responseData['message'] ?? 
          'Erreur lors de la récupération des promotions: ${response.statusCode}'
        );
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'promotions': <Promotion>[],
      };
    }
  }
  
  /// Crée une nouvelle promotion
  /// 
  /// [productId] : ID du produit à mettre en promotion
  /// [image] : URL de l'image principale (requis)
  /// [image1-4] : URLs des images supplémentaires (optionnel)
  /// [libelle] : Libellé de la promotion
  /// [delaiPromotion] : Date de fin de la promotion (ISO 8601)
  /// [nouveauPrix] : Nouveau prix en promotion
  /// [ancienPrix] : Ancien prix avant promotion
  /// [likes] : Nombre de likes (optionnel, défaut: 0)
  Future<Map<String, dynamic>> createPromotion({
    required int productId,
    required String image,
    String? image1,
    String? image2,
    String? image3,
    String? image4,
    required String libelle,
    required DateTime delaiPromotion,
    required double nouveauPrix,
    required double ancienPrix,
    int likes = 0,
  }) async {
    try {
      final token = await StorageService().getToken();
      
      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      // Préparer le body
      final body = {
        'productId': productId,
        'image': image,
        'libelle': libelle,
        'delaiPromotion': delaiPromotion.toUtc().toIso8601String(),
        'nouveauPrix': nouveauPrix,
        'ancienPrix': ancienPrix,
        'likes': likes,
      };

      // Ajouter les images optionnelles si fournies
      if (image1 != null && image1.isNotEmpty) {
        body['image1'] = image1;
      }
      if (image2 != null && image2.isNotEmpty) {
        body['image2'] = image2;
      }
      if (image3 != null && image3.isNotEmpty) {
        body['image3'] = image3;
      }
      if (image4 != null && image4.isNotEmpty) {
        body['image4'] = image4;
      }

      // Faire la requête POST
      final response = await http.post(
        Uri.parse('$baseUrl/promotions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        throw Exception(
          responseData['message'] ?? 
          'Erreur lors de la création de la promotion: ${response.statusCode}'
        );
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}


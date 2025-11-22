import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';
import '../models/promotion.dart';

class PromotionService {
  // URL de base pour l'API - utiliser celle du code existant
  static const String baseUrl = 'http://24.144.87.127:3333';
  
  /// Récupère une promotion par ID
  Future<Map<String, dynamic>> getPromotionById(int promotionId) async {
    try {
      final token = await StorageService().getToken();
      
      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/promotions/$promotionId'),
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

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final promotionJson = responseData['promotion'];
        final Promotion promotion = Promotion.fromJson(promotionJson);
        
        return {
          'success': true,
          'promotion': promotion,
        };
      } else {
        throw Exception(
          responseData['message'] ?? 
          'Erreur lors de la récupération de la promotion: ${response.statusCode}'
        );
      }
    } on http.ClientException catch (e) {
      return {
        'success': false,
        'error': 'Impossible de se connecter au serveur. Vérifiez votre connexion internet.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Récupère toutes les promotions actives (filtrées par marchand si merchantId fourni)
  Future<Map<String, dynamic>> getPromotions({int? merchantId}) async {
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
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: La connexion au serveur a pris trop de temps');
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> promotionsJson = responseData['promotions'] ?? [];
        List<Promotion> promotions = promotionsJson
            .map((json) => Promotion.fromJson(json))
            .toList();
        
        // Filtrer par marchand si merchantId est fourni
        if (merchantId != null) {
          promotions = promotions.where((promo) {
            return promo.product?.vendeurId == merchantId;
          }).toList();
        }
        
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
    } on http.ClientException catch (e) {
      return {
        'success': false,
        'error': 'Impossible de se connecter au serveur. Vérifiez votre connexion internet.',
        'promotions': <Promotion>[],
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'promotions': <Promotion>[],
      };
    }
  }
  
  /// Crée une nouvelle promotion avec multipart/form-data
  /// 
  /// [productId] : ID du produit à mettre en promotion
  /// [image] : Fichier de l'image principale (requis)
  /// [image1-4] : Fichiers des images supplémentaires (optionnel)
  /// [libelle] : Libellé de la promotion
  /// [delaiPromotion] : Date de fin de la promotion (ISO 8601)
  /// [nouveauPrix] : Nouveau prix en promotion
  /// [ancienPrix] : Ancien prix avant promotion
  /// [likes] : Nombre de likes (optionnel, défaut: 0)
  Future<Map<String, dynamic>> createPromotion({
    required int productId,
    required File image,
    File? image1,
    File? image2,
    File? image3,
    File? image4,
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

      // Créer la requête multipart
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/promotions'),
      );

      // Ajouter les headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      // Ajouter les champs de formulaire
      request.fields.addAll({
        'productId': productId.toString(),
        'libelle': libelle,
        'delaiPromotion': delaiPromotion.toUtc().toIso8601String(),
        'nouveauPrix': nouveauPrix.toString(),
        'ancienPrix': ancienPrix.toString(),
        'likes': likes.toString(),
      });

      // Ajouter l'image principale (requis)
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          image.path,
        ),
      );

      // Ajouter les images optionnelles
      if (image1 != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'image1',
            image1.path,
          ),
        );
      }
      if (image2 != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'image2',
            image2.path,
          ),
        );
      }
      if (image3 != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'image3',
            image3.path,
          ),
        );
      }
      if (image4 != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'image4',
            image4.path,
          ),
        );
      }

      // Envoyer la requête
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
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


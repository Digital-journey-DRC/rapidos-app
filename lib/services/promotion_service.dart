import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';
import '../models/promotion.dart';

class PromotionService {
  // URL de base pour l'API - utiliser celle du code existant
  static const String baseUrl = 'http://24.144.87.127:3333';
  
  /// Récupère une promotion par ID de l'utilisateur connecté
  Future<Map<String, dynamic>> getPromotionById() async {
    try {
      // Récupérer l'ID de l'utilisateur connecté
      int? userId;
      final storageService = StorageService();
      final userDataStr = await storageService.getUserData();
      
      if (userDataStr != null) {
        try {
          final userData = jsonDecode(userDataStr);
          final userIdValue = userData['id'];
          print('🔍 promotion_service.getPromotionById - userId brut: $userIdValue (type: ${userIdValue.runtimeType})');
          
          if (userIdValue != null) {
            if (userIdValue is int) {
              userId = userIdValue;
            } else if (userIdValue is String) {
              userId = int.tryParse(userIdValue);
            } else if (userIdValue is num) {
              userId = userIdValue.toInt();
            }
          }
        } catch (e) {
          print('🔍 promotion_service.getPromotionById - Erreur parsing user data: $e');
        }
      }
      
      if (userId == null) {
        throw Exception('ID utilisateur non trouvé. Veuillez vous reconnecter.');
      }
      
      print('🔍 promotion_service.getPromotionById - userId final: $userId');
      print('🔍 promotion_service.getPromotionById - URL: $baseUrl/promotions/$userId');
      
      final token = await storageService.getToken();
      
      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/promotions/$userId'),
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

      print('🔍 promotion_service.getPromotionById - Status code: ${response.statusCode}');
      final responseData = jsonDecode(response.body);
      print('🔍 promotion_service.getPromotionById - Response data keys: ${responseData.keys.toList()}');

      if (response.statusCode == 200) {
        final promotionJson = responseData['promotion'];
        print('🔍 promotion_service.getPromotionById - Promotion JSON keys: ${promotionJson?.keys.toList()}');
        
        if (promotionJson != null) {
          print('🔍 promotion_service.getPromotionById - Promotion images: ${promotionJson['images']}');
          print('🔍 promotion_service.getPromotionById - Promotion image (old format): ${promotionJson['image']}');
        }
        
        final Promotion promotion = Promotion.fromJson(promotionJson);
        print('🔍 promotion_service.getPromotionById - Promotion parsée - ID: ${promotion.id}, Images count: ${promotion.images.length}');
        
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
      print('🔍 promotion_service.getPromotionById - ClientException: $e');
      return {
        'success': false,
        'error': 'Impossible de se connecter au serveur. Vérifiez votre connexion internet.',
      };
    } catch (e) {
      print('🔍 promotion_service.getPromotionById - Exception: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Récupère toutes les promotions actives (pour les clients)
  /// Endpoint: GET /promotions
  /// Accessible à: Tous utilisateurs authentifiés (clients)
  /// Retourne: Toutes les promotions actives de tous les marchands
  Future<Map<String, dynamic>> getPromotions() async {
    try {
      print('🔍 promotion_service.getPromotions - Récupération de toutes les promotions actives (pour clients)');
      print('🔍 promotion_service.getPromotions - URL: $baseUrl/promotions');
      
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

      print('🔍 promotion_service.getPromotions - Status code: ${response.statusCode}');
      final responseData = jsonDecode(response.body);
      print('🔍 promotion_service.getPromotions - Response keys: ${responseData.keys.toList()}');

      if (response.statusCode == 200) {
        final List<dynamic> promotionsJson = responseData['promotions'] ?? [];
        List<Promotion> promotions = [];
        
        print('🔍 promotion_service.getPromotions - Nombre de promotions reçues: ${promotionsJson.length}');
        
        for (var json in promotionsJson) {
          try {
            final promoId = json['id']?.toString() ?? 'unknown';
            print('🔍 promotion_service.getPromotions - Parsing promotion ID: $promoId');
            print('🔍 promotion_service.getPromotions - nouveauPrix type: ${json['nouveauPrix'].runtimeType}, value: ${json['nouveauPrix']}');
            print('🔍 promotion_service.getPromotions - ancienPrix type: ${json['ancienPrix'].runtimeType}, value: ${json['ancienPrix']}');
            print('🔍 promotion_service.getPromotions - product vendeur: ${json['product']?['vendeur']}');
            print('🔍 promotion_service.getPromotions - product vendeurId: ${json['product']?['vendeurId']}');
            final promotion = Promotion.fromJson(json);
            promotions.add(promotion);
            print('🔍 promotion_service.getPromotions - Promotion $promoId parsée avec succès');
          } catch (e, stackTrace) {
            print('🔍 promotion_service.getPromotions - Erreur parsing promotion: $e');
            print('🔍 promotion_service.getPromotions - Stack trace: $stackTrace');
            print('🔍 promotion_service.getPromotions - JSON: $json');
            // Continuer avec les autres promotions même si une échoue
          }
        }
        
        print('🔍 promotion_service.getPromotions - Nombre de promotions parsées avec succès: ${promotions.length}');
        
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
      print('🔍 promotion_service.getPromotions - ClientException: $e');
      return {
        'success': false,
        'error': 'Impossible de se connecter au serveur. Vérifiez votre connexion internet.',
        'promotions': <Promotion>[],
      };
    } catch (e) {
      print('🔍 promotion_service.getPromotions - Exception: $e');
      return {
        'success': false,
        'error': e.toString(),
        'promotions': <Promotion>[],
      };
    }
  }

  /// Récupère les promotions d'un marchand spécifique (filtrées côté client)
  /// Note: Cette méthode utilise getPromotions() puis filtre côté client
  /// Pour une meilleure performance, le backend devrait fournir un endpoint dédié
  Future<Map<String, dynamic>> getMerchantPromotions(int merchantId) async {
    try {
      print('🔍 promotion_service.getMerchantPromotions - merchantId: $merchantId');
      
      // Récupérer toutes les promotions
      final allPromotionsResult = await getPromotions();
      
      if (allPromotionsResult['success'] != true) {
        return allPromotionsResult;
      }
      
      final allPromotions = allPromotionsResult['promotions'] as List<Promotion>;
      
      // Filtrer par marchand
      final merchantPromotions = allPromotions.where((promo) {
        final vendeurId = promo.product?.vendeurId;
        print('🔍 promotion_service.getMerchantPromotions - Promotion ${promo.id}: vendeurId=$vendeurId, match=${vendeurId == merchantId}');
        return vendeurId == merchantId;
      }).toList();
      
      print('🔍 promotion_service.getMerchantPromotions - Nombre de promotions du marchand: ${merchantPromotions.length}');
      
      return {
        'success': true,
        'promotions': merchantPromotions,
      };
    } catch (e) {
      print('🔍 promotion_service.getMerchantPromotions - Exception: $e');
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

  /// Met à jour une promotion existante avec multipart/form-data
  /// 
  /// [promotionId] : ID de la promotion à mettre à jour
  /// [libelle] : Nouveau libellé (optionnel)
  /// [delaiPromotion] : Nouvelle date de fin (optionnel)
  /// [nouveauPrix] : Nouveau prix en promotion (optionnel)
  /// [ancienPrix] : Ancien prix avant promotion (optionnel)
  /// [likes] : Nombre de likes (optionnel)
  /// [image] : Nouvelle image principale (optionnel)
  /// [image1-4] : Nouvelles images supplémentaires (optionnel)
  /// [deleteImage1-4] : Indique si on doit supprimer l'image correspondante
  Future<Map<String, dynamic>> updatePromotion({
    required int promotionId,
    String? libelle,
    DateTime? delaiPromotion,
    double? nouveauPrix,
    double? ancienPrix,
    int? likes,
    File? image,
    File? image1,
    File? image2,
    File? image3,
    File? image4,
    bool deleteImage1 = false,
    bool deleteImage2 = false,
    bool deleteImage3 = false,
    bool deleteImage4 = false,
  }) async {
    try {
      final token = await StorageService().getToken();
      
      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      // Créer la requête multipart
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/promotions/$promotionId'),
      );

      // Ajouter les headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      // Ajouter les champs de formulaire (seulement ceux fournis)
      if (libelle != null) {
        request.fields['libelle'] = libelle;
      }
      if (delaiPromotion != null) {
        request.fields['delaiPromotion'] = delaiPromotion.toUtc().toIso8601String();
      }
      if (nouveauPrix != null) {
        request.fields['nouveauPrix'] = nouveauPrix.toString();
      }
      if (ancienPrix != null) {
        request.fields['ancienPrix'] = ancienPrix.toString();
      }
      if (likes != null) {
        request.fields['likes'] = likes.toString();
      }

      // Gérer la suppression d'images
      if (deleteImage1) {
        request.fields['deleteImage1'] = 'true';
      }
      if (deleteImage2) {
        request.fields['deleteImage2'] = 'true';
      }
      if (deleteImage3) {
        request.fields['deleteImage3'] = 'true';
      }
      if (deleteImage4) {
        request.fields['deleteImage4'] = 'true';
      }

      // Ajouter l'image principale si fournie
      if (image != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            image.path,
          ),
        );
      }

      // Ajouter les images optionnelles si fournies
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

      if (response.statusCode == 200) {
        final promotionJson = responseData['promotion'];
        final Promotion promotion = Promotion.fromJson(promotionJson);
        
        return {
          'success': true,
          'promotion': promotion,
          'data': responseData,
        };
      } else {
        throw Exception(
          responseData['message'] ?? 
          'Erreur lors de la mise à jour de la promotion: ${response.statusCode}'
        );
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Supprime une promotion
  /// 
  /// [promotionId] : ID de la promotion à supprimer
  Future<Map<String, dynamic>> deletePromotion(int promotionId) async {
    try {
      print('🔍 promotion_service.deletePromotion - promotionId: $promotionId');
      
      final token = await StorageService().getToken();
      
      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      final response = await http.delete(
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

      print('🔍 promotion_service.deletePromotion - Status code: ${response.statusCode}');
      final responseData = jsonDecode(response.body);
      print('🔍 promotion_service.deletePromotion - Response: $responseData');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Promotion supprimée avec succès',
          'data': responseData,
        };
      } else {
        throw Exception(
          responseData['message'] ?? 
          'Erreur lors de la suppression de la promotion: ${response.statusCode}'
        );
      }
    } on http.ClientException catch (e) {
      print('🔍 promotion_service.deletePromotion - ClientException: $e');
      return {
        'success': false,
        'error': 'Impossible de se connecter au serveur. Vérifiez votre connexion internet.',
      };
    } catch (e) {
      print('🔍 promotion_service.deletePromotion - Exception: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}


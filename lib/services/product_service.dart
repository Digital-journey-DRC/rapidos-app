import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';
import '../models/product.dart';

class ProductService {
  final String baseUrl = 'http://24.144.87.127:3333';

  Future<Map<String, dynamic>> updateProductStock({
    required int productId,
    required int newStock,
  }) async {
    try {
      final token = await StorageService().getToken();
      
      final response = await http.post(
        Uri.parse('$baseUrl/stock/$productId/update'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'stock': newStock,
        }),
      );

      print('Stock update response status: ${response.statusCode}');
      print('Stock update response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Stock mis à jour avec succès',
          'data': responseData,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Erreur lors de la mise à jour du stock',
        };
      }
    } catch (e) {
      print('Error updating stock: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion: $e',
      };
    }
  }

  Future<Map<String, dynamic>> updateProduct({
    required int productId,
    required String name,
    required String description,
    required double price,
    required int stock,
  }) async {
    try {
      final token = await StorageService().getToken();
      
      final response = await http.put(
        Uri.parse('$baseUrl/products/$productId/update'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'description': description,
          'price': price,
          'stock': stock,
        }),
      );

      print('Product update response status: ${response.statusCode}');
      print('Product update response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Produit mis à jour avec succès',
          'data': responseData,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Erreur lors de la mise à jour du produit',
        };
      }
    } catch (e) {
      print('Error updating product: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion: $e',
      };
    }
  }

  Future<Map<String, dynamic>> deleteProduct({
    required int productId,
  }) async {
    try {
      final token = await StorageService().getToken();
      
      final response = await http.delete(
        Uri.parse('$baseUrl/products/$productId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Product delete response status: ${response.statusCode}');
      print('Product delete response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
        final responseData = response.body.isNotEmpty 
            ? jsonDecode(response.body) 
            : {'message': 'Produit supprimé avec succès'};
        return {
          'success': true,
          'message': responseData['message'] ?? 'Produit supprimé avec succès',
          'data': responseData,
        };
      } else {
        final errorData = response.body.isNotEmpty 
            ? jsonDecode(response.body) 
            : {'message': 'Erreur lors de la suppression du produit'};
        return {
          'success': false,
          'message': errorData['message'] ?? 'Erreur lors de la suppression du produit',
        };
      }
    } catch (e) {
      print('Error deleting product: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion: $e',
      };
    }
  }

  /// Récupère 5 produits recommandés basés sur les événements de l'acheteur
  /// Endpoint: GET /products/recommended
  /// Accessible à: Clients authentifiés
  Future<Map<String, dynamic>> getRecommendedProducts() async {
    try {
      print('🔍 product_service.getRecommendedProducts - Récupération des produits recommandés');
      print('🔍 product_service.getRecommendedProducts - URL: $baseUrl/products/recommended');
      
      final token = await StorageService().getToken();
      
      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/products/recommended'),
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

      print('🔍 product_service.getRecommendedProducts - Status code: ${response.statusCode}');
      final responseData = jsonDecode(response.body);
      print('🔍 product_service.getRecommendedProducts - Response keys: ${responseData.keys.toList()}');

      if (response.statusCode == 200) {
        final List<dynamic> productsJson = responseData['products'] ?? responseData['data'] ?? [];
        List<Product> products = [];
        
        print('🔍 product_service.getRecommendedProducts - Nombre de produits reçus: ${productsJson.length}');
        
        for (var json in productsJson) {
          try {
            final productId = json['id']?.toString() ?? 'unknown';
            print('🔍 product_service.getRecommendedProducts - Parsing product ID: $productId');
            final product = Product.fromJson(json);
            products.add(product);
            print('🔍 product_service.getRecommendedProducts - Product $productId parsé avec succès');
          } catch (e, stackTrace) {
            print('🔍 product_service.getRecommendedProducts - Erreur parsing product: $e');
            print('🔍 product_service.getRecommendedProducts - Stack trace: $stackTrace');
            print('🔍 product_service.getRecommendedProducts - JSON: $json');
            // Continuer avec les autres produits même si un échoue
          }
        }
        
        print('🔍 product_service.getRecommendedProducts - Nombre de produits parsés avec succès: ${products.length}');
        
        return {
          'success': true,
          'products': products,
        };
      } else {
        throw Exception(
          responseData['message'] ?? 
          'Erreur lors de la récupération des produits recommandés: ${response.statusCode}'
        );
      }
    } on http.ClientException catch (e) {
      print('🔍 product_service.getRecommendedProducts - ClientException: $e');
      return {
        'success': false,
        'error': 'Impossible de se connecter au serveur. Vérifiez votre connexion internet.',
        'products': <Product>[],
      };
    } catch (e) {
      print('🔍 product_service.getRecommendedProducts - Exception: $e');
      return {
        'success': false,
        'error': e.toString(),
        'products': <Product>[],
      };
    }
  }
} 
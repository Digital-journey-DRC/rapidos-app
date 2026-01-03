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

  /// Récupère des produits aléatoires
  /// Endpoint: GET /products/random
  /// Accessible à: Clients authentifiés
  Future<Map<String, dynamic>> getRandomProducts() async {
    try {
      print('🔍 product_service.getRandomProducts - Récupération des produits aléatoires');
      print('🔍 product_service.getRandomProducts - URL: $baseUrl/products/random');
      
      final token = await StorageService().getToken();
      
      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/products/random'),
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

      print('🔍 product_service.getRandomProducts - Status code: ${response.statusCode}');
      final responseData = jsonDecode(response.body);
      print('🔍 product_service.getRandomProducts - Response keys: ${responseData.keys.toList()}');

      if (response.statusCode == 200) {
        final List<dynamic> productsJson = responseData['products'] ?? responseData['data'] ?? [];
        List<Product> products = [];
        
        print('🔍 product_service.getRandomProducts - Nombre de produits reçus: ${productsJson.length}');
        
        for (var json in productsJson) {
          try {
            final productId = json['id']?.toString() ?? 'unknown';
            print('🔍 product_service.getRandomProducts - Parsing product ID: $productId');
            final product = Product.fromJson(json);
            products.add(product);
            print('🔍 product_service.getRandomProducts - Product $productId parsé avec succès');
          } catch (e, stackTrace) {
            print('🔍 product_service.getRandomProducts - Erreur parsing product: $e');
            print('🔍 product_service.getRandomProducts - Stack trace: $stackTrace');
            print('🔍 product_service.getRandomProducts - JSON: $json');
            // Continuer avec les autres produits même si un échoue
          }
        }
        
        print('🔍 product_service.getRandomProducts - Nombre de produits parsés avec succès: ${products.length}');
        
        return {
          'success': true,
          'products': products,
        };
      } else {
        throw Exception(
          responseData['message'] ?? 
          'Erreur lors de la récupération des produits aléatoires: ${response.statusCode}'
        );
      }
    } on http.ClientException catch (e) {
      print('🔍 product_service.getRandomProducts - ClientException: $e');
      return {
        'success': false,
        'error': 'Impossible de se connecter au serveur. Vérifiez votre connexion internet.',
        'products': <Product>[],
      };
    } catch (e) {
      print('🔍 product_service.getRandomProducts - Exception: $e');
      return {
        'success': false,
        'error': e.toString(),
        'products': <Product>[],
      };
    }
  }

  /// Récupère les produits de la catégorie Mode
  /// Endpoint: GET /category/mode/mode
  /// Accessible à: Clients authentifiés
  Future<Map<String, dynamic>> getModeProducts() async {
    try {
      print('🔍 product_service.getModeProducts - Récupération des produits Mode');
      print('🔍 product_service.getModeProducts - URL: $baseUrl/category/mode/mode');
      
      final token = await StorageService().getToken();
      
      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/category/mode/mode'),
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

      print('🔍 product_service.getModeProducts - Status code: ${response.statusCode}');
      final responseData = jsonDecode(response.body);
      print('🔍 product_service.getModeProducts - Response keys: ${responseData.keys.toList()}');

      if (response.statusCode == 200) {
        final List<dynamic> productsJson = responseData['products'] ?? responseData['data'] ?? [];
        List<Product> products = [];
        
        print('🔍 product_service.getModeProducts - Nombre de produits reçus: ${productsJson.length}');
        
        for (var json in productsJson) {
          try {
            final productId = json['id']?.toString() ?? 'unknown';
            print('🔍 product_service.getModeProducts - Parsing product ID: $productId');
            final product = Product.fromJson(json);
            products.add(product);
            print('🔍 product_service.getModeProducts - Product $productId parsé avec succès');
          } catch (e, stackTrace) {
            print('🔍 product_service.getModeProducts - Erreur parsing product: $e');
            print('🔍 product_service.getModeProducts - Stack trace: $stackTrace');
            print('🔍 product_service.getModeProducts - JSON: $json');
          }
        }
        
        print('🔍 product_service.getModeProducts - Nombre de produits parsés avec succès: ${products.length}');
        
        return {
          'success': true,
          'products': products,
        };
      } else {
        throw Exception(
          responseData['message'] ?? 
          'Erreur lors de la récupération des produits Mode: ${response.statusCode}'
        );
      }
    } on http.ClientException catch (e) {
      print('🔍 product_service.getModeProducts - ClientException: $e');
      return {
        'success': false,
        'error': 'Impossible de se connecter au serveur. Vérifiez votre connexion internet.',
        'products': <Product>[],
      };
    } catch (e) {
      print('🔍 product_service.getModeProducts - Exception: $e');
      return {
        'success': false,
        'error': e.toString(),
        'products': <Product>[],
      };
    }
  }

  /// Récupère les produits par catégorie
  /// Endpoint: GET /products/by-category/:categorySlug
  /// Accessible à: Clients authentifiés
  Future<Map<String, dynamic>> getProductsByCategory(String categorySlug) async {
    try {
      print('🔍 product_service.getProductsByCategory - Récupération des produits pour: $categorySlug');
      print('🔍 product_service.getProductsByCategory - URL: $baseUrl/products/by-category/$categorySlug');
      
      final token = await StorageService().getToken();
      
      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/products/by-category/$categorySlug'),
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

      print('🔍 product_service.getProductsByCategory - Status code: ${response.statusCode}');
      final responseData = jsonDecode(response.body);
      print('🔍 product_service.getProductsByCategory - Response keys: ${responseData.keys.toList()}');

      if (response.statusCode == 200) {
        final List<dynamic> productsJson = responseData['products'] ?? responseData['data'] ?? [];
        List<Product> products = [];
        
        print('🔍 product_service.getProductsByCategory - Nombre de produits reçus: ${productsJson.length}');
        
        for (var json in productsJson) {
          try {
            final productId = json['id']?.toString() ?? 'unknown';
            print('🔍 product_service.getProductsByCategory - Parsing product ID: $productId');
            final product = Product.fromJson(json);
            products.add(product);
            print('🔍 product_service.getProductsByCategory - Product $productId parsé avec succès');
          } catch (e, stackTrace) {
            print('🔍 product_service.getProductsByCategory - Erreur parsing product: $e');
            print('🔍 product_service.getProductsByCategory - Stack trace: $stackTrace');
            print('🔍 product_service.getProductsByCategory - JSON: $json');
            // Continuer avec les autres produits même si un échoue
          }
        }
        
        print('🔍 product_service.getProductsByCategory - Nombre de produits parsés avec succès: ${products.length}');
        
        return {
          'success': true,
          'products': products,
        };
      } else {
        throw Exception(
          responseData['message'] ?? 
          'Erreur lors de la récupération des produits par catégorie: ${response.statusCode}'
        );
      }
    } on http.ClientException catch (e) {
      print('🔍 product_service.getProductsByCategory - ClientException: $e');
      return {
        'success': false,
        'error': 'Impossible de se connecter au serveur. Vérifiez votre connexion internet.',
        'products': <Product>[],
      };
    } catch (e) {
      print('🔍 product_service.getProductsByCategory - Exception: $e');
      return {
        'success': false,
        'error': e.toString(),
        'products': <Product>[],
      };
    }
  }

  /// Récupère un produit par son ID avec toutes les informations détaillées
  /// Endpoint: GET /products/get-products/:productId
  /// Retourne: product avec id, name, description, price, stock, category, image, images, vendeur, commandes
  Future<Map<String, dynamic>> getProductById(int productId) async {
    try {
      print('🔍 ProductService.getProductById - Récupération du produit ID: $productId');
      
      final token = await StorageService().getToken();
      
      final response = await http.get(
        Uri.parse('$baseUrl/products/get-products/$productId'),
        headers: {
          'Authorization': token != null ? 'Bearer $token' : '',
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: La connexion au serveur a pris trop de temps');
        },
      );

      print('🔍 ProductService.getProductById - Status code: ${response.statusCode}');
      print('🔍 ProductService.getProductById - Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final productData = responseData['product'] ?? responseData;
        
        print('✅ ProductService.getProductById - Produit récupéré avec succès');
        
        return {
          'success': true,
          'product': productData,
        };
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['message'] ?? 
          'Erreur lors de la récupération du produit: ${response.statusCode}'
        );
      }
    } on http.ClientException catch (e) {
      print('❌ ProductService.getProductById - ClientException: $e');
      return {
        'success': false,
        'error': 'Impossible de se connecter au serveur. Vérifiez votre connexion internet.',
      };
    } catch (e) {
      print('❌ ProductService.getProductById - Exception: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
} 
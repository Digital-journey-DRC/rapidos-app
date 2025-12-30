import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/product.dart';
import '../services/storage_service.dart';

// States
abstract class ProductState {}

class ProductInitial extends ProductState {}
class ProductLoading extends ProductState {}
class ProductLoaded extends ProductState {
  final List<Product> products;
  ProductLoaded(this.products);
}
class ProductError extends ProductState {
  final String message;
  ProductError(this.message);
}

// Cubit
class ProductCubit extends Cubit<ProductState> {
  ProductCubit() : super(ProductInitial());

  Future<void> fetchProducts() async {
    try {
      emit(ProductLoading());
      
      final token = await StorageService().getToken();
      final response = await http.get(
        Uri.parse('http://24.144.87.127:3333/products/all-products'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<Product> products = (data['products'] as List)
            .map((product) => Product.fromJson(product))
            .toList();
        emit(ProductLoaded(products));
      } else {
        emit(ProductError('Pas de produits trouvés'));
      }
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  /// Récupère les produits du vendeur connecté
  Future<void> fetchVendeurProducts() async {
    try {
      emit(ProductLoading());
      
      final token = await StorageService().getToken();
      if (token == null) {
        print('❌ ProductCubit: Token manquant');
        emit(ProductError('Token d\'authentification manquant'));
        return;
      }

      print('🔄 ProductCubit: Chargement des produits du vendeur...');
      print('🔑 ProductCubit: Token présent (${token.substring(0, 20)}...)');
      print('🌐 ProductCubit: URL: http://24.144.87.127:3333/products/vendeur');
      final response = await http.get(
        Uri.parse('http://24.144.87.127:3333/products/vendeur'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Timeout: La connexion au serveur a pris trop de temps');
        },
      );

      print('📡 ProductCubit: Réponse API - Status: ${response.statusCode}');
      print('📡 ProductCubit: Réponse body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ ProductCubit: Données reçues - Keys: ${data.keys.toList()}');
        
        // Vérifier différentes structures possibles de réponse
        List<dynamic>? productsList;
        
        if (data['products'] != null) {
          productsList = data['products'] as List;
          print('✅ ProductCubit: Produits trouvés dans data["products"]: ${productsList.length}');
        } else if (data['data'] != null && data['data'] is List) {
          productsList = data['data'] as List;
          print('✅ ProductCubit: Produits trouvés dans data["data"]: ${productsList.length}');
        } else if (data is List) {
          productsList = data;
          print('✅ ProductCubit: Réponse est directement une liste: ${productsList.length}');
        }
        
        if (productsList != null && productsList.isNotEmpty) {
          print('📦 ProductCubit: Premier produit (exemple): ${productsList.first}');
          final List<Product> products = productsList
              .map((product) {
                try {
                  return Product.fromJson(product as Map<String, dynamic>);
                } catch (e) {
                  print('❌ ProductCubit: Erreur parsing produit: $e');
                  print('❌ ProductCubit: Produit problématique: $product');
                  return null;
                }
              })
              .whereType<Product>()
              .toList();
          print('✅ ProductCubit: ${products.length} produits parsés avec succès pour le vendeur');
          emit(ProductLoaded(products));
        } else {
          print('ℹ️ ProductCubit: Aucun produit dans la réponse (liste vide ou null)');
          print('ℹ️ ProductCubit: Structure complète de la réponse: $data');
          emit(ProductLoaded([]));
        }
      } else {
        final errorData = json.decode(response.body);
        print('❌ ProductCubit: Erreur API - ${response.statusCode}');
        print('❌ ProductCubit: Message d\'erreur: ${errorData['message'] ?? 'Erreur inconnue'}');
        print('❌ ProductCubit: Body complet: ${response.body}');
        emit(ProductError(errorData['message'] ?? 'Erreur lors de la récupération des produits'));
      }
    } catch (e) {
      print('❌ ProductCubit: Exception: $e');
      emit(ProductError('Erreur de connexion: $e'));
    }
  }
} 
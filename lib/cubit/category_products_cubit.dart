import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../services/storage_service.dart';

abstract class CategoryProductsState {}
class CategoryProductsInitial extends CategoryProductsState {}
class CategoryProductsLoading extends CategoryProductsState {}
class CategoryProductsLoaded extends CategoryProductsState {
  final List<Product> products;
  CategoryProductsLoaded(this.products);
}
class CategoryProductsEmpty extends CategoryProductsState {}
class CategoryProductsError extends CategoryProductsState {
  final String message;
  CategoryProductsError(this.message);
}

class CategoryProductsCubit extends Cubit<CategoryProductsState> {
  CategoryProductsCubit() : super(CategoryProductsInitial());

  /// Récupère le token depuis StorageService ou SharedPreferences
  Future<String?> _getToken() async {
    // Essayer d'abord StorageService
    String? token = await StorageService().getToken();
    
    // Si pas trouvé, essayer SharedPreferences directement
    if (token == null) {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('token');
      
      // Si trouvé dans SharedPreferences, synchroniser vers StorageService
      if (token != null) {
        await StorageService().saveToken(token);
      }
    }
    
    return token;
  }

  Future<void> fetchProductsByCategory(int categoryId) async {
    emit(CategoryProductsLoading());
    try {
      final token = await _getToken();
      print('🛍️ CategoryProductsCubit: Token récupéré: ${token != null ? "Présent" : "Absent"}');
      
      if (token == null) {
        print('❌ CategoryProductsCubit: Token manquant, impossible de charger les produits');
        emit(CategoryProductsError('Token d\'authentification manquant'));
        return;
      }
      
      print('🔄 CategoryProductsCubit: Chargement des produits de la catégorie $categoryId...');
      final response = await http.get(
        Uri.parse('http://24.144.87.127:3333/products/category/$categoryId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      print('📡 CategoryProductsCubit: Réponse API - Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ CategoryProductsCubit: Données reçues: ${data}');
        
        if (data['products'] != null) {
          final List<Product> products = (data['products'] as List)
              .map((e) => Product.fromJson(e))
              .toList();
          print('✅ CategoryProductsCubit: ${products.length} produits chargés');
          
          if (products.isEmpty) {
            print('ℹ️ CategoryProductsCubit: Aucun produit dans cette catégorie');
            emit(CategoryProductsEmpty());
          } else {
            emit(CategoryProductsLoaded(products));
          }
        } else {
          print('ℹ️ CategoryProductsCubit: Aucun produit dans la réponse');
          emit(CategoryProductsEmpty());
        }
      } else if (response.statusCode == 404) {
        print('ℹ️ CategoryProductsCubit: Catégorie non trouvée (404)');
        emit(CategoryProductsEmpty());
      } else {
        print('❌ CategoryProductsCubit: Erreur API - ${response.statusCode}: ${response.body}');
        emit(CategoryProductsError('Erreur lors du chargement des produits: ${response.statusCode}'));
      }
    } catch (e) {
      print('❌ CategoryProductsCubit: Erreur: $e');
      emit(CategoryProductsError(e.toString()));
    }
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../services/storage_service.dart';

abstract class FeaturedProductState {}
class FeaturedProductInitial extends FeaturedProductState {}
class FeaturedProductLoading extends FeaturedProductState {}
class FeaturedProductLoaded extends FeaturedProductState {
  final List<Product> products;
  FeaturedProductLoaded(this.products);
}
class FeaturedProductError extends FeaturedProductState {}

class FeaturedProductCubit extends Cubit<FeaturedProductState> {
  FeaturedProductCubit() : super(FeaturedProductInitial());

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

  Future<void> fetchFeaturedProducts() async {
    emit(FeaturedProductLoading());
    try {
      final token = await _getToken();
      print('⭐ FeaturedProductCubit: Token récupéré: ${token != null ? "Présent" : "Absent"}');
      
      if (token == null) {
        print('❌ FeaturedProductCubit: Token manquant, impossible de charger les produits');
        emit(FeaturedProductError());
        return;
      }
      
      print('🔄 FeaturedProductCubit: Chargement des produits vedettes...');
      final response = await http.get(
        Uri.parse('http://24.144.87.127:3333/products/all'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      print('📡 FeaturedProductCubit: Réponse API - Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ FeaturedProductCubit: Données reçues: ${data}');
        
        if (data['products'] != null) {
          final List<Product> products = (data['products'] as List)
              .map((e) => Product.fromJson(e))
              .toList();
          print('✅ FeaturedProductCubit: ${products.length} produits chargés');
          emit(FeaturedProductLoaded(products));
        } else {
          print('❌ FeaturedProductCubit: Aucun produit dans la réponse');
          emit(FeaturedProductError());
        }
      } else {
        print('❌ FeaturedProductCubit: Erreur API - ${response.statusCode}: ${response.body}');
        emit(FeaturedProductError());
      }
    } catch (e) {
      print('❌ FeaturedProductCubit: Erreur: $e');
      emit(FeaturedProductError());
    }
  }
} 
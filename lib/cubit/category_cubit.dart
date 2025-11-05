import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category.dart';
import '../services/storage_service.dart';

abstract class CategoryState {}
class CategoryInitial extends CategoryState {}
class CategoryLoading extends CategoryState {}
class CategoryLoaded extends CategoryState {
  final List<Category> categories;
  CategoryLoaded(this.categories);
}
class CategoryError extends CategoryState {
  final String message;
  CategoryError(this.message);
}

class CategoryCubit extends Cubit<CategoryState> {
  CategoryCubit() : super(CategoryInitial());

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

  Future<void> fetchCategories() async {
    emit(CategoryLoading());
    try {
      final token = await _getToken();
      print('🏷️ CategoryCubit: Token récupéré: ${token != null ? "Présent" : "Absent"}');
      
      if (token == null) {
        print('❌ CategoryCubit: Token manquant, impossible de charger les catégories');
        emit(CategoryError('Token d\'authentification manquant'));
        return;
      }
      
      print('🔄 CategoryCubit: Chargement des catégories...');
      final response = await http.get(
        Uri.parse('http://24.144.87.127:3333/category/get-all'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      print('📡 CategoryCubit: Réponse API - Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ CategoryCubit: Données reçues: ${data}');
        
        if (data['categories'] != null) {
          final List<Category> categories = (data['categories'] as List)
              .map((e) => Category.fromJson(e))
              .toList();
          print('✅ CategoryCubit: ${categories.length} catégories chargées');
          emit(CategoryLoaded(categories));
        } else {
          print('❌ CategoryCubit: Aucune catégorie dans la réponse');
          emit(CategoryError('Aucune catégorie trouvée'));
        }
      } else {
        print('❌ CategoryCubit: Erreur API - ${response.statusCode}: ${response.body}');
        emit(CategoryError('Erreur lors du chargement des catégories: ${response.statusCode}'));
      }
    } catch (e) {
      print('❌ CategoryCubit: Erreur: $e');
      emit(CategoryError(e.toString()));
    }
  }
} 
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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

  Future<void> fetchCategories() async {
    emit(CategoryLoading());
    try {
      final token = await StorageService().getToken();
      final response = await http.get(
        Uri.parse('http://24.144.87.127:3333/category/get-all'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<Category> categories = (data['categories'] as List)
            .map((e) => Category.fromJson(e))
            .toList();
        emit(CategoryLoaded(categories));
      } else {
        emit(CategoryError('Erreur lors du chargement des catégories'));
      }
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }
} 
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
} 
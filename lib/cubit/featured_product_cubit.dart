import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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

  Future<void> fetchFeaturedProducts() async {
    emit(FeaturedProductLoading());
    try {
      final token = await StorageService().getToken();
      final response = await http.get(
        Uri.parse('http://24.144.87.127:3333/products/all'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<Product> products = (data['products'] as List)
            .map((e) => Product.fromJson(e))
            .toList();
        emit(FeaturedProductLoaded(products));
      } else {
        emit(FeaturedProductError());
      }
    } catch (e) {
      emit(FeaturedProductError());
    }
  }
} 
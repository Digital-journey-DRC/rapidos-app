import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';

part 'favorites_state.dart';

class FavoritesCubit extends Cubit<FavoritesState> {
  FavoritesCubit() : super(FavoritesInitial());

  Box? _favoritesBox;

  Future<void> _init() async {
    if (!Hive.isBoxOpen("favorites_products")) {
      _favoritesBox = await Hive.openBox("favorites_products");
    } else {
      _favoritesBox = Hive.box("favorites_products");
    }
  }

  Future<void> loadFavorites() async {
    await _init();
    final savedData = _favoritesBox?.get("products");
    if (savedData != null) {
      List data = jsonDecode(savedData) as List;
      emit(FavoritesLoaded(List<Map<String, dynamic>>.from(data)));
    } else {
      emit(const FavoritesLoaded([]));
    }
  }

  Future<void> toggleFavorite(Map<String, dynamic> product) async {
    await _init();
    List<Map<String, dynamic>> favorites = [];
    final savedData = _favoritesBox?.get("products");
    if (savedData != null) {
      favorites = List<Map<String, dynamic>>.from(jsonDecode(savedData));
    }
    final index = favorites.indexWhere((p) => p['id'] == product['id']);
    if (index != -1) {
      favorites.removeAt(index);
    } else {
      favorites.add(product);
    }
    await _favoritesBox?.put("products", jsonEncode(favorites));
    emit(FavoritesLoaded(List<Map<String, dynamic>>.from(favorites)));
  }

  Future<bool> isFavorite(int productId) async {
    await _init();
    final savedData = _favoritesBox?.get("products");
    if (savedData != null) {
      final favorites = List<Map<String, dynamic>>.from(jsonDecode(savedData));
      return favorites.any((p) => p['id'] == productId);
    }
    return false;
  }
} 
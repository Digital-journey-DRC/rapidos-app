import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class FavoritesRepository {
  static Box? _favoritesBox;

  static Future<void> init() async {
    if (!Hive.isBoxOpen("favorites")) {
      _favoritesBox = await Hive.openBox("favorites");
    } else {
      _favoritesBox = Hive.box("favorites");
    }
  }

  static Future<List<Map<String, dynamic>>> getFavorites() async {
    try {
      await init();
      final savedData = _favoritesBox?.get("properties");
      if (savedData != null) {
        List data = jsonDecode(savedData) as List;
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (error) {
      print("Error retrieving favorites: $error");
      return [];
    }
  }

  static Future<void> saveFavorites(List<Map<String, dynamic>> favorites) async {
    try {
      await init();
      await _favoritesBox?.put("properties", jsonEncode(favorites));
      print("Favorites saved successfully");
    } catch (error) {
      print("Error saving favorites: $error");
    }
  }

  static Future<void> toggleFavorite(Map<String, dynamic> property) async {
    try {
      await init();
      var favorites = await getFavorites();
      
      // Vérifier si la propriété est déjà dans les favoris
      final index = favorites.indexWhere((p) => p['id'] == property['id']);
      
      if (index != -1) {
        // Si la propriété existe, la supprimer
        favorites.removeAt(index);
      } else {
        // Si la propriété n'existe pas, l'ajouter
        favorites.add(property);
      }
      
      await saveFavorites(favorites);
    } catch (error) {
      print("Error toggling favorite: $error");
    }
  }

  static Future<bool> isFavorite(String propertyId) async {
    try {
      await init();
      var favorites = await getFavorites();
      return favorites.any((p) => p['id'] == propertyId);
    } catch (error) {
      print("Error checking favorite status: $error");
      return false;
    }
  }

  static Future<void> clearFavorites() async {
    try {
      await init();
      await _favoritesBox?.delete("properties");
      print("Favorites cleared successfully");
    } catch (error) {
      print("Error clearing favorites: $error");
    }
  }
}

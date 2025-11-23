import 'category.dart';
import 'vendeur.dart';

class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final int stock;
  final int vendeurId;
  final String createdAt;
  final String updatedAt;
  final int categorieId;
  final Media? media;
  final Category? category;
  final Vendeur? vendeur; // Informations du vendeur

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.vendeurId,
    required this.createdAt,
    required this.updatedAt,
    required this.categorieId,
    this.media,
    this.category,
    this.vendeur,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Helper functions pour parser les valeurs de manière sécurisée
    int parseToInt(dynamic value, int fallback) {
      if (value == null) return fallback;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        return int.tryParse(value) ?? fallback;
      }
      if (value is num) return value.toInt();
      return fallback;
    }

    double parseToDouble(dynamic value, double fallback) {
      if (value == null) return fallback;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? fallback;
      }
      if (value is num) return value.toDouble();
      return fallback;
    }

    // Gérer vendeurId : peut être directement dans json ou dans un objet vendeur
    int vendeurIdValue = 0;
    Vendeur? vendeur;
    
    if (json['vendeurId'] != null) {
      vendeurIdValue = parseToInt(json['vendeurId'], 0);
    } else if (json['vendeur'] != null && json['vendeur'] is Map) {
      final vendeurJson = json['vendeur'] as Map<String, dynamic>;
      vendeurIdValue = parseToInt(vendeurJson['id'], 0);
      // Parser les informations du vendeur si disponibles
      vendeur = Vendeur.fromProductJson(vendeurJson);
    }

    return Product(
      id: parseToInt(json['id'], 0),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: parseToDouble(json['price'], 0.0),
      stock: parseToInt(json['stock'], 0),
      vendeurId: vendeurIdValue,
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
      categorieId: parseToInt(json['categorieId'], 0),
      media: json['media'] != null ? Media.fromJson(json['media']) : null,
      category: json['category'] != null ? Category.fromJson(json['category']) : null,
      vendeur: vendeur,
    );
  }
}

class Media {
  final int id;
  final String mediaUrl;
  final String mediaType;
  final String createdAt;
  final String updatedAt;
  final int productId;

  Media({
    required this.id,
    required this.mediaUrl,
    required this.mediaType,
    required this.createdAt,
    required this.updatedAt,
    required this.productId,
  });

  factory Media.fromJson(Map<String, dynamic> json) {
    // Helper function pour parser les valeurs de manière sécurisée
    int parseToInt(dynamic value, int fallback) {
      if (value == null) return fallback;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        return int.tryParse(value) ?? fallback;
      }
      if (value is num) return value.toInt();
      return fallback;
    }

    return Media(
      id: parseToInt(json['id'], 0),
      mediaUrl: json['mediaUrl']?.toString() ?? '',
      mediaType: json['mediaType']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
      productId: parseToInt(json['productId'], 0),
    );
  }
} 
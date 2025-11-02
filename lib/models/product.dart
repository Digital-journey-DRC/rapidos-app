import 'category.dart';

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
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: json['price'].toDouble(),
      stock: json['stock'],
      vendeurId: json['vendeurId'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      categorieId: json['categorieId'],
      media: json['media'] != null ? Media.fromJson(json['media']) : null,
      category: json['category'] != null ? Category.fromJson(json['category']) : null,
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
    return Media(
      id: json['id'],
      mediaUrl: json['mediaUrl'],
      mediaType: json['mediaType'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      productId: json['productId'],
    );
  }
} 
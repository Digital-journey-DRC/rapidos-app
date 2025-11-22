import 'product.dart';

class Promotion {
  final int id;
  final int productId;
  final String image;
  final String? image1;
  final String? image2;
  final String? image3;
  final String? image4;
  final String libelle;
  final int likes;
  final DateTime delaiPromotion;
  final double nouveauPrix;
  final double ancienPrix;
  final Product? product;
  final DateTime createdAt;
  final DateTime updatedAt;

  Promotion({
    required this.id,
    required this.productId,
    required this.image,
    this.image1,
    this.image2,
    this.image3,
    this.image4,
    required this.libelle,
    required this.likes,
    required this.delaiPromotion,
    required this.nouveauPrix,
    required this.ancienPrix,
    this.product,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      id: json['id'],
      productId: json['productId'],
      image: json['image'] ?? '',
      image1: json['image1'],
      image2: json['image2'],
      image3: json['image3'],
      image4: json['image4'],
      libelle: json['libelle'] ?? '',
      likes: json['likes'] ?? 0,
      delaiPromotion: DateTime.parse(json['delaiPromotion']),
      nouveauPrix: (json['nouveauPrix'] as num).toDouble(),
      ancienPrix: (json['ancienPrix'] as num).toDouble(),
      product: json['product'] != null ? Product.fromJson(json['product']) : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  /// Vérifie si la promotion est encore active
  bool get isActive {
    return DateTime.now().isBefore(delaiPromotion);
  }

  /// Calcule le pourcentage de réduction
  double get discountPercentage {
    if (ancienPrix == 0) return 0;
    return ((ancienPrix - nouveauPrix) / ancienPrix) * 100;
  }
}


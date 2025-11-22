import 'product.dart';

class Promotion {
  final int id;
  final int productId;
  final String image;
  final List<String> images; // Nouveau tableau d'images
  // Anciens champs pour compatibilité (dépréciés)
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
    required this.images,
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
    // Gérer le nouveau format avec le tableau images
    List<String> imagesList = [];
    if (json['images'] != null && json['images'] is List) {
      imagesList = (json['images'] as List)
          .map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    } else {
      // Fallback vers l'ancien format (image1-4) pour compatibilité
      if (json['image1'] != null && json['image1'].toString().isNotEmpty) {
        imagesList.add(json['image1'].toString());
      }
      if (json['image2'] != null && json['image2'].toString().isNotEmpty) {
        imagesList.add(json['image2'].toString());
      }
      if (json['image3'] != null && json['image3'].toString().isNotEmpty) {
        imagesList.add(json['image3'].toString());
      }
      if (json['image4'] != null && json['image4'].toString().isNotEmpty) {
        imagesList.add(json['image4'].toString());
      }
    }

    // Parser les dates de manière sécurisée
    DateTime parseDate(dynamic dateValue, DateTime fallback) {
      try {
        if (dateValue == null) return fallback;
        if (dateValue is String) {
          return DateTime.parse(dateValue);
        }
        return fallback;
      } catch (e) {
        return fallback;
      }
    }

    // Helper pour parser les valeurs numériques (peuvent être num ou String)
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

    final now = DateTime.now();

    return Promotion(
      id: parseToInt(json['id'], 0),
      productId: parseToInt(json['productId'], 0),
      image: json['image']?.toString() ?? '',
      images: imagesList,
      image1: json['image1']?.toString(),
      image2: json['image2']?.toString(),
      image3: json['image3']?.toString(),
      image4: json['image4']?.toString(),
      libelle: json['libelle']?.toString() ?? '',
      likes: parseToInt(json['likes'], 0),
      delaiPromotion: parseDate(json['delaiPromotion'], now.add(const Duration(days: 30))),
      nouveauPrix: parseToDouble(json['nouveauPrix'], 0.0),
      ancienPrix: parseToDouble(json['ancienPrix'], 0.0),
      product: json['product'] != null ? Product.fromJson(json['product']) : null,
      createdAt: parseDate(json['createdAt'], now),
      updatedAt: parseDate(json['updatedAt'], now),
    );
  }

  /// Retourne toutes les images (principale + secondaires)
  List<String> getAllImages() {
    final allImages = <String>[image];
    allImages.addAll(images);
    return allImages.where((img) => img.isNotEmpty).toList();
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


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
  final String? image; // Image principale (nouveau format)
  final List<String> images; // Images secondaires (nouveau format)

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
    this.image,
    this.images = const [],
  });

  // Méthode pour obtenir toutes les images (main + secondaires)
  List<String> getAllImages() {
    final allImages = <String>[];
    
    // Priorité 1: Utiliser l'image principale du nouveau format
    if (image != null && image!.isNotEmpty) {
      allImages.add(image!);
      print('📸 Product.getAllImages - Image principale ajoutée: ${image!}');
    }
    // Priorité 2: Utiliser media.mediaUrl de l'ancien format
    else if (media != null && media!.mediaUrl.isNotEmpty) {
      allImages.add(media!.mediaUrl);
      print('📸 Product.getAllImages - Image media ajoutée: ${media!.mediaUrl}');
    }
    
    // Ajouter les images secondaires du nouveau format
    final validSecondaryImages = images.where((img) => img.isNotEmpty).toList();
    allImages.addAll(validSecondaryImages);
    print('📸 Product.getAllImages - Images secondaires ajoutées (${validSecondaryImages.length}): $validSecondaryImages');
    print('📸 Product.getAllImages - Total images: ${allImages.length}');
    
    // Si aucune image n'est présente, fournir une image par défaut
    if (allImages.isEmpty) {
      // Image par défaut pour produit : panier de courses
      allImages.add('https://images.unsplash.com/photo-1556912172-45b7abe8b7e4?w=400&h=400&fit=crop');
      print('📸 Product.getAllImages - Aucune image, utilisation de l\'image par défaut');
    }
    
    return allImages;
  }

  // Méthode pour obtenir l'image principale
  String getMainImage() {
    if (image != null && image!.isNotEmpty) {
      return image!;
    }
    if (media != null && media!.mediaUrl.isNotEmpty) {
      return media!.mediaUrl;
    }
    // Image par défaut pour produit : panier de courses
    return 'https://images.unsplash.com/photo-1556912172-45b7abe8b7e4?w=400&h=400&fit=crop';
  }

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
    
    // Priorité: parser vendeurId directement s'il existe
    if (json['vendeurId'] != null) {
      vendeurIdValue = parseToInt(json['vendeurId'], 0);
    }
    
    // Parser l'objet vendeur s'il existe (format commun)
    if (json['vendeur'] != null && json['vendeur'] is Map) {
      final vendeurJson = json['vendeur'] as Map<String, dynamic>;
      // Si vendeurId n'était pas défini, l'extraire de l'objet vendeur
      if (vendeurIdValue == 0) {
        vendeurIdValue = parseToInt(vendeurJson['id'], 0);
      }
      // Parser les informations du vendeur (incluant profil avec media)
      vendeur = Vendeur.fromProductJson(vendeurJson);
    }

    // Gérer categorieId : peut être directement dans json ou dans un objet category
    int categorieIdValue = 0;
    Category? categoryObj;
    
    // Priorité: parser categorieId directement s'il existe
    if (json['categorieId'] != null) {
      categorieIdValue = parseToInt(json['categorieId'], 0);
    }
    
    // Parser l'objet category s'il existe (nouveau format)
    if (json['category'] != null && json['category'] is Map) {
      final categoryJson = json['category'] as Map<String, dynamic>;
      categoryObj = Category.fromJson(categoryJson);
      // Si categorieId n'était pas défini, l'extraire de l'objet category
      if (categorieIdValue == 0) {
        categorieIdValue = parseToInt(categoryJson['id'], 0);
      }
    }

    // Gérer les images : nouveau format avec image (string) et images (array)
    String? mainImage;
    List<String> secondaryImages = [];
    
    // Nouveau format: image (string principale)
    if (json['image'] != null) {
      mainImage = json['image'].toString();
      print('📸 Product.fromJson - Image principale: $mainImage');
    }
    
    // Nouveau format: images (array secondaires)
    if (json['images'] != null && json['images'] is List) {
      secondaryImages = (json['images'] as List)
          .map((img) => img.toString())
          .where((img) => img.isNotEmpty)
          .toList();
      print('📸 Product.fromJson - Images secondaires (${secondaryImages.length}): $secondaryImages');
    } else {
      print('📸 Product.fromJson - Pas d\'images secondaires dans le JSON');
    }
    
    // Si les images secondaires sont vides, utiliser l'image principale comme fallback
    // (comme demandé par l'utilisateur précédemment)
    if (secondaryImages.isEmpty && mainImage != null && mainImage.isNotEmpty) {
      // L'image principale est déjà dans mainImage, pas besoin de la dupliquer
    }

    // Gérer media : ancien format (objet Media)
    Media? mediaObj;
    if (json['media'] != null && json['media'] is Map) {
      mediaObj = Media.fromJson(json['media'] as Map<String, dynamic>);
    }
    // Si media n'existe pas, on utilise mainImage dans le champ image

    return Product(
      id: parseToInt(json['id'], 0),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: parseToDouble(json['price'], 0.0),
      stock: parseToInt(json['stock'], 0),
      vendeurId: vendeurIdValue,
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
      categorieId: categorieIdValue,
      media: mediaObj,
      category: categoryObj,
      vendeur: vendeur,
      image: mainImage,
      images: secondaryImages,
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
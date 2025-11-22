/// Modèle de données statique pour les produits du marchand
class MerchantProduct {
  final int id;
  final String name;
  final String description;
  final double price;
  final int stock;
  final String imageUrl;
  final String category;
  final bool isPromo;
  final bool isRecommended;
  final double? promoPrice;
  final double rating;

  MerchantProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.imageUrl,
    required this.category,
    this.isPromo = false,
    this.isRecommended = false,
    this.promoPrice,
    this.rating = 5.0,
  });

  /// Données statiques pour les produits
  static List<MerchantProduct> getStaticProducts() {
    return [
      MerchantProduct(
        id: 1,
        name: 'Produit Premium',
        description: 'Description du produit premium',
        price: 15000,
        stock: 50,
        imageUrl: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400&h=400&fit=crop',
        category: 'Électronique',
        isPromo: false,
        isRecommended: true,
        rating: 4.8,
      ),
      MerchantProduct(
        id: 2,
        name: 'Produit en Promotion',
        description: 'Description du produit en promotion',
        price: 20000,
        stock: 30,
        imageUrl: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400&h=400&fit=crop',
        category: 'Mode',
        isPromo: true,
        promoPrice: 15000,
        isRecommended: false,
        rating: 4.5,
      ),
      MerchantProduct(
        id: 3,
        name: 'Produit Recommandé',
        description: 'Description du produit recommandé',
        price: 12000,
        stock: 25,
        imageUrl: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400&h=400&fit=crop',
        category: 'Alimentation',
        isPromo: false,
        isRecommended: true,
        rating: 4.9,
      ),
      MerchantProduct(
        id: 4,
        name: 'Produit Standard',
        description: 'Description du produit standard',
        price: 8000,
        stock: 100,
        imageUrl: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400&h=400&fit=crop',
        category: 'Divers',
        isPromo: false,
        isRecommended: false,
        rating: 4.2,
      ),
      MerchantProduct(
        id: 5,
        name: 'Super Promotion',
        description: 'Description du super produit en promotion',
        price: 25000,
        stock: 15,
        imageUrl: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400&h=400&fit=crop',
        category: 'Électronique',
        isPromo: true,
        promoPrice: 18000,
        isRecommended: true,
        rating: 4.7,
      ),
    ];
  }

  /// Récupérer tous les produits
  static List<MerchantProduct> getAllProducts() {
    return getStaticProducts();
  }

  /// Récupérer les produits en promotion
  static List<MerchantProduct> getPromoProducts() {
    return getStaticProducts().where((p) => p.isPromo).toList();
  }

  /// Récupérer les produits recommandés
  static List<MerchantProduct> getRecommendedProducts() {
    return getStaticProducts().where((p) => p.isRecommended).toList();
  }
}


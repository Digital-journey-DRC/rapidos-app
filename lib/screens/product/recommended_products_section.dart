import 'package:flutter/material.dart';
import 'package:immo/constants.dart';
import 'package:immo/screens/product/product_detail_screen.dart';
import 'package:immo/screens/product/client_recommended_products_screen.dart';
import 'package:immo/services/product_service.dart';
import 'package:immo/models/product.dart';

/// Widget réutilisable pour afficher la section "Produits recommandés"
class RecommendedProductsSection extends StatelessWidget {
  const RecommendedProductsSection({Key? key}) : super(key: key);

  /// Retourne une liste statique de 4 produits recommandés en promotion
  /// TODO: Remplacer par des données du backend
  List<Map<String, dynamic>> _getRecommendedProducts() {
    final now = DateTime.now();
    return [
      {
        'id': 101,
        'name': 'Smartphone Premium',
        'category': 'Électronique',
        'tag': 'RECOMMANDÉ',
        'imagePath': 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=400&h=400&fit=crop',
        'originalPrice': 300000.0,
        'promoPrice': 240000.0,
        'discount': 20,
        'startDate': now.subtract(const Duration(days: 1)),
        'endDate': now.add(const Duration(days: 8)),
        'description': 'Smartphone premium dernière génération',
        'idVendeur': '1',
      },
      {
        'id': 102,
        'name': 'Casque Sans Fil',
        'category': 'Électronique',
        'tag': 'RECOMMANDÉ',
        'imagePath': 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400&h=400&fit=crop',
        'originalPrice': 75000.0,
        'promoPrice': 55000.0,
        'discount': 27,
        'startDate': now.subtract(const Duration(days: 2)),
        'endDate': now.add(const Duration(days: 6)),
        'description': 'Casque sans fil haute qualité',
        'idVendeur': '2',
      },
      {
        'id': 103,
        'name': 'Montre Intelligente',
        'category': 'Électronique',
        'tag': 'RECOMMANDÉ',
        'imagePath': 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400&h=400&fit=crop',
        'originalPrice': 95000.0,
        'promoPrice': 70000.0,
        'discount': 26,
        'startDate': now.subtract(const Duration(days: 3)),
        'endDate': now.add(const Duration(days: 7)),
        'description': 'Montre intelligente avec suivi fitness',
        'idVendeur': '3',
      },
      {
        'id': 104,
        'name': 'Écouteurs Pro',
        'category': 'Électronique',
        'tag': 'RECOMMANDÉ',
        'imagePath': 'https://images.unsplash.com/photo-1572569511254-d8f925fe2cbb?w=400&h=400&fit=crop',
        'originalPrice': 45000.0,
        'promoPrice': 32000.0,
        'discount': 29,
        'startDate': now.subtract(const Duration(days: 1)),
        'endDate': now.add(const Duration(days: 9)),
        'description': 'Écouteurs professionnels haute fidélité',
        'idVendeur': '4',
      },
    ];
  }

  /// Filtre les produits recommandés valides (date actuelle entre startDate et endDate)
  List<Map<String, dynamic>> _getValidRecommendedProducts() {
    final now = DateTime.now();
    return _getRecommendedProducts().where((product) {
      final startDate = product['startDate'] as DateTime;
      final endDate = product['endDate'] as DateTime;
      return now.isAfter(startDate.subtract(const Duration(days: 1))) &&
          now.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ProductService().getRecommendedProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Produits recommandés',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: 3,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      return Container(
                        width: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!['success'] != true) {
          // En cas d'erreur, utiliser les données statiques comme fallback
          final recommendedProducts = _getValidRecommendedProducts();
          if (recommendedProducts.isEmpty) {
            return const SizedBox.shrink();
          }
          return _buildPromoList(context, recommendedProducts);
        }

        final products = snapshot.data!['products'] as List<Product>;
        
        if (products.isEmpty) {
          return const SizedBox.shrink();
        }

        return _buildPromoListFromProducts(context, products);
      },
    );
  }

  /// Construit la liste avec les données statiques (fallback)
  Widget _buildPromoList(BuildContext context, List<Map<String, dynamic>> recommendedProducts) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Produits recommandés',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ClientRecommendedProductsScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Voir tout',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: recommendedProducts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final product = recommendedProducts[index];
                return _buildRecommendedProductCard(context, product);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Construit la liste avec les produits dynamiques depuis l'API
  Widget _buildPromoListFromProducts(BuildContext context, List<Product> products) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Produits recommandés',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ClientRecommendedProductsScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Voir tout',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: products.length > 5 ? 5 : products.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final product = products[index];
                return _buildRecommendedProductCardFromProduct(context, product);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Construit une carte de produit recommandé depuis un objet Product
  Widget _buildRecommendedProductCardFromProduct(
    BuildContext context,
    Product product,
  ) {
    final imageUrl = product.getMainImage();

    return GestureDetector(
      onTap: () {
        final List<String> productImages = product.getAllImages();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              description: product.description,
              idVendeur: product.vendeurId.toString(),
              id: product.id,
              tag: 'RECOMMANDÉ',
              category: product.category?.name ?? '',
              stock: product.stock,
              name: product.name,
              price: product.price,
              imagePath: imageUrl,
              productImages: productImages.isNotEmpty ? productImages : null,
              product: product, // Passer le produit complet avec les infos du vendeur
            ),
          ),
        );
      },
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Zone image - occupe toute la largeur
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Hero(
                tag: 'recommended_product_${product.id}_$imageUrl',
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 120,
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.image,
                        color: Colors.grey,
                        size: 40,
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: double.infinity,
                      height: 120,
                      color: Colors.grey.shade100,
                      child: Center(
                        child: SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            strokeWidth: 2.5,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // Informations du produit
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Nom du produit
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Prix
                    Text(
                      '${product.price.toStringAsFixed(0)} FC',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit une carte de produit recommandé avec design impeccable
  Widget _buildRecommendedProductCard(
    BuildContext context,
    Map<String, dynamic> product,
  ) {
    final id = product['id'] as int;
    final name = product['name'] as String;
    final category = product['category'] as String;
    final tag = product['tag'] as String;
    final imagePath = product['imagePath'] as String;
    final promoPrice = product['promoPrice'] as double;
    final description = product['description'] as String;
    final idVendeur = product['idVendeur'] as String;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              description: description,
              idVendeur: idVendeur,
              id: id,
              tag: tag,
              category: category,
              stock: 0, // Stock non affiché dans cette section
              name: name,
              price: promoPrice,
              imagePath: imagePath,
            ),
          ),
        );
      },
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Zone image - occupe toute la largeur
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Hero(
                tag: 'recommended_product_${id}_${imagePath}',
                child: Image.network(
                  imagePath,
                  width: double.infinity,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 120,
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.image,
                        color: Colors.grey,
                        size: 40,
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: double.infinity,
                      height: 120,
                      color: Colors.grey.shade100,
                      child: Center(
                        child: SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            strokeWidth: 2.5,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // Informations du produit
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Nom du produit
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Prix promo uniquement
                    Text(
                      '${promoPrice.toStringAsFixed(0)} FC',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


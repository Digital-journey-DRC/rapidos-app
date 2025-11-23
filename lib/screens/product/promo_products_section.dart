import 'package:flutter/material.dart';
import 'package:immo/constants.dart';
import 'package:immo/screens/product/product_detail_screen.dart';
import 'package:immo/screens/product/client_promo_products_screen.dart';
import 'package:immo/services/promotion_service.dart';
import 'package:immo/models/promotion.dart';
import 'package:intl/intl.dart';

/// Widget réutilisable pour afficher la section "Produits en promo"
class PromoProductsSection extends StatelessWidget {
  const PromoProductsSection({Key? key}) : super(key: key);

  /// Retourne une liste statique de 10 produits en promo (fallback si API échoue)
  List<Map<String, dynamic>> _getPromoProducts() {
    final now = DateTime.now();
    return [
      {
        'id': 1,
        'name': 'Casque Audio Premium',
        'category': 'Électronique',
        'tag': 'PROMO',
        'imagePath': 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400&h=400&fit=crop',
        'originalPrice': 50000.0,
        'promoPrice': 35000.0,
        'discount': 30,
        'startDate': now.subtract(const Duration(days: 2)),
        'endDate': now.add(const Duration(days: 5)),
        'stock': 15,
        'description': 'Casque audio premium avec réduction de bruit',
        'idVendeur': '1',
      },
      {
        'id': 2,
        'name': 'Montre Connectée',
        'category': 'Électronique',
        'tag': 'PROMO',
        'imagePath': 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400&h=400&fit=crop',
        'originalPrice': 80000.0,
        'promoPrice': 55000.0,
        'discount': 31,
        'startDate': now.subtract(const Duration(days: 1)),
        'endDate': now.add(const Duration(days: 7)),
        'stock': 8,
        'description': 'Montre connectée avec suivi fitness',
        'idVendeur': '2',
      },
      {
        'id': 3,
        'name': 'Chaussures Sport',
        'category': 'Mode',
        'tag': 'PROMO',
        'imagePath': 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400&h=400&fit=crop',
        'originalPrice': 45000.0,
        'promoPrice': 30000.0,
        'discount': 33,
        'startDate': now.subtract(const Duration(days: 3)),
        'endDate': now.add(const Duration(days: 4)),
        'stock': 20,
        'description': 'Chaussures de sport confortables',
        'idVendeur': '3',
      },
      {
        'id': 4,
        'name': 'Smartphone',
        'category': 'Électronique',
        'tag': 'PROMO',
        'imagePath': 'https://images.unsplash.com/photo-1560472354-b33ff0c44a43?w=400&h=400&fit=crop',
        'originalPrice': 250000.0,
        'promoPrice': 200000.0,
        'discount': 20,
        'startDate': now.subtract(const Duration(days: 5)),
        'endDate': now.add(const Duration(days: 10)),
        'stock': 5,
        'description': 'Smartphone dernière génération',
        'idVendeur': '4',
      },
      {
        'id': 5,
        'name': 'Sac à Dos',
        'category': 'Mode',
        'tag': 'PROMO',
        'imagePath': 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=400&h=400&fit=crop',
        'originalPrice': 30000.0,
        'promoPrice': 20000.0,
        'discount': 33,
        'startDate': now.subtract(const Duration(days: 1)),
        'endDate': now.add(const Duration(days: 6)),
        'stock': 12,
        'description': 'Sac à dos résistant et élégant',
        'idVendeur': '5',
      },
      {
        'id': 6,
        'name': 'Écouteurs Bluetooth',
        'category': 'Électronique',
        'tag': 'PROMO',
        'imagePath': 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400&h=400&fit=crop',
        'originalPrice': 25000.0,
        'promoPrice': 18000.0,
        'discount': 28,
        'startDate': now.subtract(const Duration(days: 2)),
        'endDate': now.add(const Duration(days: 8)),
        'stock': 25,
        'description': 'Écouteurs sans fil haute qualité',
        'idVendeur': '6',
      },
      {
        'id': 7,
        'name': 'Vêtement Sport',
        'category': 'Mode',
        'tag': 'PROMO',
        'imagePath': 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400&h=400&fit=crop',
        'originalPrice': 35000.0,
        'promoPrice': 25000.0,
        'discount': 29,
        'startDate': now.subtract(const Duration(days: 4)),
        'endDate': now.add(const Duration(days: 3)),
        'stock': 18,
        'description': 'Vêtement de sport respirant',
        'idVendeur': '7',
      },
      {
        'id': 8,
        'name': 'Tablette',
        'category': 'Électronique',
        'tag': 'PROMO',
        'imagePath': 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400&h=400&fit=crop',
        'originalPrice': 150000.0,
        'promoPrice': 120000.0,
        'discount': 20,
        'startDate': now.subtract(const Duration(days: 6)),
        'endDate': now.add(const Duration(days: 9)),
        'stock': 7,
        'description': 'Tablette 10 pouces haute performance',
        'idVendeur': '8',
      },
      {
        'id': 9,
        'name': 'Accessoire Mode',
        'category': 'Mode',
        'tag': 'PROMO',
        'imagePath': 'https://images.unsplash.com/photo-1560472354-b33ff0c44a43?w=400&h=400&fit=crop',
        'originalPrice': 20000.0,
        'promoPrice': 14000.0,
        'discount': 30,
        'startDate': now.subtract(const Duration(days: 3)),
        'endDate': now.add(const Duration(days: 5)),
        'stock': 30,
        'description': 'Accessoire mode tendance',
        'idVendeur': '9',
      },
      {
        'id': 10,
        'name': 'Gadget Électronique',
        'category': 'Électronique',
        'tag': 'PROMO',
        'imagePath': 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400&h=400&fit=crop',
        'originalPrice': 60000.0,
        'promoPrice': 42000.0,
        'discount': 30,
        'startDate': now.subtract(const Duration(days: 2)),
        'endDate': now.add(const Duration(days: 6)),
        'stock': 14,
        'description': 'Gadget électronique innovant',
        'idVendeur': '10',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: PromotionService().getPromotions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: Text(
                    'Produits en promo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 180,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: 3,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      return Container(
                        width: 140,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
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
          final promoProducts = _getValidPromoProducts();
          if (promoProducts.isEmpty) {
            return const SizedBox.shrink();
          }
          return _buildPromoList(context, promoProducts);
        }

        final promotions = snapshot.data!['promotions'] as List<Promotion>;
        final activePromos = promotions.where((p) => p.isActive).toList();

        if (activePromos.isEmpty) {
          return const SizedBox.shrink();
        }

        return _buildPromoListFromPromotions(context, activePromos);
      },
    );
  }

  /// Filtre les produits en promo valides (date actuelle entre startDate et endDate)
  List<Map<String, dynamic>> _getValidPromoProducts() {
    final now = DateTime.now();
    return _getPromoProducts().where((product) {
      final startDate = product['startDate'] as DateTime;
      final endDate = product['endDate'] as DateTime;
      return now.isAfter(startDate.subtract(const Duration(days: 1))) &&
          now.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  /// Construit la liste avec les données statiques (fallback)
  Widget _buildPromoList(BuildContext context, List<Map<String, dynamic>> promoProducts) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 16),
                child: Text(
                  'Produits en promo',
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
                      builder: (context) => const ClientPromoProductsScreen(),
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
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: promoProducts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final product = promoProducts[index];
                return _buildPromoProductCard(context, product);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Construit la liste avec les promotions dynamiques depuis l'API
  Widget _buildPromoListFromPromotions(BuildContext context, List<Promotion> promotions) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 16),
                child: Text(
                  'Produits en promo',
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
                      builder: (context) => const ClientPromoProductsScreen(),
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
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: promotions.length > 10 ? 10 : promotions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final promotion = promotions[index];
                return _buildPromoProductCardFromPromotion(context, promotion);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Construit une carte de produit en promo
  Widget _buildPromoProductCard(
    BuildContext context,
    Map<String, dynamic> product,
  ) {
    final id = product['id'] as int;
    final name = product['name'] as String;
    final category = product['category'] as String;
    final tag = product['tag'] as String;
    final imagePath = product['imagePath'] as String;
    final originalPrice = product['originalPrice'] as double;
    final promoPrice = product['promoPrice'] as double;
    final discount = product['discount'] as int;
    final startDate = product['startDate'] as DateTime;
    final endDate = product['endDate'] as DateTime;
    final stock = product['stock'] as int;
    final description = product['description'] as String;
    final idVendeur = product['idVendeur'] as String;

    final dateFormat = DateFormat('dd/MM/yyyy');

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
              stock: stock,
              name: name,
              price: promoPrice, // Utiliser le prix promo
              imagePath: imagePath,
            ),
          ),
        );
      },
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image avec badge promo
            Stack(
              children: [
                Hero(
                  tag: 'promo_product_${id}_${imagePath}',
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                    child: Image.network(
                      imagePath,
                      height: 90,
                      width: 140,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 90,
                          width: 140,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.image, color: Colors.grey, size: 20),
                        );
                      },
                    ),
                  ),
                ),
                // Badge promo en haut à droite
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      '-$discount%',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                // Tag catégorie en haut à gauche
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.buttonColor2,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        fontSize: 8,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Informations du produit
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom du produit
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Période de validité
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 9,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Prix
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Prix promo
                      Flexible(
                        child: Text(
                          '${promoPrice.toStringAsFixed(0)} FC',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 3),
                      // Prix original barré
                      Flexible(
                        child: Text(
                          '${originalPrice.toStringAsFixed(0)} FC',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey.shade500,
                            decoration: TextDecoration.lineThrough,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit une carte de produit en promo depuis un objet Promotion
  Widget _buildPromoProductCardFromPromotion(
    BuildContext context,
    Promotion promotion,
  ) {
    final product = promotion.product;
    if (product == null) {
      return const SizedBox.shrink();
    }

    final discount = promotion.discountPercentage.round();
    final dateFormat = DateFormat('dd/MM/yyyy');
    final imageUrl = promotion.image.isNotEmpty 
        ? promotion.image 
        : (product.media != null && product.media!.mediaUrl.isNotEmpty
            ? product.media!.mediaUrl
            : 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400&h=400&fit=crop');

    return GestureDetector(
      onTap: () {
        // Utiliser les images de la promotion si disponibles
        final productImages = promotion.getAllImages();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              description: product.description,
              idVendeur: product.vendeurId.toString(),
              id: product.id,
              tag: 'PROMO',
              category: product.category?.name ?? '',
              stock: product.stock,
              name: product.name,
              price: promotion.nouveauPrix,
              imagePath: imageUrl,
              productImages: productImages.length > 1 ? productImages : null,
            ),
          ),
        );
      },
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image avec badge promo
            Stack(
              children: [
                Hero(
                  tag: 'promo_product_${promotion.id}_${imageUrl}',
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                    child: Image.network(
                      imageUrl,
                      height: 90,
                      width: 140,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 90,
                          width: 140,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.image, color: Colors.grey, size: 20),
                        );
                      },
                    ),
                  ),
                ),
                // Badge promo en haut à droite
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      '-$discount%',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                // Tag catégorie en haut à gauche
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.buttonColor2,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      promotion.libelle.isNotEmpty ? promotion.libelle : 'PROMO',
                      style: const TextStyle(
                        fontSize: 8,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            // Informations du produit
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom du produit
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Période de validité
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 9,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          'Jusqu\'au ${dateFormat.format(promotion.delaiPromotion)}',
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Prix
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Prix promo
                      Flexible(
                        child: Text(
                          '${promotion.nouveauPrix.toStringAsFixed(0)} FC',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 3),
                      // Prix original barré
                      Flexible(
                        child: Text(
                          '${promotion.ancienPrix.toStringAsFixed(0)} FC',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey.shade500,
                            decoration: TextDecoration.lineThrough,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:immo/constants.dart';
import 'package:immo/screens/product/product_detail_screen.dart';
import 'package:intl/intl.dart';

/// Widget réutilisable pour afficher la section "Produits en promo"
class PromoProductsSection extends StatelessWidget {
  const PromoProductsSection({Key? key}) : super(key: key);

  /// Retourne une liste statique de 10 produits en promo
  /// TODO: Remplacer par des données du backend
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

  @override
  Widget build(BuildContext context) {
    final promoProducts = _getValidPromoProducts();

    if (promoProducts.isEmpty) {
      return const SizedBox.shrink();
    }

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
                  // TODO: Naviguer vers une page listant tous les produits en promo
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
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: promoProducts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
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
        width: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
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
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: Image.network(
                      imagePath,
                      height: 110,
                      width: 160,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 110,
                          width: 160,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.image, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                ),
                // Badge promo en haut à droite
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '-$discount%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                // Tag catégorie en haut à gauche
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.buttonColor2,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        fontSize: 9,
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
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom du produit
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Période de validité
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 10,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Prix
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Prix promo
                      Flexible(
                        child: Text(
                          '${promoPrice.toStringAsFixed(0)} FC',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Prix original barré
                      Flexible(
                        child: Text(
                          '${originalPrice.toStringAsFixed(0)} FC',
                          style: TextStyle(
                            fontSize: 10,
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


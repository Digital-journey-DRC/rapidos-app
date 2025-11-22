import 'package:flutter/material.dart';
import 'package:immo/constants.dart';
import 'package:immo/widgets/app_logo.dart';
import 'package:immo/models/merchant_product.dart';
import 'package:immo/screens/product/product_detail_screen.dart';
import 'package:immo/widgets/merchant_closed_banner.dart';

class MerchantRecommendedProductsScreen extends StatefulWidget {
  const MerchantRecommendedProductsScreen({Key? key}) : super(key: key);

  @override
  State<MerchantRecommendedProductsScreen> createState() => _MerchantRecommendedProductsScreenState();
}

class _MerchantRecommendedProductsScreenState extends State<MerchantRecommendedProductsScreen> {
  String _search = '';
  List<MerchantProduct> _products = MerchantProduct.getRecommendedProducts();

  @override
  Widget build(BuildContext context) {
    final filtered = _products.where((p) =>
      p.name.toLowerCase().contains(_search.toLowerCase()) ||
      p.description.toLowerCase().contains(_search.toLowerCase()) ||
      p.category.toLowerCase().contains(_search.toLowerCase())
    ).toList();

    return Scaffold(
      appBar: AppBarWithLogo(
        title: 'Produits recommandés',
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Ouvrir le formulaire d'ajout de produit
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fonctionnalité d\'ajout de produit à venir'),
              backgroundColor: AppColors.primary,
            ),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Ajouter un produit recommandé',
      ),
      backgroundColor: const Color(0xFFF7F8FA),
      body: Column(
        children: [
          const MerchantClosedBanner(),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher un produit...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (val) => setState(() => _search = val),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star_outline, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun produit recommandé',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ajoutez des produits recommandés pour les voir ici',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(12.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final product = filtered[index];
                      return _RecommendedProductCard(product: product);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _RecommendedProductCard extends StatelessWidget {
  final MerchantProduct product;
  const _RecommendedProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              description: product.description,
              idVendeur: '1',
              id: product.id,
              tag: product.category,
              stock: product.stock,
              category: product.category,
              name: product.name,
              price: product.price,
              imagePath: product.imageUrl,
            ),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 1,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Stack(
                children: [
                  Image.network(
                    product.imageUrl,
                    width: double.infinity,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: double.infinity,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.star,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                  if (product.isPromo)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'PROMO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            product.category,
                            style: const TextStyle(color: Colors.white, fontSize: 9),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.star, color: Colors.amber, size: 14),
                      Text(
                        '${product.rating}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (product.isPromo && product.promoPrice != null) ...[
                        Text(
                          '${product.promoPrice} FC',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${product.price} FC',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ] else
                        Text(
                          '${product.price} FC',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Stock: ${product.stock}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                    ),
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


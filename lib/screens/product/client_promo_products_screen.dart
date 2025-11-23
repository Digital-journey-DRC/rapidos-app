import 'package:flutter/material.dart';
import 'package:immo/constants.dart';
import 'package:immo/widgets/app_logo.dart';
import 'package:immo/services/promotion_service.dart';
import 'package:immo/models/promotion.dart';
import 'package:immo/screens/product/product_detail_screen.dart';

/// Écran pour afficher toutes les promotions côté client
class ClientPromoProductsScreen extends StatefulWidget {
  const ClientPromoProductsScreen({Key? key}) : super(key: key);

  @override
  State<ClientPromoProductsScreen> createState() => _ClientPromoProductsScreenState();
}

class _ClientPromoProductsScreenState extends State<ClientPromoProductsScreen> {
  String _search = '';
  List<Promotion> _promotions = [];
  bool _isLoading = true;
  final PromotionService _promotionService = PromotionService();

  @override
  void initState() {
    super.initState();
    _loadPromotions();
  }

  Future<void> _loadPromotions() async {
    setState(() => _isLoading = true);
    try {
      final result = await _promotionService.getPromotions();
      if (result['success'] == true) {
        setState(() {
          _promotions = result['promotions'] as List<Promotion>;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${result['error']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _promotions.where((promo) {
      if (!promo.isActive) return false;
      final product = promo.product;
      if (product == null) return false;
      final searchLower = _search.toLowerCase();
      return product.name.toLowerCase().contains(searchLower) ||
          promo.libelle.toLowerCase().contains(searchLower) ||
          (product.category?.name ?? '').toLowerCase().contains(searchLower);
    }).toList();

    return Scaffold(
      appBar: AppBarWithLogo(
        title: 'Tous les produits en promo',
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF7F8FA),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher une promotion...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (val) => setState(() => _search = val),
            ),
          ),
          // Liste des promotions
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune promotion disponible',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Aucune promotion active pour le moment',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadPromotions,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12.0),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final promotion = filtered[index];
                            return _PromoProductCard(promotion: promotion);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _PromoProductCard extends StatelessWidget {
  final Promotion promotion;

  const _PromoProductCard({required this.promotion});

  double _calculateRating() {
    double rating = 4.0;
    if (promotion.likes > 10) rating += 0.5;
    if (promotion.discountPercentage > 20) rating += 0.3;
    if ((promotion.product?.stock ?? 0) > 30) rating += 0.2;
    return rating.clamp(3.5, 5.0);
  }

  @override
  Widget build(BuildContext context) {
    final product = promotion.product;
    if (product == null) return const SizedBox.shrink();

    final productName = product.name;
    final productCategory = product.category?.name ?? '';
    final productStock = product.stock;

    final imageUrl = promotion.image.isNotEmpty
        ? promotion.image
        : (product.media != null && product.media!.mediaUrl.isNotEmpty
            ? product.media!.mediaUrl
            : 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400&h=400&fit=crop');

    return GestureDetector(
      onTap: () {
        final List<String> productImages = [promotion.image];
        productImages.addAll(promotion.images.where((img) => img.isNotEmpty));

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              description: product.description,
              idVendeur: product.vendeurId.toString(),
              id: product.id,
              tag: 'PROMO',
              category: productCategory,
              stock: productStock,
              name: productName,
              price: promotion.nouveauPrix,
              imagePath: imageUrl,
              productImages: productImages.length > 1 ? productImages : null,
              product: product, // Passer le produit complet avec les infos du vendeur
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 1,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: Stack(
                children: [
                  Image.network(
                    imageUrl,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 30),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '-${promotion.discountPercentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
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
            // Détails
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Catégorie et rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              productCategory.isNotEmpty ? productCategory : 'Promotion',
                              style: const TextStyle(color: Colors.white, fontSize: 9),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.star, color: AppColors.primary, size: 14),
                            Text(
                              _calculateRating().toStringAsFixed(1),
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Nom du produit
                    Text(
                      productName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Libellé de la promotion
                    if (promotion.libelle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        promotion.libelle,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    // Prix
                    Row(
                      children: [
                        Text(
                          '${promotion.nouveauPrix.toStringAsFixed(0)} FC',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${promotion.ancienPrix.toStringAsFixed(0)} FC',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Stock
                    Row(
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 12, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          'Stock: $productStock',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),
                      ],
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


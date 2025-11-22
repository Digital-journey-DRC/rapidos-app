import 'package:flutter/material.dart';
import 'package:immo/constants.dart';
import 'package:immo/widgets/app_logo.dart';
import 'package:immo/models/promotion.dart';
import 'package:immo/screens/product/product_detail_screen.dart';
import 'package:immo/screens/product/create_promotion_screen.dart';
import 'package:immo/widgets/merchant_closed_banner.dart';
import 'package:immo/services/promotion_service.dart';

class MerchantPromoProductsScreen extends StatefulWidget {
  const MerchantPromoProductsScreen({Key? key}) : super(key: key);

  @override
  State<MerchantPromoProductsScreen> createState() => _MerchantPromoProductsScreenState();
}

class _MerchantPromoProductsScreenState extends State<MerchantPromoProductsScreen> {
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
      final productName = promo.product?.name ?? '';
      final libelle = promo.libelle.toLowerCase();
      final searchLower = _search.toLowerCase();
      return productName.toLowerCase().contains(searchLower) ||
          libelle.contains(searchLower);
    }).toList();

    return Scaffold(
      appBar: AppBarWithLogo(
        title: 'Produits en promotions',
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreatePromotionScreen(),
            ),
          ).then((success) {
            if (success == true) {
              // Rafraîchir la liste
              _loadPromotions();
            }
          });
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Ajouter une promotion',
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
            child: RefreshIndicator(
              onRefresh: _loadPromotions,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.5,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey.shade400),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Aucun produit en promotion',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Ajoutez des produits en promotion pour les voir ici',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
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

  /// Calcule un rating dynamique basé sur les likes et le produit
  double _calculateRating() {
    double rating = 4.0;
    
    // Bonus basé sur les likes
    if (promotion.likes > 50) {
      rating += 0.5;
    } else if (promotion.likes > 20) {
      rating += 0.3;
    } else if (promotion.likes > 10) {
      rating += 0.2;
    } else if (promotion.likes > 0) {
      rating += 0.1;
    }
    
    // Bonus basé sur le pourcentage de réduction (plus de réduction = meilleur)
    final discount = promotion.discountPercentage;
    if (discount > 50) {
      rating += 0.3;
    } else if (discount > 30) {
      rating += 0.2;
    } else if (discount > 15) {
      rating += 0.1;
    }
    
    // Bonus basé sur le stock du produit
    final product = promotion.product;
    if (product != null) {
      if (product.stock > 50) {
        rating += 0.2;
      } else if (product.stock > 20) {
        rating += 0.1;
      }
    }
    
    // Limiter entre 3.5 et 5.0
    return rating.clamp(3.5, 5.0);
  }

  @override
  Widget build(BuildContext context) {
    final product = promotion.product;
    final productName = product?.name ?? 'Produit';
    final productDescription = product?.description ?? '';
    final productCategory = product?.category?.name ?? '';
    final productStock = product?.stock ?? 0;
    final productId = product?.id ?? promotion.productId;
    final vendeurId = product?.vendeurId.toString() ?? '';

    return GestureDetector(
      onTap: () {
        if (product != null) {
          // Préparer la liste des images (image principale + images secondaires)
          final List<String> productImages = [promotion.image];
          if (promotion.image1 != null && promotion.image1!.isNotEmpty) {
            productImages.add(promotion.image1!);
          }
          if (promotion.image2 != null && promotion.image2!.isNotEmpty) {
            productImages.add(promotion.image2!);
          }
          if (promotion.image3 != null && promotion.image3!.isNotEmpty) {
            productImages.add(promotion.image3!);
          }
          if (promotion.image4 != null && promotion.image4!.isNotEmpty) {
            productImages.add(promotion.image4!);
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(
                description: productDescription,
                idVendeur: vendeurId,
                id: productId,
                tag: productCategory,
                stock: productStock,
                category: productCategory,
                name: productName,
                price: promotion.nouveauPrix,
                imagePath: promotion.image,
                productImages: productImages,
              ),
            ),
          );
        }
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
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
                    promotion.image,
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
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
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
                            productCategory.isNotEmpty ? productCategory : 'Promotion',
                            style: const TextStyle(color: Colors.white, fontSize: 9),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.star, color: Colors.amber, size: 14),
                      Text(
                        _calculateRating().toStringAsFixed(1),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    productName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (promotion.libelle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      promotion.libelle,
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '${promotion.nouveauPrix.toStringAsFixed(0)} FC',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${promotion.ancienPrix.toStringAsFixed(0)} FC',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  if (productStock > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Stock: $productStock',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


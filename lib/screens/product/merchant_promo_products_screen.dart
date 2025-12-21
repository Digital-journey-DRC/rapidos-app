import 'package:flutter/material.dart';
import 'package:immo/constants.dart';
import 'package:immo/widgets/app_logo.dart';
import 'package:immo/models/promotion.dart';
import 'package:immo/screens/product/create_promotion_screen.dart';
import 'package:immo/screens/product/promotion_detail_screen.dart';
import 'package:immo/services/promotion_service.dart';
import 'package:immo/cubit/auth_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
      // Récupérer l'ID du marchand connecté
      final authState = context.read<AuthCubit>().state;
      int? merchantId;
      
      if (authState is AuthSuccess && authState.user != null) {
        final userId = authState.user!['id'];
        print('🔍 merchant_promo_products_screen - userId brut: $userId (type: ${userId.runtimeType})');
        if (userId != null) {
          if (userId is int) {
            merchantId = userId;
            print('🔍 merchant_promo_products_screen - userId est int: $merchantId');
          } else if (userId is String) {
            merchantId = int.tryParse(userId);
            print('🔍 merchant_promo_products_screen - userId est String, parsé: $merchantId');
          } else if (userId is num) {
            merchantId = userId.toInt();
            print('🔍 merchant_promo_products_screen - userId est num, converti: $merchantId');
          }
        } else {
          print('🔍 merchant_promo_products_screen - userId est null');
        }
      } else {
        print('🔍 merchant_promo_products_screen - authState n\'est pas AuthSuccess ou user est null');
      }
      
      print('🔍 merchant_promo_products_screen - merchantId final: $merchantId');
      
      // Charger les promotions filtrées par marchand
      final result = merchantId != null 
          ? await _promotionService.getMerchantPromotions(merchantId)
          : await _promotionService.getPromotions();
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
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
         // cons MerchantClosedBanner(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher un produit...',
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                'Aucun produit en promotion',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
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
                        )
                      : GridView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.only(
                      left: 8.0,
                      right: 8.0,
                      top: 4.0,
                      bottom: MediaQuery.of(context).padding.bottom + 20,
                    ),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.68,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final promotion = filtered[index];
                      return _PromoProductCard(
                        promotion: promotion,
                        onEdit: () => _loadPromotions(),
                        onDelete: () => _loadPromotions(),
                      );
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
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _PromoProductCard({
    required this.promotion,
    required this.onEdit,
    required this.onDelete,
  });

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
    final productCategory = product?.category?.name ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PromotionDetailScreen(
              promotion: promotion,
            ),
          ),
        ).then((success) {
          if (success == true) {
            // Rafraîchir la liste si une modification/suppression a été effectuée
            onEdit();
          }
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 0.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image du produit
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      color: Colors.grey.shade50,
                      child: Image.network(
                        promotion.image,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: double.infinity,
                          color: Colors.grey.shade100,
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey.shade400,
                            size: 32,
                          ),
                        ),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey.shade100,
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'PROMO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '-${promotion.discountPercentage.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Contenu de la carte
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Catégorie
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        productCategory.isNotEmpty ? productCategory : 'Promotion',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Nom du produit
                    Text(
                      productName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        height: 1.2,
                        color: Color(0xFF1A1A1A),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Prix et note
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${promotion.nouveauPrix.toStringAsFixed(0)} FC',
                              style: const TextStyle(
                                color: Color(0xFF147C3C),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${promotion.ancienPrix.toStringAsFixed(0)} FC',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 10,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 11,
                              color: Colors.amber.shade700,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              _calculateRating().toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
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


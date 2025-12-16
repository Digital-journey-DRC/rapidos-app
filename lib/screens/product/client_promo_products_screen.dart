import 'package:flutter/material.dart';
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
      backgroundColor: const Color(0xFFF7F8FA),
      body: RefreshIndicator(
        onRefresh: _loadPromotions,
        child: CustomScrollView(
          slivers: [
          // Header compact et professionnel
          SliverAppBar(
            floating: true,
            pinned: true,
            snap: false,
            elevation: 0,
            backgroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 18, color: Color(0xFF1A1A1A)),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Promotions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
                letterSpacing: -0.5,
              ),
            ),
            centerTitle: false,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(0),
              child: Container(
                height: 1,
                color: Colors.grey.shade200,
              ),
            ),
          ),
          // Barre de recherche intégrée
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200, width: 1),
                ),
                child: TextField(
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Rechercher une promotion...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 15,
                    ),
                    prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey.shade400),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (val) => setState(() => _search = val),
                ),
              ),
            ),
          ),
          // Liste des promotions
          _isLoading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              : filtered.isEmpty
                  ? SliverFillRemaining(
                      child: Center(
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
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final promotion = filtered[index];
                            return _PromoProductCard(promotion: promotion);
                          },
                          childCount: filtered.length,
                        ),
                      ),
                    ),
          ],
        ),
      ),
    );
  }
}

class _PromoProductCard extends StatelessWidget {
  final Promotion promotion;

  const _PromoProductCard({required this.promotion});

  @override
  Widget build(BuildContext context) {
    final product = promotion.product;
    if (product == null) return const SizedBox.shrink();

    final productName = product.name;
    final productCategory = product.category?.name ?? '';
    final productStock = product.stock;

    // Priorité: image de la promotion, sinon getMainImage() du produit
    final imageUrl = promotion.image.isNotEmpty
        ? promotion.image
        : product.getMainImage();

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
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image - Plus grande et mise en avant
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: Stack(
                children: [
                  Image.network(
                    imageUrl,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 120,
                      height: 120,
                      color: Colors.grey.shade100,
                      child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 30),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '-${promotion.discountPercentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Détails - Design moderne et épuré
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Catégorie discrète
                        if (productCategory.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              productCategory,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (productCategory.isNotEmpty) const SizedBox(height: 8),
                        // Nom du produit - Plus visible
                        Text(
                          productName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Color(0xFF1A1A1A),
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Libellé de la promotion
                        if (promotion.libelle.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            promotion.libelle,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Prix et infos en bas
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Prix - Mise en avant
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${promotion.nouveauPrix.toStringAsFixed(0)} FC',
                              style: const TextStyle(
                                color: Color(0xFF1A1A1A),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${promotion.ancienPrix.toStringAsFixed(0)} FC',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 12,
                                decoration: TextDecoration.lineThrough,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Stock discret
                        Row(
                          children: [
                            Icon(Icons.check_circle_outline, size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(
                              '$productStock disponibles',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
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





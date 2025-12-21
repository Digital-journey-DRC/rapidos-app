import 'package:flutter/material.dart';
import 'package:immo/constants.dart';
import 'package:immo/widgets/app_logo.dart';
import 'package:immo/models/product.dart';
import 'package:immo/screens/product/product_detail_screen.dart';
// import 'package:immo/widgets/merchant_closed_banner.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:immo/cubit/product_cubit.dart';
import 'package:immo/screens/product/add_product_screen.dart';

class MerchantAllProductsScreen extends StatefulWidget {
  const MerchantAllProductsScreen({Key? key}) : super(key: key);

  @override
  State<MerchantAllProductsScreen> createState() => _MerchantAllProductsScreenState();
}

class _MerchantAllProductsScreenState extends State<MerchantAllProductsScreen> {
  String _search = '';

  @override
  void initState() {
    super.initState();
    // Charger les produits au démarrage
    context.read<ProductCubit>().fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWithLogo(
        title: 'Tous les produits',
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddProductScreen(),
            ),
          ).then((success) {
            if (success == true && mounted) {
              // Rafraîchir la liste des produits
              context.read<ProductCubit>().fetchProducts();
            }
          });
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Ajouter un produit',
      ),
      backgroundColor: const Color(0xFFF7F8FA),
      body: Column(
        children: [
          // const MerchantClosedBanner(),
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
            child: BlocBuilder<ProductCubit, ProductState>(
              builder: (context, state) {
                if (state is ProductLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is ProductError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          state.message == 'Pas de produits trouvés' 
                              ? 'Aucun produit pour l\'instant'
                              : 'Erreur lors du chargement',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            context.read<ProductCubit>().fetchProducts();
                          },
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is ProductLoaded) {
                  final filtered = state.products.where((p) =>
                    p.name.toLowerCase().contains(_search.toLowerCase()) ||
                    p.description.toLowerCase().contains(_search.toLowerCase()) ||
                    (p.category?.name ?? '').toLowerCase().contains(_search.toLowerCase())
                  ).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _search.isEmpty ? Icons.inbox : Icons.search_off,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _search.isEmpty
                                ? 'Aucun produit pour l\'instant'
                                : 'Aucun produit trouvé',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_search.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Essayez avec d\'autres mots-clés',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      await context.read<ProductCubit>().fetchProducts();
                    },
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.only(
                        left: 12.0,
                        right: 12.0,
                        top: 12.0,
                        bottom: MediaQuery.of(context).padding.bottom + 20,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final product = filtered[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ProductCard(product: product),
                        );
                      },
                    ),
                  );
                }

                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  /// Calcule un rating dynamique basé sur le stock et d'autres critères
  double _calculateRating() {
    // Rating de base
    double rating = 4.0;
    
    // Bonus basé sur le stock (plus de stock = meilleur rating)
    if (product.stock > 50) {
      rating += 0.5;
    } else if (product.stock > 20) {
      rating += 0.3;
    } else if (product.stock > 10) {
      rating += 0.1;
    }
    
    // Bonus basé sur le prix (produits à prix raisonnable)
    if (product.price > 0 && product.price < 50000) {
      rating += 0.2;
    }
    
    // Limiter entre 3.5 et 5.0
    return rating.clamp(3.5, 5.0);
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.getMainImage();
    final productImages = product.getAllImages();
    final categoryName = product.category?.name ?? '';
    final vendeurId = product.vendeurId.toString();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              description: product.description,
              idVendeur: vendeurId,
              id: product.id,
              tag: categoryName,
              stock: product.stock,
              category: categoryName,
              name: product.name,
              price: product.price,
              imagePath: imageUrl,
              productImages: productImages.isNotEmpty ? productImages : null,
              product: product, // Passer le produit complet avec toutes les infos
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.zero,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Image du produit
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                bottomLeft: Radius.circular(10),
              ),
              child: Stack(
                children: [
                  Image.network(
                    imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    cacheWidth: 160,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                      ),
                      child: Icon(Icons.image_not_supported, color: Colors.grey.shade400, size: 24),
                    ),
                  ),
                  if (categoryName.isNotEmpty)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          categoryName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Informations du produit
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Colors.black87,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, color: Colors.amber.shade700, size: 12),
                              const SizedBox(width: 2),
                              Text(
                                _calculateRating().toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.amber.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '${product.price.toStringAsFixed(0)} FC',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: Colors.blue.shade100, width: 0.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inventory_2, size: 12, color: Colors.blue.shade700),
                              const SizedBox(width: 3),
                              Text(
                                '${product.stock}',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
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


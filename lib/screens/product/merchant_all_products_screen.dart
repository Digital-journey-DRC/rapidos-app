import 'package:flutter/material.dart';
import 'package:immo/constants.dart';
import 'package:immo/widgets/app_logo.dart';
import 'package:immo/models/product.dart';
import 'package:immo/screens/product/product_detail_screen.dart';
import 'package:immo/widgets/merchant_closed_banner.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:immo/cubit/product_cubit.dart';

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
        tooltip: 'Ajouter un produit',
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
                    child: GridView.builder(
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
                        return _ProductCard(product: product);
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
    final imageUrl = product.media?.mediaUrl ?? 
        'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400&h=400&fit=crop';
    final categoryName = product.category?.name ?? '';
    final vendeurId = product.vendeurId.toString();

    return GestureDetector(
      onTap: () {
        // Passer l'image principale dans productImages
        // La logique dans ProductDetailScreen complétera avec l'image principale si nécessaire
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
              productImages: [imageUrl], // Image principale, sera complétée automatiquement
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
                    imageUrl,
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
                  if (categoryName.isNotEmpty)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          categoryName,
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
                  if (categoryName.isNotEmpty)
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
                              categoryName,
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
                  if (categoryName.isNotEmpty) const SizedBox(height: 6),
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product.price.toStringAsFixed(0)} FC',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
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


import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:immo/constants.dart';
import 'package:immo/cubit/favorites_cubit.dart';
import 'package:immo/screens/product/product_detail_screen.dart';
import 'package:immo/widgets/app_logo.dart';
import 'package:immo/services/review_service.dart';

class FavorisScreen extends StatelessWidget {
  const FavorisScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBarWithLogo(
        title: 'Mes Favoris',
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocBuilder<FavoritesCubit, FavoritesState>(
        builder: (context, state) {
          if (state is FavoritesInitial) {
            context.read<FavoritesCubit>().loadFavorites();
            return const Center(child: CircularProgressIndicator());
          }
          if (state is FavoritesLoaded) {
            final favoris = state.favorites;
            if (favoris.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite_border, size: 80, color: AppColors.primary.withOpacity(0.5)),
                    const SizedBox(height: 24),
                    const Text('Aucun produit favori', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                context.read<FavoritesCubit>().loadFavorites();
              },
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(
                  left: 12,
                  right: 12,
                  top: 8,
                  bottom: MediaQuery.of(context).padding.bottom + 20,
                ),
                itemCount: favoris.length,
                itemBuilder: (context, index) {
                final product = favoris[index];
                // Gérer le nouveau format (image) et l'ancien format (media.mediaUrl)
                String imageUrl = 'https://images.unsplash.com/photo-1556912172-45b7abe8b7e4?w=200&h=200&fit=crop';
                if (product['image'] != null && product['image'].toString().isNotEmpty) {
                  imageUrl = product['image'].toString();
                } else if (product['media'] != null && product['media'] is Map) {
                  final media = product['media'] as Map<String, dynamic>;
                  if (media['mediaUrl'] != null && media['mediaUrl'].toString().isNotEmpty) {
                    imageUrl = media['mediaUrl'].toString();
                  }
                }
                final productId = product['id'] is int ? product['id'] : int.tryParse(product['id']?.toString() ?? '');
                return InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailScreen(
                          description: product['description']??'',
                          idVendeur: product['vendeurId']?.toString() ?? '',
                          id: productId ?? 0,
                          tag: 'Favori',
                          stock: product['stock']??0,
                          category: product['category'] ?? '',
                          name: product['name']??"",
                          price: (product['price'] is double) ? product['price'] : (product['price'] is int ? (product['price'] as int).toDouble() : 0.0),
                          imagePath: imageUrl,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.grey.shade200,
                        width: 0.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          // Image produit
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 70,
                              height: 70,
                              color: Colors.grey.shade50,
                              child: Image.network(
                                imageUrl,
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.shopping_bag_outlined,
                                      color: Colors.grey.shade400,
                                      size: 32,
                                    ),
                                  );
                                },
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    width: 70,
                                    height: 70,
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
                          ),
                          const SizedBox(width: 10),
                          // Détails produit
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Catégorie
                                if (product['category'] != null && product['category'].toString().isNotEmpty)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      product['category'] ?? '',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                // Nom du produit
                                Text(
                                  product['name'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    height: 1.2,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                // Prix et note
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${(product['price'] is double ? product['price'] : (product['price'] is int ? (product['price'] as int).toDouble() : 0.0)).toStringAsFixed(0)} FC',
                                      style: const TextStyle(
                                        color: Color(0xFF147C3C),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (productId != null)
                                      FutureBuilder<double>(
                                        future: ReviewService().getCachedAverageRating(productId),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasData && snapshot.data! > 0) {
                                            final rating = snapshot.data!;
                                            return Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.star_rounded,
                                                  size: 11,
                                                  color: Colors.amber.shade700,
                                                ),
                                                const SizedBox(width: 2),
                                                Text(
                                                  rating.toStringAsFixed(1),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            );
                                          }
                                          return const SizedBox.shrink();
                                        },
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Bouton supprimer (coeur)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.2),
                                width: 0.5,
                              ),
                            ),
                            child: InkWell(
                              onTap: () {
                                context.read<FavoritesCubit>().toggleFavorite(product);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Retiré des favoris'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                              child: const Icon(
                                Icons.favorite,
                                color: Colors.red,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
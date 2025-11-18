import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:immo/constants.dart';
import 'package:immo/cubit/favorites_cubit.dart';
import 'package:immo/screens/product/product_detail_screen.dart';
import 'package:immo/widgets/app_logo.dart';

class FavorisScreen extends StatelessWidget {
  const FavorisScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: favoris.length,
              itemBuilder: (context, index) {
                final product = favoris[index];
                final hasImage = product['media'] != null && product['media']['mediaUrl'] != null && product['media']['mediaUrl'].toString().isNotEmpty;
                final imageUrl = hasImage
                  ? product['media']['mediaUrl']
                  : 'https://via.placeholder.com/80';
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    print(product['idVendeur']);
                    print(product);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailScreen(
                          description: product['description']??'',
                          idVendeur: product['vendeurId']??'',
                          id: product['id']??'',
                          tag: 'Favori',
                          stock: product['stock']??0,
                          category: product['category'] ?? '',
                          name: product['name']??"",
                          price: product['price'],
                          imagePath: imageUrl,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          // Image produit
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.image, color: Colors.grey),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Détails produit
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product['name'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                // const SizedBox(height: 4),
                                // Text(
                                //   product['category'] ?? '',
                                //   style: TextStyle(
                                //     color: Colors.grey.shade600,
                                //     fontSize: 14,
                                //   ),
                                // ),
                                const SizedBox(height: 8),
                                Text(
                                  '${product['price']} FC',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Bouton supprimer (coeur)
                          IconButton(
                            icon: const Icon(Icons.favorite, color: Colors.red),
                            onPressed: () {
                              context.read<FavoritesCubit>().toggleFavorite(product);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Retiré des favoris')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:immo/constants.dart';
import 'package:immo/widgets/app_logo.dart';
import 'package:immo/cubit/auth_cubit.dart';
import 'package:immo/models/category.dart';
import 'package:immo/models/product.dart';
import 'package:immo/screens/auth/login_screen.dart';
import 'package:immo/screens/product/product_detail_screen.dart';
import 'package:immo/cubit/category_products_cubit.dart';
import 'package:immo/widgets/shimmer_loading.dart';
import 'package:immo/services/review_service.dart';

class CategoryProductsScreen extends StatefulWidget {
  final Category category;
  const CategoryProductsScreen({Key? key, required this.category})
      : super(key: key);

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  String _search = '';

  @override
  void initState() {
    super.initState();
    context
        .read<CategoryProductsCubit>()
        .fetchProductsByCategory(widget.category.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWithLogo(
        title: widget.category.name,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
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
            child: BlocBuilder<CategoryProductsCubit, CategoryProductsState>(
              builder: (context, state) {
                if (state is CategoryProductsLoading) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<CategoryProductsCubit>().fetchProductsByCategory(widget.category.id);
                    },
                    child: GridView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.only(
                      left: 8.0,
                      right: 8.0,
                      top: 4.0,
                      bottom: MediaQuery.of(context).padding.bottom + 20,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.68,
                    ),
                    itemCount: 6,
                    itemBuilder: (context, index) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 0.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const ShimmerLoading(
                              width: double.infinity,
                              height: 120,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ShimmerLoading(
                                      width: 60,
                                      height: 10,
                                      borderRadius: BorderRadius.circular(4)),
                                  const SizedBox(height: 6),
                                  ShimmerLoading(
                                      width: double.infinity,
                                      height: 12,
                                      borderRadius: BorderRadius.circular(4)),
                                  const SizedBox(height: 4),
                                  ShimmerLoading(
                                      width: 70,
                                      height: 12,
                                      borderRadius: BorderRadius.circular(4)),
                                  const SizedBox(height: 4),
                                  ShimmerLoading(
                                      width: 50,
                                      height: 10,
                                      borderRadius: BorderRadius.circular(4)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    ),
                  );
                }

                if (state is CategoryProductsEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<CategoryProductsCubit>().fetchProductsByCategory(widget.category.id);
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Pas de produit pour cette catégorie',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }

                if (state is CategoryProductsError) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<CategoryProductsCubit>().fetchProductsByCategory(widget.category.id);
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline,
                                  size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Text(
                                  state.message,
                                  style: TextStyle(
                                      color: Colors.grey.shade600, fontSize: 14),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton(
                                onPressed: () {
                                  context
                                      .read<CategoryProductsCubit>()
                                      .fetchProductsByCategory(widget.category.id);
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: AppColors.primary),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                                child: Text(
                                  'Réessayer',
                                  style: TextStyle(color: AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }

                if (state is CategoryProductsLoaded) {
                  final filtered = state.products
                      .where((p) =>
                          p.name
                              .toLowerCase()
                              .contains(_search.toLowerCase()) ||
                          p.description
                              .toLowerCase()
                              .contains(_search.toLowerCase()))
                      .toList();

                  if (filtered.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: () async {
                        context.read<CategoryProductsCubit>().fetchProductsByCategory(widget.category.id);
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off,
                                    size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text(
                                  _search.isEmpty
                                      ? 'Aucun produit dans cette catégorie'
                                      : 'Aucun produit trouvé',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<CategoryProductsCubit>().fetchProductsByCategory(widget.category.id);
                    },
                    child: GridView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.only(
                      left: 8.0,
                      right: 8.0,
                      top: 4.0,
                      bottom: MediaQuery.of(context).padding.bottom + 20,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.68,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final product = filtered[index];
                      return _TwitterStyleProductCard(product: product);
                    },
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TwitterStyleProductCard extends StatelessWidget {
  final Product product;
  const _TwitterStyleProductCard({required this.product});

  bool _isAuthorizedUser(BuildContext context) {
    try {
      final authState = context.read<AuthCubit>().state;
      if (authState is AuthSuccess && authState.user != null) {
        final userPhone = authState.user!['phone']?.toString() ?? '';
        print(
            '🔍 Vérification autorisation - Téléphone utilisateur: $userPhone');

        // Si le numéro est +243842613999, l'utilisateur n'est PAS autorisé
        final isAuthorized = userPhone != '+243842613999';
        print('🔍 Utilisateur autorisé: $isAuthorized');

        return isAuthorized;
      }
      print('❌ Utilisateur non connecté');
      return false;
    } catch (e) {
      print('❌ Erreur lors de la vérification d\'autorisation: $e');
      return false;
    }
  }

  void _checkAuthorizationAndRedirect(BuildContext context) {
    if (!_isAuthorizedUser(context)) {
      print('🚫 Utilisateur non autorisé, redirection vers login...');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _checkAuthorizationAndRedirect(context);
        if (_isAuthorizedUser(context)) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(
                description: product.description,
                idVendeur: product.vendeurId.toString(),
                id: product.id,
                tag: product.category?.name ?? '',
                stock: product.stock,
                category: product.category?.name ?? '',
                name: product.name,
                price: product.price,
                imagePath: product.getMainImage(),
                product: product, // Passer le produit complet avec les infos du vendeur
                productImages: product.getAllImages(), // Toutes les images (principale + secondaires)
                goToCartTab: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
            ),
          );
        }
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
                child: Container(
                  width: double.infinity,
                  color: Colors.grey.shade50,
                  child: Image.network(
                    product.getMainImage(),
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: Icon(
                        Icons.shopping_bag_outlined,
                        color: Colors.grey.shade400,
                        size: 40,
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
                        product.category?.name ?? '',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Nom du produit
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Prix et note
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Prix
                        Text(
                          '${product.price} FC',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF147C3C),
                          ),
                        ),
                        // Note
                        FutureBuilder<double>(
                          future: ReviewService().getCachedAverageRating(product.id),
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
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
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
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:immo/widgets/app_logo.dart';
import 'package:immo/models/product.dart';
import 'package:immo/widgets/ecommerce_loading.dart';
import 'package:immo/constants.dart';

class CategoryProductsAllScreen extends StatefulWidget {
  final String categoryName;
  final List<Product>? products;
  final Future<List<Product>>? productsFuture;
  final Widget Function(Product, {double? width}) cardBuilder;

  const CategoryProductsAllScreen({
    Key? key,
    required this.categoryName,
    this.products,
    this.productsFuture,
    required this.cardBuilder,
  }) : super(key: key);

  @override
  State<CategoryProductsAllScreen> createState() => _CategoryProductsAllScreenState();
}

class _CategoryProductsAllScreenState extends State<CategoryProductsAllScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Product>? _cachedProducts;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    // Charger les produits si on a un Future
    if (widget.productsFuture != null && widget.products == null) {
      _loadProducts();
    } else if (widget.products != null) {
      _cachedProducts = widget.products;
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  Future<void> _loadProducts() async {
    if (widget.productsFuture != null) {
      try {
        final products = await widget.productsFuture!;
        if (mounted) {
          setState(() {
            _cachedProducts = products;
          });
        }
      } catch (e) {
        // Erreur silencieuse
      }
    }
  }

  Future<void> _onRefresh() async {
    await _loadProducts();
  }

  List<Product> _getFilteredProducts(List<Product> products) {
    if (_searchQuery.isEmpty) {
      return products;
    }
    return products.where((product) {
      final name = product.name.toLowerCase();
      final description = product.description.toLowerCase();
      final category = product.category?.name.toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return name.contains(query) ||
          description.contains(query) ||
          category.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBarWithLogo(
        title: widget.categoryName,
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Barre de recherche
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un produit...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey.shade400, size: 20),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          // Contenu avec RefreshIndicator
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              color: AppColors.primary,
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    // Si on a des produits en cache, les utiliser
    if (_cachedProducts != null) {
      final filteredProducts = _getFilteredProducts(_cachedProducts!);
      if (filteredProducts.isEmpty) {
        return _buildEmptyState(isSearch: _searchQuery.isNotEmpty);
      }
      return _buildProductsGrid(filteredProducts);
    }

    // Si on a une liste de produits directement, l'utiliser
    if (widget.products != null) {
      final filteredProducts = _getFilteredProducts(widget.products!);
      if (filteredProducts.isEmpty) {
        return _buildEmptyState(isSearch: _searchQuery.isNotEmpty);
      }
      return _buildProductsGrid(filteredProducts);
    }

    // Sinon, utiliser le Future
    if (widget.productsFuture != null) {
      return FutureBuilder<List<Product>>(
        future: widget.productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: EcommerceLoading.simple(size: 150),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur lors du chargement',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(isSearch: false);
          }

          // Mettre en cache les produits
          if (_cachedProducts == null) {
            _cachedProducts = snapshot.data!;
          }

          final filteredProducts = _getFilteredProducts(snapshot.data!);
          if (filteredProducts.isEmpty) {
            return _buildEmptyState(isSearch: _searchQuery.isNotEmpty);
          }
          return _buildProductsGrid(filteredProducts);
        },
      );
    }

    // Si ni products ni productsFuture n'est fourni
    return _buildEmptyState(isSearch: false);
  }

  Widget _buildEmptyState({required bool isSearch}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearch ? Icons.search_off : Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            isSearch ? 'Aucun produit trouvé' : 'Aucun produit disponible',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (isSearch) ...[
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

  Widget _buildProductsGrid(List<Product> products) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        // Utiliser LayoutBuilder pour obtenir la largeur disponible
        return LayoutBuilder(
          builder: (context, constraints) {
            return widget.cardBuilder(products[index], width: constraints.maxWidth);
          },
        );
      },
    );
  }
}


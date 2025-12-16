import 'package:flutter/material.dart';
import 'package:immo/constants.dart';
import 'package:immo/widgets/app_logo.dart';
import 'package:flutter/services.dart';
import 'package:immo/services/product_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:immo/cubit/product_cubit.dart';
import 'package:immo/models/product.dart';
import 'package:immo/models/category.dart';
import 'package:immo/screens/product/edit_product_screen.dart';

class DetailProduitMarchantScreen extends StatefulWidget {
  final int productId;
  final String productName;
  final String productPrice;
  final String productStock;
  final String productBadge;
  final String productImageUrl;
  final bool isPromo;
  final Product? product; // Produit complet avec toutes les infos (images, etc.)
  final List<String>? productImages; // Images supplémentaires

  const DetailProduitMarchantScreen({
    Key? key,
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.productStock,
    required this.productBadge,
    required this.productImageUrl,
    required this.isPromo,
    this.product,
    this.productImages,
  }) : super(key: key);

  @override
  State<DetailProduitMarchantScreen> createState() => _DetailProduitMarchantScreenState();
}

class _DetailProduitMarchantScreenState extends State<DetailProduitMarchantScreen> {
  final ProductService _productService = ProductService();
  bool _isLoading = false;
  String _currentMainImage = '';
  int _currentImageIndex = 0;
  Product? _product;

  @override
  void initState() {
    super.initState();
    
    // Utiliser le produit passé en paramètre s'il est disponible
    if (widget.product != null) {
      _product = widget.product;
      final allImages = _getAllImages();
      if (allImages.isNotEmpty) {
        _currentMainImage = _getImageUrl(allImages[0]);
      } else {
        _currentMainImage = _getImageUrl(widget.productImageUrl);
      }
    } else {
      // Initialiser l'image principale
      _currentMainImage = _getImageUrl(widget.productImageUrl);
      
      // Récupérer le produit complet depuis ProductCubit
      _loadProduct();
    }
  }

  void _loadProduct() {
    final productState = context.read<ProductCubit>().state;
    if (productState is ProductLoaded) {
      final product = productState.products.firstWhere(
        (p) => p.id == widget.productId,
        orElse: () {
          // Créer un produit de fallback avec les données disponibles
          final priceValue = double.tryParse(widget.productPrice.replaceAll(' FC', '').replaceAll(' ', '')) ?? 0.0;
          final stockValue = int.tryParse(widget.productStock) ?? 0;
          return Product(
            id: widget.productId,
            name: widget.productName,
            description: widget.productBadge,
            price: priceValue,
            stock: stockValue,
            vendeurId: 0,
            createdAt: '',
            updatedAt: '',
            categorieId: 0,
            category: widget.productBadge.isNotEmpty ? Category(
              id: 0,
              name: widget.productBadge,
              description: '',
            ) : null,
            media: widget.productImageUrl.isNotEmpty ? Media(
              id: 0,
              mediaUrl: widget.productImageUrl,
              mediaType: 'image',
              createdAt: '',
              updatedAt: '',
              productId: widget.productId,
            ) : null,
          );
        },
      );
      if (mounted) {
        setState(() {
          _product = product;
        });
      }
    } else {
      // Si les produits ne sont pas encore chargés, créer un produit de fallback
      final priceValue = double.tryParse(widget.productPrice.replaceAll(' FC', '').replaceAll(' ', '')) ?? 0.0;
      final stockValue = int.tryParse(widget.productStock) ?? 0;
      final fallbackProduct = Product(
        id: widget.productId,
        name: widget.productName,
        description: widget.productBadge,
        price: priceValue,
        stock: stockValue,
        vendeurId: 0,
        createdAt: '',
        updatedAt: '',
        categorieId: 0,
        category: widget.productBadge.isNotEmpty ? Category(
          id: 0,
          name: widget.productBadge,
          description: '',
        ) : null,
        media: widget.productImageUrl.isNotEmpty ? Media(
          id: 0,
          mediaUrl: widget.productImageUrl,
          mediaType: 'image',
          createdAt: '',
          updatedAt: '',
          productId: widget.productId,
        ) : null,
      );
      if (mounted) {
        setState(() {
          _product = fallbackProduct;
        });
      }
    }
  }

  String _getImageUrl(String imagePath) {
    if (imagePath.isEmpty || imagePath == 'null') {
      return 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=600&h=400&fit=crop';
    }
    if (imagePath.startsWith('http')) {
      return imagePath;
    }
    return 'http://24.144.87.127:3333/$imagePath';
  }

  /// Retourne toutes les images disponibles (principale + secondaires)
  /// Priorité: product.getAllImages() > productImages > productImageUrl
  List<String> _getAllImages() {
    // Priorité 1: Utiliser getAllImages() du produit complet si disponible
    if (_product != null) {
      final productImages = _product!.getAllImages();
      if (productImages.isNotEmpty) {
        print('🖼️ DetailProduitMarchantScreen._getAllImages - Produit complet disponible, images: ${productImages.length}');
        return productImages;
      }
    }
    
    // Priorité 2: Utiliser productImages si fourni
    if (widget.productImages != null && widget.productImages!.isNotEmpty) {
      print('🖼️ DetailProduitMarchantScreen._getAllImages - productImages fourni: ${widget.productImages!.length}');
      final List<String> images = List<String>.from(widget.productImages!);
      // Ajouter l'image principale si elle n'est pas déjà dans la liste
      final mainImage = _getImageUrl(widget.productImageUrl);
      if (!images.contains(mainImage)) {
        images.insert(0, mainImage);
      }
      return images;
    }
    
    // Priorité 3: Utiliser uniquement l'image principale
    print('🖼️ DetailProduitMarchantScreen._getAllImages - Utilisation de l\'image principale uniquement');
    final mainImage = _getImageUrl(widget.productImageUrl);
    return [mainImage];
  }

  void _changeMainImage(int index) {
    final allImages = _getAllImages();
    if (index >= 0 && index < allImages.length) {
      setState(() {
        _currentImageIndex = index;
        _currentMainImage = allImages[index];
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }



  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmer la suppression', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: Text('Êtes-vous sûr de vouloir supprimer "${widget.productName}" ?\n\nCette action est irréversible.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : () => _deleteProduct(),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Supprimer', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteProduct() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _productService.deleteProduct(
        productId: widget.productId,
      );

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        Navigator.of(context).pop(); // Fermer le dialogue de confirmation
        Navigator.of(context).pop(); // Retour à la page précédente
        
        // Rafraîchir la liste des produits
        context.read<ProductCubit>().fetchProducts();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        Navigator.of(context).pop(); // Fermer le dialogue de confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Navigator.of(context).pop(); // Fermer le dialogue de confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final allImages = _getAllImages();

    return Scaffold(
      appBar: AppBarWithLogo(
        title: 'Détails du produit',
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              if (_product != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProductScreen(product: _product!),
                  ),
                ).then((result) {
                  if (result == true) {
                    // Rafraîchir les données et retourner à la page précédente
                    context.read<ProductCubit>().fetchProducts();
                    Navigator.pop(context);
                  }
                });
              } else {
                // Si le produit n'est pas encore chargé, essayer de le récupérer
                _loadProduct();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Chargement du produit...'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            tooltip: 'Modifier le produit',
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _showDeleteConfirmation,
            tooltip: 'Supprimer',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image principale
                Expanded(
                  flex: 4,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        _currentMainImage,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.image, size: 80, color: Colors.grey),
                        ),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[50],
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                color: AppColors.primary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Section des miniatures cliquables
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    itemCount: allImages.length,
                    itemBuilder: (context, index) {
                      final imageUrl = allImages[index];
                      final isActive = index == _currentImageIndex;
                      return GestureDetector(
                        onTap: () {
                          _changeMainImage(index);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isActive
                                  ? AppColors.primary
                                  : Colors.grey.shade300,
                              width: isActive ? 2.5 : 1.5,
                            ),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade100,
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 20,
                                    color: Colors.grey.shade400,
                                  ),
                                );
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: Colors.grey.shade50,
                                  child: Center(
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                            : null,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 8),

                // Badge/Catégorie et nom
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.isPromo ? Colors.redAccent : AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        widget.productBadge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.productName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Prix
                Text(
                  '${widget.productPrice} FC',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: widget.isPromo ? Colors.red : Colors.green,
                  ),
                ),

                const SizedBox(height: 8),

                // Informations détaillées en grille
                Expanded(
                  flex: 3,
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 3.0,
                    children: [
                      _buildInfoCard(
                        icon: Icons.inventory_2,
                        title: 'Stock',
                        value: '${widget.productStock}',
                        color: Colors.blue,
                      ),
                      _buildInfoCard(
                        icon: Icons.category,
                        title: 'Catégorie',
                        value: widget.productBadge,
                        color: Colors.orange,
                      ),
                      _buildInfoCard(
                        icon: Icons.local_offer,
                        title: 'Statut',
                        value: widget.isPromo ? 'Promotion' : 'Normal',
                        color: widget.isPromo ? Colors.red : Colors.green,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Boutons d'action
                Row(
                  children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (_product != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditProductScreen(product: _product!),
                                ),
                              ).then((result) {
                                if (result == true) {
                                  // Rafraîchir les données et retourner à la page précédente
                                  context.read<ProductCubit>().fetchProducts();
                                  Navigator.pop(context);
                                }
                              });
                            } else {
                              // Si le produit n'est pas encore chargé, essayer de le récupérer
                              _loadProduct();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Chargement du produit...'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                          label: const Text(
                            'Modifier',
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showDeleteConfirmation,
                        icon: const Icon(Icons.delete, color: Colors.white, size: 18),
                        label: const Text(
                          'Supprimer',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 
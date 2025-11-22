import 'package:flutter/material.dart';
import 'package:immo/constants.dart';
import 'package:immo/widgets/app_logo.dart';
import '../merchant/merchant_profile_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:immo/cubit/cart_cubit.dart';
import 'package:immo/cubit/merchant_cubit.dart';
import 'package:immo/cubit/favorites_cubit.dart';

class ProductDetailScreen extends StatefulWidget {
  final int id;
  final int stock;
  final String tag;
  final String category;
  final String name;
  final double price;
  final String description;
  final String imagePath;
  final void Function()? goToCartTab;
  final String idVendeur;
  final List<String>? productImages; // Liste des images (1 principale + 4 secondaires)
  final String? merchantName; // Nom du marchand
  final List<Map<String, dynamic>>? merchantProducts; // Produits du marchand pour navigation
  const ProductDetailScreen({
    Key? key,
    required this.id,
    required this.description,
    required this.idVendeur,
    required this.stock,
    required this.tag,
    required this.category,
    required this.name,
    required this.price,
    required this.imagePath,
    this.goToCartTab,
    this.productImages,
    this.merchantName,
    this.merchantProducts,
  }) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int quantity = 1;
  bool isInCart = false;
  bool isFavorite = false;
  late PageController _secondaryImagesPageController;
  int _currentSecondaryImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkIfInCart();
    context.read<MerchantCubit>().fetchMerchants(context);
    _checkIfFavorite();
    _secondaryImagesPageController = PageController();
  }

  @override
  void dispose() {
    _secondaryImagesPageController.dispose();
    super.dispose();
  }

  void _checkIfInCart() {
    final cartItems = context.read<CartCubit>().state.items;
    setState(() {
      isInCart = cartItems.any((item) => item['name'] == widget.name);
    });
  }

  void _checkIfFavorite() async {
    final fav = await context.read<FavoritesCubit>().isFavorite(widget.id);
    if (mounted) {
      setState(() {
        isFavorite = fav;
      });
    }
  }

  /// Retourne les 4 images secondaires qui défilent horizontalement
  List<String> _getSecondaryImages() {
    // Si productImages est fourni, utiliser ces images
    if (widget.productImages != null && widget.productImages!.isNotEmpty) {
      final images = widget.productImages!.take(4).toList();
      // Si on a moins de 4 images, compléter avec l'image principale
      while (images.length < 4) {
        images.add(widget.imagePath);
      }
      return images;
    }
    
    // Si aucune image secondaire n'est fournie, utiliser l'image principale 4 fois
    return List.filled(4, widget.imagePath);
  }

  /// Récupère les informations du marchand (version statique)
  /// Pour l'instant, on utilise des données statiques de démonstration
  Map<String, dynamic>? _getMerchantInfo() {
    // Données statiques du marchand pour la démonstration
    final staticMerchantData = {
      'name': widget.merchantName ?? 'Rapidos Store',
      'products': widget.merchantProducts ?? _getStaticMerchantProducts(),
      'imagePath': widget.imagePath,
      'merchantId': widget.idVendeur,
      'rating': 4.5,
      'isVerified': true,
    };
    
    // Essayer de récupérer depuis MerchantCubit si disponible (pour plus tard)
    try {
      final merchantState = context.read<MerchantCubit>().state;
      if (merchantState is MerchantLoaded) {
        try {
          final vendeurId = int.tryParse(widget.idVendeur);
          if (vendeurId != null) {
            final foundMerchant = merchantState.merchants.firstWhere(
              (m) {
                final merchantVendeurId = m['vendeur']?['id'] ?? m['id'];
                return merchantVendeurId == vendeurId;
              },
            );
            
            final vendeur = foundMerchant['vendeur'] ?? foundMerchant;
            final firstName = vendeur['firstName'] ?? '';
            final lastName = vendeur['lastName'] ?? '';
            final name = '$firstName $lastName'.trim();
            
            return {
              'name': name.isNotEmpty ? name : staticMerchantData['name'],
              'products': foundMerchant['products'] ?? staticMerchantData['products'],
              'imagePath': foundMerchant['products'] != null && 
                          (foundMerchant['products'] as List).isNotEmpty &&
                          (foundMerchant['products'] as List)[0]['media'] != null
                  ? (foundMerchant['products'] as List)[0]['media']['mediaUrl']
                  : staticMerchantData['imagePath'],
              'merchantId': foundMerchant['vendeur']?['id']?.toString() ?? widget.idVendeur,
              'rating': 4.5,
              'isVerified': true,
            };
          }
        } catch (e) {
          // Marchand non trouvé dans MerchantCubit, utiliser les données statiques
          print('Marchand non trouvé dans MerchantCubit, utilisation des données statiques');
        }
      }
    } catch (e) {
      // MerchantCubit non disponible, utiliser les données statiques
      print('MerchantCubit non disponible, utilisation des données statiques');
    }
    
    // Retourner les données statiques
    return staticMerchantData;
  }
  
  /// Génère une liste statique de produits du marchand pour la démonstration
  List<Map<String, dynamic>> _getStaticMerchantProducts() {
    return [
      {
        'id': widget.id,
        'name': widget.name,
        'price': widget.price,
        'description': widget.description,
        'stock': widget.stock,
        'category': widget.category,
        'media': {'mediaUrl': widget.imagePath},
      },
      // Produits supplémentaires statiques pour la démonstration
      {
        'id': widget.id + 1,
        'name': 'Produit Similaire 1',
        'price': widget.price * 0.9,
        'description': 'Un produit similaire de qualité',
        'stock': 15,
        'category': widget.category,
        'media': {'mediaUrl': 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400&h=400&fit=crop'},
      },
      {
        'id': widget.id + 2,
        'name': 'Produit Similaire 2',
        'price': widget.price * 1.1,
        'description': 'Un autre produit de la même catégorie',
        'stock': 20,
        'category': widget.category,
        'media': {'mediaUrl': 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400&h=400&fit=crop'},
      },
    ];
  }

  void _toggleFavorite() async {
    final productMap = {
      'id': widget.id,
      'name': widget.name,
      'idVendeur': widget.idVendeur,
      'category': widget.category,
      'price': widget.price,
      'stock': widget.stock,
      'media': {'mediaUrl': widget.imagePath},
    };
    await context.read<FavoritesCubit>().toggleFavorite(productMap);
    _checkIfFavorite();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isFavorite ? 'Retiré des favoris' : 'Ajouté aux favoris'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _addToCart() async {
    final newItem = {
      'id': widget.id,
      'name': widget.name,
      'category': widget.category,
      'price': widget.price,
      'imagePath': widget.imagePath,
      'quantity': quantity,
      'stock': widget.stock,
      'idVendeur': widget.idVendeur,
    };
    final success = await context.read<CartCubit>().addToCart(newItem);
    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stock insuffisant : il ne reste que ${widget.stock} en stock.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    setState(() {
      isInCart = true;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Article ajouté au panier'),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 2),
          // action: SnackBarAction(
          //   label: 'Voir le panier',
          //   textColor: Colors.white,
          //   onPressed: () {
          //     if (widget.goToCartTab != null) {
          //       widget.goToCartTab!();
          //     } else {
          //       Navigator.of(context).popUntil((route) => route.isFirst);
          //     }
          //   },
          // ),
        ),
      );
    }
  }

  void _removeFromCart() async {
    await context.read<CartCubit>().removeFromCart(widget.name);
    setState(() {
      isInCart = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.name} retiré du panier'),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBarWithLogo(
        title: widget.name,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : AppColors.primary,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image principale - Design élégant et moderne
            Hero(
              tag: 'product_${widget.id}_${widget.imagePath}',
              child: Container(
                height: MediaQuery.of(context).size.width < 600 ? 220 : 260,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image principale avec effet de zoom
                    Image.network(
                      widget.imagePath,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.grey.shade100,
                                Colors.grey.shade200,
                              ],
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_not_supported,
                                  size: 60,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Image non disponible',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.grey.shade50,
                                Colors.grey.shade100,
                              ],
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    color: AppColors.primary,
                                    strokeWidth: 3,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Chargement...',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    // Gradient overlay subtil en bas pour un effet élégant
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.03),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Section des images secondaires en carrousel - Design professionnel et épuré
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Carrousel principal avec PageView
                  SizedBox(
                    height: 100,
                    child: PageView.builder(
                      controller: _secondaryImagesPageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentSecondaryImageIndex = index;
                        });
                      },
                      itemCount: _getSecondaryImages().length,
                      itemBuilder: (context, index) {
                        final imageUrl = _getSecondaryImages()[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade100,
                                  child: Center(
                                    child: Icon(
                                      Icons.image_not_supported,
                                      size: 28,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                );
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: Colors.grey.shade50,
                                  child: Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                            : null,
                                        strokeWidth: 2,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Miniatures cliquables en bas
                  SizedBox(
                    height: 70,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _getSecondaryImages().length,
                      itemBuilder: (context, index) {
                        final imageUrl = _getSecondaryImages()[index];
                        final isActive = index == _currentSecondaryImageIndex;
                        return GestureDetector(
                          onTap: () {
                            _secondaryImagesPageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 10),
                            width: 70,
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
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(
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
                                              value: loadingProgress.expectedTotalBytes != null
                                                  ? loadingProgress.cumulativeBytesLoaded /
                                                      loadingProgress.expectedTotalBytes!
                                                  : null,
                                              strokeWidth: 2,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  // Overlay pour l'image active
                                  if (isActive)
                                    Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Indicateurs (dots) minimalistes
                  if (_getSecondaryImages().length > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _getSecondaryImages().length,
                          (index) => _buildCarouselIndicator(index == _currentSecondaryImageIndex),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Product Details - Design e-commerce professionnel optimisé
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tag et Stock - Design compact et élégant optimisé
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.2),
                              width: 0.7,
                            ),
                          ),
                          child: Text(
                            widget.tag,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 9.5,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 11,
                                color: Colors.green.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "${widget.stock} en stock",
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Category - Texte réduit optimisé
                    Text(
                      widget.category.toUpperCase(),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Product Name - Taille optimisée
                    Text(
                      widget.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 19,
                        color: AppColors.primary,
                        height: 1.25,
                        letterSpacing: -0.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Price - Design compact et moderne optimisé
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            "${widget.price.toStringAsFixed(0)}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                              color: AppColors.primary,
                              letterSpacing: -0.6,
                              height: 1,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Text(
                              'FC',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 18),
                    
                    // Merchant Information (Cliquable) - Version statique
                    Builder(
                      builder: (context) {
                        final merchantInfo = _getMerchantInfo();
                        if (merchantInfo != null) {
                          return _buildMerchantCard(merchantInfo);
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Description - Design compact optimisé
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 15,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Description',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.description,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.grey.shade700,
                            height: 1.5,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 18),
                  
                    // Quantity Selector - Design compact et élégant optimisé
                    Row(
                      children: [
                        Text(
                          'Quantité',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.06),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    if (quantity > 1) {
                                      setState(() {
                                        quantity--;
                                      });
                                    }
                                  },
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(9),
                                    bottomLeft: Radius.circular(9),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(9),
                                    child: Icon(
                                      Icons.remove,
                                      size: 15,
                                      color: quantity > 1 
                                          ? AppColors.primary 
                                          : Colors.grey.shade400,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                child: Text(
                                  '$quantity',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      quantity++;
                                    });
                                  },
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(9),
                                    bottomRight: Radius.circular(9),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(9),
                                    child: const Icon(
                                      Icons.add,
                                      size: 15,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                  
                  // const SizedBox(height: 24),
                  
                  // Seller Information
                  // Container(
                  //   padding: const EdgeInsets.all(16),
                  //   decoration: BoxDecoration(
                  //     color: Colors.grey.shade100,
                  //     borderRadius: BorderRadius.circular(8),
                  //     border: Border.all(color: Colors.grey.shade300),
                  //   ),
                  //   child: Row(
                  //     children: [
                  //       CircleAvatar(
                  //         radius: 24,
                  //         backgroundColor: AppColors.primary.withOpacity(0.1),
                  //         child: Icon(
                  //           Icons.store,
                  //           color: AppColors.primary,
                  //           size: 26,
                  //         ),
                  //       ),
                  //       const SizedBox(width: 16),
                  //       Expanded(
                  //         child: Column(
                  //           crossAxisAlignment: CrossAxisAlignment.start,
                  //           children: [
                  //             const Row(
                  //               children: [
                  //                 Text(
                  //                   'Rapidos Store',
                  //                   style: TextStyle(
                  //                     fontWeight: FontWeight.bold,
                  //                     fontSize: 16,
                  //                     color: AppColors.primary,
                  //                   ),
                  //                 ),
                  //                 SizedBox(width: 8),
                  //                 Icon(
                  //                   Icons.verified,
                  //                   color: AppColors.primary,
                  //                   size: 16,
                  //                 ),
                  //               ],
                  //             ),
                  //             const SizedBox(height: 4),
                  //             Row(
                  //               children: [
                  //                 Icon(
                  //                   Icons.star,
                  //                   color: Colors.amber,
                  //                   size: 14,
                  //                 ),
                  //                 const SizedBox(width: 4),
                  //                 Text(
                  //                   '4.8 (520 ventes)',
                  //                   style: TextStyle(
                  //                     fontSize: 12,
                  //                     color: Colors.grey.shade700,
                  //                   ),
                  //                 ),
                  //               ],
                  //             ),
                  //             const SizedBox(height: 8),
                  //             Row(
                  //               children: [
                  //                 Icon(
                  //                   Icons.location_on,
                  //                   color: Colors.grey.shade600,
                  //                   size: 14,
                  //                 ),
                  //                 const SizedBox(width: 4),
                  //                 Text(
                  //                   'Kinshasa, Congo',
                  //                   style: TextStyle(
                  //                     fontSize: 12,
                  //                     color: Colors.grey.shade700,
                  //                   ),
                  //                 ),
                  //               ],
                  //             ),
                  //           ],
                  //         ),
                  //       ),
                  //       ElevatedButton(
                  //         onPressed: () {
                  //           final merchantState = context.read<MerchantCubit>().state;
                  //           if (merchantState is MerchantLoaded) {
                  //             // Trouver le marchand correspondant au produit
                  //             final merchant = merchantState.merchants.firstWhere(
                  //               (m) => (m['products'] as List).any((p) => p['id'] == widget.id),
                  //               orElse: () => {
                  //                 'vendeur': {'firstName': 'Rapidos', 'lastName': 'Store'},
                  //                 'products': []
                  //               },
                  //             );
                  //             final products = (merchant['products'] as List).cast<Map<String, dynamic>>();
                  //             final vendeur = merchant['vendeur'];
                  //             final name = '${vendeur['firstName']} ${vendeur['lastName']}';
                  //             final image = products.isNotEmpty && products[0]['media'] != null
                  //                 ? 'http://24.144.87.127:3333/${products[0]['media']['mediaUrl']}'
                  //                 : widget.imagePath;
                              
                  //             Navigator.push(
                  //               context, 
                  //               MaterialPageRoute(
                  //                 builder: (context) => MerchantProfileScreen(
                  //                   name: name,
                  //                   imagePath: image,
                  //                   category: widget.category,
                  //                   rating: 4.8,
                  //                   isVerified: true,
                  //                   products: products,
                  //                 ),
                  //               ),
                  //             );
                  //           }
                  //         },
                  //         style: ElevatedButton.styleFrom(
                  //           backgroundColor: AppColors.primary,
                  //           foregroundColor: Colors.white,
                  //           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  //           minimumSize: Size.zero,
                  //           tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  //         ),
                  //         child: const Text('Voir'),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  
                  const SizedBox(height: 24),
                  
                  
                  const SizedBox(height: 24),
                  
                    // Add to Cart Button - Design professionnel optimisé
                    Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: (isInCart ? Colors.red : AppColors.primary).withOpacity(0.22),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: isInCart ? _removeFromCart : _addToCart,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isInCart ? Colors.red : AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isInCart ? Icons.remove_shopping_cart_outlined : Icons.shopping_cart_outlined,
                              size: 17,
                            ),
                            const SizedBox(width: 9),
                            Text(
                              isInCart ? 'RETIRER DU PANIER' : 'AJOUTER AU PANIER',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget pour afficher la carte du marchand cliquable
  Widget _buildMerchantCard(Map<String, dynamic> merchantInfo) {
    final merchantName = merchantInfo['name'] as String;
    // Convertir la liste en List<Map<String, dynamic>> de manière sûre
    final productsList = merchantInfo['products'];
    final merchantProducts = productsList is List
        ? List<Map<String, dynamic>>.from(
            productsList.map((item) => item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{}))
        : <Map<String, dynamic>>[];
    final merchantImagePath = merchantInfo['imagePath'] as String;
    final merchantId = merchantInfo['merchantId'] as String;
    final rating = merchantInfo['rating'] as double? ?? 4.5;
    final isVerified = merchantInfo['isVerified'] as bool? ?? true;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MerchantProfileScreen(
              name: merchantName,
              imagePath: merchantImagePath,
              category: widget.category,
              rating: rating,
              isVerified: isVerified,
              products: merchantProducts,
              description: widget.description,
              merchantId: merchantId,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: Colors.grey.shade200, width: 0.8),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Icon(
                Icons.store,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Vendu par',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          merchantName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.verified,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget pour créer les indicateurs du carrousel des images secondaires - Design minimaliste
  Widget _buildCarouselIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      height: 5,
      width: isActive ? 20 : 5,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : Colors.grey.shade400,
        borderRadius: BorderRadius.circular(2.5),
      ),
    );
  }

}

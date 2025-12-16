import 'package:flutter/material.dart';
import 'package:immo/constants.dart';
import 'package:immo/widgets/app_logo.dart';
import '../merchant/vendeur_detail_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:immo/cubit/cart_cubit.dart';
import 'package:immo/cubit/merchant_cubit.dart';
import 'package:immo/cubit/favorites_cubit.dart';
import 'package:immo/cubit/auth_cubit.dart';
import '../auth/login_screen.dart';
import '../../models/product.dart';
import '../../models/vendeur.dart';

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
  final Product? product; // Produit complet avec informations du vendeur
  final Vendeur? vendeur; // Informations du vendeur directement
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
    this.product,
    this.vendeur,
  }) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int quantity = 1;
  bool isInCart = false;
  bool isFavorite = false;
  String _currentMainImage = ''; // Image principale actuellement affichée
  int _currentSecondaryImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkIfInCart();
    context.read<MerchantCubit>().fetchMerchants(context);
    _checkIfFavorite();
    // Initialiser l'image principale : utiliser getMainImage() si product est disponible, sinon widget.imagePath
    _currentMainImage = widget.product?.getMainImage() ?? widget.imagePath;
  }

  /// Vérifie si l'utilisateur est autorisé à effectuer des actions
  bool _isAuthorizedUser() {
    try {
      final authState = context.read<AuthCubit>().state;
      if (authState is AuthSuccess && authState.user != null) {
        final userPhone = authState.user!['phone']?.toString() ?? '';
        // Si le numéro est +243842613999, l'utilisateur n'est PAS autorisé
        return userPhone != '+243842613999';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Redirige vers le login si l'utilisateur n'est pas autorisé
  void _checkAuthorizationAndRedirect() {
    if (!mounted) {
      return;
    }
    if (!_isAuthorizedUser()) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _checkIfInCart() async {
    // Vérifier si l'utilisateur est autorisé
    if (!_isAuthorizedUser()) {
      setState(() {
        isInCart = false;
      });
      return;
    }

    // Vérifier si le produit est dans le panier
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

  /// Retourne toutes les images disponibles (principale + secondaires)
  List<String> _getAllImages() {
    // Priorité 1: Utiliser getAllImages() du produit complet si disponible
    if (widget.product != null) {
      final productImages = widget.product!.getAllImages();
      print('🖼️ ProductDetailScreen._getAllImages - Produit complet disponible, images: ${productImages.length}');
      print('🖼️ ProductDetailScreen._getAllImages - Liste: $productImages');
      if (productImages.isNotEmpty) {
        // Retourner toutes les images telles quelles, sans compléter
        return productImages;
      }
    }
    
    // Priorité 2: Utiliser productImages si fourni
    if (widget.productImages != null && widget.productImages!.isNotEmpty) {
      print('🖼️ ProductDetailScreen._getAllImages - productImages fourni: ${widget.productImages!.length}');
      print('🖼️ ProductDetailScreen._getAllImages - Liste: ${widget.productImages}');
      final List<String> images = List<String>.from(widget.productImages!);
      // Ajouter l'image principale si elle n'est pas déjà dans la liste
      if (!images.contains(widget.imagePath)) {
        images.insert(0, widget.imagePath);
      }
      return images;
    }
    
    // Priorité 3: Utiliser uniquement l'image principale
    print('🖼️ ProductDetailScreen._getAllImages - Utilisation de l\'image principale uniquement: ${widget.imagePath}');
    return [widget.imagePath];
  }

  /// Change l'image principale lorsqu'on clique ou scroll sur une image secondaire
  void _changeMainImage(int index) {
    final allImages = _getAllImages();
    if (index >= 0 && index < allImages.length) {
      setState(() {
        _currentMainImage = allImages[index];
        _currentSecondaryImageIndex = index;
      });
    }
  }

  /// Récupère les informations du marchand/vendeur
  /// Le marchand et le vendeur sont la même chose, donc on utilise toujours firstName et lastName de la clé vendeur
  Map<String, dynamic>? _getMerchantInfo() {
    // Construire le nom du vendeur directement à partir de firstName et lastName de la clé vendeur
    String fallbackVendeurName = 'Inconnu';
    
    // Priorité 1: Utiliser le vendeur depuis widget.product (format commun)
    if (widget.product?.vendeur != null) {
      final vendeur = widget.product!.vendeur!;
      final firstName = vendeur.firstName.trim();
      final lastName = vendeur.lastName.trim();
      final name = '$firstName $lastName'.trim();
      if (name.isNotEmpty) {
        fallbackVendeurName = name;
      }
    }
    // Priorité 2: Utiliser widget.vendeur directement
    else if (widget.vendeur != null) {
      final firstName = widget.vendeur!.firstName.trim();
      final lastName = widget.vendeur!.lastName.trim();
      final name = '$firstName $lastName'.trim();
      if (name.isNotEmpty) {
        fallbackVendeurName = name;
      }
    }
    
    final fallbackVendeurId = widget.product?.vendeurId ??
        widget.product?.vendeur?.id ??
        (int.tryParse(widget.idVendeur)) ??
        widget.vendeur?.id;

    final staticMerchantData = {
      'name': fallbackVendeurName,
      'products': widget.merchantProducts ?? _getStaticMerchantProducts(),
      'imagePath': widget.imagePath,
      'merchantId': fallbackVendeurId?.toString() ?? widget.idVendeur,
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
    // Vérifier l'autorisation avant d'ajouter au panier
    if (!_isAuthorizedUser() || !mounted) {
      _checkAuthorizationAndRedirect();
      return;
    }

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
              tag: 'product_${widget.id}_$_currentMainImage',
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
                    // Image principale avec effet de zoom (dynamique)
                    Image.network(
                      _currentMainImage,
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
            
            // Section des miniatures cliquables - Design professionnel et épuré
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Miniatures cliquables avec scroll
                  SizedBox(
                    height: 70,
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (ScrollNotification notification) {
                        if (notification is ScrollUpdateNotification) {
                          // Détecter l'image visible lors du scroll
                          final scrollPosition = notification.metrics.pixels;
                          final itemWidth = 70.0 + 10.0; // width + margin
                          final currentIndex = (scrollPosition / itemWidth).round();
                          if (currentIndex >= 0 && 
                              currentIndex < _getAllImages().length && 
                              currentIndex != _currentSecondaryImageIndex) {
                            _changeMainImage(currentIndex);
                          }
                        }
                        return false;
                      },
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _getAllImages().length,
                        itemBuilder: (context, index) {
                          final imageUrl = _getAllImages()[index];
                          final isActive = index == _currentSecondaryImageIndex;
                          return GestureDetector(
                            onTap: () {
                              _changeMainImage(index);
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
                  ),
                  // Indicateurs (dots) minimalistes
                  if (_getAllImages().length > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _getAllImages().length,
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
                    
                    // Merchant Information (Cliquable) - Version dynamique
                    Builder(
                      builder: (context) {
                        // Utiliser l'ID du vendeur depuis le produit pour la redirection
                        final vendeurId = widget.product?.vendeurId ?? 
                                         (widget.idVendeur.isNotEmpty ? int.tryParse(widget.idVendeur) : null);
                        
                        // Prioriser les informations du vendeur depuis le produit (format commun)
                        if (widget.product?.vendeur != null && vendeurId != null) {
                          return _buildVendeurCard(widget.product!.vendeur!, vendeurId);
                        } else if (widget.vendeur != null && vendeurId != null) {
                          return _buildVendeurCard(widget.vendeur!, vendeurId);
                        }
                        // Fallback vers l'ancienne méthode
                        final merchantInfo = _getMerchantInfo();
                        if (merchantInfo != null && vendeurId != null) {
                          return _buildMerchantCard(merchantInfo, vendeurId);
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
                  //                   'Inconnu',
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

  /// Widget pour afficher la carte du vendeur cliquable (version dynamique)
  Widget _buildVendeurCard(Vendeur vendeur, int vendeurId) {
    // Afficher toujours firstName + lastName du vendeur (format commun)
    final firstName = vendeur.firstName.trim();
    final lastName = vendeur.lastName.trim();
    final vendeurName = '$firstName $lastName'.trim();
    
    // Si le nom est vide, utiliser un fallback
    final displayName = vendeurName.isNotEmpty 
        ? vendeurName 
        : (vendeur.email.isNotEmpty ? vendeur.email : 'Vendeur');
    // Utiliser l'id du vendeur provenant de l'objet, sinon le paramètre fourni
    final targetVendeurId = vendeur.id != 0 ? vendeur.id : vendeurId;
    // Utiliser l'image de la boutique (media) au lieu de l'image du profil
    final boutiqueImageUrl = vendeur.media?.mediaUrl ?? vendeur.profileImageUrl;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VendeurDetailScreen(
              vendeurId: targetVendeurId, // ID du vendeur depuis l'objet
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
            boutiqueImageUrl != null && boutiqueImageUrl.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      boutiqueImageUrl,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return CircleAvatar(
                          radius: 26,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: Icon(
                            Icons.store,
                            color: AppColors.primary,
                            size: 28,
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return CircleAvatar(
                          radius: 26,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                    ),
                  )
                : CircleAvatar(
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
                          displayName,
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

  /// Widget pour afficher la carte du marchand cliquable (version statique - fallback)
  Widget _buildMerchantCard(Map<String, dynamic> merchantInfo, int vendeurId) {
    final merchantName = merchantInfo['name'] as String;
    // Ne pas utiliser l'image du produit, mais chercher une image de boutique
    // Pour l'instant, on n'affiche pas d'image de boutique dans le fallback, seulement l'icône store
    
    return GestureDetector(
      onTap: () {
        // Toujours utiliser VendeurDetailScreen avec l'ID du vendeur depuis le produit
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VendeurDetailScreen(
              vendeurId: vendeurId,
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
            // Toujours afficher l'icône store pour le fallback (pas d'image de boutique disponible)
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

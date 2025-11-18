import 'package:flutter/material.dart';
import 'package:immo/constants.dart';
import 'package:immo/widgets/app_logo.dart';
import '../merchant/merchant_profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../cart/cart_screen.dart';
import 'package:immo/widgets/cart_badge.dart';
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
  }) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int quantity = 1;
  bool isInCart = false;
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkIfInCart();
    context.read<MerchantCubit>().fetchMerchants(context);
    _checkIfFavorite();
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Hero(
              tag: 'product_${widget.id}_${widget.imagePath}',
              child: Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                ),
                child: Image.network(
                  widget.imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                    );
                  },
                ),
              ),
            ),
            
            // Product Details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.tag,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Category and Name
                  Text(
                    widget.category,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                        Text(
                    "${widget.stock} en stock",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: AppColors.primary,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Price
                  Text(
                    "${widget.price.toStringAsFixed(0)} FC",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: AppColors.primary,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.description,
                    // 'Ce produit est un excellent choix pour tous ceux qui recherchent qualité et style. Fabriqué avec des matériaux de haute qualité, il est conçu pour durer et apporter satisfaction.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Quantity Selector
                  Row(
                    children: [
                      const Text(
                        'Quantité:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 16),
                              onPressed: () {
                                if (quantity > 1) {
                                  setState(() {
                                    quantity--;
                                  });
                                }
                              },
                            ),
                            Text(
                              '$quantity',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 16),
                              onPressed: () {
                                setState(() {
                                  quantity++;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
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
                  
                  // Add to Cart Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isInCart ? _removeFromCart : _addToCart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isInCart ? Colors.red : AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: Text(
                        isInCart ? 'RETIRER DU PANIER' : 'AJOUTER AU PANIER',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(String name, int rating, String comment) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.grey.shade300,
                radius: 12,
              ),
              const SizedBox(width: 8),
              Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: List.generate(
              rating,
              (index) => const Icon(Icons.star, color: Colors.amber, size: 14),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            comment, 
            style: const TextStyle(fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

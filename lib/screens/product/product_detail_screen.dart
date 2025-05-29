import 'package:flutter/material.dart';
import 'package:immo/constants.dart';
import '../merchant/merchant_profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../cart/cart_screen.dart';
import '../cart/cart_notifier.dart';
import 'package:immo/widgets/cart_badge.dart';

class ProductDetailScreen extends StatefulWidget {
  final String tag;
  final String category;
  final String name;
  final String price;
  final String imagePath;

  const ProductDetailScreen({
    Key? key,
    required this.tag,
    required this.category,
    required this.name,
    required this.price,
    required this.imagePath,
  }) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int quantity = 1;
  bool isInCart = false;

  @override
  void initState() {
    super.initState();
    _checkIfInCart();
  }

  Future<void> _checkIfInCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartItems = prefs.getStringList('cart_items') ?? [];
    setState(() {
      isInCart = cartItems.contains(jsonEncode({
        'name': widget.name,
        'price': widget.price,
        'imagePath': widget.imagePath,
        'category': widget.category,
      }));
    });
  }

  Future<void> _addToCart() async {
    final prefs = await SharedPreferences.getInstance();
    final items = prefs.getStringList('cart_items') ?? [];
    
    final newItem = {
      'name': widget.name,
      'category': widget.category,
      'price': widget.price,
      'imagePath': widget.imagePath,
      'quantity': quantity,
    };

    // Vérifier si le produit existe déjà dans le panier
    bool productExists = false;
    for (int i = 0; i < items.length; i++) {
      final existingItem = jsonDecode(items[i]);
      if (existingItem['name'] == widget.name) {
        // Mettre à jour la quantité du produit existant
        existingItem['quantity'] = (existingItem['quantity'] as int) + quantity;
        items[i] = jsonEncode(existingItem);
        productExists = true;
        break;
      }
    }

    // Si le produit n'existe pas, l'ajouter au panier
    if (!productExists) {
      items.add(jsonEncode(newItem));
    }

    await prefs.setStringList('cart_items', items);

    // Mettre à jour le compteur global
    cartItemCount += quantity;

    setState(() {
      isInCart = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Article ajouté au panier'),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'Voir le panier',
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CartScreen(),
                ),
              );
            },
          ),
        ),
      );
      
      // Notifier le badge du panier de manière sécurisée
      try {
        CartNotifier.of(context).notifyCartChanged();
      } catch (e) {
        // Ignorer l'erreur si le CartNotifier n'est pas disponible
        debugPrint('CartNotifier non disponible: $e');
      }
    }
  }

  Future<void> _removeFromCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartItems = prefs.getStringList('cart_items') ?? [];
    
    // Trouver l'élément à supprimer et sa quantité
    int removedQuantity = 0;
    cartItems.removeWhere((item) {
      final decodedItem = jsonDecode(item);
      if (decodedItem['name'] == widget.name) {
        removedQuantity = decodedItem['quantity'] as int;
        return true;
      }
      return false;
    });

    await prefs.setStringList('cart_items', cartItems);

    // Mettre à jour le compteur global
    cartItemCount -= removedQuantity;

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
      appBar: AppBar(
        title: Text(
          widget.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border, color: AppColors.primary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ajouté aux favoris!'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Hero(
              tag: widget.imagePath,
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
                      style: TextStyle(
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
                    widget.price,
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
                    'Ce produit est un excellent choix pour tous ceux qui recherchent qualité et style. Fabriqué avec des matériaux de haute qualité, il est conçu pour durer et apporter satisfaction.',
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
                  
                  const SizedBox(height: 24),
                  
                  // Seller Information
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: Icon(
                            Icons.store,
                            color: AppColors.primary,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Text(
                                    'Rapidos Store',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(
                                    Icons.verified,
                                    color: AppColors.primary,
                                    size: 16,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '4.8 (520 ventes)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: Colors.grey.shade600,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Kinshasa, Congo',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context, 
                              MaterialPageRoute(
                                builder: (context) => MerchantProfileScreen(
                                  name: 'Rapidos Store',
                                  imagePath: widget.imagePath,
                                  category: widget.category,
                                  rating: 4.8,
                                  isVerified: true,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Voir'),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Customer Reviews Section
                  const Text(
                    'Avis des clients',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Reviews - Horizontal scrollable
                  SizedBox(
                    height: 120,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        SizedBox(
                          width: 220,
                          child: _buildReviewCard('Alice', 5, 'Excellent produit, je recommande!'),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 220,
                          child: _buildReviewCard('Bob', 4, 'Très satisfait de mon achat'),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 220,
                          child: _buildReviewCard('Marie', 5, 'Livraison rapide, qualité au top'),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 220,
                          child: _buildReviewCard('Thomas', 4, 'Bon rapport qualité/prix'),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 220,
                          child: _buildReviewCard('Julie', 5, 'Produit conforme à la description, très contente!'),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 220,
                          child: _buildReviewCard('Marc', 4, 'Bonne qualité et livraison rapide'),
                        ),
                      ],
                    ),
                  ),
                  
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

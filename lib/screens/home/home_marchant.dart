import 'package:flutter/material.dart';
import 'package:immo/constants.dart';
import 'package:immo/widgets/app_logo.dart';
import 'package:immo/screens/home/voir_plus_produits.dart';
import 'package:immo/screens/home/detail_produit_marchant.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:immo/cubit/auth_cubit.dart';
import 'package:immo/cubit/product_cubit.dart';
import 'package:flutter/services.dart';
import 'package:immo/screens/dashboard/setting_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:immo/widgets/shimmer_loading.dart';
import 'package:immo/cubit/category_cubit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:immo/screens/product/merchant_promo_products_screen.dart';
import 'package:immo/screens/product/promotion_detail_screen.dart';
import 'package:immo/services/promotion_service.dart';
import 'package:immo/models/promotion.dart';
import 'package:immo/screens/product/add_product_screen.dart';

class HomeMarchantScreen extends StatefulWidget {
  const HomeMarchantScreen({Key? key}) : super(key: key);

  @override
  State<HomeMarchantScreen> createState() => _HomeMarchantScreenState();
}

class _HomeMarchantScreenState extends State<HomeMarchantScreen> {
  String? _selectedCategory;
  final List<String> _categories = [
    'sports',
    
  ];

  bool _isLoading = false;
  GoogleMapController? _mapController;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    context.read<ProductCubit>().fetchProducts();
    context.read<CategoryCubit>().fetchCategories();
    _getCurrentLocation();
    
  }

  

void saveCommande() async {
    // Enregistrer la commande
    DocumentReference commandeRef = await FirebaseFirestore.instance.collection('commandes').add({
      'client': 'Joël',
      'adresse': 'Gombe',
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
    });

    print("✅ Commande enregistrée avec succès: ${commandeRef.id}");

}


  Future<void> _getCurrentLocation() async {
    try {
      // Vérifier et demander les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      // Obtenir la position actuelle
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );

      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });

      // Animer la caméra vers la position
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 15,
          ),
        ),
      );
    } catch (e) {
      print('Erreur de localisation: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const AppLogo(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                if (state is AuthSuccess && state.user != null && state.user!['media'] != null) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingScreen()),
                      );
                    },
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.buttonColor2,
                      child: CircleAvatar(
                        radius: 17,
                        backgroundColor: AppColors.white,
                        backgroundImage: NetworkImage(state.user!['media']),
                      ),
                    ),
                  );
                } else {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingScreen()),
                      );
                    },
                    child: const CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.buttonColor2,
                      child: CircleAvatar(
                        radius: 17,
                        backgroundColor: AppColors.buttonColor,
                        child: Icon(Icons.person, color: AppColors.white),
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // const SizedBox(height: 30),
            // Navigation rapide
            // const Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //   children: [
            //     _QuickNavButton(
            //         icon: Icons.local_shipping, label: 'Livraisons'),
            //     _QuickNavButton(icon: Icons.inventory_2, label: 'Produits'),
            //     _QuickNavButton(icon: Icons.person, label: 'Profil'),
            //   ],
            // ),
            // const SizedBox(height: 12),
            // Profil

            // const SizedBox(height: 18),
            // Section: Mes Produits
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mes Produits',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VoirPlusProduitsScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Voir tout',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            BlocBuilder<ProductCubit, ProductState>(
              builder: (context, state) {
                if (state is ProductLoading) {
                  return SizedBox(
                    height: 90,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: 3,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) => const ProductCardShimmer(),
                    ),
                  );
                }
                
                if (state is ProductError) {
                  return Center(
                    child: state.message == 'Pas de produits trouvés'
                        ? const SizedBox(
                            height: 90,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.inbox, size: 48, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text(
                                    "Aucun produit pour l'instant",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : const Text('Erreur lors du chargement des produits'),
                  );
                }

                if (state is ProductLoaded) {
                  if (state.products.isEmpty) {
                    return const SizedBox(
                      height: 90,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox, size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              "Aucun produit pour l'instant",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return SizedBox(
                    height: 90,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: state.products.length > 5 ? 5 : state.products.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final product = state.products.reversed.toList()[index];
                        return _ProductCard(
                          badge: product.category?.name ?? '',
                          name: product.name,
                          stock: product.stock.toString(),
                          isPromo: false,
                          price: product.price.toString(),
                          imageUrl: product.media?.mediaUrl ??
                              'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400&h=400&fit=crop',
                          productId: product.id,
                        );
                      },
                    ),
                  );
                }
                
                return const SizedBox.shrink();
              },
            ),

            const SizedBox(height: 24),

            // Section: Produits en promotions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Produits en promotions',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MerchantPromoProductsScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Voir tout',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            BlocBuilder<AuthCubit, AuthState>(
              builder: (context, authState) {
                int? merchantId;
                if (authState is AuthSuccess && authState.user != null) {
                  final userId = authState.user!['id'];
                  print('🔍 home_marchant - userId brut: $userId (type: ${userId.runtimeType})');
                  if (userId != null) {
                    if (userId is int) {
                      merchantId = userId;
                      print('🔍 home_marchant - userId est int: $merchantId');
                    } else if (userId is String) {
                      merchantId = int.tryParse(userId);
                      print('🔍 home_marchant - userId est String, parsé: $merchantId');
                    } else if (userId is num) {
                      merchantId = userId.toInt();
                      print('🔍 home_marchant - userId est num, converti: $merchantId');
                    }
                  } else {
                    print('🔍 home_marchant - userId est null');
                  }
                } else {
                  print('🔍 home_marchant - authState n\'est pas AuthSuccess ou user est null');
                }
                print('🔍 home_marchant - merchantId final: $merchantId');
                
                return FutureBuilder<Map<String, dynamic>>(
                  future: merchantId != null
                      ? PromotionService().getMerchantPromotions(merchantId)
                      : PromotionService().getPromotions(),
                  builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 90,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasData && snapshot.data!['success'] == true) {
                  final promotions =
                      snapshot.data!['promotions'] as List<Promotion>;
                  final activePromos =
                      promotions.where((p) => p.isActive).toList();

                  if (activePromos.isEmpty) {
                    return const SizedBox(
                      height: 60,
                      child: Center(
                        child: Text(
                          'Aucune promotion active',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }

                  return SizedBox(
                    height: 90,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount:
                          activePromos.length > 5 ? 5 : activePromos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final promotion = activePromos[index];
                        final product = promotion.product;
                        if (product == null) return const SizedBox.shrink();

                        return _ProductCard(
                          badge: 'PROMO',
                          name: product.name,
                          stock: product.stock.toString(),
                          isPromo: true,
                          price: promotion.nouveauPrix.toString(),
                          imageUrl: promotion.image,
                          productId: product.id,
                          promotion: promotion, // Passer l'objet Promotion complet
                        );
                      },
                    ),
                  );
                }
                
                return const SizedBox(
                  height: 60,
                  child: Center(
                    child: Text(
                      'Erreur chargement promotions',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                );
                  },
                );
              },
            ),

            const SizedBox(height: 24),

            // Section: Position du livreur
            const Text(
              'Ma position',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _currentPosition == null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.location_off,
                                    size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 8),
                                Text(
                                  'Impossible d\'obtenir la localisation',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: LatLng(
                                _currentPosition!.latitude,
                                _currentPosition!.longitude,
                              ),
                              zoom: 15,
                            ),
                            onMapCreated: (GoogleMapController controller) {
                              _mapController = controller;
                            },
                            myLocationEnabled: true,
                            myLocationButtonEnabled: true,
                            zoomControlsEnabled: true,
                            mapType: MapType.normal,
                          ),
              ),
            ),

            const SizedBox(height: 24),

            // Section: Statistiques de vente
            const Text(
              'Statistiques de Vente',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Expanded(
                  child: _StatCard(title: 'Ventes', value: '150', percent: '+10%'),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _StatCard(title: 'Clients', value: '200', percent: '-5%'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Section: Avis Clients
            const Text(
              'Avis Clients',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 2,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return const _ReviewCard(
                      client: 'Client A',
                      comment: 'Excellent service!',
                      rating: 5,
                    );
                  } else {
                    return const _ReviewCard(
                      client: 'Client B',
                      comment: 'Livraison rapide et efficace.',
                      rating: 4,
                    );
                  }
                },
              ),
            ),
            



     

          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddProductScreen(),
            ),
          ).then((result) {
            if (result == true) {
              // Rafraîchir la liste des produits si un produit a été ajouté
              context.read<ProductCubit>().fetchProducts();
            }
          });
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Ajouter un produit',
      ),

    );
  }
}

class _QuickNavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  const _QuickNavButton({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary),
          ),
          padding: const EdgeInsets.all(20),
          child: Icon(icon, color: AppColors.primary, size: 8),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}

class _ProductCard extends StatefulWidget {
  final String badge;
  final String name;
  final String stock;
  final bool isPromo;
  final String imageUrl;
  final String price;
  final int productId;
  final Promotion? promotion; // Ajout de l'objet Promotion optionnel
  const _ProductCard(
      {required this.badge,
      required this.name,
      required this.stock,
      required this.price,
      required this.isPromo,
      required this.imageUrl,
      required this.productId,
      this.promotion}); // Promotion optionnel

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final String displayImageUrl = (widget.imageUrl.isEmpty || widget.imageUrl == 'null')
        ? 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400&h=400&fit=crop'
        : widget.imageUrl.startsWith('http')
            ? widget.imageUrl
            : 'http://24.144.87.127:3333/$widget.imageUrl';
    return GestureDetector(
      onTap: () {
        // Si c'est une promotion, rediriger vers l'écran de détail de la promotion
        if (widget.isPromo && widget.promotion != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PromotionDetailScreen(
                promotion: widget.promotion!,
              ),
            ),
          );
        } else if (!widget.isPromo) {
          // Sinon, navigation vers la page de détail du produit
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailProduitMarchantScreen(
                productName: widget.name,
                productPrice: widget.price,
                productStock: widget.stock,
                productBadge: widget.badge,
                productImageUrl: widget.imageUrl,
                isPromo: widget.isPromo,
                productId: widget.productId,
              ),
            ),
          );
        }
      },
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            alignment: Alignment.center,
            child: Container(
              width: 160,
              height: 90,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.07),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Row(
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              bottomLeft: Radius.circular(12),
                            ),
                            child: Image.network(
                              displayImageUrl,
                              width: 50,
                              height: 90,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                width: 50,
                                height: 90,
                                color: Colors.grey[200],
                                child: const Icon(Icons.image, color: Colors.grey),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 6,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: widget.isPromo
                                    ? Colors.redAccent
                                    : AppColors.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                widget.badge.length > 8
                                    ? '${widget.badge.substring(0, 8)}...'
                                    : widget.badge,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Stock: ${widget.stock}",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "${widget.price} FC",
                                style: TextStyle(
                                  color:
                                      widget.isPromo ? Colors.red : Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Badge Modifier réduit
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final String client;
  final String comment;
  final int rating;
  const _ReviewCard(
      {required this.client, required this.comment, required this.rating});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, size: 14, color: Colors.white)),
              const SizedBox(width: 8),
              Text(client,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
              const Spacer(),
              Row(
                children: List.generate(
                    rating,
                    (index) =>
                        const Icon(Icons.star, color: Colors.amber, size: 14)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(comment, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

class _DeliveryRow extends StatelessWidget {
  final String title;
  final String status;
  final String livreur;
  final IconData icon;
  final Color iconColor;
  const _DeliveryRow(
      {required this.title,
      required this.status,
      required this.livreur,
      required this.icon,
      required this.iconColor});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 6),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Text(status, style: const TextStyle(color: Colors.grey)),
          const Spacer(),
          Text('Livreur: $livreur',
              style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
          const Icon(Icons.notifications_active, color: Colors.amber, size: 18),
        ],
      ),
    );
  }
}

class _ChipButton extends StatelessWidget {
  final String label;
  const _ChipButton({required this.label});
  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: AppColors.primary.withOpacity(0.13),
      labelStyle: const TextStyle(color: AppColors.primary),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String label;
  final IconData icon;
  const _CategoryCard({required this.label, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String percent;
  const _StatCard(
      {required this.title, required this.value, required this.percent});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const Spacer(),
            Row(
              children: [
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(width: 8),
                Text(percent,
                    style: TextStyle(
                        color:
                            percent.startsWith('+') ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class OrderCardShimmer extends StatelessWidget {
  const OrderCardShimmer({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline shimmer
          Container(
            width: 6,
            height: 110,
            margin: const EdgeInsets.only(right: 10, top: 10, bottom: 10),
            decoration: BoxDecoration(
              color: AppColors.buttonColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          // Image shimmer
          Padding(
            padding: const EdgeInsets.only(top: 16, left: 0, right: 10),
            child: ShimmerLoading(
              width: 70,
              height: 70,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          // Détails shimmer
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ShimmerLoading(
                        width: 90,
                        height: 16,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      const SizedBox(width: 8),
                      ShimmerLoading(
                        width: 60,
                        height: 16,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ShimmerLoading(
                    width: 120,
                    height: 12,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ShimmerLoading(
                        width: 60,
                        height: 12,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      const SizedBox(width: 12),
                      ShimmerLoading(
                        width: 50,
                        height: 14,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ShimmerLoading(
                        width: 80,
                        height: 12,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      const SizedBox(width: 8),
                      ShimmerLoading(
                        width: 60,
                        height: 12,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProductCardShimmer extends StatelessWidget {
  const ProductCardShimmer({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 90,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.07),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                child: ShimmerLoading(
                  width: 50,
                  height: 90,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              Positioned(
                top: 6,
                left: 6,
                child: ShimmerLoading(
                  width: 30,
                  height: 12,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ShimmerLoading(
                    width: 60,
                    height: 12,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  const SizedBox(height: 4),
                  ShimmerLoading(
                    width: 40,
                    height: 10,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  const SizedBox(height: 4),
                  ShimmerLoading(
                    width: 45,
                    height: 11,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

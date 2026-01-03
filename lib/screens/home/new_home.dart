import 'package:flutter/material.dart';
import 'package:immo/constants.dart';
import 'package:immo/screens/home/all_merchants_screen.dart';
import 'package:immo/screens/navigation_example.dart';
import 'package:immo/screens/product/product_detail_screen.dart';
import 'package:immo/widgets/ecommerce_loading.dart';
import '../merchant/vendeur_detail_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:immo/cubit/auth_cubit.dart';
import 'package:immo/screens/dashboard/setting_screen.dart';
import 'package:immo/cubit/featured_product_cubit.dart';
import 'package:immo/screens/product/all_products_screen.dart';
import 'package:immo/screens/product/category_products_screen.dart';
import 'package:immo/screens/product/promo_products_section.dart';
import 'package:immo/screens/product/recommended_products_section.dart';
import 'package:immo/cubit/category_cubit.dart';
import 'package:immo/widgets/shimmer_loading.dart';
import 'package:immo/cubit/merchant_cubit.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:immo/cubit/order_cubit.dart';
import 'package:immo/cubit/cart_cubit.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:immo/screens/auth/login_screen.dart';
import 'dart:math' as math;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:immo/models/product.dart';
import 'package:immo/services/review_service.dart';
import 'package:immo/services/product_service.dart';
import 'package:immo/services/event_service.dart';
import 'package:immo/screens/product/category_products_all_screen.dart';

/// Clipper personnalisé pour créer une forme asymétrique pour l'image restaurant
class _RestaurantImageClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height - 15);
    path.quadraticBezierTo(size.width * 0.7, size.height, size.width * 0.5, size.height - 10);
    path.quadraticBezierTo(size.width * 0.3, size.height - 20, 0, size.height - 15);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class NewHomeScreen extends StatefulWidget {
  const NewHomeScreen({Key? key}) : super(key: key);

  @override
  State<NewHomeScreen> createState() => _NewHomeScreenState();
}

class _NewHomeScreenState extends State<NewHomeScreen> {
  Position? _currentPosition;
  bool _isLoading = false;
  List<dynamic> _commandes = [];
  http.Client? _httpClient;
  Future<Map<String, dynamic>>? _randomProductsFuture;
  Future<Map<String, dynamic>>? _telephoneProductsFuture;
  Future<Map<String, dynamic>>? _restaurantProductsFuture;
  Future<Map<String, dynamic>>? _modeProductsFuture;

  /// Retourne le widget icône approprié pour une catégorie, ou Icons.category par défaut
  Widget _getCategoryIconWidget(String categoryName, Color color, double size) {
    final name = categoryName.toLowerCase().trim();

    // Footwear / Talons dame / Chaussures dame (priorité spécifique)
    if (name.contains('footwear') ||
        name.contains('talon') ||
        name.contains('high heel') ||
        name.contains('highheel') ||
        name.contains('chaussure dame') ||
        name.contains('chaussure femme')) {
      return FaIcon(FontAwesomeIcons.shoePrints, color: color, size: size);
    }
    // Chaussures (priorité spécifique) - utilise FontAwesome
    if (name.contains('chaussure') ||
        name.contains('shoe') ||
        name.contains('basket') ||
        name.contains('sneaker') ||
        name.contains('soulier') ||
        name == 'chaussures') {
      return FaIcon(FontAwesomeIcons.shoePrints, color: color, size: size);
    }

    // Boucherie (priorité spécifique)
    if (name.contains('boucherie') ||
        name.contains('boucher') ||
        name.contains('viande') ||
        name.contains('meat') ||
        name == 'boucherie') {
      return FaIcon(FontAwesomeIcons.drumstickBite, color: color, size: size);
    }

    // Take away / Fast food (priorité spécifique)
    if (name.contains('take away') ||
        name.contains('takeaway') ||
        name.contains('à emporter') ||
        name.contains('a emporter') ||
        name.contains('emporter') ||
        name.contains('take-away') ||
        name.contains('fastfood') ||
        name.contains('fast food') ||
        name.contains('fast-food') ||
        name.contains('burger') ||
        name.contains('shawarma')) {
      return FaIcon(FontAwesomeIcons.burger, color: color, size: size);
    }

    // Alimentation
    if (name.contains('food') ||
        name.contains('nourriture') ||
        name.contains('restaurant') ||
        name.contains('repas') ||
        name.contains('plat') ||
        name.contains('cuisine')) {
      return FaIcon(FontAwesomeIcons.utensils, color: color, size: size);
    }
    // Épicerie / Supermarché
    if (name.contains('grocer') ||
        name.contains('épicerie') ||
        name.contains('supermarche') ||
        name.contains('supermarché') ||
        name.contains('alimentation')) {
      return FaIcon(FontAwesomeIcons.shoppingCart, color: color, size: size);
    }
    // Pharmacie / Santé
    if (name.contains('pharmac') ||
        name.contains('médicament') ||
        name.contains('santé') ||
        name.contains('sante') ||
        name.contains('médical')) {
      return FaIcon(FontAwesomeIcons.pills, color: color, size: size);
    }
    // Pâtisserie (priorité spécifique)
    if (name.contains('pâtisserie') ||
        name.contains('patisserie') ||
        name.contains('patissier')) {
      return FaIcon(FontAwesomeIcons.birthdayCake, color: color, size: size);
    }
    // Sucreries / Desserts
    if (name.contains('sweet') ||
        name.contains('dessert') ||
        name.contains('gateau') ||
        name.contains('gâteau') ||
        name.contains('sucre') ||
        name.contains('confiserie')) {
      return FaIcon(FontAwesomeIcons.cookie, color: color, size: size);
    }
    // Magasin / Boutique
    if (name.contains('store') ||
        name.contains('magasin') ||
        name.contains('boutique') ||
        name.contains('shop')) {
      return FaIcon(FontAwesomeIcons.store, color: color, size: size);
    }
    // Téléphonie Mobile (priorité haute pour cette catégorie spécifique)
    if (name.contains('téléphonie') ||
        name.contains('telephonie') ||
        name.contains('mobile') ||
        name.contains('téléphone mobile') ||
        name.contains('telephone mobile') ||
        name.contains('smartphone') ||
        name.contains('phone mobile')) {
      return FaIcon(FontAwesomeIcons.mobileScreenButton,
          color: color, size: size);
    }
    // Électronique / Technologie
    if (name.contains('electronic') ||
        name.contains('électronique') ||
        name.contains('tech') ||
        name.contains('téléphone') ||
        name.contains('telephone')) {
      return FaIcon(FontAwesomeIcons.laptop, color: color, size: size);
    }
    // Vêtements / Mode
    if (name.contains('clothing') ||
        name.contains('vêtement') ||
        name.contains('mode') ||
        name.contains('habillement') ||
        name.contains('vetement') ||
        name.contains('fashion')) {
      return FaIcon(FontAwesomeIcons.shirt, color: color, size: size);
    }
    // Parfumerie (priorité spécifique)
    if (name.contains('parfumerie') ||
        name.contains('parfum') ||
        name == 'parfumerie' ||
        name.contains('fragrance') ||
        name.contains('perfume')) {
      return FaIcon(FontAwesomeIcons.sprayCan, color: color, size: size);
    }
    // Maquillage (priorité spécifique)
    if (name.contains('maquillage') ||
        name.contains('makeup') ||
        name == 'maquillage') {
      return FaIcon(FontAwesomeIcons.paintBrush, color: color, size: size);
    }
    // Beauté / Cosmétique
    if (name.contains('beauty') ||
        name.contains('beauté') ||
        name.contains('cosmétique') ||
        name.contains('cosmetique')) {
      return FaIcon(FontAwesomeIcons.spa, color: color, size: size);
    }
    // Sport / Fitness
    if (name.contains('sport') ||
        name.contains('fitness') ||
        name.contains('gym') ||
        name.contains('exercise') ||
        name.contains('musculation')) {
      return FaIcon(FontAwesomeIcons.futbol, color: color, size: size);
    }
    // Livres / Librairie
    if (name.contains('book') ||
        name.contains('livre') ||
        name.contains('librairie')) {
      return FaIcon(FontAwesomeIcons.book, color: color, size: size);
    }
    // Boissons
    if (name.contains('drink') ||
        name.contains('boisson') ||
        name.contains('café') ||
        name.contains('coffee') ||
        name.contains('cafe') ||
        name.contains('jus')) {
      return FaIcon(FontAwesomeIcons.glassWater, color: color, size: size);
    }
    // Fleurs / Plantes
    if (name.contains('flower') ||
        name.contains('fleur') ||
        name.contains('plante')) {
      return FaIcon(FontAwesomeIcons.seedling, color: color, size: size);
    }
    // Tissage / Produits capillaires (spécifique à votre app)
    if (name.contains('tissage') ||
        name.contains('weaving') ||
        name.contains('cheveu') ||
        name.contains('coiffure') ||
        name.contains('capillaire') ||
        name.contains('perruque') ||
        name.contains('extension') ||
        name.contains('hair') ||
        name.contains('weave')) {
      return FaIcon(FontAwesomeIcons.scissors, color: color, size: size);
    }
    // Automobile / Voiture
    if (name.contains('auto') ||
        name.contains('voiture') ||
        name.contains('car') ||
        name.contains('véhicule') ||
        name.contains('vehicule')) {
      return FaIcon(FontAwesomeIcons.car, color: color, size: size);
    }
    // Maison / Décoration
    if (name.contains('home') ||
        name.contains('maison') ||
        name.contains('décoration') ||
        name.contains('decoration') ||
        name.contains('meuble') ||
        name.contains('déco')) {
      return FaIcon(FontAwesomeIcons.house, color: color, size: size);
    }
    // Jouets / Enfants
    if (name.contains('toy') ||
        name.contains('jouet') ||
        name.contains('enfant') ||
        name.contains('bébé') ||
        name.contains('bebe')) {
      return FaIcon(FontAwesomeIcons.baby, color: color, size: size);
    }
    // Animaux / Pets
    if (name.contains('animal') ||
        name.contains('pet') ||
        name.contains('chien') ||
        name.contains('chat')) {
      return FaIcon(FontAwesomeIcons.paw, color: color, size: size);
    }
    // Bijoux
    if (name.contains('bijou') ||
        name.contains('jewelry') ||
        name.contains('montre') ||
        name.contains('bague')) {
      return FaIcon(FontAwesomeIcons.gem, color: color, size: size);
    }

    // Icône par défaut
    return Icon(Icons.category, color: color, size: size);
  }

  @override
  void initState() {
    super.initState();
    // Créer un client HTTP pour pouvoir l'annuler si nécessaire
    _httpClient = http.Client();
    // Attendre que l'AuthCubit soit initialisé avant de charger les données
    _initializeData();
  }

  @override
  void dispose() {
    // Fermer le client HTTP pour éviter les fuites mémoire
    _httpClient?.close();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      // Attendre que l'AuthCubit soit initialisé
      int attempts = 0;
      while (attempts < 10) {
        final authState = context.read<AuthCubit>().state;
        if (authState is AuthSuccess && authState.token != null) {
          break;
        }
        await Future.delayed(const Duration(milliseconds: 500));
        attempts++;
      }

      // Charger les données
      context.read<FeaturedProductCubit>().fetchFeaturedProducts();
      context.read<CategoryCubit>().fetchCategories();
      context.read<MerchantCubit>().fetchMerchants(context);
      _fetchOrdersAndLocation();
      _fetchUserMedia();
      // Charger les produits aléatoires
      if (mounted) {
        setState(() {
          _randomProductsFuture = ProductService().getRandomProducts();
          _telephoneProductsFuture = ProductService().getProductsByCategory('telephones');
          _restaurantProductsFuture = ProductService().getProductsByCategory('restaurants');
          _modeProductsFuture = ProductService().getModeProducts();
        });
      }
    } catch (e) {
      // Erreur silencieuse pour la production
    }
  }

  Future<void> _fetchUserMedia() async {
    try {
      if (!mounted) return;
      // Récupérer l'utilisateur connecté
      final authState = context.read<AuthCubit>().state;

      if (authState is AuthSuccess && authState.user != null) {
        final userId = authState.user!['id']?.toString() ?? '';
        final token = authState.token;

        if (userId.isNotEmpty && token != null && _httpClient != null) {
          if (!mounted) return;
          
          // Requête pour récupérer les médias de l'utilisateur
          final response = await _httpClient!.get(
            Uri.parse('http://24.144.87.127:3333/users/me'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          );

          if (!mounted) return;
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);

            // Mettre à jour les données utilisateur avec les médias
            if (data['data']['media'] != null) {
              final updatedUser = Map<String, dynamic>.from(authState.user!);
              updatedUser['media'] = data['data']['media'];

              // Mettre à jour l'état de l'authentification
              if (mounted) {
                context.read<AuthCubit>().updateUser(updatedUser, token);
              }
            }
          }
        }
      }
    } catch (e) {
      // Erreur silencieuse pour la production
    }
  }

  Future<void> _fetchOrdersAndLocation() async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
      });

      // Récupérer les commandes via OrderCubit
      final orderCubit = context.read<OrderCubit>();
      await orderCubit.fetchOrders();
      final commandes = orderCubit.orderListState.commandes;
      if (!mounted) return;
      setState(() {
        _commandes = commandes;
      });

      if (commandes.isNotEmpty) {
        // Si au moins une commande, récupérer la position
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
          });
          return;
        }
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            if (!mounted) return;
            setState(() {
              _isLoading = false;
            });
            return;
          }
        }
        if (permission == LocationPermission.deniedForever) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
          });
          return;
        }
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        if (!mounted) return;
        setState(() {
          _currentPosition = position;
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
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
    if (!_isAuthorizedUser()) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  /// Vérifie si l'utilisateur est connecté (pas seulement autorisé)
  bool _isUserLoggedIn() {
    try {
      final authState = context.read<AuthCubit>().state;
      return authState is AuthSuccess && authState.user != null;
    } catch (e) {
      return false;
    }
  }

  /// Redirige vers login si l'utilisateur n'est pas connecté (pour ajout au panier)
  void _checkLoginAndRedirect() {
    if (!_isUserLoggedIn()) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  /// Effectue la déconnexion et redirige vers l'écran home non connecté
  Future<void> _logout() async {
    try {

      // Effacer la session via AuthCubit (qui fait déjà clearAll + clearSession)
      if (mounted) {
        await context.read<AuthCubit>().logout();
      }

      // Rediriger vers l'écran home non connecté (comme au premier chargement)
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const NewHomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      // Rediriger quand même vers l'écran home non connecté
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const NewHomeScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<FeaturedProductCubit>().fetchFeaturedProducts();
          context.read<CategoryCubit>().fetchCategories();
          context.read<MerchantCubit>().fetchMerchants(context);
          // Recharger les produits aléatoires, téléphones, restaurants et mode
          if (mounted) {
            setState(() {
              _randomProductsFuture = ProductService().getRandomProducts();
              _telephoneProductsFuture = ProductService().getProductsByCategory('telephones');
              _restaurantProductsFuture = ProductService().getProductsByCategory('restaurants');
              _modeProductsFuture = ProductService().getModeProducts();
            });
          }
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
          // Header compact avec personnalité
          SliverAppBar(
            floating: true,
            pinned: true,
            snap: false,
            elevation: 0,
            backgroundColor: Colors.white,
            expandedHeight: 0,
            title: BlocBuilder<FeaturedProductCubit, FeaturedProductState>(
              builder: (context, state) {
                return GestureDetector(
                  onTap: () {
                    _checkAuthorizationAndRedirect();
                    if (_isAuthorizedUser()) {
                      if (state is FeaturedProductLoaded && state.products.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AllProductsScreen(
                              products: state.products.reversed.toList(),
                            ),
                          ),
                        );
                      }
                    }
                  },
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.search,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Rechercher des produits...',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.tune,
                          size: 18,
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    if (state is AuthSuccess &&
                        state.user != null &&
                        state.user!['media'] != null) {
                      return GestureDetector(
                        onTap: () {
                          _checkAuthorizationAndRedirect();
                          if (_isAuthorizedUser()) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SettingScreen(),
                              ),
                            );
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.2),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.white,
                            backgroundImage: NetworkImage(state.user!['media']),
                          ),
                        ),
                      );
                    } else {
                      return GestureDetector(
                        onTap: () {
                          _checkAuthorizationAndRedirect();
                          if (_isAuthorizedUser()) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SettingScreen(),
                              ),
                            );
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.2),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.person,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),

          // Categories Section (Horizontal Scroll)
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: SizedBox(
                height: 120,
                child: BlocBuilder<CategoryCubit, CategoryState>(
                builder: (context, state) {
                  if (state is CategoryLoading) {
                    return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: 6,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) => Container(
                        width: 90,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ShimmerLoading(
                          width: 90,
                          height: 120,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                  if (state is CategoryLoaded) {
                    // Trier les catégories par ordre alphabétique
                    final sortedCategories = List.from(state.categories)
                      ..sort((a, b) =>
                          a.name.toLowerCase().compareTo(b.name.toLowerCase()));

                    return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: sortedCategories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final cat = sortedCategories[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CategoryProductsScreen(category: cat),
                              ),
                            );
                          },
                          child: Container(
                            width: 90,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Center(
                                    child: _getCategoryIconWidget(
                                      cat.name,
                                      AppColors.primary,
                                      28,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  child: Text(
                                    cat.name,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }
                  if (state is CategoryError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Erreur de chargement',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                ),
              ),
            ),
          ),

          // Content Section
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  // Container "Bonjour connectez-vous" retiré pour afficher directement le contenu
                  // comme au premier chargement (sans connexion)

                  // Featured products section
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 16),
                              child: Text(
                                'Tous les produits',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                    letterSpacing: 0.3),
                              ),
                            ),
                            BlocBuilder<FeaturedProductCubit,
                                FeaturedProductState>(
                              builder: (context, state) {
                                if (state is FeaturedProductLoaded &&
                                    state.products.isNotEmpty) {
                                  return TextButton(
                                    onPressed: () {
                                      // Permettre l'accès à tous les produits sans connexion
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              AllProductsScreen(
                                                  products: state
                                                      .products.reversed
                                                      .toList()),
                                        ),
                                      );
                                    },
                                    child: const Text('Voir tout',
                                        style: TextStyle(
                                            color: AppColors.primary)),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        BlocBuilder<FeaturedProductCubit, FeaturedProductState>(
                          builder: (context, state) {
                            if (state is FeaturedProductLoading) {
                              return const FeaturedProductShimmer();
                            }
                            if (state is FeaturedProductError) {
                              return const Center(
                                  child: Text('Erreur lors du chargement'));
                            }
                            if (state is FeaturedProductLoaded) {
                              final products = state.products;
                              if (products.isEmpty) {
                                return const Center(
                                    child: Text('Aucun produit vedette'));
                              }
                              return SizedBox(
                                height: 190,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  itemCount: products.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 12),
                                  itemBuilder: (context, index) {
                                    final product =
                                        products.reversed.toList()[index];
                                    return _buildProductCard(
                                      idVendeur: product.vendeurId.toString(),
                                      description: product.description,
                                      stock: product.stock,
                                      id: product.id,
                                      tag: product.category?.name ?? '',
                                      category: product.category?.name ?? '',
                                      name: product.name,
                                      price: product.price,
                                      imagePath: product.getMainImage(),
                                      product: product, // Passer le produit complet pour le print
                                      heroTagSuffix: 'featured_$index', // Tag unique pour éviter les conflits Hero
                                    );
                                  },
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                  ),

                  // Espacement entre sections
                  const SizedBox(height: 24),

                  // Produits en promo section
                  const PromoProductsSection(),

                  // Espacement entre sections
                  const SizedBox(height: 24),

                  // Section Restaurants & Repas (via API /products/by-category/restaurants)
                  FutureBuilder<Map<String, dynamic>>(
                    future: _restaurantProductsFuture ?? ProductService().getProductsByCategory('restaurants'),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        // Afficher un shimmer pendant le chargement
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Restaurants & Repas',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 220,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: 3,
                                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                                  itemBuilder: (context, index) {
                                    return Container(
                                      width: 180,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Center(
                                        child: EcommerceLoading.simple(size: 80),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      if (snapshot.hasError) {
                        return const SizedBox.shrink();
                      }
                      
                      if (snapshot.hasData && snapshot.data!['success'] == true) {
                        final products = snapshot.data!['products'] as List<Product>;
                        if (products.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        
                        // Limiter à 6 produits pour l'affichage
                        final displayProducts = products.take(6).toList();
                        
                        return _buildCategorySection(
                          title: 'Restaurants & Repas',
                          products: displayProducts,
                          allProducts: products, // Tous les produits pour "Voir tout"
                          cardBuilder: _buildRestaurantCard,
                          categoryName: 'Restaurants & Repas',
                        );
                      }
                      
                      return const SizedBox.shrink();
                    },
                  ),

                  // Espacement entre sections
                  const SizedBox(height: 24),

                  // Section Mode, Beauté & Accessoires (via API /category/mode/mode)
                  FutureBuilder<Map<String, dynamic>>(
                    future: _modeProductsFuture ?? ProductService().getModeProducts(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        // Afficher un shimmer pendant le chargement
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Mode, Beauté & Accessoires',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 240,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: 3,
                                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                                  itemBuilder: (context, index) {
                                    return Container(
                                      width: 160,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Center(
                                        child: EcommerceLoading.simple(size: 80),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      if (snapshot.hasError) {
                        return const SizedBox.shrink();
                      }
                      
                      if (snapshot.hasData && snapshot.data!['success'] == true) {
                        final products = snapshot.data!['products'] as List<Product>;
                        if (products.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        
                        // Limiter à 6 produits pour l'affichage
                        final displayProducts = products.take(6).toList();
                        
                        return _buildCategorySection(
                          title: 'Mode, Beauté & Accessoires',
                          products: displayProducts,
                          allProducts: products, // Tous les produits pour "Voir tout"
                          cardBuilder: _buildFashionCard,
                          categoryName: 'Mode, Beauté & Accessoires',
                        );
                      }
                      
                      return const SizedBox.shrink();
                    },
                  ),

                  // Espacement entre sections
                  const SizedBox(height: 24),

                  // Section Téléphones & Accessoires (via API /products/by-category/telephones)
                  FutureBuilder<Map<String, dynamic>>(
                    future: _telephoneProductsFuture ?? ProductService().getProductsByCategory('telephones'),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        // Afficher un shimmer pendant le chargement
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Téléphones & Accessoires',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 220,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: 3,
                                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                                  itemBuilder: (context, index) {
                                    return Container(
                                      width: 160,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Center(
                                        child: EcommerceLoading.simple(size: 80),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      if (snapshot.hasError) {
                        return const SizedBox.shrink();
                      }
                      
                      if (snapshot.hasData && snapshot.data!['success'] == true) {
                        final products = snapshot.data!['products'] as List<Product>;
                        if (products.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        
                        // Limiter à 6 produits pour l'affichage
                        final displayProducts = products.take(6).toList();
                        
                        return _buildCategorySection(
                          title: 'Téléphones & Accessoires',
                          products: displayProducts,
                          allProducts: products, // Tous les produits pour "Voir tout"
                          cardBuilder: _buildPhoneCard,
                          categoryName: 'Téléphones & Accessoires',
                        );
                      }
                      
                      return const SizedBox.shrink();
                    },
                  ),

                  // Espacement entre sections
                  const SizedBox(height: 24),

                  // Produits recommandés section
                  const RecommendedProductsSection(),

                  // Espacement entre sections
                  const SizedBox(height: 24),

                  // Produit choisi pour vous section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Produits choisis pour vous',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FutureBuilder<Map<String, dynamic>>(
                          future: _randomProductsFuture ?? ProductService().getRandomProducts(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Column(
                                children: List.generate(3, (index) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    height: 180,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Center(
                                      child: EcommerceLoading.simple(size: 120),
                                    ),
                                  );
                                }),
                              );
                            }
                            
                            if (snapshot.hasError) {
                              return Container(
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    'Erreur de chargement',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              );
                            }
                            
                            if (snapshot.hasData && snapshot.data!['success'] == true) {
                              final products = snapshot.data!['products'] as List<Product>;
                              if (products.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              
                              return _buildAlternatingProductGrid(products);
                            }
                            
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                  ),

                  // Espacement entre sections
                  const SizedBox(height: 24),

                  // Top Marchands section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Top Marchands',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  letterSpacing: 0.3),
                            ),
                            TextButton(
                              onPressed: () {
                                // Permettre l'accès à tous les marchands sans connexion
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const AllMerchantsScreen(),
                                  ),
                                );
                              },
                              child: const Text('Voir tout',
                                  style: TextStyle(color: AppColors.primary)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Horizontal scrollable merchants
                        BlocBuilder<MerchantCubit, MerchantState>(
                          builder: (context, state) {
                            if (state is MerchantLoading) {
                              return MerchantShimmer();
                            }
                            if (state is MerchantLoaded) {
                              final merchants = state.merchants;
                              if (merchants.isEmpty) {
                                return const Center(
                                    child: Text('Aucun marchand trouvé'));
                              }
                              return SizedBox(
                                height: 150,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  itemCount: merchants.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 16),
                                  itemBuilder: (context, index) {
                                    final vendeur = merchants[index]['vendeur'];
                                    final products =
                                        (merchants[index]['products'] as List)
                                            .cast<Map<String, dynamic>>();
                                    final media = merchants[index]['media'];
                                    final image = media != null &&
                                            media['mediaUrl'] != null
                                        ? media['mediaUrl']
                                        : 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=400&h=400&fit=crop';
                                    final name =
                                        '${vendeur['firstName']} ${vendeur['lastName']}';
                                    return GestureDetector(
                                      onTap: () {
                                        // Naviguer vers VendeurDetailScreen de manière cohérente avec le détail produit
                                        final vendeurId = vendeur['id'] is int 
                                            ? vendeur['id'] 
                                            : int.tryParse(vendeur['id'].toString());
                                        
                                        if (vendeurId != null) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => VendeurDetailScreen(
                                                vendeurId: vendeurId,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      child: _buildMerchantCard(
                                        id: vendeur['id'].toString(),
                                        name: name,
                                        rating: 4.5,
                                        category: products.isNotEmpty
                                            ? products[0]['description'] ?? ''
                                            : '',
                                        imagePath: image,
                                        isVerified: true,
                                        products: products,
                                      ),
                                    );
                                  },
                                ),
                              );
                            }
                            if (state is MerchantError) {
                              return Center(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.store_outlined,
                                          color: Colors.grey.shade600,
                                          size: 24),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Impossible de charger les boutiques',
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Vérifiez votre connexion internet',
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                  ),

                  // Espacement entre sections
                  if (_commandes.isNotEmpty || _currentPosition != null)
                    const SizedBox(height: 24),

                  // Map Section
                  if (_commandes.isNotEmpty || _currentPosition != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ma position',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _isLoading
                              ? const SizedBox(
                                  height: 200,
                                  child: Center(
                                      child: CircularProgressIndicator()),
                                )
                              : _commandes.isNotEmpty
                                  ? GestureDetector(
                                      onTap: () {
                                        _checkAuthorizationAndRedirect();
                                        if (_isAuthorizedUser()) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const NavigationExample(
                                                      backNavigation: true),
                                            ),
                                          );
                                        }
                                      },
                                      child: Container(
                                        height: 200,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.05),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          child: _currentPosition == null
                                              ? const Center(
                                                  child: Text(
                                                    'Impossible d\'obtenir la localisation',
                                                    style: TextStyle(
                                                        color: Colors.black54),
                                                  ),
                                                )
                                              : Stack(
                                                  children: [
                                                    GoogleMap(
                                                      initialCameraPosition:
                                                          CameraPosition(
                                                        target: LatLng(
                                                          _currentPosition!
                                                              .latitude,
                                                          _currentPosition!
                                                              .longitude,
                                                        ),
                                                        zoom: 15,
                                                      ),
                                                      onMapCreated:
                                                          (GoogleMapController
                                                              controller) {},
                                                      myLocationEnabled: true,
                                                      myLocationButtonEnabled:
                                                          true,
                                                      zoomControlsEnabled: true,
                                                      mapType: MapType.normal,
                                                    ),
                                                    Positioned.fill(
                                                      child: Material(
                                                        color:
                                                            Colors.transparent,
                                                        child: Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        16),
                                                            gradient:
                                                                LinearGradient(
                                                              begin: Alignment
                                                                  .topCenter,
                                                              end: Alignment
                                                                  .bottomCenter,
                                                              colors: [
                                                                Colors
                                                                    .transparent,
                                                                Colors.black
                                                                    .withOpacity(
                                                                        0.2),
                                                              ],
                                                            ),
                                                          ),
                                                          child: const Center(
                                                            child: Column(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .end,
                                                              children: [
                                                                Icon(
                                                                  Icons
                                                                      .fullscreen,
                                                                  color: Colors
                                                                      .white,
                                                                  size: 24,
                                                                ),
                                                                SizedBox(
                                                                    height: 8),
                                                                Text(
                                                                  'Voir la carte en détail',
                                                                  style:
                                                                      TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize:
                                                                        14,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                    height: 16),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                        ),
                                      ),
                                    )
                                  : Container(
                                      height: 150,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          CustomPaint(
                                            painter: MapPatternPainter(),
                                            size: Size.infinite,
                                          ),
                                          Icon(Icons.location_on,
                                              color: AppColors.primary
                                                  .withOpacity(0.7)),
                                          const Positioned(
                                            bottom: 10,
                                            child: Text(
                                              'Pas de livraison pour le moment',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                fontSize: 14,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                        ],
                      ),
                    ),

              const SizedBox(height: 24), // Bottom padding
            ],
          ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildProductCard({
    required String idVendeur,
    required int id,
    required String description,
    required String tag,
    required String category,
    required int stock,
    required String name,
    required double price,
    required String imagePath,
    Product? product, // Produit complet optionnel pour le print
    String? heroTagSuffix, // Suffixe optionnel pour rendre le tag Hero unique
  }) {
    return Builder(
      builder: (context) {
        return GestureDetector(
          onTap: () {
            // Print des données du produit
            print('📦 ========== DONNÉES DU PRODUIT CLIQUE ==========');
            if (product != null) {
              print('📦 Produit complet:');
              print('  - id: ${product.id}');
              print('  - name: ${product.name}');
              print('  - description: ${product.description}');
              print('  - price: ${product.price}');
              print('  - stock: ${product.stock}');
              print('  - vendeurId: ${product.vendeurId}');
              print('  - categorieId: ${product.categorieId}');
              print('  - createdAt: ${product.createdAt}');
              print('  - updatedAt: ${product.updatedAt}');
              
              if (product.category != null) {
                print('  - category:');
                print('    * id: ${product.category!.id}');
                print('    * name: ${product.category!.name}');
                print('    * description: ${product.category!.description}');
              }
              
              if (product.media != null) {
                print('  - media:');
                print('    * id: ${product.media!.id}');
                print('    * mediaUrl: ${product.media!.mediaUrl}');
                print('    * mediaType: ${product.media!.mediaType}');
                print('    * productId: ${product.media!.productId}');
              }
              
              if (product.vendeur != null) {
                print('  - vendeur:');
                print('    * id: ${product.vendeur!.id}');
                print('    * firstName: ${product.vendeur!.firstName}');
                print('    * lastName: ${product.vendeur!.lastName}');
                print('    * email: ${product.vendeur!.email}');
                print('    * phone: ${product.vendeur!.phone}');
                print('    * role: ${product.vendeur!.role}');
                print('    * userStatus: ${product.vendeur!.userStatus}');
                
                if (product.vendeur!.profil != null) {
                  print('    * profil:');
                  print('      - id: ${product.vendeur!.profil!.id}');
                  if (product.vendeur!.profil!.media != null) {
                    print('      - media:');
                    print('        * id: ${product.vendeur!.profil!.media!.id}');
                    print('        * mediaUrl: ${product.vendeur!.profil!.media!.mediaUrl}');
                    print('        * mediaType: ${product.vendeur!.profil!.media!.mediaType}');
                  }
                }
              } else {
                print('  - vendeur: null');
              }
            } else {
              print('📦 Données partielles (produit complet non disponible):');
              print('  - id: $id');
              print('  - name: $name');
              print('  - description: $description');
              print('  - price: $price');
              print('  - stock: $stock');
              print('  - idVendeur: $idVendeur');
              print('  - category: $category');
              print('  - tag: $tag');
              print('  - imagePath: $imagePath');
            }
            print('📦 ===========================================');
            
            // Permettre de voir les détails du produit sans être connecté
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailScreen(
                  description: description,
                  idVendeur: idVendeur,
                  id: id,
                  tag: tag,
                  category: category,
                  stock: stock,
                  name: name,
                  price: price,
                  imagePath: imagePath,
                  product: product, // Passer le produit complet si disponible
                ),
              ),
            );
          },
          child: Container(
            width: 150,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image container with tag overlay
                Stack(
                  children: [
                    // Product image
                    Hero(
                      tag: heroTagSuffix != null 
                          ? 'product_${id}_${imagePath}_$heroTagSuffix'
                          : 'product_${id}_${imagePath}',
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                        child: Image.network(
                          imagePath,
                          height: 100,
                          width: 150,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 100,
                              width: 150,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(4),
                                  topRight: Radius.circular(4),
                                ),
                              ),
                              child: Icon(
                                Icons.shopping_bag_outlined,
                                color: Colors.grey.shade400,
                                size: 40,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    // Tag label
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        // width: 110,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.buttonColor2,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          tag,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              const TextStyle(fontSize: 9, color: Colors.white),
                        ),
                      ),
                    ),
                    // Add to cart button
                    Positioned(
                      bottom: 1,
                      right: 8,
                      child: GestureDetector(
                        onTap: () async {
                          // Vérifier l'autorisation avant d'ajouter au panier (même logique que product_detail_screen)
                          if (!_isAuthorizedUser() || !mounted) {
                            _checkAuthorizationAndRedirect();
                            return;
                          }

                          final newItem = {
                            'id': id,
                            'name': name,
                            'category': category,
                            'price': price,
                            'imagePath': imagePath,
                            'quantity': 1,
                            'stock': stock,
                            'idVendeur': idVendeur,
                            'description': description,
                          };
                          final success = await context
                              .read<CartCubit>()
                              .addToCart(newItem);
                          if (!success) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Stock insuffisant : il ne reste que $stock en stock.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                            return;
                          }
                          
                          // Track add to cart event in background
                          final authState = context.read<AuthCubit>().state;
                          if (authState is AuthSuccess && authState.user != null) {
                            final userId = authState.user!['id'];
                            if (userId != null) {
                              EventService().trackAddToCart(
                                productId: id,
                                userId: userId is int ? userId : int.tryParse(userId.toString()) ?? 0,
                              );
                            }
                          }
                          
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: const Text('Article ajouté au panier'),
                                backgroundColor: AppColors.primary,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Product details
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          "$stock en stock",
                          style:
                              const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          price.toString() + " FC",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppColors.primary),
                        ),
                        const SizedBox(height: 1),
                        FutureBuilder<double>(
                          future: ReviewService().getCachedAverageRating(id),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data! > 0) {
                              final rating = snapshot.data!;
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    size: 9,
                                    color: Colors.amber.shade700,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    rating.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: 9,
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
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Construit une grille alternée de produits : 2 produits côte à côte, puis 1 en pleine largeur, etc.
  Widget _buildAlternatingProductGrid(List<Product> products) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = 16.0;
    final availableWidth = screenWidth - (padding * 2);
    final spacing = 12.0;
    
    List<Widget> rows = [];
    int index = 0;
    
    while (index < products.length) {
      // Pattern: 2 produits côte à côte (chacun 50% de largeur)
      if (index < products.length) {
        final product1 = products[index];
        final product2 = index + 1 < products.length ? products[index + 1] : null;
        
        rows.add(
          Row(
            children: [
              Expanded(
                child: _buildProductCardWithWidth(
                  idVendeur: product1.vendeurId.toString(),
                  description: product1.description,
                  stock: product1.stock,
                  id: product1.id,
                  tag: product1.category?.name ?? '',
                  category: product1.category?.name ?? '',
                  name: product1.name,
                  price: product1.price,
                  imagePath: product1.getMainImage(),
                  product: product1,
                  heroTagSuffix: 'random_${index}',
                  width: double.infinity, // Sera géré par Expanded
                ),
              ),
              SizedBox(width: spacing),
              if (product2 != null)
                Expanded(
                  child: _buildProductCardWithWidth(
                    idVendeur: product2.vendeurId.toString(),
                    description: product2.description,
                    stock: product2.stock,
                    id: product2.id,
                    tag: product2.category?.name ?? '',
                    category: product2.category?.name ?? '',
                    name: product2.name,
                    price: product2.price,
                    imagePath: product2.getMainImage(),
                    product: product2,
                    heroTagSuffix: 'random_${index + 1}',
                    width: double.infinity, // Sera géré par Expanded
                  ),
                )
              else
                const Spacer(),
            ],
          ),
        );
        rows.add(SizedBox(height: spacing));
        index += 2;
      }
      
      // Pattern: 1 produit en pleine largeur
      if (index < products.length) {
        final product = products[index];
        rows.add(
          _buildProductCardWithWidth(
            idVendeur: product.vendeurId.toString(),
            description: product.description,
            stock: product.stock,
            id: product.id,
            tag: product.category?.name ?? '',
            category: product.category?.name ?? '',
            name: product.name,
            price: product.price,
            imagePath: product.getMainImage(),
            product: product,
            heroTagSuffix: 'random_$index',
            width: availableWidth,
          ),
        );
        if (index + 1 < products.length) {
          rows.add(SizedBox(height: spacing));
        }
        index += 1;
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
    );
  }

  /// Version de _buildProductCard avec largeur personnalisable
  Widget _buildProductCardWithWidth({
    required String idVendeur,
    required int id,
    required String description,
    required String tag,
    required String category,
    required int stock,
    required String name,
    required double price,
    required String imagePath,
    Product? product,
    String? heroTagSuffix,
    required double width,
  }) {
    return Builder(
      builder: (context) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = width == double.infinity ? constraints.maxWidth : width;
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailScreen(
                      description: description,
                      idVendeur: idVendeur,
                      id: id,
                      tag: tag,
                      category: category,
                      stock: stock,
                      name: name,
                      price: price,
                      imagePath: imagePath,
                      product: product,
                    ),
                  ),
                );
              },
              child: Container(
                width: width == double.infinity ? null : width,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Image container with tag overlay
                    Stack(
                      children: [
                        // Product image
                        Hero(
                          tag: heroTagSuffix != null 
                              ? 'product_${id}_${imagePath}_$heroTagSuffix'
                              : 'product_${id}_${imagePath}',
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                            child: Image.network(
                              imagePath,
                              height: width == double.infinity ? 200 : 160,
                              width: cardWidth,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  height: width == double.infinity ? 200 : 160,
                                  width: cardWidth,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      topRight: Radius.circular(16),
                                    ),
                                  ),
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
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: width == double.infinity ? 200 : 160,
                                  width: cardWidth,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      topRight: Radius.circular(16),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.shopping_bag_outlined,
                                    color: Colors.grey.shade400,
                                    size: 50,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        // Tag label
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.buttonColor2,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              tag,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        // Add to cart button
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: GestureDetector(
                            onTap: () async {
                              if (!_isAuthorizedUser() || !mounted) {
                                _checkAuthorizationAndRedirect();
                                return;
                              }

                              final newItem = {
                                'id': id,
                                'name': name,
                                'category': category,
                                'price': price,
                                'imagePath': imagePath,
                                'quantity': 1,
                                'stock': stock,
                                'idVendeur': idVendeur,
                                'description': description,
                              };

                              final success = await context.read<CartCubit>().addToCart(newItem);
                              if (!success) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Stock insuffisant : il ne reste que $stock en stock.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                                return;
                              }
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Produit ajouté au panier'),
                                    backgroundColor: AppColors.success,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.add_shopping_cart_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                  ],
                ),
                    // Product info
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      price.toString() + " FC",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.inventory_2_outlined,
                                          size: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          "$stock en stock",
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              FutureBuilder<double>(
                                future: ReviewService().getCachedAverageRating(id),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData && snapshot.data! > 0) {
                                    final rating = snapshot.data!;
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.star_rounded,
                                            size: 14,
                                            color: Colors.amber.shade700,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            rating.toStringAsFixed(1),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.amber.shade900,
                                            ),
                                          ),
                                        ],
                                      ),
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
              ],
            ),
          ),
        );
          },
        );
      },
    );
  }

  /// Construit une section de catégorie avec titre, bouton "Voir tout" et liste de produits
  Widget _buildCategorySection({
    required String title,
    required List<Product> products,
    List<Product>? allProducts, // Tous les produits pour "Voir tout"
    required Widget Function(Product, {double? width}) cardBuilder,
    required String categoryName,
    double? listHeight, // Hauteur personnalisée pour la liste
  }) {
    if (products.isEmpty) {
      return const SizedBox.shrink();
    }

    // Utiliser allProducts si fourni, sinon utiliser products
    final productsForViewAll = allProducts ?? products;
    
    // Déterminer la hauteur selon la catégorie
    final height = listHeight ?? 
                   (categoryName == 'Restaurants & Repas' ? 220.0 : 
                    categoryName == 'Mode, Beauté & Accessoires' ? 240.0 : 200.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: 0.3,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Naviguer vers l'écran "Voir tout" avec tous les produits
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CategoryProductsAllScreen(
                        categoryName: categoryName,
                        products: productsForViewAll,
                        cardBuilder: cardBuilder,
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Voir tout',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: height,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return cardBuilder(products[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Carte pour Restaurants & Repas - Design organique avec forme asymétrique (LARGE)
  Widget _buildRestaurantCard(Product product, {double? width}) {
    final cardWidth = width ?? 180.0; // Plus large
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              description: product.description,
              idVendeur: product.vendeurId.toString(),
              id: product.id,
              tag: product.category?.name ?? '',
              category: product.category?.name ?? '',
              stock: product.stock,
              name: product.name,
              price: product.price,
              imagePath: product.getMainImage(),
              product: product,
            ),
          ),
        );
      },
      child: Container(
        width: cardWidth,
        height: 220, // Hauteur fixe
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24), // Plus arrondi
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 5),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Image avec forme asymétrique organique
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ClipPath(
                clipper: _RestaurantImageClipper(),
                child: Container(
                  height: 150, // Plus haute
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Image.network(
                        product.getMainImage(),
                        height: 150,
                        width: cardWidth,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 150,
                            width: cardWidth,
                            color: Colors.grey.shade200,
                            child: Icon(
                              Icons.restaurant_menu,
                              color: Colors.grey.shade400,
                              size: 50,
                            ),
                          );
                        },
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.2),
                            ],
                          ),
                        ),
                      ),
                      // Badge organique arrondi
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.local_fire_department,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'HOT',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Section info en bas
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.attach_money,
                                size: 11,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                "${product.price} FC",
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add,
                            size: 16,
                            color: Colors.white,
                          ),
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

  /// Carte pour Mode, Beauté & Accessoires - Design élégant VERTICAL ÉTROIT (HAUTE)
  Widget _buildFashionCard(Product product, {double? width}) {
    final cardWidth = width ?? 140.0; // Plus étroite
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              description: product.description,
              idVendeur: product.vendeurId.toString(),
              id: product.id,
              tag: product.category?.name ?? '',
              category: product.category?.name ?? '',
              stock: product.stock,
              name: product.name,
              price: product.price,
              imagePath: product.getMainImage(),
              product: product,
            ),
          ),
        );
      },
      child: Container(
        width: cardWidth,
        height: 240, // Plus haute
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28), // Très arrondi
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image avec coins très arrondis
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                  child: Stack(
                    children: [
                      Image.network(
                        product.getMainImage(),
                        height: double.infinity,
                        width: cardWidth,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: double.infinity,
                            width: cardWidth,
                            color: Colors.grey.shade200,
                            child: Icon(
                              Icons.checkroom,
                              color: Colors.grey.shade400,
                              size: 40,
                            ),
                          );
                        },
                      ),
                      // Badge losange élégant
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Transform.rotate(
                          angle: 0.785398,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Transform.rotate(
                                angle: -0.785398,
                                child: Icon(
                                  Icons.star,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Section info compacte
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.attach_money,
                                  size: 10,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 2),
                                Flexible(
                                  child: Text(
                                    "${product.price} FC",
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add,
                            size: 14,
                            color: Colors.white,
                          ),
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

  /// Carte pour Téléphones & Accessoires - Design RECTANGULAIRE MODERNE (COMPACT)
  Widget _buildPhoneCard(Product product, {double? width}) {
    final cardWidth = width ?? 150.0; // Compact
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              description: product.description,
              idVendeur: product.vendeurId.toString(),
              id: product.id,
              tag: product.category?.name ?? '',
              category: product.category?.name ?? '',
              stock: product.stock,
              name: product.name,
              price: product.price,
              imagePath: product.getMainImage(),
              product: product,
            ),
          ),
        );
      },
      child: Container(
        width: cardWidth,
        height: 200, // Compact
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12), // Moins arrondi - rectangulaire
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image rectangulaire avec fond tech
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Stack(
                  children: [
                    // Image centrée
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        child: Image.network(
                          product.getMainImage(),
                          height: 100,
                          width: cardWidth * 0.8,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 100,
                              width: cardWidth * 0.8,
                              color: Colors.grey.shade200,
                              child: Icon(
                                Icons.smartphone,
                                color: Colors.grey.shade400,
                                size: 45,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    // Badge rectangulaire tech
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(6), // Rectangulaire arrondi
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.memory,
                              size: 10,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 3),
                            const Text(
                              'TECH',
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Section info compacte rectangulaire
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(6), // Rectangulaire
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.attach_money,
                                  size: 10,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 2),
                                Flexible(
                                  child: Text(
                                    "${product.price} FC",
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(4), // Carré arrondi
                          ),
                          child: Icon(
                            Icons.add,
                            size: 14,
                            color: Colors.white,
                          ),
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

  Widget _buildMerchantCard({
    required String name,
    required double rating,
    required String category,
    required String imagePath,
    required bool isVerified,
    required String id,
    required List<Map<String, dynamic>> products,
  }) {
    return Builder(
      builder: (context) => GestureDetector(
        onTap: () {
          // Print des données du marchand
          print('🏪 ========== DONNÉES DU MARCHAND CLIQUE ==========');
          print('🏪 Données du marchand:');
          print('  - id: $id');
          print('  - name: $name');
          print('  - rating: $rating');
          print('  - category: $category');
          print('  - imagePath: $imagePath');
          print('  - isVerified: $isVerified');
          print('🏪 Produits du marchand: ${products.length}');
          for (var i = 0; i < products.length && i < 3; i++) {
            final product = products[i];
            print('  - Produit ${i + 1}:');
            print('    * id: ${product['id']}');
            print('    * name: ${product['name']}');
            print('    * price: ${product['price']}');
            if (product['description'] != null) {
              print('    * description: ${product['description']}');
            }
          }
          if (products.length > 3) {
            print('  - ... et ${products.length - 3} autres produits');
          }
          print('🏪 ===========================================');
          
          // Naviguer vers VendeurDetailScreen pour utiliser le même endpoint que "tous les produits par marchand"
          final vendeurId = int.tryParse(id);
          if (vendeurId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VendeurDetailScreen(
                  vendeurId: vendeurId,
                ),
              ),
            );
          }
        },
        child: Container(
          width: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Merchant image
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: Image.network(
                      imagePath,
                      width: 200,
                      height: 85,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 200,
                          height: 85,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
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
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 200,
                          height: 85,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: Icon(
                            Icons.store_outlined,
                            color: Colors.grey.shade400,
                            size: 40,
                          ),
                        );
                      },
                    ),
                  ),
                  // Verified badge
                  if (isVerified)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.verified,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
              // Merchant details
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Merchant name
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Rating and products count
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 12,
                          color: Colors.amber.shade700,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        if (products.isNotEmpty) ...[
                          const SizedBox(width: 5),
                          Text(
                            '• ${products.length}',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom painter to draw wave at the bottom of header
// Smooth wave like Talabat design

class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();

    // Wave parameters - smooth and natural like Talabat
    double waveHeight = 20;
    double numberOfWaves = 1.5; // Fewer waves for smoother look

    // Start from bottom left corner
    path.moveTo(0, size.height);

    // Create very smooth wave like Talabat - using many points for perfect smoothness
    int points = 150; // Many points for ultra-smooth curve like Talabat

    for (int i = 0; i <= points; i++) {
      double x = (i / points) * size.width;
      double normalizedX = x / size.width;

      // Smooth sinusoidal wave
      double y = size.height -
          waveHeight *
              (1 + math.sin(normalizedX * numberOfWaves * 2 * math.pi)) /
              2;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Complete the path to create a filled shape
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter to draw a grid pattern for the map background
class MapPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw horizontal lines
    double horizontalSpacing = 15;
    for (double i = 0; i < size.height; i += horizontalSpacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    // Draw vertical lines
    double verticalSpacing = 15;
    for (double i = 0; i < size.width; i += verticalSpacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    // Draw diagonal lines for a more map-like appearance
    for (double i = -size.height;
        i < size.width + size.height;
        i += horizontalSpacing * 2) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class FeaturedProductShimmer extends StatelessWidget {
  const FeaturedProductShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return Container(
            width: 150,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shimmer image
                const Padding(
                  padding: const EdgeInsets.only(bottom: 0),
                  child: ShimmerLoading(
                    width: 150,
                    height: 100,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                ),
                // Shimmer text
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerLoading(
                          width: 60,
                          height: 12,
                          borderRadius: BorderRadius.circular(4)),
                      const SizedBox(height: 8),
                      ShimmerLoading(
                          width: 90,
                          height: 14,
                          borderRadius: BorderRadius.circular(4)),
                      const SizedBox(height: 8),
                      ShimmerLoading(
                          width: 40,
                          height: 12,
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
}

class MerchantShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => Container(
          width: 180,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

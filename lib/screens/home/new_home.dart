import 'package:flutter/material.dart';
import 'package:immo/constants.dart';
import 'package:immo/screens/home/all_merchants_screen.dart';
import 'package:immo/screens/navigation_example.dart';
import 'package:immo/screens/product/product_detail_screen.dart';
import '../merchant/merchant_profile_screen.dart';
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
      body: CustomScrollView(
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
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 16),
                              child: Text(
                                'Produits',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black),
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
                        const SizedBox(height: 12),
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

                  // Produits en promo section
                  const PromoProductsSection(),

                  // Produits recommandés section
                  const RecommendedProductsSection(),

                  // Top Marchands section
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                'Top Marchands',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black),
                              ),
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
                        const SizedBox(height: 12),

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
                                height: 100,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  itemCount: merchants.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 12),
                                  itemBuilder: (context, index) {
                                    final vendeur = merchants[index]['vendeur'];
                                    final products =
                                        (merchants[index]['products'] as List)
                                            .cast<Map<String, dynamic>>();
                                    final media = merchants[index]['media'];
                                    final image = media != null &&
                                            media['mediaUrl'] != null
                                        ? media['mediaUrl']
                                        : 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400&h=400&fit=crop';
                                    final name =
                                        '${vendeur['firstName']} ${vendeur['lastName']}';
                                    return GestureDetector(
                                      onTap: () {
                                        // Print des données du marchand
                                        print('🏪 ========== DONNÉES DU MARCHAND CLIQUE ==========');
                                        print('🏪 Marchand (vendeur):');
                                        print('  - id: ${vendeur['id']}');
                                        print('  - firstName: ${vendeur['firstName']}');
                                        print('  - lastName: ${vendeur['lastName']}');
                                        print('  - email: ${vendeur['email']}');
                                        print('  - phone: ${vendeur['phone']}');
                                        print('  - role: ${vendeur['role']}');
                                        print('  - userStatus: ${vendeur['userStatus']}');
                                        
                                        if (vendeur['profil'] != null) {
                                          print('  - profil:');
                                          print('    * id: ${vendeur['profil']['id']}');
                                          if (vendeur['profil']['media'] != null) {
                                            print('    * media:');
                                            print('      - id: ${vendeur['profil']['media']['id']}');
                                            print('      - mediaUrl: ${vendeur['profil']['media']['mediaUrl']}');
                                            print('      - mediaType: ${vendeur['profil']['media']['mediaType']}');
                                          }
                                        }
                                        
                                        if (media != null) {
                                          print('  - media (boutique):');
                                          print('    * id: ${media['id']}');
                                          print('    * mediaUrl: ${media['mediaUrl']}');
                                          print('    * mediaType: ${media['mediaType']}');
                                        }
                                        
                                        print('🏪 Produits du marchand: ${products.length}');
                                        for (var i = 0; i < products.length && i < 3; i++) {
                                          final product = products[i];
                                          print('  - Produit ${i + 1}:');
                                          print('    * id: ${product['id']}');
                                          print('    * name: ${product['name']}');
                                          print('    * price: ${product['price']}');
                                        }
                                        if (products.length > 3) {
                                          print('  - ... et ${products.length - 3} autres produits');
                                        }
                                        
                                        print('🏪 Données affichées:');
                                        print('  - name: $name');
                                        print('  - image: $image');
                                        print('  - rating: 4.5');
                                        print('  - isVerified: true');
                                        print('🏪 ===========================================');
                                        
                                        // Permettre l'accès aux profils de marchands sans connexion
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                MerchantProfileScreen(
                                              description: products.isNotEmpty
                                                  ? products[0]
                                                          ['description'] ??
                                                      ''
                                                  : '',
                                              merchantId: vendeur['id'],
                                              name: name,
                                              rating: 4.5,
                                              category: products.isNotEmpty
                                                  ? products[0]
                                                          ['description'] ??
                                                      ''
                                                  : '',
                                              imagePath: image,
                                              isVerified: true,
                                              products: products,
                                            ),
                                          ),
                                        );
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

                  // Map Section
                  if (_commandes.isNotEmpty || _currentPosition != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ma position',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 12),
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

              const SizedBox(height: 9), // Bottom padding
            ],
          ),
          ),
        ],
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
                      tag: 'product_${id}_${imagePath}',
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
                              color: Colors.grey.shade300,
                              child:
                                  const Icon(Icons.image, color: Colors.grey),
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
          
          // Permettre l'accès aux profils de marchands sans connexion
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MerchantProfileScreen(
                description: products.isNotEmpty
                    ? products[0]['description'] ?? ''
                    : '',
                merchantId: id,
                name: name,
                rating: rating,
                category: category,
                  imagePath: imagePath,
                  isVerified: isVerified,
                  products: products,
                ),
              ),
            );
        },
        child: Container(
          width: 180,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Merchant image
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
                child: Image.network(
                  imagePath,
                  width: 60,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 60,
                      height: 100,
                      color: Colors.grey.shade200,
                      child: Icon(Icons.store, color: Colors.grey.shade400),
                    );
                  },
                ),
              ),
              // Merchant details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Merchant name with verification badge
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isVerified) const SizedBox(width: 4),
                          if (isVerified)
                            const Icon(
                              Icons.verified,
                              color: AppColors.primary,
                              size: 14,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Rating
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            rating.toString(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Category
                      Text(
                        category,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
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

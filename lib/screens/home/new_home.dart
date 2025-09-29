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
import 'package:immo/cubit/category_cubit.dart';
import 'package:immo/widgets/shimmer_loading.dart';
import 'package:immo/cubit/merchant_cubit.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:immo/cubit/order_cubit.dart';
import 'package:immo/cubit/cart_cubit.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:immo/services/auth_gate_service.dart';
import 'package:immo/screens/auth/login_screen.dart';

class NewHomeScreen extends StatefulWidget {
  const NewHomeScreen({Key? key}) : super(key: key);

  @override
  State<NewHomeScreen> createState() => _NewHomeScreenState();
}

class _NewHomeScreenState extends State<NewHomeScreen> {
  Position? _currentPosition;
  bool _isLoading = false;
  List<dynamic> _commandes = [];

  @override
  void initState() {
    super.initState();
    // Attendre que l'AuthCubit soit initialisé avant de charger les données
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      print('🔄 NewHomeScreen: Initialisation des données...');
      
      // Attendre que l'AuthCubit soit initialisé
      int attempts = 0;
      while (attempts < 10) {
        final authState = context.read<AuthCubit>().state;
        print('🔍 NewHomeScreen: État AuthCubit (tentative ${attempts + 1}): ${authState.runtimeType}');
        
        if (authState is AuthSuccess && authState.token != null) {
          print('✅ NewHomeScreen: AuthCubit initialisé, chargement des données...');
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
      
      print('✅ NewHomeScreen: Données initialisées');
    } catch (e) {
      print('❌ NewHomeScreen: Erreur lors de l\'initialisation: $e');
    }
  }

  Future<void> _fetchUserMedia() async {
    try {
      print('🔄 NewHomeScreen: Récupération des médias utilisateur...');
      
      // Récupérer l'utilisateur connecté
      final authState = context.read<AuthCubit>().state;
      print('🔍 NewHomeScreen: État AuthCubit: ${authState.runtimeType}');
      
      if (authState is AuthSuccess && authState.user != null) {
        final userId = authState.user!['id']?.toString() ?? '';
        final token = authState.token;
        
        print('🔄 NewHomeScreen: Récupération des médias pour l\'utilisateur: $userId');
        
        if (userId.isNotEmpty && token != null) {
          // Requête pour récupérer les médias de l'utilisateur
          final response = await http.get(
            Uri.parse('http://24.144.87.127:3333/users/me'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          );
          
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            print('✅ NewHomeScreen: Médias récupérés: ${data['data']['media']}');
            
            // Mettre à jour les données utilisateur avec les médias
            if (data['data']['media'] != null) {
              final updatedUser = Map<String, dynamic>.from(authState.user!);
              updatedUser['media'] = data['data']['media'];
              
              // Mettre à jour l'état de l'authentification
              context.read<AuthCubit>().updateUser(updatedUser, token);
              print('✅ NewHomeScreen: Données utilisateur mises à jour');
            }
          } else {
            print('❌ NewHomeScreen: Erreur lors de la récupération des médias: ${response.statusCode}');
            print('❌ NewHomeScreen: Réponse: ${response.body}');
          }
        } else {
          print('❌ NewHomeScreen: Token ou userId manquant pour la récupération des médias');
          print('❌ NewHomeScreen: userId: $userId, token: ${token != null ? "présent" : "absent"}');
        }
      } else {
        print('❌ NewHomeScreen: Utilisateur non connecté ou AuthCubit non initialisé');
        print('❌ NewHomeScreen: authState: $authState');
      }
    } catch (e) {
      print('❌ NewHomeScreen: Erreur lors de la récupération des médias: $e');
    }
  }

  Future<void> _fetchOrdersAndLocation() async {
    try {
      print('🔄 NewHomeScreen: Récupération des commandes et localisation...');
      setState(() { _isLoading = true; });
      
      // Récupérer les commandes via OrderCubit
      final orderCubit = context.read<OrderCubit>();
      await orderCubit.fetchOrders();
      final commandes = orderCubit.orderListState.commandes;
      setState(() { _commandes = commandes; });
      
      print('📦 NewHomeScreen: Commandes récupérées: ${commandes.length}');
      
      if (commandes.isNotEmpty) {
        // Si au moins une commande, récupérer la position
        print('📍 NewHomeScreen: Récupération de la position...');
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          print('❌ NewHomeScreen: Service de localisation désactivé');
          setState(() { _isLoading = false; });
          return;
        }
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            print('❌ NewHomeScreen: Permission de localisation refusée');
            setState(() { _isLoading = false; });
            return;
          }
        }
        if (permission == LocationPermission.deniedForever) {
          print('❌ NewHomeScreen: Permission de localisation refusée définitivement');
          setState(() { _isLoading = false; });
          return;
        }
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        setState(() {
          _currentPosition = position;
          _isLoading = false;
        });
        print('✅ NewHomeScreen: Position récupérée: ${position.latitude}, ${position.longitude}');
      } else {
        setState(() { _isLoading = false; });
        print('ℹ️ NewHomeScreen: Aucune commande trouvée');
      }
    } catch (e) {
      print('❌ NewHomeScreen: Erreur lors de la récupération des commandes: $e');
      setState(() { _isLoading = false; });
    }
  }

  /// Affiche une boîte de dialogue de confirmation pour la déconnexion
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Déconnexion'),
          content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              child: const Text(
                'Déconnexion',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Vérifie si l'utilisateur est autorisé à effectuer des actions
  bool _isAuthorizedUser() {
    try {
      final authState = context.read<AuthCubit>().state;
      if (authState is AuthSuccess && authState.user != null) {
        final userPhone = authState.user!['phone']?.toString() ?? '';
        print('🔍 Vérification autorisation - Téléphone utilisateur: $userPhone');
        
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

  /// Redirige vers le login si l'utilisateur n'est pas autorisé
  void _checkAuthorizationAndRedirect() {
    if (!_isAuthorizedUser()) {
      print('🚫 Utilisateur non autorisé, redirection vers login...');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  /// Effectue la déconnexion et redirige vers l'écran de login
  Future<void> _logout() async {
    try {
      print('🔄 Déconnexion en cours...');
      
      // Effacer la session via AuthGateService
      final authGateService = AuthGateService();
      await authGateService.clearSession();
      
      // Effacer la session via AuthCubit
      if (mounted) {
        context.read<AuthCubit>().logout();
      }
      
      print('✅ Session effacée avec succès');
      
      // Rediriger vers l'écran de login
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      print('❌ Erreur lors de la déconnexion: $e');
      // Rediriger quand même vers l'écran de login
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: Image.asset(AppAssets.logo, width: 100, height: 100),
        actions: [
          // Bouton Logout
          // IconButton(
          //   onPressed: () => _showLogoutDialog(context),
          //   icon: const Icon(
          //     Icons.logout,
          //     color: AppColors.primary,
          //   ),
          //   tooltip: 'Déconnexion',
          // ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
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
                              builder: (context) => const SettingScreen()),
                        );
                      }
                    },
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.buttonColor2,
                      child: CircleAvatar(
                        radius: 17,
                        backgroundColor: AppColors.white,
                        backgroundImage:
                            NetworkImage(state.user!['media']),
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
                              builder: (context) => const SettingScreen()),
                        );
                      }
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        _checkAuthorizationAndRedirect();
                        if (_isAuthorizedUser()) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AllMerchantsScreen(),
                            ),
                          );
                        }
                      },
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Recherche',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            color: AppColors.primary,
                            height: 40,
                            width: 40,
                            child: const Icon(Icons.search, color: Colors.white, size: 20),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Trouvez ce dont vous avez besoin',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                ],
              ),
            ),

            // Category icons - scrollable
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: SizedBox(
                height: 40,
                child: BlocBuilder<CategoryCubit, CategoryState>(
                  builder: (context, state) {
                    if (state is CategoryLoading) {
                      return ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: 6,
                        separatorBuilder: (_, __) => const SizedBox(width: 16),
                        itemBuilder: (context, index) => ShimmerLoading(
                          width: 90,
                          height: 32,
                          borderRadius: BorderRadius.circular(60),
                        ),
                      );
                    }
                    if (state is CategoryLoaded) {
                      return ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: state.categories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 16),
                        itemBuilder: (context, index) {
                          final cat = state.categories[index];
                          return Container(
                            padding: const EdgeInsets.only(
                                right: 12, left: 3, top: 3, bottom: 3),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(60),
                              border: Border.all(color: AppColors.primary),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    border:
                                        Border.all(color: AppColors.primary),
                                    borderRadius: BorderRadius.circular(60),
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: Icon(Icons.category,
                                      color: Colors.grey.shade100, size: 10),
                                ),
                                const SizedBox(width: 4),
                                Text(cat.name,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          );
                        },
                      );
                    }
                    if (state is CategoryError) {
                      return Center(
                          child: Text(state.message,
                              style: const TextStyle(color: Colors.red)));
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),

            // Featured products section
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 16),
                        child: Text(
                          'Produits vedettes',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
                      ),
                      BlocBuilder<FeaturedProductCubit, FeaturedProductState>(
                        builder: (context, state) {
                          if (state is FeaturedProductLoaded &&
                              state.products.isNotEmpty) {
                            return TextButton(
                              onPressed: () {
                                _checkAuthorizationAndRedirect();
                                if (_isAuthorizedUser()) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AllProductsScreen(
                                          products: state.products.reversed.toList()),
                                    ),
                                  );
                                }
                              },
                              child: const Text('Voir tout',
                                  style: TextStyle(color: AppColors.primary)),
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
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            itemCount: products.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final product = products.reversed.toList()[index];
                              return _buildProductCard(
                                idVendeur: product.vendeurId.toString(),
                                stock: product.stock,
                                id: product.id,
                                tag: 'Nouveau',
                                category: 'Catégorie',
                                name: product.name,
                                price: product.price,
                                imagePath: product.media?.mediaUrl != null
                                    ? product.media!.mediaUrl
                                    : 'https://via.placeholder.com/150',
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

            // Top Marchands section
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
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
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _checkAuthorizationAndRedirect();
                          if (_isAuthorizedUser()) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AllMerchantsScreen(),
                              ),
                            );
                          }
                        },
                        child: const Text('Voir tout', style: TextStyle(color: AppColors.primary)),
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
                          return const Center(child: Text('Aucun marchand trouvé'));
                        }
                        return SizedBox(
                          height: 100,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            itemCount: merchants.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final vendeur = merchants[index]['vendeur'];
                              final products = (merchants[index]['products'] as List).cast<Map<String, dynamic>>();
                              final media = merchants[index]['media'];
                              final image = media != null && media['mediaUrl'] != null
                                  ? media['mediaUrl']
                                  : 'https://via.placeholder.com/150';
                              final name = '${vendeur['firstName']} ${vendeur['lastName']}';
                              return GestureDetector(
                                onTap: () {
                                  _checkAuthorizationAndRedirect();
                                  if (_isAuthorizedUser()) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MerchantProfileScreen(
                                          merchantId: vendeur['id'],
                                        name: name,
                                        rating: 4.5,
                                        category: products.isNotEmpty ? products[0]['description'] ?? '' : '',
                                        imagePath: image,
                                        isVerified: true,
                                        products: products,
                                      ),
                                    ),
                                  );
                                  }
                                },
                                child: _buildMerchantCard(
                                  id: vendeur['id'].toString(), // Convertir en String
                                  name: name,
                                  rating: 4.5,
                                  category: products.isNotEmpty ? products[0]['description'] ?? '' : '',
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
                        return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Text('Ma position', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: _isLoading
                  ? const SizedBox(
                      height: 150,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _commandes.isNotEmpty
                      ? MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: InkWell(
                            onTap: () {
                              _checkAuthorizationAndRedirect();
                              if (_isAuthorizedUser()) {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const NavigationExample(backNavigation: true)));
                              }
                            },
                            child: Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Stack(
                                  children: [
                                    _currentPosition == null
                                        ? const Center(child: Text('Impossible d\'obtenir la localisation', style: TextStyle(color: Colors.black54)))
                                        : GoogleMap(
                                            initialCameraPosition: CameraPosition(
                                              target: LatLng(
                                                _currentPosition!.latitude,
                                                _currentPosition!.longitude,
                                              ),
                                              zoom: 15,
                                            ),
                                            onMapCreated: (GoogleMapController controller) {
                                              // Map controller initialized
                                            },
                                            myLocationEnabled: true,
                                            myLocationButtonEnabled: true,
                                            zoomControlsEnabled: true,
                                            mapType: MapType.normal,
                                          ),
                                    // Overlay avec effet de survol
                                    Positioned.fill(
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () {
                                            _checkAuthorizationAndRedirect();
                                            if (_isAuthorizedUser()) {
                                              Navigator.push(context, MaterialPageRoute(builder: (context) => const NavigationExample(backNavigation: true)));
                                            }
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(12),
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.transparent,
                                                  Colors.black.withOpacity(0.3),
                                                ],
                                              ),
                                            ),
                                            child: const Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  Icon(
                                                    Icons.fullscreen,
                                                    color: Colors.white,
                                                    size: 24,
                                                  ),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    'Voir la carte en détail',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w600,
                                                      shadows: [
                                                        Shadow(
                                                          offset: Offset(0, 1),
                                                          blurRadius: 3,
                                                          color: Colors.black54,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  SizedBox(height: 16),
                                                ],
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
                        )
                      : Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomPaint(
                                painter: MapPatternPainter(),
                                size: Size.infinite,
                              ),
                              Icon(Icons.location_on, color: AppColors.primary.withOpacity(0.7)),
                              const Positioned(
                                bottom: 10,
                                child: Text(
                                  'Pas de livraison pour le moment',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                      color: Colors.black),
                                ),
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

  Widget _buildProductCard({
    required String idVendeur,
    required int id,
    required String tag,
    required String category,
    required int stock,
    required String name,
    required double price,
    required String imagePath,
  }) {
    return Builder(
      builder: (context) {
        return GestureDetector(
          onTap: () {
            _checkAuthorizationAndRedirect();
            if (_isAuthorizedUser()) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailScreen(
                    idVendeur: idVendeur,
                    id: id,
                    tag: tag,
                    category: category,
                    stock: stock,
                    name: name,
                    price: price,
                    imagePath: imagePath,
                  ),
                ),
              );
            }
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
              children: [
                // Image container with tag overlay
                Stack(
                  children: [
                    // Product image
                    Hero(
                      tag: imagePath,
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
                          style: const TextStyle(
                              fontSize: 10, color: Colors.white),
                        ),
                      ),
                    ),
                    // Add to cart button
                    Positioned(
                      bottom: 1,
                      right: 8,
                      child: GestureDetector(
                        onTap: () async {
                          _checkAuthorizationAndRedirect();
                          if (!_isAuthorizedUser()) return;
                          
                          final newItem = {
                            'id': id,
                            'name': name,
                            'category': category,
                            'price': price,
                            'imagePath': imagePath,
                            'quantity': 1,
                            'stock': stock,
                            'idVendeur': idVendeur,
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
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      Text(
                        name,
                        style: const TextStyle(fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "$stock en stock",
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        price.toString() + " FC",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.primary),
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
          _checkAuthorizationAndRedirect();
          if (_isAuthorizedUser()) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MerchantProfileScreen(
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
          }
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
                Padding(
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

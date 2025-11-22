import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:immo/cubit/listing_cubit.dart';
import 'package:immo/screens/cart/cart_screen.dart';
import 'package:immo/screens/express_livreur.dart';
import 'package:immo/screens/express_screen.dart';
import 'package:immo/screens/favoris_screen.dart';
import 'package:immo/screens/home/home_livreur.dart';
import 'package:immo/screens/home/home_marchant.dart';
import 'package:immo/screens/home/new_home.dart';
import 'package:immo/screens/home/voir_plus_produits.dart';
import 'package:immo/screens/navigation_example.dart';
import 'package:immo/screens/order_screen.dart';

import '../constants.dart';
import '../cubit/auth_cubit.dart';
import 'package:immo/widgets/cart_badge.dart';
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/version_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  int _previousIndex = 0;
  late final StreamController<void> _cartStreamController;

  final List<Widget> _screens = [
    const NewHomeScreen(),
    const CartScreen(backNavigaton: false),
    const FavorisScreen(),
    const HomeMarchantScreen(),
    const OrderScreen(backNavigation: false),
    const HomeLivreurScreen(),
    // const TrackingMapPage(),
    const NavigationExample(backNavigation: false),
    const VoirPlusProduitsScreen(),
    const ExpressScreen(),
    const ExpressLivreur(),
    const NavigationExample(backNavigation: false),
  ];

  static Future<void> saveTokenToFirestore(
      String token, AuthState authState) async {
    try {
      String? userId;
      String? role;

      if (authState is AuthSuccess && authState.user != null) {
        print('📱 AuthState user data: ${authState.user}');
        userId = authState.user!['id']?.toString();
        role = authState.user!['role'];
        print('📱 From AuthState - userId: $userId, role: $role');
      } else {
        final prefs = await SharedPreferences.getInstance();
        final userDataStr = prefs.getString('user_data');
        print('📱 SharedPreferences user data: $userDataStr');

        if (userDataStr != null) {
          try {
            final userData = jsonDecode(userDataStr);
            print('📱 Parsed user data: $userData');
            userId = userData['id']?.toString();
            role = userData['role'];
            print('📱 From SharedPreferences - userId: $userId, role: $role');
          } catch (e) {
            print('❌ Error parsing user data from SharedPreferences: $e');
          }
        }
      }

      if (userId == null) {
        print('❌ userId is null, cannot save token');
        return;
      }

      // Utiliser userId comme identifiant du document
      final docRef = FirebaseFirestore.instance.collection('tokens').doc(userId);
      await docRef.set({
        'token': token,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': Platform.isIOS ? 'ios' : 'android',
        'role': role ?? 'user',
        'userId': userId,
        'permission_status':
            (await FirebaseMessaging.instance.getNotificationSettings())
                .authorizationStatus
                .toString(),
      }, SetOptions(merge: true)); // merge pour ne pas effacer d'autres champs

      print("✅ Token saved to Firestore successfully (by userId)");
    } catch (e) {
      print("❌ Error saving token to Firestore: $e");
    }
  }

  Future<void> _initializeFirebaseMessaging() async {
    try {
      print("🚀 Initializing Firebase Messaging...");
      FirebaseMessaging messaging = FirebaseMessaging.instance;

      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: true,
      );

      print("📱 Notification settings: ${settings.authorizationStatus}");

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        messaging.onTokenRefresh.listen((String token) {
          print('🔄 FCM Token Refreshed: $token');
          saveTokenToFirestore(token, context.read<AuthCubit>().state);
        });

        String? token = await messaging.getToken();
        if (token != null) {
          print('✅ FCM Token received: $token');
          await saveTokenToFirestore(token, context.read<AuthCubit>().state);
        } else {
          print('⚠️ No FCM token received');
        }
      } else {
        print(
            "❌ Notification permissions not granted: ${settings.authorizationStatus}");
      }
    } catch (e) {
      print("❌ Error initializing Firebase Messaging: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _cartStreamController = StreamController<void>.broadcast();
    // Charger les données au démarrage
    context.read<ListingCubit>().getListings();
    _initializeFirebaseMessaging();
    
    // Vérifier la version après l'initialisation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      VersionService.checkForUpdate(context);
    });
  }

  @override
  void dispose() {
    _cartStreamController.close();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (!mounted) return;
    
    final authState = context.read<AuthCubit>().state;
    
    // Vérifier si l'utilisateur a le numéro spécifique
    if (authState is AuthSuccess && authState.user != null) {
      final userPhone = authState.user!['phone']?.toString();
      print('🔍 MainScreen: Vérification du numéro - $userPhone');
      
      if (userPhone == "+243842613999") {
        print('🚫 MainScreen: Utilisateur avec numéro restreint détecté, redirection vers login');
        // Rediriger vers le login
        context.read<AuthCubit>().logout();
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.login,
            (route) => false,
          );
        }
        return;
      }
    }

    if (mounted) {
      setState(() {
        _previousIndex = _currentIndex;
        _currentIndex = index;

        // Recharger les listings uniquement si on revient à la page d'accueil depuis une autre page
        if (index == 0 && _previousIndex != 0 && mounted) {
          context.read<ListingCubit>().getListings();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final bool isAcheteur = authState is AuthSuccess &&
        authState.user != null &&
        authState.user!['role'] == 'acheteur';
    final bool isVendeur = authState is AuthSuccess &&
        authState.user != null &&
        authState.user!['role'] == 'vendeur';
    final bool isLivreur = authState is AuthSuccess &&
        authState.user != null &&
        authState.user!['role'] == 'livreur';
    
    // Vérifier si l'utilisateur a le numéro restreint
    final bool isRestrictedUser = authState is AuthSuccess &&
        authState.user != null &&
        authState.user!['phone']?.toString() == "+243842613999";

    List<BottomNavigationBarItem> navigationItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        label: 'Accueil',
      ),
      const BottomNavigationBarItem(
        icon: CartBadge(),
        label: 'Panier',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.favorite_border),
        label: 'Favoris',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.shopping_bag_outlined),
        label: 'Commandes',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.place_outlined),
        label: 'Maps',
      ),
    ];

    // Filtrer les écrans en fonction du rôle
    List<Widget> filteredScreens = [];

    if (isAcheteur) {
      filteredScreens = [
        _screens[0], // NewHomeScreen
        _screens[1], // CartScreen
        _screens[2], // FavorisScreen
        _screens[4],
        _screens[6]
        // _screens[10]
        // HomeMarchantScreen
      ];
    } else if (isVendeur) {
      filteredScreens = [
        _screens[3], // HomeMarchantScreen
        _screens[7], // HomeMarchantScreen (pour l'onglet Produits)
        _screens[4],
        _screens[8], // HomeMarchantScreen (pour l'onglet Profil)
      ];
      navigationItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Produits'),
        BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_checkout), label: 'Commandes'),
        BottomNavigationBarItem(
            icon: Icon(Icons.bolt_outlined), label: 'Express'),
      ];
    } else if (isLivreur) {
      filteredScreens = [
        _screens[5],
        _screens[6],
        _screens[4],
        _screens[9],
        // _screens[10]
        // HomeLivreurScreen
        // CartScreen
        // HomeMarchantScreen
      ];
      navigationItems = const [
        BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined), label: 'Statistiques'),
        BottomNavigationBarItem(
            icon: Icon(Icons.place_outlined), label: 'Maps'),
        BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_checkout), label: 'Livraisons'),
        BottomNavigationBarItem(
            icon: Icon(Icons.bolt_outlined), label: 'Express'),
      ];
    } else {
      filteredScreens = _screens;
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: filteredScreens,
      ),
      // Cacher la barre de navigation pour l'utilisateur restreint
      bottomNavigationBar: isRestrictedUser ? null : BottomNavigationBar(
        backgroundColor: const Color.fromARGB(255, 250, 250, 250),
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        items: navigationItems,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
      ),
    );
  }

}

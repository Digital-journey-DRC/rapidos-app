import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:immo/cubit/listing_cubit.dart';
import 'package:immo/screens/cart/cart_screen.dart';
import 'package:immo/screens/favoris_screen.dart';
import 'package:immo/screens/home/home_livreur.dart';
import 'package:immo/screens/home/home_marchant.dart';
import 'package:immo/screens/home/new_home.dart';

import 'package:immo/screens/order_screen.dart';

import '../constants.dart';
import '../cubit/auth_cubit.dart';
import 'package:immo/widgets/cart_badge.dart';
import 'dart:async';

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
    // const DashboardScreen(),
    const NewHomeScreen(),
    const CartScreen(backNavigaton: false),
    const FavorisScreen(),
    const HomeMarchantScreen(),
    const OrderScreen(),
    const HomeLivreurScreen()
  ];

  @override
  void initState() {
    super.initState();
    _cartStreamController = StreamController<void>.broadcast();
    // Charger les données au démarrage
    context.read<ListingCubit>().getListings();
  }

  @override
  void dispose() {
    _cartStreamController.close();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = index;

      // Recharger les listings uniquement si on revient à la page d'accueil depuis une autre page
      if (index == 0 && _previousIndex != 0) {
        context.read<ListingCubit>().getListings();
      }
    });
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
        icon: Icon(Icons.message_outlined),
        label: 'Commandes',
      ),
    ];

    // Filtrer les écrans en fonction du rôle
    List<Widget> filteredScreens = [];

    if (isAcheteur) {
      filteredScreens = [
        _screens[0], // NewHomeScreen
        _screens[1], // CartScreen
        _screens[2], // FavorisScreen
        _screens[4], // HomeMarchantScreen
      ];
    } else if (isVendeur) {
      filteredScreens = [
        _screens[3], // HomeMarchantScreen
        // _screens[3], // HomeMarchantScreen (pour l'onglet Produits)
        _screens[4], // HomeMarchantScreen (pour l'onglet Profil)
      ];
      navigationItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
        BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_checkout), label: 'Commandes'),
      ];
    } else if (isLivreur) {
      filteredScreens = [
        _screens[5],
        _screens[4],
         // HomeLivreurScreen
         // CartScreen
        // HomeMarchantScreen
      ];
      navigationItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), label: 'Statistiques'),
        BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_checkout), label: 'Livraisons'),
        
        
      ];
    } else {
      filteredScreens = _screens;
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: filteredScreens,
      ),
      bottomNavigationBar: BottomNavigationBar(
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

  // Afficher une boîte de dialogue de confirmation avant la déconnexion
  void _confirmLogout(BuildContext context) {
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
                context.read<AuthCubit>().logout();
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.login,
                  (route) => false,
                );
              },
              child: const Text('Déconnexion',
                  style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}

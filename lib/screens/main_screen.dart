import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:immo/cubit/listing_cubit.dart';
import 'package:immo/screens/favoris_screen.dart';
import 'package:immo/screens/home/new_home.dart';
import 'package:immo/screens/messages_screen.dart';
import 'package:immo/screens/payment_screen.dart';
import 'package:immo/screens/rent_book.dart';
import '../constants.dart';
import '../cubit/auth_cubit.dart';
import 'home_screen.dart';
import 'dashboard/dashboard_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  int _previousIndex = 0;

  final List<Widget> _screens = [
    // const DashboardScreen(),
    const NewHomeScreen(),
    const FavorisScreen(),
    const FavorisScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Charger les données au démarrage
    context.read<ListingCubit>().getListings();
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
    final bool isLocataire = authState is AuthSuccess &&
        authState.user != null &&
        authState.user!['role'] == 'locataire';

    final List<BottomNavigationBarItem> navigationItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        label: 'Accueil',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.shopping_bag_outlined),
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

    // if (isLocataire) {
    //   filteredScreens.add(_screens[4]); // PaymentScreen
    //   filteredScreens.add(_screens[1]); // FavorisScreen
    //   filteredScreens.add(_screens[3]); // ListRentBook
    //   filteredScreens.add(_screens[0]); // HomeScreen (Découvrir)
    //   filteredScreens.add(_screens[5]); // MessagesScreen
    // } else {
    //   filteredScreens.add(_screens[2]); // DashboardScreen
    //   filteredScreens.add(_screens[0]); // HomeScreen (Découvrir)
    //   filteredScreens.add(_screens[1]); // FavorisScreen
    //   filteredScreens.add(_screens[5]); // MessagesScreen
    // }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
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

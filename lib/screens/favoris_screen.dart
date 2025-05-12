import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:immo/constants.dart';
import 'package:immo/cubit/auth_cubit.dart';
import 'package:immo/screens/dashboard/setting_screen.dart';
import '../repository/favorites_repository.dart';
import '../widgets/image_viewer.dart';
import 'property_detail_screen.dart';
import '../screens/home_screen.dart';

// Stream global pour les mises à jour des favoris
final favoritesUpdateStream = StreamController<void>.broadcast();

class FavorisScreen extends StatefulWidget {
  const FavorisScreen({super.key});

  @override
  State<FavorisScreen> createState() => _FavorisScreenState();
}

class _FavorisScreenState extends State<FavorisScreen> {
  late StreamSubscription _subscription;

  @override
  void initState() {
    super.initState();
    // S'abonner au stream pour les mises à jour
    _subscription = favoritesUpdateStream.stream.listen((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            if (state is AuthSuccess && 
                state.user != null && 
                state.user!['profileImage'] != null) {
              // Display profile image if available
              return CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.white,
                child: CircleAvatar(
                  radius: 23,
                  backgroundColor: AppColors.buttonColor,
                  backgroundImage: NetworkImage(state.user!['profileImage']),
                  child: IconButton(
                    icon: const Icon(Icons.person, color: Colors.transparent),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SettingScreen()));
                    },
                  ),
                ),
              );
            } else {
              // Show default person icon if no profile image
              return CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.white,
                child: CircleAvatar(
                  radius: 23,
                  backgroundColor: AppColors.buttonColor,
                  child: CircleAvatar(
                    backgroundColor: AppColors.white,
                    child: IconButton(
                      icon: const Icon(Icons.person, color: AppColors.buttonColor),
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SettingScreen()));
                      },
                    ),
                  ),
                ),
              );
            }
          },
        ),
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Text('Mes Favoris',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: FavoritesRepository.getFavorites(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final favoris = snapshot.data ?? [];

          if (favoris.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.buttonColor.withOpacity(0.3), width: 2),
                      color: Colors.white,
                    ),
                    child: Icon(
                      Icons.favorite_border,
                      size: 80,
                      color: AppColors.buttonColor.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Aucun favori pour le moment',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.buttonColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      'Explorez nos propriétés et ajoutez-les à vos favoris pour les retrouver ici',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favoris.length,
            itemBuilder: (context, index) {
              final property = Property.fromJson(favoris[index]);
              return Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.buttonColor, width: 2),
                    borderRadius: BorderRadius.circular(20)),
                margin: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PropertyDetailScreen(
                          property: property,
                        ),
                      ),
                    ).then((_) => setState(() {}));
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        child: Stack(
                          children: [
                            ImageViewerWidget(
                              url: property.images[0],
                              width: double.infinity,
                              height: 200,
                              imageFit: BoxFit.cover,
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: CircleAvatar(
                                backgroundColor: Colors.white,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.favorite,
                                    color: Colors.red,
                                  ),
                                  onPressed: () async {
                                    await FavoritesRepository.toggleFavorite(
                                      favoris[index],
                                    );
                                    favoritesUpdateStream.add(null);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text('Retiré des favoris'),
                                          behavior: SnackBarBehavior.floating,
                                          margin: EdgeInsets.all(16),
                                          backgroundColor: Colors.grey,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              property.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              property.location,
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${property.price.toInt()} \$ /mois',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
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
      ),
    );
  }
}

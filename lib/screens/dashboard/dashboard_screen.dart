import 'dart:async';

import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:immo/cubit/auth_cubit.dart';
import 'package:immo/cubits/building/building_cubit.dart';
import 'package:immo/cubits/building/building_state.dart';
import 'package:immo/screens/building_detail_screen.dart';
import 'package:immo/screens/dashboard/MaintenanceMonitoring.dart';
import 'package:immo/screens/dashboard/facture_page.dart';
import 'package:immo/screens/dashboard/listing_monitoring.dart';
import 'package:immo/screens/dashboard/rent_book_monitoring.dart';
import 'package:immo/screens/dashboard/setting_screen.dart';
import 'package:immo/services/building_service.dart';
import 'package:immo/widgets/custom_skeletons.dart';
import 'package:immo/widgets/image_viewer.dart';
import 'package:multi_select_flutter/chip_display/multi_select_chip_display.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';
import 'package:multi_select_flutter/util/multi_select_list_type.dart';
import '../../constants.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  final BuildingCubit _buildingCubit = BuildingCubit(BuildingService());
  final _formKey = GlobalKey<FormState>();
  Country? selectedCountry;
  final List<String> _selectedFeatures = [];

  // List of available features
  final List<String> _availableFeatures = [
    'ascenseur',
    'parking',
    'gardien',
    'piscine',
    'gym',
    'jardin',
  ];
  
  // Controllers pour le formulaire
  final _nameController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _availableApartmentsController = TextEditingController();
  final _constructionYearController = TextEditingController();

  // Ajouter un compteur pour forcer le refresh (méthode brutale mais efficace)
  int _refreshCounter = 0;
  
  // StreamSubscription pour écouter les événements d'upload d'images
  StreamSubscription? _imageUploadSubscription;
  
  @override
  void initState() {
    super.initState();
    _initializeData();
    
    // S'abonner au stream de téléchargement d'images réussi
    _imageUploadSubscription = BuildingCubit.imageUploadSuccess.listen((buildingId) {
      print('📣 Notification reçue: téléchargement d\'images réussi pour le bâtiment $buildingId');
      // Rafraîchir la liste des bâtiments
      _refreshBuildings();
    });
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _descriptionController.dispose();
    _availableApartmentsController.dispose();
    _constructionYearController.dispose();
    _buildingCubit.close();
    
    // Annuler l'abonnement au stream
    _imageUploadSubscription?.cancel();
    
    super.dispose();
  }

  // Méthode explicite pour rafraîchir la liste des bâtiments
  Future<void> _refreshBuildings() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthSuccess) {
      try {
        // Recharger les données
        await _buildingCubit.loadUserBuildings(
          authState.user!['id'],
          authState.token ?? '',
        );
        
        // Forcer un rebuild de l'UI
        if (mounted) {
          setState(() {
            _refreshCounter++;
            print('🔄 Rafraîchissement forcé: $_refreshCounter');
          });
        }
      } catch (e) {
        print('❌ Erreur lors du rafraîchissement: $e');
      }
    }
  }

  void _initializeData() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthSuccess) {
      final userId = authState.user?['id'];
      final token = authState.token;
      if (userId != null && token != null) {
        await _buildingCubit.loadUserBuildings(userId, token);
      }
    }
  }

  void _showYearPicker(BuildContext context) {
    final int currentYear = DateTime.now().year;
    final int startYear = 1900;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          child: ListView.builder(
            itemCount: (currentYear - startYear) + 1,
            itemBuilder: (context, index) {
              final int year = currentYear - index;
              return ListTile(
                title: Text(year.toString(), textAlign: TextAlign.center),
                onTap: () {
                  setState(() {
                    _constructionYearController.text = year.toString();
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _buildingCubit,
      child: BlocListener<BuildingCubit, BuildingState>(
        listener: (context, state) async {
          if (state is BuildingSuccess) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Résidence ajoutée avec succès'),
                backgroundColor: Colors.green,
              ),
            );
            final authState = context.read<AuthCubit>().state;
            if (authState is AuthSuccess) {
              final buildingCubit = context.read<BuildingCubit>();
              await buildingCubit.loadUserBuildings(
                authState.user!['id'],
                authState.token ?? '',
              );
            }
          } else if (state is BuildingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Scaffold(
          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FloatingActionButton.extended(
                onPressed: () => _showAddBuildingDialog(context),
                icon: const Icon(
                  Icons.add_home_work,
                  color: Colors.white,
                ),
                label: const Text('Nouvelle propriété',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white)),
                backgroundColor: AppColors.buttonColor,
                heroTag: 'publish',
              ),
            ],
          ),
          backgroundColor: AppColors.background,
          body: BlocBuilder<AuthCubit, AuthState>(
            builder: (context, authState) {
              if (authState is AuthSuccess) {
                return RefreshIndicator(
                  onRefresh: _refreshBuildings,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 0.0, vertical: 0.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 24),
                          _buildQuickActions(),
                          const SizedBox(height: 24),
                          _buildMyProperties(),
                          const SizedBox(height: 24),
                          // _buildRecentTransactions(),
                          // Ajouter un espace en bas pour le scroll
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                );
              } else {
                return const Center(child: Text('Veuillez vous connecter'));
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // color: AppColors.buttonColor,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.buttonColor,
            Color.fromARGB(255, 230, 98, 88),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        // borderRadius:  BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 50),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tableau de bord',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gérez vos biens immobiliers',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.white,
                child: CircleAvatar(
                  radius: 23,
                  backgroundColor: AppColors.buttonColor,
                  child: BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) {
                      if (state is AuthSuccess && 
                          state.user != null && 
                          state.user!['profileImage'] != null) {
                        // Display profile image if available
                        return CircleAvatar(
                          backgroundColor: AppColors.white,
                          backgroundImage: NetworkImage(state.user!['profileImage']),
                          child: IconButton(
                            icon: const Icon(Icons.person, color: Colors.transparent),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const SettingScreen()),
                              );
                            },
                          ),
                        );
                      } else {
                        // Show default person icon if no profile image
                        return CircleAvatar(
                          backgroundColor: AppColors.white,
                          child: IconButton(
                            icon: const Icon(Icons.person,
                                color: AppColors.buttonColor),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const SettingScreen()),
                              );
                            },
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: BlocBuilder<BuildingCubit, BuildingState>(
              builder: (context, state) {
                print('Current BuildingState: $state'); // Debug print

                if (state is BuildingInitial) {
                  final authState = context.read<AuthCubit>().state;
                  if (authState is AuthSuccess) {
                    final userId = authState.user?['id'];
                    final token = authState.token;
                    if (userId != null && token != null) {
                      print(
                          'Loading buildings for user: $userId'); // Debug print
                      context
                          .read<BuildingCubit>()
                          .loadUserBuildings(userId, token);
                    }
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        SkeletonItem(
                          child: Column(
                            children: [
                              SkeletonAvatar(
                                style: SkeletonAvatarStyle(
                                  width: 30,
                                  height: 30,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SkeletonLine(
                                style: SkeletonLineStyle(
                                  width: 50,
                                  height: 12,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SkeletonItem(
                          child: Column(
                            children: [
                              SkeletonAvatar(
                                style: SkeletonAvatarStyle(
                                  width: 30,
                                  height: 30,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SkeletonLine(
                                style: SkeletonLineStyle(
                                  width: 80,
                                  height: 12,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (state is BuildingLoading) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        SkeletonItem(
                          child: Column(
                            children: [
                              SkeletonAvatar(
                                style: SkeletonAvatarStyle(
                                  width: 30,
                                  height: 30,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SkeletonLine(
                                style: SkeletonLineStyle(
                                  width: 50,
                                  height: 12,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SkeletonItem(
                          child: Column(
                            children: [
                              SkeletonAvatar(
                                style: SkeletonAvatarStyle(
                                  width: 30,
                                  height: 30,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SkeletonLine(
                                style: SkeletonLineStyle(
                                  width: 80,
                                  height: 12,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (state is BuildingError) {
                  return Center(child: Text(state.message));
                }

                if (state is BuildingsLoaded) {
                  print(
                      'BuildingsLoaded - Total: ${state.total}, Apartments: ${state.totalApartments}'); // Debug print
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat('Résidences', '${state.total}'),
                      const SizedBox(width: 16),
                      _buildStat('Appartements', '${state.totalApartments}'),
                    ],
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat('Résidences', '0'),
                    const SizedBox(width: 16),
                    _buildStat('Appartements', '0'),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions rapides',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                icon: Icons.add_home_work,
                label: 'Propriétés',
                onTap: () => _showAddBuildingDialog(context),
              ),
              _buildActionButton(
                icon: Icons.payment,
                label: 'Factures',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const FacturePage()),
                  );
                },
              ),
              _buildActionButton(
                icon: Icons.campaign,
                label: 'Annonces',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ListingMonitoring()),
                  );
                },
              ),
              _buildActionButton(
                icon: Icons.build,
                label: 'Maintenances',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const MaintenanceMonitoring()),
                  );
                },
              ),
              _buildActionButton(
                icon: Icons.analytics,
                label: 'Carnet de loyer',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const RentBookMonitoring()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 70,
      height: 75,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.buttonColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyProperties() {
    final authCubit = context.read<AuthCubit>();
    final authState = authCubit.state;

    if (authState is! AuthSuccess) {
      return const Center(child: Text('Veuillez vous connecter'));
    }

    final userId = authState.user?['id'];
    final token = authState.token;

    if (userId == null || token == null) {
      return const Center(child: Text('Informations utilisateur manquantes'));
    }

    return BlocBuilder<BuildingCubit, BuildingState>(
      builder: (context, state) {
        if (state is BuildingInitial) {
          final authState = context.read<AuthCubit>().state;
          if (authState is AuthSuccess) {
            final userId = authState.user?['id'];
            final token = authState.token;
            if (userId != null && token != null) {
              _buildingCubit.loadUserBuildings(userId, token);
            }
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mes propriétés',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    // Skeleton loading for total count
                    SkeletonLine(
                      style: SkeletonLineStyle(
                        width: 60,
                        height: 14,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSkeletonBuildingCards(),
              ],
            ),
          );
        }

        if (state is BuildingLoading) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mes propriétés',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    // Skeleton loading for total count
                    SkeletonLine(
                      style: SkeletonLineStyle(
                        width: 60,
                        height: 14,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSkeletonBuildingCards(),
              ],
            ),
          );
        }

        if (state is BuildingError) {
          return Center(child: Text(state.message));
        }

        if (state is BuildingsLoaded) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mes propriétés',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'Total: ${state.total}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (state.buildings.isEmpty)
                  _buildSkeletonBuildingCards()
                else
                  SizedBox(
                    height: 220,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: state.buildings.length,
                      itemBuilder: (context, index) {
                        final building = state.buildings[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BuildingDetailScreen(
                                  building: building,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: 200,
                            margin:
                                const EdgeInsets.only(right: 16, bottom: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ImageViewerWidget(
                                  height: 120,
                                  width: MediaQuery.of(context).size.width,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                  ),
                                  url: building.images != null &&
                                          building.images!.isNotEmpty
                                      ? building.images![0]
                                      : 'https://via.placeholder.com/400',
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        building.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${building.address.city}, ${building.address.country}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                
              ],
            ),
          );
        }

        return const Center(child: Text('État inconnu'));
      },
    );
  }

  Widget _buildSkeletonBuildingCards() {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3, // Show 3 skeleton cards
        itemBuilder: (context, index) {
          return Container(
            width: 200,
            margin: const EdgeInsets.only(right: 16, bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image skeleton
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: SkeletonAvatar(
                    style: SkeletonAvatarStyle(
                      width: double.infinity,
                      height: 120,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                  ),
                ),
                // Text content skeleton
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Building name skeleton
                      SkeletonLine(
                        style: SkeletonLineStyle(
                          width: 150,
                          height: 16,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Building location skeleton
                      SkeletonLine(
                        style: SkeletonLineStyle(
                          width: 120,
                          height: 12,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
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

  void _showAddBuildingDialog(BuildContext context) {
    final buildingCubit = context.read<BuildingCubit>();
    final authState = context.read<AuthCubit>().state;

    if (authState is! AuthSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous devez être connecté pour ajouter une propriété'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final userId = authState.user?['id'];
    buildingCubit.setCurrentUserId(userId);
    
    // Réinitialiser les controllers
    _nameController.clear();
    _streetController.clear();
    _cityController.clear();
    _postalCodeController.clear();
    _descriptionController.clear();
    _constructionYearController.clear();
    _selectedFeatures.clear();
    selectedCountry = null;

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ajouter une propriété',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  TextFormField(
                    controller: _nameController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un nom';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Nom de la résidence',
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      labelStyle: const TextStyle(color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _streetController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer une rue';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Rue',
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      labelStyle: const TextStyle(color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _cityController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer une ville';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Ville',
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      labelStyle: const TextStyle(color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _postalCodeController,
                    validator: (value) {
                      // if (value == null || value.isEmpty) {
                      //   return 'Veuillez entrer un code postal';
                      // }
                      // return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Code postal',
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      labelStyle: const TextStyle(color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  StatefulBuilder(
                    builder: (context, setState) => InkWell(
                      onTap: () {
                        showCountryPicker(
                          context: context,
                          showPhoneCode: false,
                          favorite: <String>['CD'],
                          countryListTheme: CountryListThemeData(
                            flagSize: 25,
                            backgroundColor: Colors.white,
                            textStyle: const TextStyle(
                                fontSize: 16, color: Colors.black),
                            bottomSheetHeight: 500,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20.0),
                              topRight: Radius.circular(20.0),
                            ),
                            inputDecoration: InputDecoration(
                              labelText: 'Rechercher un pays',
                              hintText: 'Tapez pour rechercher',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: AppColors.primary.withOpacity(0.2),
                                ),
                              ),
                            ),
                          ),
                          onSelect: (Country pays) {
                            setState(() {
                              selectedCountry = pays;
                            });
                          },
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            if (selectedCountry != null) ...[
                              Text(
                                selectedCountry!.flagEmoji,
                                style: const TextStyle(fontSize: 25),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                selectedCountry!.name,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 16,
                                ),
                              ),
                            ] else
                              Text(
                                'Sélectionner un pays',
                                style: TextStyle(
                                  color: AppColors.primary.withOpacity(0.5),
                                  fontSize: 16,
                                ),
                              ),
                            const Spacer(),
                            const Icon(
                              Icons.arrow_drop_down,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer une description';
                      }
                      return null;
                    },
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      labelStyle: const TextStyle(color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  MultiSelectDialogField<String>(
                    items: _availableFeatures
                        .map((feature) => MultiSelectItem<String>(feature,
                            feature[0].toUpperCase() + feature.substring(1)))
                        .toList(),
                    listType: MultiSelectListType.CHIP,
                    cancelText: const Text('Annuler'),
                    selectedItemsTextStyle:
                        const TextStyle(color: Colors.white),
                    onConfirm: (values) {
                      setState(() {
                        _selectedFeatures.clear();
                        _selectedFeatures.addAll(values);
                      });
                    },
                    validator: (values) {
                      if (values == null || values.isEmpty) {
                        return 'Veuillez sélectionner au moins une caractéristique';
                      }
                      return null;
                    },
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    buttonText: const Text(
                      'Caractéristiques',
                      style: TextStyle(color: AppColors.primary),
                    ),
                    title: const Text('Caractéristiques'),
                    selectedColor: AppColors.primary,
                    chipDisplay: MultiSelectChipDisplay(
                      onTap: (value) {
                        setState(() {
                          _selectedFeatures.remove(value);
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _constructionYearController,
                    readOnly: true,
                    onTap: () => _showYearPicker(context),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez sélectionner une année';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Année de construction',
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: const Icon(Icons.calendar_today,
                          color: AppColors.primary),
                      labelStyle: const TextStyle(color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      BlocListener<BuildingCubit, BuildingState>(
                        listener: (context, state) async {
                          if (state is BuildingSuccess) {
                            // Fermer d'abord le dialogue
                            Navigator.of(context).pop();
                            
                            // Afficher le message de succès
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Résidence ajoutée avec succès'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            
                            // Attendre un court délai pour être sûr que l'API a enregistré les modifications
                            await Future.delayed(const Duration(milliseconds: 300));
                            
                            // Rafraîchir explicitement la liste
                            await _refreshBuildings();
                          } else if (state is BuildingError) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(state.message),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        child: BlocBuilder<BuildingCubit, BuildingState>(
                          builder: (context, state) {
                            return ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.buttonColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: state is BuildingLoading
                                  ? null
                                  : () async {
                                      if (_formKey.currentState!.validate() &&
                                          selectedCountry != null) {
                                        // Set default postal code "0012" if empty
                                        if (_postalCodeController.text.isEmpty) {
                                          _postalCodeController.text = "0012";
                                        }
                                        
                                        await buildingCubit.createBuilding(
                                          name: _nameController.text,
                                          street: _streetController.text,
                                          city: _cityController.text,
                                          postalCode:
                                              _postalCodeController.text,
                                          country: selectedCountry!.name,
                                          description:
                                              _descriptionController.text,
                                          features: _selectedFeatures,
                                          totalApartments: 0,
                                          availableApartments: 0,
                                          constructionYear: int.parse(
                                              _constructionYearController.text),
                                          token: authState.token ?? '',
                                        );
                                      }
                                    },
                              child: state is BuildingLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Enregistrer',
                                      style: TextStyle(color: Colors.white)),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                        child: const Text('Annuler'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:immo/constants.dart';
import 'package:immo/cubit/auth_cubit.dart';
import 'package:immo/cubits/building/building_cubit.dart';
import 'package:immo/cubits/building/building_state.dart';
import 'package:immo/screens/dashboard/select_facture_page.dart';
import 'package:immo/widgets/image_viewer.dart';

class FacturePage extends StatefulWidget {
  const FacturePage({super.key});

  @override
  State<FacturePage> createState() => _FacturePageState();
}

class _FacturePageState extends State<FacturePage> {
  @override
  void initState() {
    super.initState();
    _loadBuildings();
  }

  void _loadBuildings() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthSuccess && authState.token != null && authState.user != null) {
      final userId = authState.user!['id'];
      context.read<BuildingCubit>().loadUserBuildings(userId, authState.token!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    bool isAuthenticated = authState is AuthSuccess && authState.token != null;

    if (!isAuthenticated) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text('Veuillez vous connecter pour accéder à vos bâtiments'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: true,
        title: const Text('Mes propriétés',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBuildings,
          ),
        ],
      ),
      body: BlocBuilder<BuildingCubit, BuildingState>(
        builder: (context, state) {
          if (state is BuildingLoading) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title skeleton
                  Container(
                    width: 200,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Buildings list skeletons
                  Column(
                    children: List.generate(3, (index) {
                      return Card(
                        color: Colors.grey.withOpacity(0.1),
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(
                            color: AppColors.buttonColor,
                            width: 2,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Image skeleton with border
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: const Border.fromBorderSide(
                                    BorderSide(
                                      color: AppColors.buttonColor,
                                      width: 1,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              
                              // Content column on the right
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Building name skeleton
                                    Container(
                                      width: 180,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    
                                    // Address skeleton
                                    Container(
                                      width: 150,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    
                                    // Info chips row
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        // First info chip skeleton
                                        Container(
                                          height: 28,
                                          width: 100,
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                        ),
                                        
                                        // Second info chip skeleton
                                        Container(
                                          height: 28,
                                          width: 120,
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(14),
                                          ),
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
                    }),
                  ),
                ],
              ),
            );
          } else if (state is BuildingError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur: ${state.message}',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadBuildings,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          } else if (state is BuildingsLoaded) {
            if (state.buildings.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.home_work_outlined, size: 60, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Aucun bâtiment trouvé',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Vous n\'avez pas encore de bâtiment enregistré',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: state.buildings.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final building = state.buildings[index];
                final image = (building.images != null && building.images!.isNotEmpty)
                    ? building.images![0]
                    : 'https://via.placeholder.com/150';

                return Card(
                  color: Colors.grey.withOpacity(0.1),
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(
                      color: AppColors.buttonColor,
                      width: 2,
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SelectPageFacture(
                            building: building,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          ImageViewerWidget(
                              url: image,
                              width: 80,
                              height: 80,
                              borderRadius: BorderRadius.circular(12),
                              border: const Border.fromBorderSide(
                                BorderSide(
                                  color: AppColors.buttonColor,
                                  width: 1,
                                ),
                              )),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  building.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${building.address.city}, ${building.address.country}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _buildInfoChip(
                                      '${building.totalApartments} Appartements',
                                      Icons.apartment,
                                    ),
                                    const SizedBox(width: 8),
                                    _buildInfoChip(
                                      '${building.availableApartments} Disponibles',
                                      Icons.check_circle_outline,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Icon(
                          //   Icons.arrow_forward_ios,
                          //   size: 16,
                          //   color: Colors.grey.shade600,
                          // ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }

          return const Center(child: Text('État inconnu'));
        },
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        // color: AppColors.primary.withOpacity(0.1),
        color: AppColors.buttonColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
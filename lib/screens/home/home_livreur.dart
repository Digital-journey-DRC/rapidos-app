import 'package:flutter/material.dart';
import 'package:immo/constants.dart';
import 'package:immo/widgets/app_logo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:immo/cubit/auth_cubit.dart';
import 'package:immo/screens/dashboard/setting_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:immo/screens/navigation_example.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:immo/screens/home/new_home.dart';
import 'package:immo/services/delivery_statistics_service.dart';
import 'package:immo/screens/statistics/delivery_statistics_detail_screen.dart';
import 'package:intl/intl.dart';

class HomeLivreurScreen extends StatefulWidget {
  const HomeLivreurScreen({Key? key}) : super(key: key);

  @override
  State<HomeLivreurScreen> createState() => _HomeLivreurScreenState();
}

class _HomeLivreurScreenState extends State<HomeLivreurScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _checkLivreurStatus();
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;
    setState(() { _isLoading = true; });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() { _isLoading = false; });
        }
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() { _isLoading = false; });
          }
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() { _isLoading = false; });
        }
        return;
      }
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  Future<void> _checkLivreurStatus() async {
    if (!mounted) return;
    try {
      // Récupérer l'utilisateur connecté
      final authState = context.read<AuthCubit>().state;
      if (authState is AuthSuccess && authState.user != null) {
        final userId = authState.user!['id']?.toString() ?? '';
        final userName = '${authState.user!['firstName'] ?? ''} ${authState.user!['lastName'] ?? ''}';
        
        print('🔍 Vérification du statut pour le livreur: $userName (ID: $userId)');
        
        if (userId.isNotEmpty) {
          // Vérifier si un enregistrement existe déjà pour ce livreur
          final statusQuery = await FirebaseFirestore.instance
              .collection('status')
              .where('userId', isEqualTo: userId)
              .get();

          print('📊 Nombre de documents trouvés pour userId $userId: ${statusQuery.docs.length}');

          if (statusQuery.docs.isNotEmpty) {
            // Récupérer le statut existant
            final statusDoc = statusQuery.docs.first;
            final statusData = statusDoc.data();
            final status = statusData['status'];
            final lastUpdated = statusData['lastUpdated'];
            
            print('✅ Statut trouvé pour le livreur $userName: $status');
            print('📅 Dernière mise à jour: $lastUpdated');
            print('📋 Données complètes: $statusData');
            print('🆔 Document ID: ${statusDoc.id}');
            
            // Vérifier si le statut est false et afficher le popup
            if (status == false && mounted) {
              print('⚠️ Statut false détecté, affichage du popup');
              _showStatusPopup();
            }
            
            // Si plusieurs documents existent, supprimer les doublons
            if (statusQuery.docs.length > 1) {
              print('⚠️ ATTENTION: ${statusQuery.docs.length} documents trouvés pour le même userId!');
              print('🗑️ Suppression des doublons...');
              
              // Garder le premier document et supprimer les autres
              for (int i = 1; i < statusQuery.docs.length; i++) {
                await statusQuery.docs[i].reference.delete();
                print('🗑️ Document supprimé: ${statusQuery.docs[i].id}');
              }
              print('✅ Nettoyage terminé, ${statusQuery.docs.length - 1} doublons supprimés');
            }
          } else {
            // Créer un nouvel enregistrement de statut
            print('📝 Aucun statut trouvé, création d\'un nouveau statut pour $userName');
            
            final newStatusData = {
              'userId': userId,
              'userName': userName,
              'status': false, // Statut par défaut
              'lastUpdated': FieldValue.serverTimestamp(),
              'createdAt': FieldValue.serverTimestamp(),
              'role': 'livreur',
            };
            
            // Utiliser setDoc avec merge pour éviter les doublons
            final docRef = FirebaseFirestore.instance
                .collection('status')
                .doc(userId); // Utiliser userId comme document ID
            
            await docRef.set(newStatusData, SetOptions(merge: true));
            
            print('✅ Nouveau statut créé avec succès!');
            print('🆔 ID du document: ${docRef.id}');
            print('📋 Données créées: $newStatusData');
            
            // Afficher le popup car le statut par défaut est false
            if (mounted) {
              _showStatusPopup();
            }
          }
        } else {
          print('❌ ID utilisateur non trouvé');
        }
      } else {
        print('❌ Utilisateur non connecté');
      }
    } catch (e) {
      print('❌ Erreur lors de la vérification du statut: $e');
      print('❌ Stack trace: ${StackTrace.current}');
    }
  }

  void _showStatusPopup() {
    showDialog(
      context: context,
      barrierDismissible: false, // Empêcher la fermeture en cliquant à l'extérieur
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.8),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icône d'attention
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Titre
                const Text(
                  'Action Requise',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // Message
                const Text(
                  'Veuillez contacter Rapidos pour activer votre compte.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // Adresse
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: const Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.phone,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Téléphone:',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '+243 808 000 316',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Bouton Appeler Rapidos
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      final Uri phoneUri = Uri(scheme: 'tel', path: '+243808000316');
                      if (await canLaunchUrl(phoneUri)) {
                        await launchUrl(phoneUri);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Impossible de lancer l\'appel'),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Appeler Rapidos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Bouton Quitter l'application
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      // Déconnecter l'utilisateur (reset complet via AuthCubit qui fait clearAll + clearSession)
                      context.read<AuthCubit>().logout();
                      // Rediriger vers l'écran home non connecté (comme au premier chargement)
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const NewHomeScreen()),
                        (route) => false,
                      );
                      print('🚪 Utilisateur déconnecté et redirigé vers l\'écran home non connecté');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Quitter l\'application',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
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
                        backgroundColor: AppColors.white,
                        child: Icon(Icons.person, color: AppColors.buttonColor),
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ],
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 10,
          bottom: MediaQuery.of(context).padding.bottom + 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header profil
            BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                if (state is AuthSuccess && state.user != null) {
                  return Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${state.user!['firstName'] ?? ''} ${state.user!['lastName'] ?? ''}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                          ),
                          const Text('Livreur', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ],
                  );
                }
                return const Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Livreur', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                        Text('Livreur', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            // Statistiques de livraison (en premier)
            _DeliveryStatisticsWidget(),
            const SizedBox(height: 20),
            // Carte de position livraison
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const NavigationExample(backNavigation: true)));
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
                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _currentPosition == null
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
                                      _mapController = controller;
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
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const NavigationExample(backNavigation: true)));
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
            ),
            const SizedBox(height: 20),
            // Evaluations clients
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Évaluations des Clients', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                TextButton(
                  onPressed: () {},
                  child: Row(
                    children: [
                      Text('Voir tout', style: TextStyle(color: AppColors.primary)),
                      Icon(Icons.chevron_right, color: AppColors.primary, size: 18),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 90,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: const [
                  _ReviewCard(client: 'Client A', comment: 'Livreur très courtois', rating: 5),
                  SizedBox(width: 10),
                  _ReviewCard(client: 'Client B', comment: 'Livraison à l\'heure', rating: 4),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}


class _ReviewCard extends StatelessWidget {
  final String client;
  final String comment;
  final int rating;
  const _ReviewCard({required this.client, required this.comment, required this.rating});
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
              const CircleAvatar(radius: 12, backgroundColor: Colors.grey, child: Icon(Icons.person, size: 14, color: Colors.white)),
              const SizedBox(width: 8),
              Text(client, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const Spacer(),
              Row(
                children: List.generate(rating, (index) => const Icon(Icons.star, color: Colors.amber, size: 14)),
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


class _DeliveryStatisticsWidget extends StatefulWidget {
  @override
  State<_DeliveryStatisticsWidget> createState() => _DeliveryStatisticsWidgetState();
}

class _DeliveryStatisticsWidgetState extends State<_DeliveryStatisticsWidget> {
  final DeliveryStatisticsService _statisticsService = DeliveryStatisticsService();
  Map<String, dynamic>? _statistics;
  bool _isLoading = true;
  String? _livreurId;

  @override
  void initState() {
    super.initState();
    _loadLivreurId();
  }

  void _loadLivreurId() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthSuccess && authState.user != null) {
      final userId = authState.user!['id'];
      if (userId != null) {
        setState(() {
          _livreurId = userId.toString();
        });
        _loadStatistics();
      }
    }
  }

  Future<void> _loadStatistics() async {
    if (_livreurId == null) return;
    
    setState(() => _isLoading = true);
    try {
      final result = await _statisticsService.getDeliveryStatistics(_livreurId!);
      if (result['success'] == true) {
        setState(() {
          _statistics = result;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_livreurId == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête de section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.local_shipping,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Statistiques de livraison',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF2B2D42),
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DeliveryStatisticsDetailScreen(
                      period: 'daily',
                      livreurId: _livreurId!,
                    ),
                  ),
                );
              },
              child: const Text(
                'Voir plus',
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
        // Grille de statistiques
        _isLoading
            ? Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200, width: 0.5),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            : _statistics == null
                ? Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200, width: 0.5),
                    ),
                    child: const Center(
                      child: Text(
                        'Aucune donnée disponible',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Aujourd\'hui',
                          _statistics!['daily']?['total'] ?? 0.0,
                          _statistics!['daily']?['count'] ?? 0,
                          Icons.today,
                          'daily',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          'Semestre',
                          _statistics!['semester']?['total'] ?? 0.0,
                          _statistics!['semester']?['count'] ?? 0,
                          Icons.calendar_view_month,
                          'semester',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          'Ce mois',
                          _statistics!['monthly']?['total'] ?? 0.0,
                          _statistics!['monthly']?['count'] ?? 0,
                          Icons.calendar_month,
                          'monthly',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          'Cette année',
                          _statistics!['yearly']?['total'] ?? 0.0,
                          _statistics!['yearly']?['count'] ?? 0,
                          Icons.calendar_today,
                          'yearly',
                        ),
                      ),
                    ],
                  ),
      ],
    );
  }

  Widget _buildStatCard(String label, double total, int count, IconData icon, String period) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeliveryStatisticsDetailScreen(
              period: period,
              livreurId: _livreurId!,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${NumberFormat('#,###').format(total)} FC',
              style: const TextStyle(
                color: Color(0xFF147C3C),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '$count livraisons',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
} 
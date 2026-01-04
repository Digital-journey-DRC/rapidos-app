
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:immo/constants.dart';
import 'package:immo/cubit/auth_cubit.dart';
import 'package:immo/cubit/order_cubit.dart';
import 'package:immo/widgets/shimmer_loading.dart';
import 'package:immo/widgets/app_logo.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:immo/screens/order_details_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:immo/services/invoice_service.dart';
import 'package:immo/services/merchant_service.dart';
import 'package:image_picker/image_picker.dart';

class CameraColisScreen extends StatefulWidget {
  final Function(String imagePath) onPictureTaken;
  final List<CameraDescription> cameras;
  const CameraColisScreen(
      {required this.onPictureTaken, required this.cameras, Key? key})
      : super(key: key);

  @override
  State<CameraColisScreen> createState() => _CameraColisScreenState();
}

class _CameraColisScreenState extends State<CameraColisScreen> {
  late CameraController _controller;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    if (widget.cameras.isNotEmpty) {
      _controller = CameraController(
        widget.cameras[0],
        ResolutionPreset.medium,
      );
      _controller.initialize().then((_) {
        if (!mounted) return;
        setState(() => _isReady = true);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (!_controller.value.isInitialized) return;
    final XFile file = await _controller.takePicture();
    widget.onPictureTaken(file.path);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return Scaffold(
        appBar: AppBarWithLogo(
          title: 'Appareil photo',
          backgroundColor: Colors.black,
          elevation: 0,
          useWhiteLogo: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBarWithLogo(
        title: 'Appareil photo',
        backgroundColor: Colors.black87,
        elevation: 0,
        useWhiteLogo: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          CameraPreview(_controller),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                onPressed: _takePicture,
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.camera_alt, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OrderScreen extends StatefulWidget {
  final bool backNavigation;
  final String? initialStatusFilter; // Filtre de statut initial (pour afficher pending_payment après initialisation)
  const OrderScreen({
    Key? key,
    required this.backNavigation,
    this.initialStatusFilter,
  }) : super(key: key);

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  late AuthState authState;
  late bool isLivreur;
  bool _hasFetchedOrders = false;
  List<CameraDescription>? cameras;
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatusFilter = 'Tous';
  bool _hasSearchText = false;

  @override
  void initState() {
    super.initState();
    _initializeCameras();
    // Si un filtre initial est fourni, l'utiliser (ex: pending_payment après initialisation)
    if (widget.initialStatusFilter != null) {
      _selectedStatusFilter = widget.initialStatusFilter!;
      print('📋 [OrderScreen] Filtre initial appliqué: ${widget.initialStatusFilter}');
    }
  }

  Future<void> _initializeCameras() async {
    try {
      cameras = await availableCameras();
    } catch (e) {
      print('❌ Error initializing cameras: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    authState = context.watch<AuthCubit>().state;
    isLivreur = authState is AuthSuccess &&
        (authState as AuthSuccess).user != null &&
        (authState as AuthSuccess).user!['role'] == 'livreur';
    if (!_hasFetchedOrders && authState is AuthSuccess && !isLivreur) {
      _hasFetchedOrders = true;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void saveCommande() async {
    // Enregistrer la commande
    DocumentReference commandeRef =
        await FirebaseFirestore.instance.collection('commandes').add({
      'client': 'Joël',
      'adresse': 'Gombe',
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
    });

    print("✅ Commande enregistrée avec succès: ${commandeRef.id}");
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending_payment':
        return Colors.orange;
      case 'pending':
        return AppColors.buttonColor2;
      case 'en_preparation':
      case 'in_preparation':
        return Colors.orange;
      case 'pret_a_expedier':
      case 'ready_to_ship':
      case 'prêt à expédier':
      case 'pret a expedier':
        return Colors.blue;
      case 'accepte_livreur':
      case 'accepté livreur':
        return Colors.purple;
      case 'in_delivery':
      case 'en_route':
      case 'en route':
        return Colors.green;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Date non disponible';
    
    // Si c'est un Timestamp Firestore
    if (date is Timestamp) {
      return DateFormat('dd/MM/yyyy à HH:mm').format(date.toDate());
    }
    
    // Si c'est une String (format ISO)
    if (date is String) {
      try {
        final parsedDate = DateTime.parse(date);
        return DateFormat('dd/MM/yyyy à HH:mm').format(parsedDate);
      } catch (e) {
        return date;
      }
    }
    
    // Si c'est un DateTime
    if (date is DateTime) {
      return DateFormat('dd/MM/yyyy à HH:mm').format(date);
    }
    
    return date.toString();
  }

  /// Widget pour afficher les statistiques des commandes
  Widget _buildStatsSection(Map<String, dynamic> stats) {
    final total = stats['total'] ?? 0;
    // Harmoniser avec les statuts réels du backend
    final pendingPayment = stats['pending_payment'] ?? 0;
    final pending = stats['pending'] ?? 0;
    // Les stats peuvent utiliser 'in_preparation' mais les commandes utilisent 'en_preparation'
    final inPreparation = (stats['in_preparation'] ?? 0) + (stats['en_preparation'] ?? 0);
    // Les stats peuvent utiliser 'ready_to_ship' mais les commandes utilisent 'pret_a_expedier' ou 'prêt à expédier' ou 'pret a expedier'
    final readyToShip = (stats['ready_to_ship'] ?? 0) + (stats['pret_a_expedier'] ?? 0) + (stats['prêt à expédier'] ?? 0) + (stats['pret a expedier'] ?? 0);
    final inDelivery = stats['in_delivery'] ?? 0;
    final delivered = stats['delivered'] ?? 0;
    final cancelled = stats['cancelled'] ?? 0;
    final rejected = stats['rejected'] ?? 0;

    // Print pour debug (comme dans l'exemple JavaScript)
    print('📊 Statistiques:');
    print('   Total: $total commandes');
    print('   En attente de paiement: $pendingPayment');

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Statistiques',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Total', total.toString(), AppColors.primary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatItem('En attente de paiement', pendingPayment.toString(), Colors.orange),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('En attente', pending.toString(), AppColors.buttonColor2),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatItem('En préparation', inPreparation.toString(), Colors.orange),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Prêt à expédier', readyToShip.toString(), Colors.blue),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatItem('En route', inDelivery.toString(), Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Livré', delivered.toString(), Colors.green),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatItem('Annulé/Rejeté', (cancelled + rejected).toString(), Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _translateStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending_payment':
        return 'EN ATTENTE DE PAIEMENT';
      case 'pending':
        return 'EN ATTENTE';
      case 'en_preparation':
      case 'in_preparation':
        return 'EN PRÉPARATION';
      case 'pret_a_expedier':
      case 'ready_to_ship':
      case 'prêt à expédier':
      case 'pret a expedier':
        return 'PRÊT À EXPÉDIER';
      case 'accepte_livreur':
      case 'accepté livreur':
        return 'ACCEPTÉ LIVREUR';
      case 'in_delivery':
      case 'en_route':
      case 'en route':
        return 'EN ROUTE';
      case 'delivered':
        return 'LIVRÉ';
      case 'cancelled':
        return 'ANNULÉ';
      case 'rejected':
        return 'REJETÉ';
      default:
        return status.toUpperCase().replaceAll('_', ' ');
    }
  }

  Widget _buildStatusFilterChip(String label, String statusValue) {
    final isSelected = _selectedStatusFilter == statusValue;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? Colors.white : Colors.grey.shade700,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatusFilter = statusValue;
        });
      },
      selectedColor: AppColors.primary,
      backgroundColor: Colors.grey.shade200,
      checkmarkColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.transparent,
          width: 1.5,
        ),
      ),
    );
  }

  void _showExpeditionDialog(BuildContext context, String docId) {
    bool isChecked = false;
    String? photoPath;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Confirmation d\'expédition',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Checkbox(
                        value: isChecked,
                        onChanged: (value) {
                          setState(() {
                            isChecked = value ?? false;
                          });
                        },
                      ),
                      const Expanded(
                        child: Text(
                          'J\'ai inscrit le numéro de la commande, le nom et l\'adresse de livraison dans le colis',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Photo du colis',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: photoPath == null
                        ? Center(
                            child: isUploading
                                ? const CircularProgressIndicator()
                                : IconButton(
                                    icon: const Icon(Icons.camera_alt,
                                        size: 40, color: Colors.grey),
                                    onPressed: () async {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              CameraColisScreen(
                                            onPictureTaken: (imagePath) async {
                                              setState(() {
                                                isUploading = true;
                                              });
                                              try {
                                                final file = File(imagePath);
                                                final fileName =
                                                    'colis_${DateTime.now().millisecondsSinceEpoch}.jpg';
                                                final ref = FirebaseStorage
                                                    .instance
                                                    .ref()
                                                    .child('colis_photos')
                                                    .child(fileName);
                                                await ref.putFile(file);
                                                final downloadUrl =
                                                    await ref.getDownloadURL();
                                                setState(() {
                                                  photoPath = downloadUrl;
                                                  isUploading = false;
                                                });
                                              } catch (e) {
                                                setState(() {
                                                  isUploading = false;
                                                });
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                        'Erreur lors de l\'upload : $e'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            },
                                            cameras: cameras ?? [],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          )
                        : Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  photoPath!,
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: IconButton(
                                  icon: const Icon(Icons.close,
                                      color: Colors.white),
                                  onPressed: () {
                                    setState(() {
                                      photoPath = null;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'ANNULER',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: isChecked &&
                                photoPath != null &&
                                !isUploading
                            ? () async {
                                try {
                                  await FirebaseFirestore.instance
                                      .collection('carts')
                                      .doc(docId)
                                      .update({
                                    'status': 'prêt à expédier',
                                    'timestamp': FieldValue.serverTimestamp(),
                                    'packagePhoto': photoPath,
                                  });

                                  if (mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Commande expédiée avec succès'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Erreur: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Rapidos'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCodeConfirmationDialog(BuildContext context, String docId, String shortCode, String livreurId) {
    final TextEditingController codeController = TextEditingController();
    bool isCodeValid = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Confirmation de livraison',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Veuillez entrer le code de confirmation à 4 chiffres fourni par le client',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    decoration: InputDecoration(
                      hintText: 'Entrez le code à 4 chiffres',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                      errorText: isCodeValid ? 'Code incorrect' : null,
                    ),
                    onChanged: (value) {
                      setState(() {
                        isCodeValid = value.length == 4 && value != shortCode;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'ANNULER',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: codeController.text == shortCode
                            ? () async {
                                try {
                                  await FirebaseFirestore.instance
                                      .collection('carts')
                                      .doc(docId)
                                      .update({
                                    'status': 'delivered',
                                    'livreur': livreurId,
                                    'timestamp': FieldValue.serverTimestamp(),
                                  });

                                  if (mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Colis livré avec succès'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Erreur: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('CONFIRMER'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthSuccess) {
      return const Center(child: Text('Non authentifié'));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBarWithLogo(
        leading: widget.backNavigation
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pushNamed(context, AppRoutes.main),
              )
            : null,
        title: _selectedStatusFilter == 'pending_payment' 
            ? 'Commandes en attente de paiement'
            : 'Commandes',
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          if (authState.user!['role'] == 'livreur')
            Expanded(
              child: Column(
                children: [
                  // Barre de recherche et filtre
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Barre de recherche
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Rechercher une commande...',
                            prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                            suffixIcon: _hasSearchText
                                ? IconButton(
                                    icon: Icon(Icons.clear, color: Colors.grey.shade600),
                                    onPressed: () {
                                      setState(() {
                                        _searchController.clear();
                                        _hasSearchText = false;
                                      });
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _hasSearchText = value.isNotEmpty;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        // Filtres par statut
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildStatusFilterChip('Tous', 'Tous'),
                              const SizedBox(width: 8),
                              _buildStatusFilterChip('PRÊT À EXPÉDIER', 'pret_a_expedier'),
                              const SizedBox(width: 8),
                              _buildStatusFilterChip('ACCEPTÉ LIVREUR', 'accepte_livreur'),
                              const SizedBox(width: 8),
                              _buildStatusFilterChip('EN ROUTE', 'en_route'),
                              const SizedBox(width: 8),
                              _buildStatusFilterChip('LIVRÉ', 'delivered'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _buildLivreurOrders(),
                  ),
                ],
              ),
            )
          else if (authState.user!['role'] == 'vendeur')
            Expanded(
              child: Column(
                children: [
                  // Barre de recherche et filtre
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Barre de recherche
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Rechercher une commande...',
                            prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                            suffixIcon: _hasSearchText
                                ? IconButton(
                                    icon: Icon(Icons.clear, color: Colors.grey.shade600),
                                    onPressed: () {
                                      setState(() {
                                        _searchController.clear();
                                        _hasSearchText = false;
                                      });
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _hasSearchText = value.isNotEmpty;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        // Filtres par statut
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildStatusFilterChip('Tous', 'Tous'),
                              const SizedBox(width: 8),
                              _buildStatusFilterChip('EN ATTENTE', 'pending'),
                              const SizedBox(width: 8),
                              _buildStatusFilterChip('EN PRÉPARATION', 'en_preparation'),
                              const SizedBox(width: 8),
                              _buildStatusFilterChip('PRÊT À EXPÉDIER', 'pret_a_expedier'),
                              const SizedBox(width: 8),
                              _buildStatusFilterChip('ACCEPTÉ LIVREUR', 'accepte_livreur'),
                              const SizedBox(width: 8),
                              _buildStatusFilterChip('EN ROUTE', 'en_route'),
                              const SizedBox(width: 8),
                              _buildStatusFilterChip('LIVRÉ', 'delivered'),
                              const SizedBox(width: 8),
                              _buildStatusFilterChip('ANNULÉ', 'cancelled'),
                              const SizedBox(width: 8),
                              _buildStatusFilterChip('REJETÉ', 'rejected'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _buildVendeurOrders(),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  // Barre de recherche et filtre
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Barre de recherche
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Rechercher un produit...',
                            prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                            suffixIcon: _hasSearchText
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        _searchController.clear();
                                        _hasSearchText = false;
                                      });
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _hasSearchText = value.isNotEmpty;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        // Filtre par statut
                        SizedBox(
                          height: 40,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildStatusFilterChip('Tous', 'Tous'),
                                const SizedBox(width: 8),
                                _buildStatusFilterChip('EN ATTENTE DE PAIEMENT', 'pending_payment'),
                                const SizedBox(width: 8),
                                _buildStatusFilterChip('EN ATTENTE', 'pending'),
                                const SizedBox(width: 8),
                                _buildStatusFilterChip('EN PRÉPARATION', 'en_preparation'),
                                const SizedBox(width: 8),
                                _buildStatusFilterChip('PRÊT À EXPÉDIER', 'pret_a_expedier'),
                                const SizedBox(width: 8),
                                _buildStatusFilterChip('ACCEPTÉ LIVREUR', 'accepte_livreur'),
                                const SizedBox(width: 8),
                                _buildStatusFilterChip('EN ROUTE', 'en_route'),
                                const SizedBox(width: 8),
                                _buildStatusFilterChip('LIVRÉ', 'delivered'),
                                const SizedBox(width: 8),
                                _buildStatusFilterChip('ANNULÉ', 'cancelled'),
                                const SizedBox(width: 8),
                                _buildStatusFilterChip('REJETÉ', 'rejected'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Liste des commandes
                  Expanded(
                    child: _buildClientOrders(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _generateInvoiceForClient(
    BuildContext context,
    Map<String, dynamic> orderData,
    String orderId,
    List<Map<String, dynamic>> items,
  ) async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthSuccess || authState.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de générer la facture. Utilisateur non connecté.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final client = authState.user!;

    // Récupérer l'ID du vendeur depuis les items
    int? vendeurId;
    for (var item in items) {
      if (item['idVendeur'] != null) {
        vendeurId = int.tryParse(item['idVendeur'].toString());
        break;
      }
    }

    // Informations du client (utilisateur connecté)
    final clientInfo = {
      'name': '${client['firstName'] ?? ''} ${client['lastName'] ?? ''}'.trim().isEmpty
          ? 'Client'
          : '${client['firstName'] ?? ''} ${client['lastName'] ?? ''}'.trim(),
      'phone': client['phone']?.toString() ?? '',
      'address': orderData['adresse']?.toString() ?? 'Adresse non spécifiée',
    };

    // Informations du marchand
    Map<String, dynamic> merchantInfo = {
      'name': 'Marchand',
      'phone': '',
      'email': '',
    };

    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Si on a un vendeurId, récupérer ses informations depuis l'API
      if (vendeurId != null) {
        try {
          final merchantService = MerchantService();
          final result = await merchantService.getVendeurById(vendeurId);

          if (result['success'] == true && result['vendeur'] != null) {
            final vendeur = result['vendeur'] as dynamic;
            merchantInfo = {
              'firstName': vendeur.firstName ?? '',
              'lastName': vendeur.lastName ?? '',
              'name': vendeur.fullName ?? 'Marchand',
              'phone': vendeur.phone ?? '',
              'email': vendeur.email ?? '',
            };
          }
        } catch (e) {
          print('Erreur lors de la récupération du marchand: $e');
          // Continuer avec les informations par défaut
        }
      }

      await InvoiceService.generateInvoice(
        context: context,
        orderData: orderData,
        orderId: orderId,
        merchantInfo: merchantInfo,
        clientInfo: clientInfo,
      );
    } finally {
      if (context.mounted) {
        Navigator.of(context).pop(); // Fermer le dialog de chargement
      }
    }
  }

  Widget _buildClientOrders() {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthSuccess || authState.user == null) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Text(
            'Veuillez vous connecter pour voir vos commandes',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return BlocBuilder<OrderCubit, OrderState>(
      builder: (context, state) {
        final orderListState = context.read<OrderCubit>().orderListState;

        // Charger les commandes si elles ne sont pas encore chargées
        if (!orderListState.isLoading && orderListState.orders.isEmpty && orderListState.error == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<OrderCubit>().fetchOrders();
          });
        }

        if (orderListState.isLoading) {
          return _buildLoadingShimmer();
        }

        if (orderListState.error != null) {
          return Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 50, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Erreur: ${orderListState.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.read<OrderCubit>().fetchOrders(),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        if (orderListState.orders.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox,
                    size: 80, color: AppColors.buttonColor.withOpacity(0.3)),
                const SizedBox(height: 18),
                const Text(
                  'Aucune commande trouvée',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // Filtrer par statut
        final filteredByStatus = _selectedStatusFilter == 'Tous'
            ? orderListState.orders
            : orderListState.orders.where((order) {
                final status = order['status']?.toString().toLowerCase() ?? '';
                final filterStatus = _selectedStatusFilter.toLowerCase();
                
                // Gérer les correspondances de statuts (harmoniser avec les statuts réels du backend)
                if (filterStatus == 'tous' || filterStatus == 'all') {
                  return true;
                } else if (filterStatus == 'pending_payment') {
                  return status == 'pending_payment';
                } else if (filterStatus == 'pending') {
                  return status == 'pending';
                } else if (filterStatus == 'en_preparation') {
                  // Accepter les deux variantes
                  return status == 'en_preparation' || status == 'in_preparation';
                } else if (filterStatus == 'pret_a_expedier') {
                  // Accepter toutes les variantes
                  return status == 'pret_a_expedier' || status == 'ready_to_ship' || status == 'prêt à expédier' || status == 'pret a expedier';
                } else if (filterStatus == 'accepte_livreur') {
                  return status == 'accepte_livreur' || status == 'accepté livreur';
                } else if (filterStatus == 'en_route' || filterStatus == 'in_delivery') {
                  // Accepter les variantes
                  return status == 'en_route' || status == 'en route' || status == 'in_delivery';
                } else if (filterStatus == 'delivered') {
                  return status == 'delivered';
                } else if (filterStatus == 'cancelled') {
                  return status == 'cancelled';
                } else if (filterStatus == 'rejected') {
                  return status == 'rejected';
                }
                return status == filterStatus;
              }).toList();

        // Filtrer par recherche
        final searchQuery = _searchController.text.toLowerCase().trim();
        final filteredCommandes = searchQuery.isEmpty
            ? filteredByStatus
            : filteredByStatus.where((order) {
                final products = order['products'] as List? ?? [];
                return products.any((product) {
                  final name = product['name']?.toString().toLowerCase() ?? '';
                  return name.contains(searchQuery);
                });
              }).toList();

        // Trier par date (plus récentes en premier)
        final sortedCommandes = List.from(filteredCommandes)
          ..sort((a, b) {
            final aDate = a['createdAt']?.toString() ?? '';
            final bDate = b['createdAt']?.toString() ?? '';
            if (aDate.isEmpty && bDate.isEmpty) return 0;
            if (aDate.isEmpty) return 1;
            if (bDate.isEmpty) return -1;
            try {
              final aDateTime = DateTime.parse(aDate);
              final bDateTime = DateTime.parse(bDate);
              return bDateTime.compareTo(aDateTime);
            } catch (e) {
              return 0;
            }
          });

        if (sortedCommandes.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off,
                    size: 80, color: AppColors.buttonColor.withOpacity(0.3)),
                const SizedBox(height: 18),
                const Text(
                  'Aucune commande trouvée',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // Récupérer les statistiques
        final stats = orderListState.stats;
        
        return RefreshIndicator(
          onRefresh: () => context.read<OrderCubit>().fetchOrders(),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              // Liste des commandes
              ...sortedCommandes.map((order) {
              try {
                final orderId = order['orderId']?.toString() ?? '';
                final orderIdNum = order['id']?.toString() ?? '';
                final status = order['status']?.toString() ?? 'pending';
                final products = order['products'] as List? ?? [];
                final address = order['address'] as Map<String, dynamic>? ?? {};
                
                // Convertir total et deliveryFee qui peuvent être String ou double
                final totalValue = order['total'];
                final total = totalValue is double 
                    ? totalValue 
                    : (totalValue is String 
                        ? double.tryParse(totalValue) ?? 0.0 
                        : (totalValue is int 
                            ? totalValue.toDouble() 
                            : 0.0));
                
                final deliveryFeeValue = order['deliveryFee'];
                final deliveryFee = deliveryFeeValue is double 
                    ? deliveryFeeValue 
                    : (deliveryFeeValue is String 
                        ? double.tryParse(deliveryFeeValue) ?? 0.0 
                        : (deliveryFeeValue is int 
                            ? deliveryFeeValue.toDouble() 
                            : 0.0));
                
                final totalAvecLivraisonValue = order['totalAvecLivraison'];
                final totalAvecLivraison = totalAvecLivraisonValue is double 
                    ? totalAvecLivraisonValue 
                    : (totalAvecLivraisonValue is String 
                        ? double.tryParse(totalAvecLivraisonValue) ?? (total + deliveryFee)
                        : (totalAvecLivraisonValue is int 
                            ? totalAvecLivraisonValue.toDouble() 
                            : (total + deliveryFee)));
                final distanceKm = order['distanceKm']?.toString() ?? '';
                final vendeur = order['vendeur'] as Map<String, dynamic>? ?? {};
                final vendeurFirstName = vendeur['firstName']?.toString() ?? '';
                final vendeurLastName = vendeur['lastName']?.toString() ?? '';
                final paymentMethod = order['paymentMethod'] as Map<String, dynamic>?;
                final paymentMethodName = paymentMethod?['name']?.toString() ?? '';
                final paymentMethodNumero = paymentMethod?['numeroCompte']?.toString() ?? '';
                final createdAt = order['createdAt']?.toString() ?? '';
                
                // Print pour debug (comme dans l'exemple JavaScript)
                print('📦 Commande #${orderIdNum.isNotEmpty ? orderIdNum : orderId}: ${total.toStringAsFixed(0)} FC + ${deliveryFee.toStringAsFixed(0)} FC livraison');
                print('   Vendeur: $vendeurFirstName $vendeurLastName');
                print('   Moyen de paiement: $paymentMethodName ($paymentMethodNumero)');

                // Formater la date
                String formattedDate = '';
                if (createdAt.isNotEmpty) {
                  try {
                    final dateTime = DateTime.parse(createdAt);
                    formattedDate = DateFormat('dd/MM/yyyy').format(dateTime);
                  } catch (e) {
                    formattedDate = createdAt;
                  }
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderDetailsScreen(
                              orderData: order,
                              orderId: orderId,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // En-tête avec numéro de commande et statut
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.receipt_long,
                                              size: 14,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Commande #${orderIdNum.isNotEmpty ? orderIdNum : (orderId.length > 8 ? orderId.substring(0, 8) : orderId)}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      // Date
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today_outlined,
                                            size: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            formattedDate,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _statusColor(status).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _statusColor(status).withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    _translateStatus(status),
                                    style: TextStyle(
                                      color: _statusColor(status),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Divider(height: 1, color: Colors.grey.shade200),
                            const SizedBox(height: 12),
                            // Informations vendeur et produits
                            Row(
                              children: [
                                if (vendeur.isNotEmpty) ...[
                                  Icon(
                                    Icons.store_outlined,
                                    size: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '$vendeurFirstName $vendeurLastName'.trim(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 14,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${products.length} ${products.length > 1 ? 'produits' : 'produit'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Montant total et actions
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${totalAvecLivraison.toStringAsFixed(0)} FC',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    // Bouton générer PDF
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Colors.red.withOpacity(0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: InkWell(
                                        onTap: () {
                                          final productsList = List<Map<String, dynamic>>.from(
                                            products.map((product) => product is Map 
                                              ? Map<String, dynamic>.from(product) 
                                              : <String, dynamic>{}),
                                          );
                                          _generateInvoiceForClient(
                                            context,
                                            order,
                                            orderId,
                                            productsList,
                                          );
                                        },
                                        child: Icon(
                                          Icons.picture_as_pdf,
                                          size: 16,
                                          color: Colors.red.shade700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.chevron_right,
                                      size: 20,
                                      color: Colors.grey.shade400,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              } catch (e) {
                print('Erreur lors de l\'affichage de la commande: $e');
                return Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    'Erreur lors de l\'affichage de la commande: $e',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }
            }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLivreurOrders() {
          Future<void> _updateClientLocation(double longitude, double latitude, idClient) async {


    try {
      // Vérifier et demander les permissions de localisation


      // Récupérer l'utilisateur connecté
      final authState = context.read<AuthCubit>().state;
      if (authState is AuthSuccess && authState.user != null) {
        final user = authState.user!;
        final userId = user['id']?.toString() ?? '';
        final userRole = user['role']?.toString() ?? '';
        final phone = user['phone']?.toString() ?? '';

        // Vérifier si un enregistrement existe déjà pour cet utilisateur
        final locationQuery = await FirebaseFirestore.instance
            .collection('locations')
            .where('userId', isEqualTo: idClient)
            .get();

        if (locationQuery.docs.isNotEmpty) {
          // Mettre à jour l'enregistrement existant
          await locationQuery.docs.first.reference.update({
            'longitude': longitude,
            'latitude': latitude,
            'timestamp': FieldValue.serverTimestamp(),
          });
          print('✅ Position mise à jour avec succès');
        } else {
          // Créer un nouvel enregistrement
          await FirebaseFirestore.instance.collection('locations').add({
            'userId': idClient,
            'role': "acheteur",
            'longitude': longitude,
            'latitude': latitude,
            'phone': "Pas de numéro",
            'timestamp': FieldValue.serverTimestamp(),
          });
          print('✅ Nouvelle position enregistrée avec succès');
        }
      }
    } catch (e) {
      print('❌ Erreur lors de la récupération de la position: $e');
    }
  }

      Future<void> _saveCurrentLocation() async {


    try {
      // Vérifier et demander les permissions de localisation
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      // Obtenir la position actuelle
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Récupérer l'utilisateur connecté
      final authState = context.read<AuthCubit>().state;
      if (authState is AuthSuccess && authState.user != null) {
        final user = authState.user!;
        final userId = user['id']?.toString() ?? '';
        final userRole = user['role']?.toString() ?? '';
        final phone = user['phone']?.toString() ?? '';

        // Vérifier si un enregistrement existe déjà pour cet utilisateur
        final locationQuery = await FirebaseFirestore.instance
            .collection('locations')
            .where('userId', isEqualTo: userId)
            .get();

        if (locationQuery.docs.isNotEmpty) {
          // Mettre à jour l'enregistrement existant
          await locationQuery.docs.first.reference.update({
            'longitude': position.longitude,
            'latitude': position.latitude,
            'timestamp': FieldValue.serverTimestamp(),
          });
          print('✅ Position mise à jour avec succès');
        } else {
          // Créer un nouvel enregistrement
          await FirebaseFirestore.instance.collection('locations').add({
            'userId': userId,
            'role': userRole,
            'longitude': position.longitude,
            'latitude': position.latitude,
            'phone': phone,
            'timestamp': FieldValue.serverTimestamp(),
          });
          print('✅ Nouvelle position enregistrée avec succès');
        }
      }
    } catch (e) {
      print('❌ Erreur lors de la récupération de la position: $e');
    }
  }

    String generate4DigitCode() {
      final random = Random();
      int code = (1000 + random.nextInt(9000))
          as int; // Génère un nombre entre 1000 et 9999
      return code.toString();
    }

    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthSuccess) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Text(
            'Non authentifié',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Charger les commandes au premier build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orderListState = context.read<OrderCubit>().orderListState;
      if (!orderListState.isLoading && orderListState.orders.isEmpty && orderListState.error == null) {
        context.read<OrderCubit>().fetchLivreurOrders();
      }
    });

    return BlocConsumer<OrderCubit, OrderState>(
      listener: (context, state) {
        if (state.error != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        final orderListState = context.read<OrderCubit>().orderListState;
        
        if (orderListState.isLoading && orderListState.orders.isEmpty) {
          return const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              OrderCardShimmer(),
              SizedBox(height: 10),
              OrderCardShimmer(),
            ],
          );
        }

        if (orderListState.error != null && orderListState.orders.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 50, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Erreur: ${orderListState.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.read<OrderCubit>().fetchLivreurOrders(),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        final orders = orderListState.orders;

        if (orders.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_shipping_outlined,
                    size: 80, color: AppColors.buttonColor.withOpacity(0.3)),
                const SizedBox(height: 18),
                const Text(
                  'Aucune commande en attente',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.read<OrderCubit>().fetchLivreurOrders(),
                  child: const Text('Actualiser'),
                ),
              ],
            ),
          );
        }

        // Filtrer par statut
        var filteredOrders = List<dynamic>.from(orders);
        if (_selectedStatusFilter != 'Tous') {
          filteredOrders = filteredOrders.where((order) {
            final status = order['status']?.toString().toLowerCase() ?? '';
            return status == _selectedStatusFilter.toLowerCase();
          }).toList();
        }

        // Filtrer par recherche
        final searchQuery = _searchController.text.toLowerCase().trim();
        if (searchQuery.isNotEmpty) {
          filteredOrders = filteredOrders.where((order) {
            final clientName = (order['client']?.toString() ?? '').toLowerCase();
            final phone = (order['phone']?.toString() ?? '').toLowerCase();
            final orderId = (order['orderId']?.toString() ?? '').toLowerCase();
            final codeColis = (order['codeColis']?.toString() ?? '').toLowerCase();
            final items = order['items'] as List? ?? [];
            final productNames = items.map((item) {
              if (item is Map) {
                return (item['name']?.toString() ?? '').toLowerCase();
              }
              return '';
            }).join(' ');

            return clientName.contains(searchQuery) ||
                phone.contains(searchQuery) ||
                orderId.contains(searchQuery) ||
                codeColis.contains(searchQuery) ||
                productNames.contains(searchQuery);
          }).toList();
        }

        if (filteredOrders.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off,
                    size: 80, color: AppColors.buttonColor.withOpacity(0.3)),
                const SizedBox(height: 18),
                Text(
                  searchQuery.isNotEmpty || _selectedStatusFilter != 'Tous'
                      ? 'Aucune commande trouvée'
                      : 'Aucune commande en attente',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => context.read<OrderCubit>().fetchLivreurOrders(),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 8,
              bottom: MediaQuery.of(context).padding.bottom + 20,
            ),
            itemCount: filteredOrders.length,
            itemBuilder: (context, index) {
              final order = filteredOrders[index] as Map<String, dynamic>;
              final items = order['items'] as List? ?? [];
              final status = order['status']?.toString() ?? 'pending';
              final phone = order['phone']?.toString() ?? '';
              final clientName = order['clientName']?.toString() ?? order['client']?.toString() ?? 'Client';
              final codeColis = order['codeColis']?.toString() ?? '';
              
              // Construire l'adresse à partir de l'objet address
              final addressData = order['address'] as Map<String, dynamic>? ?? {};
              final address = [
                addressData['avenue'],
                addressData['numero'],
                addressData['quartier'],
                addressData['commune'],
              ].where((e) => e != null && e.toString().isNotEmpty).join(', ');
              
              // Parser le total
              double total = 0.0;
              final totalValue = order['total'];
              if (totalValue is double) {
                total = totalValue;
              } else if (totalValue is int) {
                total = totalValue.toDouble();
              } else if (totalValue is String) {
                total = double.tryParse(totalValue) ?? 0.0;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderDetailsScreen(
                            orderData: order,
                            orderId: order['orderId']?.toString() ?? order['id']?.toString() ?? '',
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          // Icône de livraison
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.local_shipping_outlined,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Informations principales
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            clientName,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (phone.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              phone,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.location_on_outlined,
                                                size: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  address.isNotEmpty ? address : 'Adresse non spécifiée',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _statusColor(status).withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: _statusColor(status).withOpacity(0.3),
                                              width: 0.5,
                                            ),
                                          ),
                                          child: Text(
                                            _translateStatus(status),
                                            style: TextStyle(
                                              color: _statusColor(status),
                                              fontSize: 9,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        if (codeColis.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Code: $codeColis',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.inventory_2_outlined,
                                              size: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${items.length} ${items.length > 1 ? 'articles' : 'article'}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${total.toStringAsFixed(0)} FC',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: AppColors.primary.withOpacity(0.2),
                                          width: 0.5,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.arrow_forward_ios,
                                        size: 12,
                                        color: AppColors.primary,
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
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildVendeurOrders() {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthSuccess || authState.user == null) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Text(
            'Veuillez vous connecter pour voir vos commandes',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Charger les commandes au premier build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orderListState = context.read<OrderCubit>().orderListState;
      if (!orderListState.isLoading && orderListState.orders.isEmpty && orderListState.error == null) {
        context.read<OrderCubit>().fetchVendeurOrders();
      }
    });

    return BlocConsumer<OrderCubit, OrderState>(
      listener: (context, state) {
        if (state.error != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state.success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Action effectuée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      builder: (context, state) {
        final orderListState = context.read<OrderCubit>().orderListState;
        
        if (orderListState.isLoading && orderListState.orders.isEmpty) {
          return _buildLoadingShimmer();
        }

        if (orderListState.error != null && orderListState.orders.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 50, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Erreur: ${orderListState.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.read<OrderCubit>().fetchVendeurOrders(),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        final orders = orderListState.orders;
        
        // Filtrer par statut
        var filteredOrders = List<dynamic>.from(orders);
        if (_selectedStatusFilter != 'Tous') {
          filteredOrders = filteredOrders.where((order) {
            final status = order['status']?.toString().toLowerCase() ?? '';
            return status == _selectedStatusFilter.toLowerCase();
          }).toList();
        }

        // Filtrer par recherche
        final searchQuery = _searchController.text.toLowerCase().trim();
        if (searchQuery.isNotEmpty) {
          filteredOrders = filteredOrders.where((order) {
            final buyer = order['buyer'] as Map<String, dynamic>? ?? {};
            // Adapter pour la nouvelle structure : buyer peut avoir email/phone ou firstName/lastName
            final buyerName = buyer['email']?.toString().toLowerCase() ?? 
                             '${buyer['firstName'] ?? ''} ${buyer['lastName'] ?? ''}'.toLowerCase();
            final buyerPhone = buyer['phone']?.toString().toLowerCase() ?? '';
            final orderId = order['orderId']?.toString().toLowerCase() ?? '';
            final products = order['products'] as List? ?? [];
            final productNames = products.map((p) => (p['name']?.toString() ?? '').toLowerCase()).join(' ');
            
            return buyerName.contains(searchQuery) ||
                buyerPhone.contains(searchQuery) ||
                orderId.contains(searchQuery) ||
                productNames.contains(searchQuery);
          }).toList();
        }

        if (filteredOrders.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox,
                    size: 80, color: AppColors.buttonColor.withOpacity(0.3)),
                const SizedBox(height: 18),
                Text(
                  searchQuery.isNotEmpty || _selectedStatusFilter != 'Tous'
                      ? 'Aucune commande trouvée'
                      : 'Aucune commande reçue',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // Trier les commandes par date (plus récentes en premier)
        filteredOrders.sort((a, b) {
          final aCreatedAt = a['createdAt']?.toString() ?? '';
          final bCreatedAt = b['createdAt']?.toString() ?? '';
          if (aCreatedAt.isEmpty && bCreatedAt.isEmpty) return 0;
          if (aCreatedAt.isEmpty) return 1;
          if (bCreatedAt.isEmpty) return -1;
          return bCreatedAt.compareTo(aCreatedAt);
        });

        return RefreshIndicator(
          onRefresh: () async {
            await context.read<OrderCubit>().fetchVendeurOrders();
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 8,
              bottom: MediaQuery.of(context).padding.bottom + 20,
            ),
            itemCount: filteredOrders.length,
            itemBuilder: (context, index) {
              try {
                final order = filteredOrders[index] as Map<String, dynamic>;
                final orderId = order['orderId']?.toString() ?? '';
                final status = order['status']?.toString() ?? 'pending';
                final createdAt = order['createdAt']?.toString() ?? '';
                final buyer = order['buyer'] as Map<String, dynamic>? ?? {};
                // Utiliser clientName de l'API en priorité, sinon fallback sur l'ancien système
                String buyerName = order['clientName']?.toString() ?? '';
                if (buyerName.isEmpty) {
                  buyerName = '${buyer['firstName'] ?? ''} ${buyer['lastName'] ?? ''}'.trim();
                }
                if (buyerName.isEmpty) {
                  buyerName = order['client']?.toString() ?? 'Client';
                }
                final products = order['products'] as List? ?? [];
                final totalProduit = _parseAmount(order['total'] ?? 0);
                final deliveryFee = _parseAmount(order['deliveryFee'] ?? 0);
                final totalAvecLivraison = _parseAmount(order['totalAvecLivraison'] ?? totalProduit + deliveryFee);
                final address = order['address'] as Map<String, dynamic>? ?? {};
                final packagePhoto = order['packagePhoto']?.toString();

                return _buildVendeurOrderCard(
                  order: order,
                  orderId: orderId,
                  status: status,
                  createdAt: createdAt,
                  buyerName: buyerName.isNotEmpty ? buyerName : 'Client',
                  products: products,
                  totalProduit: totalProduit,
                  totalAvecLivraison: totalAvecLivraison,
                  address: address,
                  packagePhoto: packagePhoto,
                );
              } catch (e) {
                print('Erreur lors de l\'affichage de la commande: $e');
                return Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    'Erreur: $e',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }

  // Convertir total et deliveryFee qui peuvent être String ou double
  double _parseAmount(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // Construire une carte de commande pour le vendeur - Design moderne
  Widget _buildVendeurOrderCard({
    required Map<String, dynamic> order,
    required String orderId,
    required String status,
    required String createdAt,
    required String buyerName,
    required List products,
    required double totalProduit,
    required double totalAvecLivraison,
    required Map<String, dynamic> address,
    String? packagePhoto,
  }) {
    final productCount = products.length;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OrderDetailsScreen(
                  orderData: order,
                  orderId: orderId,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Icône client compacte
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.person_outline,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                // Informations principales
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Nom client et statut sur une ligne
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              buyerName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _statusColor(status).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _translateStatus(status),
                              style: TextStyle(
                                color: _statusColor(status),
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Numéro commande et nombre de produits
                      Row(
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 11,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '#${orderId.length > 6 ? orderId.substring(0, 6) : orderId}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.shopping_bag_outlined,
                            size: 11,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$productCount ${productCount > 1 ? 'articles' : 'article'}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Montant total et flèche
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${totalAvecLivraison.toStringAsFixed(0)} FC',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: Colors.grey.shade400,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  // Uploader la photo du colis
  Future<void> _uploadPackagePhoto(String orderId) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image == null) return;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upload de la photo en cours...'),
            backgroundColor: Colors.blue,
          ),
        );
      }

      final result = await context.read<OrderCubit>().uploadPackagePhoto(
        orderId: orderId,
        imagePath: image.path,
      );

      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo uploadée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Erreur lors de l\'upload'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Widget pour gérer les actions de commande (Accepter, Rejeter, Commencer)
  Widget _OrderActionsWidget({
    required String orderId,
    required Map<String, dynamic> order,
    required VoidCallback onStatusChanged,
  }) {
    return _OrderActionsStatefulWidget(
      orderId: orderId,
      order: order,
      onStatusChanged: onStatusChanged,
    );
  }

  // Marquer prêt à expédier
  Future<void> _markReadyToShip(String orderId) async {
    final result = await context.read<OrderCubit>().updateOrderStatus(
      orderId: orderId,
      status: 'pret_a_expedier',
      reason: 'Colis prêt pour livraison',
    );

    if (mounted) {
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commande marquée comme prête à expédier'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Erreur lors de la mise à jour'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildLoadingShimmer() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 150,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// Widget Stateful pour gérer l'état d'acceptation
class _OrderActionsStatefulWidget extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic> order;
  final VoidCallback onStatusChanged;

  const _OrderActionsStatefulWidget({
    required this.orderId,
    required this.order,
    required this.onStatusChanged,
  });

  @override
  State<_OrderActionsStatefulWidget> createState() => _OrderActionsStatefulWidgetState();
}

class _OrderActionsStatefulWidgetState extends State<_OrderActionsStatefulWidget> {
  bool _isAccepted = false;
  bool _isRejected = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Vérifier si la commande est déjà acceptée ou rejetée
    final status = widget.order['status']?.toString() ?? 'pending';
    _isAccepted = status == 'accepted' || status == 'en_preparation';
    _isRejected = status == 'rejected' || status == 'cancelled';
  }

  Future<void> _acceptOrder() async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });

    try {
      final result = await context.read<OrderCubit>().updateOrderStatus(
        orderId: widget.orderId,
        status: 'accepted',
        reason: 'Commande acceptée',
      );

      if (mounted) {
        if (result['success'] == true) {
          setState(() {
            _isAccepted = true;
            _isRejected = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Commande acceptée'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onStatusChanged();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Erreur lors de l\'acceptation'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _rejectOrder() async {
    if (_isProcessing) return;

    // Demander une raison pour le rejet
    final TextEditingController reasonController = TextEditingController();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Rejeter la commande'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Veuillez indiquer la raison du rejet :'),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  hintText: 'Raison du rejet...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (reasonController.text.trim().isNotEmpty) {
                  Navigator.pop(context, true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Rejeter'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || reasonController.text.trim().isEmpty) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final result = await context.read<OrderCubit>().updateOrderStatus(
        orderId: widget.orderId,
        status: 'rejected',
        reason: reasonController.text.trim(),
      );

      if (mounted) {
        if (result['success'] == true) {
          setState(() {
            _isRejected = true;
            _isAccepted = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Commande rejetée'),
              backgroundColor: Colors.orange,
            ),
          );
          widget.onStatusChanged();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Erreur lors du rejet'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _startPreparation() async {
    if (_isProcessing || !_isAccepted) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final result = await context.read<OrderCubit>().updateOrderStatus(
        orderId: widget.orderId,
        status: 'en_preparation',
        reason: 'Commande prise en charge',
      );

      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Préparation de la commande commencée'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onStatusChanged();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Erreur lors de la mise à jour'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Boutons Accepter et Rejeter alignés
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isAccepted || _isRejected || _isProcessing
                    ? null
                    : _acceptOrder,
                icon: Icon(
                  Icons.check_circle_outline,
                  size: 18,
                  color: _isAccepted
                      ? Colors.green
                      : (_isRejected || _isProcessing
                          ? Colors.grey
                          : AppColors.primary),
                ),
                label: Text(
                  _isAccepted ? 'Acceptée' : 'Accepter',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _isAccepted
                        ? Colors.green
                        : (_isRejected || _isProcessing
                            ? Colors.grey
                            : AppColors.primary),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: _isAccepted
                        ? Colors.green
                        : (_isRejected || _isProcessing
                            ? Colors.grey.shade300
                            : AppColors.primary),
                    width: 1.5,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isAccepted || _isRejected || _isProcessing
                    ? null
                    : _rejectOrder,
                icon: Icon(
                  Icons.cancel_outlined,
                  size: 18,
                  color: _isRejected
                      ? Colors.red
                      : (_isAccepted || _isProcessing
                          ? Colors.grey
                          : Colors.red.shade600),
                ),
                label: Text(
                  _isRejected ? 'Rejetée' : 'Rejeter',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _isRejected
                        ? Colors.red
                        : (_isAccepted || _isProcessing
                            ? Colors.grey
                            : Colors.red.shade600),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: _isRejected
                        ? Colors.red
                        : (_isAccepted || _isProcessing
                            ? Colors.grey.shade300
                            : Colors.red.shade600),
                    width: 1.5,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Bouton Commencer la préparation
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isAccepted && !_isProcessing
                ? _startPreparation
                : null,
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('Commencer la préparation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              disabledForegroundColor: Colors.grey.shade600,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Marquer prêt à expédier
  Future<void> _markReadyToShip(String orderId) async {
    final result = await context.read<OrderCubit>().updateOrderStatus(
      orderId: orderId,
      status: 'pret_a_expedier',
      reason: 'Colis prêt pour livraison',
    );

    if (mounted) {
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commande marquée comme prête à expédier'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Erreur lors de la mise à jour'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildLoadingShimmer() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline shimmer
                  Container(
                    width: 6,
                    height: 110,
                    margin:
                        const EdgeInsets.only(right: 10, top: 10, bottom: 10),
                    decoration: BoxDecoration(
                      color: AppColors.buttonColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  // Image shimmer
                  Padding(
                    padding: const EdgeInsets.only(top: 16, left: 0, right: 10),
                    child: ShimmerLoading(
                      width: 70,
                      height: 70,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  // Détails shimmer
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ShimmerLoading(
                                width: 90,
                                height: 16,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              const SizedBox(width: 8),
                              ShimmerLoading(
                                width: 60,
                                height: 16,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ShimmerLoading(
                            width: 120,
                            height: 12,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              ShimmerLoading(
                                width: 60,
                                height: 12,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              const SizedBox(width: 12),
                              ShimmerLoading(
                                width: 50,
                                height: 14,
                                borderRadius: BorderRadius.circular(6),
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
          ],
        );
      },
    );
  }
}

class OrderCardShimmer extends StatelessWidget {
  const OrderCardShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline shimmer
          Container(
            width: 6,
            height: 110,
            margin: const EdgeInsets.only(right: 10, top: 10, bottom: 10),
            decoration: BoxDecoration(
              color: AppColors.buttonColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          // Image shimmer
          Padding(
            padding: const EdgeInsets.only(top: 16, left: 0, right: 10),
            child: ShimmerLoading(
              width: 70,
              height: 70,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          // Détails shimmer
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ShimmerLoading(
                        width: 90,
                        height: 16,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      const SizedBox(width: 8),
                      ShimmerLoading(
                        width: 60,
                        height: 16,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ShimmerLoading(
                    width: 120,
                    height: 12,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ShimmerLoading(
                        width: 60,
                        height: 12,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      const SizedBox(width: 12),
                      ShimmerLoading(
                        width: 50,
                        height: 14,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

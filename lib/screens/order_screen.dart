
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:immo/constants.dart';
import 'package:immo/cubit/auth_cubit.dart';
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
  const OrderScreen({Key? key, required this.backNavigation}) : super(key: key);

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
      case 'pending':
        return AppColors.buttonColor2;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'en route pour livraison':
        return Colors.green;
      case 'prêt à expédier':
        return Colors.blue;
      case 'colis en cours de préparation':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _translateStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'EN ATTENTE';
      case 'delivered':
        return 'LIVRÉ';
      case 'cancelled':
        return 'ANNULÉ';
      case 'en route pour livraison':
        return 'EN ROUTE';
      case 'prêt à expédier':
        return 'PRÊT À EXPÉDIER';
      case 'colis en cours de préparation':
        return 'EN PRÉPARATION';
      case 'rejected':
        return 'REJETÉ';
      default:
        return status.toUpperCase();
    }
  }

  Widget _buildStatusFilterChip(String label, String statusValue) {
    final isSelected = _selectedStatusFilter == statusValue;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        title: 'Commandes',
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          if (authState.user!['role'] == 'livreur')
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).padding.bottom + 20,
                ),
                child: _buildLivreurOrders(),
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
                              _buildStatusFilterChip('En attente', 'pending'),
                              const SizedBox(width: 8),
                              _buildStatusFilterChip('En préparation', 'colis en cours de préparation'),
                              const SizedBox(width: 8),
                              _buildStatusFilterChip('Prêt à expédier', 'prêt à expédier'),
                              const SizedBox(width: 8),
                              _buildStatusFilterChip('En route', 'en route pour livraison'),
                              const SizedBox(width: 8),
                              _buildStatusFilterChip('Livré', 'delivered'),
                              const SizedBox(width: 8),
                              _buildStatusFilterChip('Rejeté', 'rejected'),
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
                                _buildStatusFilterChip('EN ATTENTE', 'pending'),
                                const SizedBox(width: 8),
                                _buildStatusFilterChip('EN PRÉPARATION', 'colis en cours de préparation'),
                                const SizedBox(width: 8),
                                _buildStatusFilterChip('PRÊT À EXPÉDIER', 'prêt à expédier'),
                                const SizedBox(width: 8),
                                _buildStatusFilterChip('EN ROUTE', 'en route pour livraison'),
                                const SizedBox(width: 8),
                                _buildStatusFilterChip('LIVRÉ', 'delivered'),
                                const SizedBox(width: 8),
                                _buildStatusFilterChip('ANNULÉ', 'cancelled'),
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

    final userId = authState.user!['id']?.toString() ?? '';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('carts')
          .where('idClient', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Erreur Firestore: ${snapshot.error}');
          return Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 50, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Erreur: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingShimmer();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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

        // Trier et filtrer les documents côté client
        final allDocs = snapshot.data!.docs.toList();
        
        // Filtrer par statut
        final filteredByStatus = _selectedStatusFilter == 'Tous'
            ? allDocs
            : allDocs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final status = data['status']?.toString().toLowerCase() ?? '';
                return status == _selectedStatusFilter.toLowerCase();
              }).toList();
        
        // Filtrer par recherche
        final searchQuery = _searchController.text.toLowerCase().trim();
        final filteredDocs = searchQuery.isEmpty
            ? filteredByStatus
            : filteredByStatus.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final items = data['items'] as List? ?? [];
                return items.any((item) {
                  final name = item['name']?.toString().toLowerCase() ?? '';
                  return name.contains(searchQuery);
                });
              }).toList();
        
        // Trier par date
        final sortedDocs = filteredDocs.toList()
          ..sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTimestamp = aData['timestamp'] as Timestamp?;
            final bTimestamp = bData['timestamp'] as Timestamp?;

            if (aTimestamp == null && bTimestamp == null) return 0;
            if (aTimestamp == null) return 1;
            if (bTimestamp == null) return -1;

            return bTimestamp.compareTo(aTimestamp); // Tri décroissant
          });

        if (sortedDocs.isEmpty) {
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

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          children: sortedDocs.map((doc) {
            try {
              final data = doc.data() as Map<String, dynamic>;

              // Vérification et conversion sécurisée des items
              List<Map<String, dynamic>> items = [];
              if (data['items'] != null) {
                if (data['items'] is List) {
                  items = List<Map<String, dynamic>>.from(
                    (data['items'] as List).map((item) {
                      if (item is Map) {
                        return Map<String, dynamic>.from(item);
                      }
                      return <String, dynamic>{};
                    }),
                  );
                }
              }

              final status = data['status']?.toString() ?? 'pending';
              final timestamp = data['timestamp'] as Timestamp?;
              final shortCode = data['shortCode']?.toString() ?? '';
              
              // Calculer le total
              double total = 0.0;
              for (var item in items) {
                final price = (item['price'] ?? 0.0) is double 
                    ? item['price'] as double 
                    : (item['price'] ?? 0).toDouble();
                final quantity = (item['quantity'] ?? 1) is int 
                    ? item['quantity'] as int 
                    : int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
                total += price * quantity;
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
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
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
                            orderData: data,
                            orderId: doc.id,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          // Icône de commande avec gradient
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primary.withOpacity(0.7),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.shopping_bag_outlined,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Informations principales
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (shortCode.isNotEmpty)
                                            Text(
                                              'Commande #$shortCode',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey.shade700,
                                              ),
                                            )
                                          else
                                            Text(
                                              'Commande #${doc.id.substring(0, 8)}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.calendar_today,
                                                size: 10,
                                                color: Colors.grey.shade500,
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                _formatDate(timestamp),
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
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.inventory_2_outlined,
                                          size: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          '${items.length} ${items.length > 1 ? 'produits' : 'produit'}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '$total FC',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Bouton générer facture PDF
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.2),
                                width: 0.5,
                              ),
                            ),
                            child: InkWell(
                              onTap: () {
                                _generateInvoiceForClient(
                                  context,
                                  data,
                                  doc.id,
                                  items,
                                );
                              },
                              child: Icon(
                                Icons.picture_as_pdf,
                                size: 14,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Bouton voir détails
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
                              size: 14,
                              color: AppColors.primary,
                            ),
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
                child: const Text(
                  'Erreur lors de l\'affichage de la commande',
                  style: TextStyle(color: Colors.red),
                ),
              );
            }
          }).toList(),
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

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('carts').where('status',
          whereIn: ['prêt à expédier', 'en route pour livraison', 'delivered']).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(32.0),
            child: Center(
              child: Text(
                'Erreur: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const OrderCardShimmer(),
              const SizedBox(height: 10),
              const OrderCardShimmer(),
            ],
          );
        }

        final orders = snapshot.data!.docs;

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
              ],
            ),
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: orders.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final items = data['items'] as List? ?? [];
            final status = data['status']?.toString() ?? 'pending';
            final timestamp = data['timestamp'] as Timestamp?;
            final date = timestamp?.toDate().toString().substring(0, 10) ?? '';
            final address =
                data['address']?.toString() ?? 'Adresse non spécifiée';

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
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  if (authState.user!['role'] == 'acheteur') {
                    print('acheteur');
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderDetailsScreen(
                          orderData: data,
                          orderId: doc.id,
                        ),
                      ),
                    );
                  }
                },
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Timeline
                        Container(
                          width: 6,
                          height: 110,
                          margin: const EdgeInsets.only(
                              right: 10, top: 10, bottom: 10),
                          decoration: BoxDecoration(
                            color: _statusColor(status),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        // Image produit
                        Padding(
                          padding: const EdgeInsets.only(
                              top: 16, left: 0, right: 10),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              items.isNotEmpty
                                  ? (items[0]['imagePath'] ??
                                      'https://images.unsplash.com/photo-1560472354-b33ff0c44a43?w=200&h=200&fit=crop')
                                  : 'https://images.unsplash.com/photo-1560472354-b33ff0c44a43?w=200&h=200&fit=crop',
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 70,
                                  height: 70,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.image,
                                      color: Colors.grey),
                                );
                              },
                            ),
                          ),
                        ),
                        // Détails commande
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        items.isNotEmpty
                                            ? (items[0]['name'] ?? 'Produit')
                                            : 'Produit',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _statusColor(status)
                                            .withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _translateStatus(status),
                                        style: TextStyle(
                                          color: _statusColor(status),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on,
                                        size: 14, color: AppColors.primary),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        data['adresse'] ??
                                            'Adresse non spécifiée',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.shopping_cart,
                                        size: 14, color: AppColors.primary),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${items.length} article${items.length > 1 ? 's' : ''}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    const SizedBox(width: 12),
                                    const Icon(Icons.calendar_today,
                                        size: 14, color: AppColors.primary),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDate(timestamp),
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Bouton pour accepter la livraison
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          if (status == 'prêt à expédier' &&
                              data['packagePhoto'] != null) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Photo du colis:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return Dialog(
                                            insetPadding: EdgeInsets.zero,
                                            child: Stack(
                                              children: [
                                                InteractiveViewer(
                                                  minScale: 0.5,
                                                  maxScale: 4.0,
                                                  child: Image.network(
                                                    data['packagePhoto'],
                                                    fit: BoxFit.contain,
                                                    width: MediaQuery.of(context)
                                                        .size
                                                        .width,
                                                    height: MediaQuery.of(context)
                                                        .size
                                                        .height,
                                                  ),
                                                ),
                                                Positioned(
                                                  top: 10,
                                                  right: 10,
                                                  child: IconButton(
                                                    icon: const Icon(Icons.close,
                                                        color: Colors.white),
                                                    onPressed: () =>
                                                        Navigator.pop(context),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        data['packagePhoto'],
                                        width: double.infinity,
                                        height: 150,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            width: double.infinity,
                                            height: 150,
                                            color: Colors.grey.shade200,
                                            child: const Icon(Icons.image,
                                                color: Colors.grey),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (status != 'delivered') ...[
                            ElevatedButton(
                              onPressed: () async {
                                if (status == 'prêt à expédier') {
                                  _updateClientLocation(data['longitude'], data['latitude'], data['idClient']);
                                  _saveCurrentLocation();
                                  try {
                                    await FirebaseFirestore.instance
                                        .collection('carts')
                                        .doc(doc.id)
                                        .update({
                                      'status': 'en route pour livraison',
                                      'livreur': authState.user!['id'].toString(),
                                      'shortCode': generate4DigitCode(),
                                      'timestamp': FieldValue.serverTimestamp(),
                                    });

                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Colis reçu avec succès'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
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
                                } else if (status == 'en route pour livraison') {
                                  final shortCode = data['shortCode']??"";
                                  
                                  _showCodeConfirmationDialog(
                                    context,
                                    doc.id,
                                    shortCode,
                                    authState.user!['id'].toString(),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                minimumSize: const Size(double.infinity, 40),
                              ),
                              child: Text(
                                status == 'prêt à expédier'
                                    ? 'Recevoir colis'
                                    : 'Confirmer la livraison',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
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

    final userId = authState.user!['id']?.toString() ?? '';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('carts').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Erreur Firestore: ${snapshot.error}');
          return Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 50, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Erreur: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingShimmer();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox,
                    size: 80, color: AppColors.buttonColor.withOpacity(0.3)),
                const SizedBox(height: 18),
                const Text(
                  'Aucune commande reçue',
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

        // Filtrer les commandes par vendeur
        var filteredDocs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['items'] == null) return false;

          final items = data['items'] as List;
          return items.any((item) {
            if (item is Map) {
              return item['idVendeur'] == userId;
            }
            return false;
          });
        }).toList();

        // Filtrer par statut
        if (_selectedStatusFilter != 'Tous') {
          filteredDocs = filteredDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status']?.toString().toLowerCase() ?? '';
            return status == _selectedStatusFilter.toLowerCase();
          }).toList();
        }

        // Filtrer par recherche
        final searchQuery = _searchController.text.toLowerCase().trim();
        if (searchQuery.isNotEmpty) {
          filteredDocs = filteredDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final clientName = (data['client']?.toString() ?? '').toLowerCase();
            final shortCode = (data['shortCode']?.toString() ?? '').toLowerCase();
            final orderId = doc.id.toLowerCase();
            final items = data['items'] as List? ?? [];
            final productNames = items.map((item) {
              if (item is Map) {
                return (item['name']?.toString() ?? '').toLowerCase();
              }
              return '';
            }).join(' ');

            return clientName.contains(searchQuery) ||
                shortCode.contains(searchQuery) ||
                orderId.contains(searchQuery) ||
                productNames.contains(searchQuery);
          }).toList();
        }

        if (filteredDocs.isEmpty) {
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

        // Trier les commandes par date
        filteredDocs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTimestamp = aData['timestamp'] as Timestamp?;
          final bTimestamp = bData['timestamp'] as Timestamp?;

          if (aTimestamp == null && bTimestamp == null) return 0;
          if (aTimestamp == null) return 1;
          if (bTimestamp == null) return -1;

          return bTimestamp.compareTo(aTimestamp); // Tri décroissant
        });

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            try {
              final doc = filteredDocs[index];
              final data = doc.data() as Map<String, dynamic>;
              final status = data['status']?.toString() ?? 'pending';
              final timestamp = data['timestamp'] as Timestamp?;
              final adresse =
                  data['adresse']?.toString() ?? 'Adresse non spécifiée';

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
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
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
                            orderData: data,
                            orderId: doc.id,
                          ),
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              // Icône de commande avec gradient
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.primary.withOpacity(0.7),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.shopping_bag_outlined,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Informations principales
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                data['items'] != null &&
                                                        (data['items'] as List)
                                                            .isNotEmpty
                                                    ? (data['items'] as List)[0]
                                                            ['name'] ??
                                                        'Produit'
                                                    : 'Produit',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.grey.shade700,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 3),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.calendar_today,
                                                    size: 10,
                                                    color: Colors.grey.shade500,
                                                  ),
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    _formatDate(timestamp),
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
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.inventory_2_outlined,
                                              size: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              '${(data['items'] as List?)?.length ?? 0} ${((data['items'] as List?)?.length ?? 0) > 1 ? 'produits' : 'produit'}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey.shade700,
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
                                            size: 14,
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
                      ],
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
                child: const Text(
                  'Erreur lors de l\'affichage de la commande',
                  style: TextStyle(color: Colors.red),
                ),
              );
            }
          },
        );
      },
    );
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

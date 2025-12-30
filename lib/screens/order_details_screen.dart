import 'package:flutter/material.dart';
import 'package:immo/constants.dart';
import 'package:immo/widgets/app_logo.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:immo/cubit/auth_cubit.dart';
import 'package:immo/cubit/order_cubit.dart';
import 'package:immo/services/invoice_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'order_screen.dart'; // Pour accéder à CameraColisScreen

class OrderDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> orderData;
  final String orderId;

  const OrderDetailsScreen({
    Key? key,
    required this.orderData,
    required this.orderId,
  }) : super(key: key);

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  List<CameraDescription>? cameras;

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
      case 'a la recherche du livreur':
        return 'RECHERCHE LIVREUR';
      default:
        return status.toUpperCase();
    }
  }


  String _generate4DigitCode() {
    final random = Random();
    int code = 1000 + random.nextInt(9000); // Génère un nombre entre 1000 et 9999
    return code.toString();
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
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                    Navigator.pop(context); // Retour à la liste
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Erreur: $e'),
                                        backgroundColor: Colors.red,
                                        behavior: SnackBarBehavior.floating,
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

  Future<void> _generateInvoice(BuildContext context, dynamic authState) async {
    if (authState is! AuthSuccess || authState.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de générer la facture. Utilisateur non connecté.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = authState.user!;
    
    // Informations du marchand
    final merchantInfo = {
      'firstName': user['firstName'] ?? '',
      'lastName': user['lastName'] ?? '',
      'name': '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim(),
      'phone': user['phone'] ?? '',
      'email': user['email'] ?? '',
    };

    // Informations du client
    final clientInfo = {
      'name': widget.orderData['client']?.toString() ?? 'Client',
      'phone': widget.orderData['phone']?.toString() ?? '',
      'address': widget.orderData['adresse']?.toString() ?? 'Adresse non spécifiée',
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
      await InvoiceService.generateInvoice(
        context: context,
        orderData: widget.orderData,
        orderId: widget.orderId,
        merchantInfo: merchantInfo,
        clientInfo: clientInfo,
      );
    } finally {
      if (context.mounted) {
        Navigator.of(context).pop(); // Fermer le dialog de chargement
      }
    }
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
                                      if (cameras == null || cameras!.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Caméra non disponible'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return;
                                      }
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
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                          'Erreur lors de l\'upload : $e'),
                                                      backgroundColor: Colors.red,
                                                    ),
                                                  );
                                                }
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

                                  if (context.mounted) {
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
                                  if (context.mounted) {
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

  // Helper pour parser les montants
  double _parseAmount(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // Helper pour formater la date
  String _formatDateString(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final String? userRole = (authState is AuthSuccess) ? authState.user != null ? authState.user!['role'] : null : null;
    
    // Nouvelle structure de données
    final items = widget.orderData['items'] as List? ?? widget.orderData['products'] as List? ?? [];
    final status = widget.orderData['status']?.toString() ?? 'pending';
    final createdAt = widget.orderData['createdAt']?.toString() ?? '';
    final updatedAt = widget.orderData['updatedAt']?.toString() ?? '';
    final address = widget.orderData['address'] as Map<String, dynamic>? ?? {};
    final phone = widget.orderData['phone']?.toString() ?? '';
    // Extraire le nom du client depuis l'email ou utiliser une valeur par défaut
    final clientEmail = widget.orderData['client']?.toString() ?? '';
    String clientName = 'Client';
    if (clientEmail.isNotEmpty) {
      // Extraire le nom depuis l'email (partie avant @)
      final nameFromEmail = clientEmail.split('@').first;
      if (nameFromEmail.isNotEmpty) {
        clientName = nameFromEmail[0].toUpperCase() + nameFromEmail.substring(1);
      }
    }
    final packagePhoto = widget.orderData['packagePhoto']?.toString();
    final paymentMethod = widget.orderData['paymentMethod'] as Map<String, dynamic>? ?? {};
    final numeroPayment = widget.orderData['numeroPayment']?.toString();
    final codeColis = widget.orderData['codeColis']?.toString();
    final distanceKm = widget.orderData['distanceKm']?.toString() ?? '';
    
    // Calculer les totaux
    final totalProduit = _parseAmount(widget.orderData['total'] ?? 0);
    final deliveryFee = _parseAmount(widget.orderData['deliveryFee'] ?? 0);
    final totalAvecLivraison = totalProduit + deliveryFee;
    
    // Formater l'adresse
    final adresseFormatee = address.isNotEmpty
        ? '${address['numero'] ?? ''} ${address['avenue'] ?? ''}, ${address['quartier'] ?? ''}, ${address['commune'] ?? ''}, ${address['ville'] ?? ''}, ${address['pays'] ?? ''}'
        : 'Adresse non spécifiée';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBarWithLogo(
        title: 'Détails de la commande',
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // En-tête élégant avec gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.receipt_long,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.orderId.length > 8 ? '#${widget.orderId.substring(0, 8)}' : '#$widget.orderId',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 12, color: Colors.white.withOpacity(0.9)),
                            const SizedBox(width: 5),
                            Text(
                              _formatDateString(createdAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      _translateStatus(status),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Contenu principal
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informations client - Redesign moderne
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.person_outline,
                                color: AppColors.primary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Informations client',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    clientName,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  if (clientEmail.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.email_outlined,
                                          size: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            clientEmail,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade700,
                                              fontWeight: FontWeight.w400,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (phone.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.phone,
                                          size: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            phone,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade700,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (userRole != null && userRole != 'acheteur' && phone.isNotEmpty)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.green.shade200,
                                    width: 1,
                                  ),
                                ),
                                child: IconButton(
                                  padding: const EdgeInsets.all(8),
                                  iconSize: 18,
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return Dialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.all(20),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Text(
                                                  'Contacter le client',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  clientName,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                                const SizedBox(height: 20),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                  children: [
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        if (phone.isNotEmpty) {
                                                          launchUrl(Uri.parse('tel:$phone'));
                                                        } else {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                  'Numéro de téléphone non disponible'),
                                                              backgroundColor: Colors.red,
                                                            ),
                                                          );
                                                        }
                                                        Navigator.pop(context);
                                                      },
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: AppColors.primary,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        padding: const EdgeInsets.symmetric(
                                                            horizontal: 20, vertical: 12),
                                                      ),
                                                      child: const Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(Icons.phone, color: Colors.white),
                                                          SizedBox(width: 8),
                                                          Text('Appeler',
                                                              style: TextStyle(color: Colors.white)),
                                                        ],
                                                      ),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        if (phone.isNotEmpty) {
                                                          final whatsappUrl = 'https://wa.me/$phone';
                                                          launchUrl(Uri.parse(whatsappUrl));
                                                        } else {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                  'Numéro de téléphone non disponible'),
                                                              backgroundColor: Colors.red,
                                                            ),
                                                          );
                                                        }
                                                        Navigator.pop(context);
                                                      },
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: Colors.green,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        padding: const EdgeInsets.symmetric(
                                                            horizontal: 20, vertical: 12),
                                                      ),
                                                      child: const Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(Icons.message, color: Colors.white),
                                                          SizedBox(width: 8),
                                                          Text('WhatsApp',
                                                              style: TextStyle(color: Colors.white)),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 16),
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: const Text(
                                                    'ANNULER',
                                                    style: TextStyle(color: Colors.grey),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  icon: Icon(
                                    Icons.phone_in_talk,
                                    color: Colors.green.shade700,
                                    size: 18,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Divider(height: 1, color: Colors.grey.shade200),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          icon: Icons.location_on,
                          label: 'Adresse de livraison',
                          value: adresseFormatee,
                        ),
                        if (distanceKm.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            icon: Icons.straighten,
                            label: 'Distance',
                            value: '$distanceKm km',
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Liste des produits
                  _buildSectionCard(
                    title: 'Articles commandés',
                    icon: Icons.shopping_bag_outlined,
                    child: Column(
                      children: items.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        final isLast = index == items.length - 1;
                        final itemPrice = ((item['price'] ?? 0.0) is double 
                            ? item['price'] as double 
                            : (item['price'] ?? 0).toDouble());
                        final itemQuantity = (item['quantity'] ?? 1) is int 
                            ? item['quantity'] as int 
                            : int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
                        final itemTotal = itemPrice * itemQuantity;

                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item['name']?.toString() ?? 'Produit',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'x$itemQuantity',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '$itemTotal FC',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            if (!isLast) ...[
                              const SizedBox(height: 8),
                              Divider(
                                height: 1,
                                color: Colors.grey.shade200,
                              ),
                              const SizedBox(height: 8),
                            ],
                          ],
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Informations de paiement - Compact (2 lignes max)
                  if (paymentMethod.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          // Image du moyen de paiement
                          if (paymentMethod['imageUrl'] != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                paymentMethod['imageUrl'],
                                width: 35,
                                height: 35,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 35,
                                    height: 35,
                                    color: Colors.grey.shade200,
                                    child: Icon(Icons.payment, color: Colors.grey.shade400, size: 18),
                                  );
                                },
                              ),
                            ),
                          if (paymentMethod['imageUrl'] != null) const SizedBox(width: 8),
                          // Informations en 2 lignes max
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Ligne 1: Nom du moyen de paiement
                                Text(
                                  paymentMethod['name']?.toString() ?? paymentMethod['type']?.toString() ?? 'N/A',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                // Ligne 2: Nom titulaire et numéro de compte (ou numéro à débiter)
                                if (paymentMethod['nomTitulaire'] != null || paymentMethod['numeroCompte'] != null || (numeroPayment != null && numeroPayment.isNotEmpty))
                                  const SizedBox(height: 3),
                                if (paymentMethod['nomTitulaire'] != null && paymentMethod['numeroCompte'] != null)
                                  Text(
                                    '${paymentMethod['nomTitulaire']} • ${paymentMethod['numeroCompte']}',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.grey.shade600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                else if (paymentMethod['nomTitulaire'] != null)
                                  Text(
                                    paymentMethod['nomTitulaire']?.toString() ?? '',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.grey.shade600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                else if (paymentMethod['numeroCompte'] != null)
                                  Text(
                                    paymentMethod['numeroCompte']?.toString() ?? '',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.grey.shade600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                else if (numeroPayment != null && numeroPayment.isNotEmpty)
                                  Text(
                                    numeroPayment,
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.grey.shade600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Informations supplémentaires (sans les IDs)
                  if (codeColis != null && codeColis.isNotEmpty || updatedAt.isNotEmpty) ...[
                    _buildSectionCard(
                      title: 'Informations supplémentaires',
                      icon: Icons.info_outline,
                      child: Column(
                        children: [
                          if (codeColis != null && codeColis.isNotEmpty) ...[
                            _buildInfoRow(
                              icon: Icons.qr_code,
                              label: 'Code colis',
                              value: codeColis,
                            ),
                          ],
                          if (updatedAt.isNotEmpty) ...[
                            if (codeColis != null && codeColis.isNotEmpty) const SizedBox(height: 10),
                            _buildInfoRow(
                              icon: Icons.update,
                              label: 'Dernière mise à jour',
                              value: _formatDateString(updatedAt),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Photo du colis (si disponible)
                  if (packagePhoto != null && packagePhoto.isNotEmpty) ...[
                    _buildSectionCard(
                      title: 'Photo du colis',
                      icon: Icons.inventory_2_outlined,
                      child: GestureDetector(
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
                                        packagePhoto,
                                        fit: BoxFit.contain,
                                        width: MediaQuery.of(context).size.width,
                                        height: MediaQuery.of(context).size.height,
                                      ),
                                    ),
                                    Positioned(
                                      top: 10,
                                      right: 10,
                                      child: IconButton(
                                        icon: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.5),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                        onPressed: () => Navigator.pop(context),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              Image.network(
                                packagePhoto,
                                width: double.infinity,
                                height: 140,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: double.infinity,
                                    height: 140,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.image_not_supported,
                                      color: Colors.grey.shade400,
                                      size: 36,
                                    ),
                                  );
                                },
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.fullscreen,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Résumé de la commande - Compact
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Total produit et Frais de livraison en spaceBetween
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total produit',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${totalProduit.toStringAsFixed(0)} FC',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Frais de livraison',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${deliveryFee.toStringAsFixed(0)} FC',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Divider(height: 1, color: Colors.grey.shade200),
                        const SizedBox(height: 8),
                        // Total général en bas
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total général',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              '${totalAvecLivraison.toStringAsFixed(0)} FC',
                              style: const TextStyle(
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

                  const SizedBox(height: 12),

                  // Boutons d'action pour les marchands
                  if (userRole == 'vendeur') ...[
                    // Widget pour gérer les actions (Accepter, Rejeter, Commencer)
                    if (status == 'pending_payment' || status == 'pending')
                      _VendeurOrderActionsWidget(
                        orderId: widget.orderId,
                        orderData: widget.orderData,
                        onStatusChanged: () {
                          // Rafraîchir les données si nécessaire
                          Navigator.pop(context);
                        },
                      ),
                    // Boutons pour en_preparation (workflow séquentiel)
                    if (status == 'en_preparation') ...[
                      _buildEnPreparationActions(
                        context, 
                        widget.orderId, 
                        packagePhoto,
                        onStatusChanged: () {
                          Navigator.pop(context, true);
                        },
                      ),
                    ],
                    // Bouton Expédier (si colis en cours de préparation)
                    if (status == 'colis en cours de préparation')
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withOpacity(0.9),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _showExpeditionDialog(context, widget.orderId);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          icon: const Icon(
                            Icons.local_shipping_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                          label: const Text(
                            'Expédier la commande',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                  ] else if (userRole == 'livreur') ...[
                    // Boutons d'action pour les livreurs
                    if (status == 'prêt à expédier')
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withOpacity(0.9),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(10),
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final authState = context.read<AuthCubit>().state;
                            if (authState is! AuthSuccess || authState.user == null) return;
                            
                            // Mettre à jour la localisation
                            // _updateClientLocation et _saveCurrentLocation seraient appelés ici
                            // mais ces méthodes sont dans order_screen.dart
                            
                            try {
                              await FirebaseFirestore.instance
                                  .collection('carts')
                                  .doc(widget.orderId)
                                  .update({
                                'status': 'en route pour livraison',
                                'livreur': authState.user!['id'].toString(),
                                'shortCode': _generate4DigitCode(),
                                'timestamp': FieldValue.serverTimestamp(),
                              });

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Colis reçu avec succès'),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                Navigator.pop(context);
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Erreur: $e'),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: const Icon(
                            Icons.check_circle_outline,
                            color: Colors.white,
                            size: 16,
                          ),
                          label: const Text(
                            'Recevoir colis',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    if (status == 'en route pour livraison')
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.shade600,
                              Colors.green.shade700,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(10),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final authState = context.read<AuthCubit>().state;
                            if (authState is! AuthSuccess || authState.user == null) return;
                            
                            final shortCode = widget.orderData['shortCode']?.toString() ?? '';
                            _showCodeConfirmationDialog(
                              context,
                              widget.orderId,
                              shortCode,
                              authState.user!['id'].toString(),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: const Icon(
                            Icons.local_shipping_outlined,
                            color: Colors.white,
                            size: 16,
                          ),
                          label: const Text(
                            'Confirmer la livraison',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                  ] else if (status.toLowerCase() == 'pending')
                    // Bouton d'annulation pour les clients
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          // Logique d'annulation
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Annuler la commande',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 80), // Espace pour le FAB
                ],
              ),
            ),
          ],
        ),
      ),
      // Bouton flottant pour générer la facture PDF (uniquement pour les marchands)
      floatingActionButton: userRole == 'vendeur'
          ? FloatingActionButton.extended(
              onPressed: () => _generateInvoice(context, authState),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
              label: const Text(
                'Générer la facture',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              tooltip: 'Générer la facture PDF',
            )
          : null,
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade100,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.15),
                      AppColors.primary.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.primary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  // Widget pour les actions en préparation
  Widget _buildEnPreparationActions(
    BuildContext context, 
    String orderId, 
    String? packagePhoto, {
    VoidCallback? onStatusChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          if (packagePhoto == null || packagePhoto.isEmpty)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await _uploadPackagePhoto(context, orderId);
                  if (onStatusChanged != null) {
                    onStatusChanged();
                  }
                },
                icon: const Icon(Icons.camera_alt, size: 16),
                label: const Text(
                  'Prendre une photo du colis',
                  style: TextStyle(fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            )
          else ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Photo du colis uploadée',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: packagePhoto != null && packagePhoto.isNotEmpty
                  ? () async {
                      await _markReadyToShip(context, orderId);
                      if (onStatusChanged != null) {
                        onStatusChanged();
                      }
                    }
                  : null,
              icon: const Icon(Icons.local_shipping, size: 16),
              label: const Text(
                'Marquer prêt à expédier',
                style: TextStyle(fontSize: 12),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadPackagePhoto(BuildContext context, String orderId) async {
    try {
      print('🔄 [OrderDetailsScreen] Étape 3: Uploader photo du colis');
      print('   📦 OrderId: $orderId');
      
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image == null) {
        print('❌ [OrderDetailsScreen] Aucune image sélectionnée');
        return;
      }

      print('📷 [OrderDetailsScreen] Image sélectionnée: ${image.path}');

      if (context.mounted) {
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

      if (context.mounted) {
        if (result['success'] == true) {
          print('✅ [OrderDetailsScreen] Photo uploadée avec succès');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo uploadée avec succès. Vous pouvez maintenant marquer la commande comme prête à expédier.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          // Rafraîchir les données pour afficher l'étape suivante
          Navigator.pop(context, true);
        } else {
          print('❌ [OrderDetailsScreen] Erreur: ${result['message']}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Erreur lors de l\'upload'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('💥 [OrderDetailsScreen] Exception: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markReadyToShip(BuildContext context, String orderId) async {
    try {
      print('🔄 [OrderDetailsScreen] Étape 4: Marquer prêt à expédier');
      print('   📦 OrderId: $orderId');
      print('   📊 Status: pret_a_expedier');
      print('   📝 Reason: Colis prêt pour livraison');
      
      final result = await context.read<OrderCubit>().updateOrderStatus(
        orderId: orderId,
        status: 'pret_a_expedier',
        reason: 'Colis prêt pour livraison',
      );

      if (context.mounted) {
        if (result['success'] == true) {
          print('✅ [OrderDetailsScreen] Commande marquée comme prête à expédier');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Commande marquée comme prête à expédier'),
              backgroundColor: Colors.green,
            ),
          );
          // Rafraîchir les données
          Navigator.pop(context, true);
        } else {
          print('❌ [OrderDetailsScreen] Erreur: ${result['message']}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Erreur lors de la mise à jour'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('💥 [OrderDetailsScreen] Exception: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Widget pour gérer les actions de commande (Accepter, Rejeter, Commencer)
class _VendeurOrderActionsWidget extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic> orderData;
  final VoidCallback onStatusChanged;

  const _VendeurOrderActionsWidget({
    required this.orderId,
    required this.orderData,
    required this.onStatusChanged,
  });

  @override
  State<_VendeurOrderActionsWidget> createState() => _VendeurOrderActionsWidgetState();
}

class _VendeurOrderActionsWidgetState extends State<_VendeurOrderActionsWidget> {
  bool _isAccepted = false;
  bool _isRejected = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    final status = widget.orderData['status']?.toString() ?? 'pending';
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
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      print('🔄 [OrderDetailsScreen] Étape 2: Commencer la préparation');
      print('   📦 OrderId: ${widget.orderId}');
      print('   📊 Status: en_preparation');
      print('   📝 Reason: Commande prise en charge');
      
      final result = await context.read<OrderCubit>().updateOrderStatus(
        orderId: widget.orderId,
        status: 'en_preparation',
        reason: 'Commande prise en charge',
      );

      if (mounted) {
        if (result['success'] == true) {
          print('✅ [OrderDetailsScreen] Préparation commencée avec succès');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Préparation de la commande commencée. Vous pouvez maintenant uploader la photo du colis.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          // Rafraîchir les données pour afficher l'étape suivante
          widget.onStatusChanged();
        } else {
          print('❌ [OrderDetailsScreen] Erreur: ${result['message']}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Erreur lors de la mise à jour'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('💥 [OrderDetailsScreen] Exception: $e');
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
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Titre de la section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.touch_app_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Actions sur la commande',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
                    size: 16,
                    color: _isAccepted
                        ? Colors.green
                        : (_isRejected || _isProcessing
                            ? Colors.grey
                            : AppColors.primary),
                  ),
                  label: Text(
                    _isAccepted ? 'Acceptée' : 'Accepter',
                    style: TextStyle(
                      fontSize: 12,
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
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
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
                    size: 16,
                    color: _isRejected
                        ? Colors.red
                        : (_isAccepted || _isProcessing
                            ? Colors.grey
                            : Colors.red.shade600),
                  ),
                  label: Text(
                    _isRejected ? 'Rejetée' : 'Rejeter',
                    style: TextStyle(
                      fontSize: 12,
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
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Bouton Commencer la préparation (toujours actif)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: !_isProcessing
                  ? _startPreparation
                  : null,
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text(
                'Commencer la préparation',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade600,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 
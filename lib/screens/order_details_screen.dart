import 'package:flutter/material.dart';
import 'package:immo/constants.dart';
import 'package:immo/widgets/app_logo.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:immo/cubit/auth_cubit.dart';
import 'package:immo/services/invoice_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:camera/camera.dart';
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

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
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

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final String? userRole = (authState is AuthSuccess) ? authState.user != null ? authState.user!['role'] : null : null;
    final items = widget.orderData['items'] as List? ?? [];
    final status = widget.orderData['status']?.toString() ?? 'pending';
    final timestamp = widget.orderData['timestamp'];
    final adresse = widget.orderData['adresse']?.toString() ?? 'Adresse non spécifiée';
    final phone = widget.orderData['phone']?.toString() ?? '';
    final clientName = widget.orderData['client']?.toString() ?? 'Client';
    final shortCode = widget.orderData['shortCode']?.toString() ?? '';
    
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
            // En-tête compact avec gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shortCode.isNotEmpty ? '#$shortCode' : '#${widget.orderId.substring(0, 8)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 13, color: Colors.white70),
                            const SizedBox(width: 5),
                            Text(
                              _formatDate(timestamp),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _translateStatus(status),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Contenu principal
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informations client
                  _buildSectionCard(
                    title: 'Informations client',
                    icon: Icons.person_outline,
                    child: Column(
                      children: [
                        _buildInfoRow(
                          icon: Icons.person,
                          label: 'Nom',
                          value: clientName,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          icon: Icons.phone,
                          label: 'Téléphone',
                          value: phone,
                          trailing: userRole != null && userRole != 'acheteur'
                              ? OutlinedButton.icon(
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
                                  icon: Icon(Icons.phone_in_talk, color: Colors.green.shade600, size: 14),
                                  label: const Text(
                                    'Contacter',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.green.shade600,
                                    side: BorderSide(
                                      color: Colors.green.shade600,
                                      width: 1,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          icon: Icons.location_on,
                          label: 'Adresse de livraison',
                          value: adresse,
                        ),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Image du produit
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: item['imagePath'] != null
                                        ? Image.network(
                                            item['imagePath'],
                                            width: 70,
                                            height: 70,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                width: 70,
                                                height: 70,
                                                color: Colors.grey.shade200,
                                                child: Icon(
                                                  Icons.image,
                                                  color: Colors.grey.shade400,
                                                  size: 24,
                                                ),
                                              );
                                            },
                                          )
                                        : Icon(
                                            Icons.image,
                                            color: Colors.grey.shade400,
                                            size: 24,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Détails du produit
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['name']?.toString() ?? 'Produit',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(5),
                                            ),
                                            child: Text(
                                              'Qté: $itemQuantity',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade700,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            '$itemTotal FC',
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
                              ],
                            ),
                            if (!isLast) ...[
                              const SizedBox(height: 14),
                              Divider(
                                height: 1,
                                color: Colors.grey.shade200,
                              ),
                              const SizedBox(height: 14),
                            ],
                          ],
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Photo du colis (si disponible)
                  if (widget.orderData['packagePhoto'] != null &&
                      (status.toLowerCase() == 'prêt à expédier' ||
                          status.toLowerCase() == 'en route pour livraison' ||
                          status.toLowerCase() == 'delivered'))
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
                                        widget.orderData['packagePhoto'],
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
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            widget.orderData['packagePhoto'],
                            width: double.infinity,
                            height: 160,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: double.infinity,
                                height: 160,
                                color: Colors.grey.shade200,
                                child: Icon(
                                  Icons.image,
                                  color: Colors.grey.shade400,
                                  size: 40,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Résumé de la commande
                  Container(
                    padding: const EdgeInsets.all(16),
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          '$total FC',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Boutons d'action pour les marchands
                  if (userRole == 'vendeur') ...[
                    // Boutons Accepter/Rejeter (si pending)
                    if (status.toLowerCase() == 'pending')
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 0.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          children: [
                            // Titre de la section
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Icon(
                                    Icons.touch_app_outlined,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Actions rapides',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Boutons Accepter/Rejeter
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () async {
                                      try {
                                        await FirebaseFirestore.instance
                                            .collection('carts')
                                            .doc(widget.orderId)
                                            .update({
                                          'status': 'colis en cours de préparation',
                                          'timestamp': FieldValue.serverTimestamp(),
                                        });
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Commande acceptée avec succès'),
                                              backgroundColor: Colors.green,
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                          Navigator.pop(context);
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
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
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      side: BorderSide(
                                        color: AppColors.primary,
                                        width: 1,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.check_circle_outline,
                                          color: AppColors.primary,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 5),
                                        const Text(
                                          'Accepter',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () async {
                                      final TextEditingController reasonController =
                                          TextEditingController();
                                      bool? confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return StatefulBuilder(
                                            builder: (context, setState) {
                                              return AlertDialog(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(16),
                                                ),
                                                title: const Row(
                                                  children: [
                                                    Icon(Icons.warning_amber_rounded,
                                                        color: Colors.red),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      'Rejeter la commande',
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                content: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      'Veuillez indiquer la raison du rejet de cette commande.',
                                                      style: TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 16),
                                                    TextField(
                                                      controller: reasonController,
                                                      decoration: InputDecoration(
                                                        hintText: 'Entrez la raison du rejet',
                                                        border: OutlineInputBorder(
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        filled: true,
                                                        fillColor: Colors.grey.shade50,
                                                        prefixIcon: const Icon(Icons.edit_note,
                                                            color: Colors.grey),
                                                      ),
                                                      maxLines: 3,
                                                      onChanged: (value) => setState(() {}),
                                                    ),
                                                  ],
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context, false),
                                                    child: const Text(
                                                      'ANNULER',
                                                      style: TextStyle(color: Colors.grey),
                                                    ),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: reasonController.text.trim().isEmpty
                                                        ? null
                                                        : () => Navigator.pop(context, true),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.red,
                                                      disabledBackgroundColor:
                                                          Colors.red.withOpacity(0.5),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                    ),
                                                    child: const Text(
                                                      'REJETER',
                                                      style: TextStyle(color: Colors.white),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      );
                                      if (confirmed == true && reasonController.text.trim().isNotEmpty) {
                                        try {
                                          await FirebaseFirestore.instance
                                              .collection('carts')
                                              .doc(widget.orderId)
                                              .update({
                                            'status': 'rejected',
                                            'rejectionReason': reasonController.text.trim(),
                                            'timestamp': FieldValue.serverTimestamp(),
                                          });
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Commande rejetée'),
                                                backgroundColor: Colors.red,
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                            Navigator.pop(context);
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
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
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red.shade600,
                                      side: BorderSide(
                                        color: Colors.red.shade600,
                                        width: 1,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.cancel_outlined,
                                          color: Colors.red.shade600,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 5),
                                        const Text(
                                          'Rejeter',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    // Bouton Expédier (si colis en cours de préparation)
                    if (status == 'colis en cours de préparation')
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
                        padding: const EdgeInsets.all(14),
                        child: ElevatedButton(
                          onPressed: () {
                            _showExpeditionDialog(context, widget.orderId);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'Expédier',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
} 
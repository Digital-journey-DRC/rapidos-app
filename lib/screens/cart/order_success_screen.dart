import 'package:flutter/material.dart';
import 'package:immo/constants.dart';
import 'package:immo/services/invoice_service.dart';
import 'package:immo/cubit/auth_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'pending_payment_screen.dart';

class OrderSuccessScreen extends StatefulWidget {
  final int vendeurId;
  final List<Map<String, dynamic>> vendeurOrders;
  final Map<String, dynamic> vendeur;

  const OrderSuccessScreen({
    Key? key,
    required this.vendeurId,
    required this.vendeurOrders,
    required this.vendeur,
  }) : super(key: key);

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen> {
  bool _isGeneratingPdf = false;

  Future<void> _generatePDF() async {
    if (_isGeneratingPdf) return;

    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      // Prendre la première commande pour générer le PDF
      final firstOrder = widget.vendeurOrders.first;
      final orderId = firstOrder['orderId']?.toString() ?? firstOrder['id']?.toString() ?? '';

      // Obtenir les informations de l'utilisateur connecté (client)
      final authState = context.read<AuthCubit>().state;
      if (authState is! AuthSuccess || authState.user == null) {
        throw Exception('Utilisateur non connecté');
      }

      final user = authState.user!;

      // Informations du client
      final clientInfo = {
        'name': user['firstName'] != null && user['lastName'] != null
            ? '${user['firstName']} ${user['lastName']}'
            : user['email']?.toString() ?? 'Client',
        'phone': user['phone']?.toString() ?? '',
        'address': firstOrder['address']?.toString() ?? 'Adresse non spécifiée',
      };

      // Informations du vendeur
      final merchantInfo = {
        'firstName': widget.vendeur['firstName'] ?? '',
        'lastName': widget.vendeur['lastName'] ?? '',
        'name': '${widget.vendeur['firstName'] ?? ''} ${widget.vendeur['lastName'] ?? ''}'.trim(),
        'phone': widget.vendeur['phone'] ?? '',
        'email': widget.vendeur['email'] ?? '',
      };

      // Préparer les données de commande pour le PDF
      final orderData = {
        'items': widget.vendeurOrders.expand((order) {
          final products = order['products'] as List? ?? [];
          return products.map((product) => {
            'name': product['name'] ?? 'Produit',
            'quantity': product['quantity'] ?? 1,
            'price': product['price'] ?? 0,
          });
        }).toList(),
        'total': widget.vendeurOrders.fold<double>(
          0.0,
          (sum, order) => sum + (double.tryParse(order['total']?.toString() ?? '0') ?? 0.0),
        ),
        'deliveryFee': widget.vendeurOrders.fold<double>(
          0.0,
          (sum, order) => sum + (double.tryParse(order['deliveryFee']?.toString() ?? '0') ?? 0.0),
        ),
        'client': clientInfo['name'],
        'phone': clientInfo['phone'],
        'adresse': clientInfo['address'],
        'timestamp': DateTime.now(),
      };

      await InvoiceService.generateInvoice(
        context: context,
        orderData: orderData,
        orderId: orderId,
        merchantInfo: merchantInfo,
        clientInfo: clientInfo,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la génération du PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPdf = false;
        });
      }
    }
  }

  void _returnToList() {
    // Retourner à la liste sans actualisation
    // On remplace simplement cet écran par la liste, sans recharger les données
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const PendingPaymentScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vendeurName = '${widget.vendeur['firstName'] ?? ''} ${widget.vendeur['lastName'] ?? ''}'.trim();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Confirmation',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // Pas de bouton retour
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              // Animation de succès moderne et élégante
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.8),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 80,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 32),

              // Titre avec style premium
              const Text(
                'Commande confirmée !',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: -0.8,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // Message de succès avec design premium
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Message principal
                    Text(
                      'Cette commande pour ${vendeurName.isNotEmpty ? vendeurName : 'le vendeur'} a été confirmée avec succès.',
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    // Notification avec style moderne
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary.withOpacity(0.12),
                            AppColors.primary.withOpacity(0.06),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.notifications_active_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Vous serez notifié par le vendeur pour suivre la commande',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.primary.withOpacity(0.9),
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Boutons d'action - Style moderne et élégant
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isGeneratingPdf ? null : _generatePDF,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isGeneratingPdf
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        )
                      : Icon(Icons.picture_as_pdf, size: 22, color: AppColors.primary),
                  label: Text(
                    _isGeneratingPdf ? 'Génération...' : 'Télécharger PDF',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _returnToList,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_back, size: 20),
                  label: const Text(
                    'Retourner vers la liste',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

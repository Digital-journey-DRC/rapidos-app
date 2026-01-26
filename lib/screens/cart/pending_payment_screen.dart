import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:immo/constants.dart';
import 'package:immo/cubit/order_cubit.dart';
import 'package:immo/widgets/ecommerce_loading.dart';
import 'package:immo/services/payment_method_service.dart';
import 'package:immo/services/order_service.dart';
import 'payment_method_selection_screen.dart';
import 'order_review_screen.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'dart:async';

class PendingPaymentScreen extends StatefulWidget {
  const PendingPaymentScreen({Key? key}) : super(key: key);

  @override
  State<PendingPaymentScreen> createState() => _PendingPaymentScreenState();
}

class _PendingPaymentScreenState extends State<PendingPaymentScreen> {
  final PaymentMethodService _paymentMethodService = PaymentMethodService();
  final OrderService _orderService = OrderService();
  Map<int, List<Map<String, dynamic>>>? _vendeurPaymentMethods;
  Map<int, Map<String, dynamic>> _selectedPaymentMethods = {};
  Map<int, bool> _isCancelling = {}; // Pour suivre l'état d'annulation par vendeur
  // State temporaire pour stocker les moyens de paiement non validés
  Map<int, Map<String, dynamic>> _pendingPaymentMethods = {}; // {vendeurId: {paymentMethod: {...}, numeroPayment: '...'}}
  Map<int, String?> _numeroPayments = {}; // {vendeurId: numeroPayment} pour stocker le numéro après validation
  Map<int, bool> _isConfirming = {}; // Pour suivre l'état de confirmation par vendeur
  Timer? _refreshTimer; // Timer pour rafraîchir périodiquement
  bool _isFetchingOrders = false; // Pour éviter les requêtes concurrentes
  bool _isInitialLoading = true; // Flag pour gérer le loading initial de 3 secondes
  bool _hasInitiallyFetched = false; // Flag pour éviter de fetch en boucle si la liste est vide

  @override
  void initState() {
    super.initState();
    // Charger les moyens de paiement une seule fois, sans actualisation automatique
    _loadPaymentMethods(context);
    
    // Timer de 3 secondes pour le loading initial
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPaymentMethods(BuildContext context) async {
    if (!mounted) return;
    
    try {
      final orderListState = context.read<OrderCubit>().orderListState;
      final orders = orderListState.orders;
      
      // Extraire les IDs des vendeurs uniques
      final vendeurIds = orders
          .map((order) {
            final vendeurId = order['vendeurId'];
            if (vendeurId is int) return vendeurId;
            if (vendeurId is String) return int.tryParse(vendeurId);
            return 0;
          })
          .where((id) => id != null && id > 0)
          .cast<int>()
          .toSet()
          .toList();

      // Charger les moyens de paiement pour chaque vendeur
      final paymentMethodsMap = <int, List<Map<String, dynamic>>>{};
      for (final vendeurId in vendeurIds) {
        try {
          final result = await _paymentMethodService.getVendeurPaymentMethodsForClient(vendeurId);
          if (result['success'] == true) {
            paymentMethodsMap[vendeurId] = List<Map<String, dynamic>>.from(result['paymentMethods'] ?? []);
          }
        } catch (e) {
          print('Erreur lors du chargement des moyens de paiement pour vendeur $vendeurId: $e');
        }
      }
      
      if (mounted) {
        setState(() {
          _vendeurPaymentMethods = paymentMethodsMap;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des moyens de paiement: $e');
      if (mounted) {
        setState(() {
          _vendeurPaymentMethods = {};
        });
      }
    }
  }

  // Convertir total et deliveryFee qui peuvent être String ou double
  double _parseAmount(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // Traduire le statut en français
  String _translateStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending_payment':
        return 'EN ATTENTE DE PAIEMENT';
      case 'pending':
        return 'EN ATTENTE';
      case 'en_preparation':
      case 'colis en cours de préparation':
        return 'EN PRÉPARATION';
      case 'pret_a_expedier':
      case 'prêt à expédier':
      case 'ready_to_ship':
        return 'PRÊT À EXPÉDIER';
      case 'en_route':
      case 'en route pour livraison':
      case 'in_delivery':
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

  // Obtenir la couleur selon le statut (pour Flutter UI)
  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending_payment':
        return Colors.orange;
      case 'pending':
        return AppColors.buttonColor2;
      case 'en_preparation':
      case 'colis en cours de préparation':
        return Colors.orange;
      case 'pret_a_expedier':
      case 'prêt à expédier':
      case 'ready_to_ship':
        return Colors.blue;
      case 'en_route':
      case 'en route pour livraison':
      case 'in_delivery':
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

  // Obtenir la couleur PDF selon le statut
  PdfColor _statusColorPdf(String status) {
    switch (status.toLowerCase()) {
      case 'pending_payment':
        return PdfColors.orange;
      case 'pending':
        return PdfColor.fromInt(0xFF147C3C);
      case 'en_preparation':
      case 'colis en cours de préparation':
        return PdfColors.orange;
      case 'pret_a_expedier':
      case 'prêt à expédier':
      case 'ready_to_ship':
        return PdfColors.blue;
      case 'en_route':
      case 'en route pour livraison':
      case 'in_delivery':
        return PdfColors.green;
      case 'delivered':
        return PdfColors.green;
      case 'cancelled':
        return PdfColors.red;
      case 'rejected':
        return PdfColors.red;
      default:
        return PdfColors.grey;
    }
  }


  // Grouper les commandes par vendeur
  Map<int, List<Map<String, dynamic>>> _groupOrdersByVendeur(List<dynamic> orders) {
    final grouped = <int, List<Map<String, dynamic>>>{};
    for (var order in orders) {
      final vendeurId = order['vendeurId'] as int? ?? 0;
      if (vendeurId > 0) {
        if (!grouped.containsKey(vendeurId)) {
          grouped[vendeurId] = [];
        }
        grouped[vendeurId]!.add(order as Map<String, dynamic>);
      }
    }
    return grouped;
  }

  // Calculer les totaux pour un vendeur
  Map<String, double> _calculateVendeurTotals(List<Map<String, dynamic>> orders) {
    double totalProducts = 0.0;
    double totalDelivery = 0.0;
    double totalWithDelivery = 0.0;

    for (var order in orders) {
      totalProducts += _parseAmount(order['total']);
      totalDelivery += _parseAmount(order['deliveryFee']);
      totalWithDelivery += _parseAmount(order['totalAvecLivraison']);
    }

    return {
      'products': totalProducts,
      'delivery': totalDelivery,
      'total': totalWithDelivery,
    };
  }

  // Calculer les totaux globaux
  Map<String, double> _calculateGlobalTotals(List<dynamic> orders) {
    double totalProducts = 0.0;
    double totalDelivery = 0.0;
    double totalWithDelivery = 0.0;

    for (var order in orders) {
      totalProducts += _parseAmount(order['total']);
      totalDelivery += _parseAmount(order['deliveryFee']);
      totalWithDelivery += _parseAmount(order['totalAvecLivraison']);
    }

    return {
      'products': totalProducts,
      'delivery': totalDelivery,
      'total': totalWithDelivery,
    };
  }

  // Charger le logo depuis les assets
  Future<Uint8List?> _loadLogo() async {
    try {
      final ByteData data = await rootBundle.load('assets/images/logo-rapidons.png');
      return data.buffer.asUint8List();
    } catch (e) {
      print('Erreur lors du chargement du logo: $e');
      return null;
    }
  }

  // Formater une date
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy à HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  // Générer le PDF des commandes
  Future<void> _generatePDF(List<dynamic> orders, Map<int, List<Map<String, dynamic>>> groupedOrders) async {
    try {
      final pdf = pw.Document();
      final logoBytes = await _loadLogo();
      
      // Couleurs
      final primaryColor = PdfColor.fromInt(0xFF147C3C);
      final primaryColorLight = PdfColor.fromInt(0xFFE8F5E9);
      final textColor = PdfColor.fromInt(0xFF2B2D42);
      final textLightColor = PdfColor.fromInt(0xFF8D99AE);
      final borderColor = PdfColor.fromInt(0xFFE0E0E0);
      
      // Calculer les totaux globaux
      final globalTotals = _calculateGlobalTotals(orders);
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              // En-tête
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (logoBytes != null)
                          pw.Image(
                            pw.MemoryImage(logoBytes),
                            width: 80,
                            height: 80,
                          )
                        else
                          pw.Text(
                            'RAPIDOS',
                            style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          'Récapitulatif des commandes',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Date: ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now())}',
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: textLightColor,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Total commandes',
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: textLightColor,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          '${orders.length}',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Liste des marchands et leurs commandes
              ...groupedOrders.entries.map((entry) {
                final vendeurOrders = entry.value;
                final firstOrder = vendeurOrders.first;
                final vendeur = firstOrder['vendeur'] as Map<String, dynamic>? ?? {};
                final vendeurName = '${vendeur['firstName'] ?? ''} ${vendeur['lastName'] ?? ''}'.trim();
                final vendeurPhone = vendeur['phone']?.toString() ?? '';
                final vendeurTotals = _calculateVendeurTotals(vendeurOrders);
                final paymentMethod = vendeurOrders.first['paymentMethod'] as Map<String, dynamic>? ?? {};
                
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // En-tête marchand
                    pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        color: primaryColorLight,
                        borderRadius: pw.BorderRadius.circular(8),
                        border: pw.Border.all(color: primaryColor, width: 1),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            children: [
                              pw.Text(
                                '🏪',
                                style: pw.TextStyle(fontSize: 16),
                              ),
                              pw.SizedBox(width: 8),
                              pw.Text(
                                vendeurName,
                                style: pw.TextStyle(
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                          if (vendeurPhone.isNotEmpty) ...[
                            pw.SizedBox(height: 4),
                            pw.Text(
                              'Téléphone: $vendeurPhone',
                              style: pw.TextStyle(
                                fontSize: 10,
                                color: textLightColor,
                              ),
                            ),
                          ],
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Moyen de paiement: ${paymentMethod['name'] ?? 'Non défini'}',
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: textLightColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    pw.SizedBox(height: 12),
                    
                    // Liste des commandes du marchand
                    ...vendeurOrders.map((order) {
                      final orderId = order['orderId']?.toString() ?? '';
                      final status = order['status']?.toString() ?? '';
                      final address = order['address'] as Map<String, dynamic>? ?? {};
                      final products = order['products'] as List? ?? [];
                      final total = _parseAmount(order['total']);
                      final deliveryFee = _parseAmount(order['deliveryFee']);
                      final totalAvecLivraison = _parseAmount(order['totalAvecLivraison']);
                      final createdAt = order['createdAt']?.toString() ?? '';
                      
                      return pw.Container(
                        margin: const pw.EdgeInsets.only(bottom: 12),
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey100,
                          borderRadius: pw.BorderRadius.circular(6),
                          border: pw.Border.all(color: borderColor),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            // Numéro de commande et statut
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text(
                                  'Commande #${orderId.length > 8 ? orderId.substring(0, 8) : orderId}',
                                  style: pw.TextStyle(
                                    fontSize: 11,
                                    fontWeight: pw.FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                                pw.Container(
                                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: pw.BoxDecoration(
                                    color: PdfColors.grey200,
                                    borderRadius: pw.BorderRadius.circular(4),
                                    border: pw.Border.all(color: _statusColorPdf(status), width: 0.5),
                                  ),
                                  child: pw.Text(
                                    _translateStatus(status),
                                    style: pw.TextStyle(
                                      fontSize: 8,
                                      fontWeight: pw.FontWeight.bold,
                                      color: _statusColorPdf(status),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            if (createdAt.isNotEmpty) ...[
                              pw.SizedBox(height: 4),
                              pw.Text(
                                'Date: ${_formatDate(createdAt)}',
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  color: textLightColor,
                                ),
                              ),
                            ],
                            
                            pw.SizedBox(height: 8),
                            
                            // Adresse
                            pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('📍 ', style: pw.TextStyle(fontSize: 12)),
                                pw.Expanded(
                                  child: pw.Text(
                                    '${address['avenue'] ?? ''}, ${address['numero'] ?? ''}, ${address['quartier'] ?? ''}, ${address['commune'] ?? ''}',
                                    style: pw.TextStyle(
                                      fontSize: 9,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            pw.SizedBox(height: 8),
                            
                            // Produits
                            pw.Text(
                              'Produits:',
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            ...products.map((product) {
                              final productName = product['name']?.toString() ?? 'Produit';
                              final quantity = product['quantity'] as int? ?? 1;
                              final price = _parseAmount(product['price']);
                              final productTotal = price * quantity;
                              
                              return pw.Padding(
                                padding: const pw.EdgeInsets.only(left: 8, bottom: 4),
                                child: pw.Row(
                                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                  children: [
                                    pw.Expanded(
                                      child: pw.Text(
                                        '$productName x$quantity',
                                        style: pw.TextStyle(
                                          fontSize: 9,
                                          color: textColor,
                                        ),
                                      ),
                                    ),
                                    pw.Text(
                                      '${productTotal.toStringAsFixed(0)} FC',
                                      style: pw.TextStyle(
                                        fontSize: 9,
                                        fontWeight: pw.FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            
                            pw.SizedBox(height: 8),
                            pw.Divider(color: borderColor, height: 1),
                            pw.SizedBox(height: 8),
                            
                            // Totaux de la commande
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text(
                                  'Sous-total:',
                                  style: pw.TextStyle(
                                    fontSize: 9,
                                    color: textLightColor,
                                  ),
                                ),
                                pw.Text(
                                  '${total.toStringAsFixed(0)} FC',
                                  style: pw.TextStyle(
                                    fontSize: 9,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                            pw.SizedBox(height: 4),
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text(
                                  'Livraison:',
                                  style: pw.TextStyle(
                                    fontSize: 9,
                                    color: textLightColor,
                                  ),
                                ),
                                pw.Text(
                                  '${deliveryFee.toStringAsFixed(0)} FC',
                                  style: pw.TextStyle(
                                    fontSize: 9,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                            pw.SizedBox(height: 4),
                            pw.Divider(color: borderColor, height: 1),
                            pw.SizedBox(height: 4),
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text(
                                  'Total:',
                                  style: pw.TextStyle(
                                    fontSize: 11,
                                    fontWeight: pw.FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                pw.Text(
                                  '${totalAvecLivraison.toStringAsFixed(0)} FC',
                                  style: pw.TextStyle(
                                    fontSize: 11,
                                    fontWeight: pw.FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                    
                    pw.SizedBox(height: 12),
                    
                    // Récapitulatif du marchand
                    pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: primaryColorLight,
                        borderRadius: pw.BorderRadius.circular(6),
                        border: pw.Border.all(color: primaryColor, width: 1),
                      ),
                      child: pw.Column(
                        children: [
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                'Total produits:',
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  color: textColor,
                                ),
                              ),
                              pw.Text(
                                '${vendeurTotals['products']!.toStringAsFixed(0)} FC',
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 4),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                'Total livraison:',
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  color: textColor,
                                ),
                              ),
                              pw.Text(
                                '${vendeurTotals['delivery']!.toStringAsFixed(0)} FC',
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 4),
                          pw.Divider(color: primaryColor, height: 1),
                          pw.SizedBox(height: 4),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                'Total à payer:',
                                style: pw.TextStyle(
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              pw.Text(
                                '${vendeurTotals['total']!.toStringAsFixed(0)} FC',
                                style: pw.TextStyle(
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    pw.SizedBox(height: 20),
                  ],
                );
              }),
              
              // Récapitulatif global
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: primaryColor,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'RÉCAPITULATIF GLOBAL',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Total produits:',
                          style: pw.TextStyle(
                            fontSize: 11,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.Text(
                          '${globalTotals['products']!.toStringAsFixed(0)} FC',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Total livraison:',
                          style: pw.TextStyle(
                            fontSize: 11,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.Text(
                          '${globalTotals['delivery']!.toStringAsFixed(0)} FC',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                    pw.Divider(color: PdfColors.white, height: 1),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'TOTAL À PAYER:',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.Text(
                          '${globalTotals['total']!.toStringAsFixed(0)} FC',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ];
          },
        ),
      );
      
      // Afficher le dialogue d'impression avec options de sauvegarde
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Commandes_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf',
      );
    } catch (e) {
      print('Erreur lors de la génération du PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la génération du PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Affiche le popup pour annuler les commandes d'un vendeur
  Future<void> _showCancelOrderDialog(int vendeurId, List<Map<String, dynamic>> vendeurOrders) async {
    final TextEditingController reasonController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.cancel_outlined, color: Colors.red, size: 18),
              const SizedBox(width: 6),
              const Text(
                'Annuler',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Voulez-vous vraiment annuler toutes les commandes de ce vendeur ?',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Raison *',
                    hintText: 'Ex: Changement d\'avis...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.edit, size: 18),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  style: const TextStyle(fontSize: 13),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Non', style: TextStyle(fontSize: 13)),
            ),
            ElevatedButton(
              onPressed: () {
                if (reasonController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez renseigner la raison'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text('Valider', style: TextStyle(fontSize: 13)),
            ),
          ],
        );
      },
    );

    if (result == true && reasonController.text.trim().isNotEmpty) {
      await _cancelVendeurOrders(vendeurId, vendeurOrders, reasonController.text.trim());
    }
  }


  // Confirme la commande (exécute l'endpoint)
  Future<void> _confirmOrder(int vendeurId, List<Map<String, dynamic>> vendeurOrders) async {
    print('🔘 [_confirmOrder] Appelé pour vendeurId: $vendeurId');
    print('🔘 [_confirmOrder] _pendingPaymentMethods[$vendeurId]: ${_pendingPaymentMethods[vendeurId]}');
    print('🔘 [_confirmOrder] _selectedPaymentMethods[$vendeurId]: ${_selectedPaymentMethods[vendeurId]}');
    
    // Utiliser les données pending si disponibles, sinon selected
    Map<String, dynamic>? paymentMethod;
    String? numeroPayment;
    
    if (_pendingPaymentMethods[vendeurId] != null) {
      paymentMethod = _pendingPaymentMethods[vendeurId]!['paymentMethod'] as Map<String, dynamic>?;
      numeroPayment = _pendingPaymentMethods[vendeurId]!['numeroPayment']?.toString();
      print('🔘 [_confirmOrder] Utilisation de pendingPaymentMethod: $paymentMethod');
    } else if (_selectedPaymentMethods[vendeurId] != null) {
      paymentMethod = _selectedPaymentMethods[vendeurId];
      numeroPayment = _numeroPayments[vendeurId];
      print('🔘 [_confirmOrder] Utilisation de selectedPaymentMethod: $paymentMethod');
    }
    
    print('🔘 [_confirmOrder] paymentMethod final: $paymentMethod');
    
    if (paymentMethod == null) {
      print('⚠️ [_confirmOrder] paymentMethod est NULL - abandon');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un moyen de paiement'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isConfirming[vendeurId] = true;
    });

    try {
      final paymentMethodId = paymentMethod['id'] as int;

      // Extraire les IDs des commandes
      final orderIds = vendeurOrders.map((order) => order['id'] as int).toList();

      // Mettre à jour toutes les commandes
      final orderCubit = context.read<OrderCubit>();
      for (var orderId in orderIds) {
        await orderCubit.updatePaymentMethod(
          orderId: orderId,
          paymentMethodId: paymentMethodId,
          numeroPayment: numeroPayment,
        );
        await Future.delayed(const Duration(milliseconds: 200));
      }

      // Rafraîchir les commandes
      await context.read<OrderCubit>().fetchOrders();
      if (mounted) {
        _loadPaymentMethods(context);
        
        setState(() {
          _isConfirming[vendeurId] = false;
          // Nettoyer les données temporaires et déplacer vers selected si c'était pending
          if (_pendingPaymentMethods[vendeurId] != null) {
            _selectedPaymentMethods[vendeurId] = paymentMethod!;
            if (numeroPayment != null) {
              _numeroPayments[vendeurId] = numeroPayment;
            }
            _pendingPaymentMethods.remove(vendeurId);
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commande confirmée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isConfirming[vendeurId] = false;
      });
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

  // Annule toutes les commandes d'un vendeur
  Future<void> _cancelVendeurOrders(
    int vendeurId,
    List<Map<String, dynamic>> vendeurOrders,
    String reason,
  ) async {
    setState(() {
      _isCancelling[vendeurId] = true;
    });

    try {
      // Annuler toutes les commandes du vendeur
      int successCount = 0;
      int failCount = 0;

      for (var order in vendeurOrders) {
        final orderId = order['id']?.toString() ?? '';
        if (orderId.isEmpty) {
          failCount++;
          continue;
        }

        try {
          final result = await _orderService.updateOrderStatus(
            orderId: orderId,
            status: 'cancelled',
            reason: reason,
          );

          if (result['success'] == true) {
            successCount++;
          } else {
            failCount++;
            print('❌ Erreur lors de l\'annulation de la commande $orderId: ${result['message']}');
          }
        } catch (e) {
          failCount++;
          print('❌ Exception lors de l\'annulation de la commande $orderId: $e');
        }
      }

      setState(() {
        _isCancelling[vendeurId] = false;
      });

      // Afficher le résultat et rafraîchir
      if (mounted) {
        if (successCount > 0) {
          // Rafraîchir les commandes avant d'afficher le message
          await context.read<OrderCubit>().fetchOrders();
          // Recharger les moyens de paiement
          _loadPaymentMethods(context);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                failCount > 0
                    ? '$successCount commande(s) annulée(s), $failCount erreur(s)'
                    : '${successCount} commande(s) annulée(s) avec succès',
              ),
              backgroundColor: failCount > 0 ? Colors.orange : Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de l\'annulation des commandes'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isCancelling[vendeurId] = false;
      });
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

  Future<void> _showHomeWarningDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Attention',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Si vous retournez vers l\'accueil, votre commande ne sera pas finalisée.',
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Vous devrez revenir ici pour compléter votre commande.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primary.withOpacity(0.9),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Êtes-vous sûr de vouloir retourner à l\'accueil ?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Rester ici',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Retourner à l\'accueil',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/',
        (route) => false,
      );
    }
  }

  void _showPaymentMethodSelection(int vendeurId, Map<String, dynamic> currentPaymentMethod, List<Map<String, dynamic>> vendeurOrders) {
    print('🔍 [_showPaymentMethodSelection] Appelé pour vendeurId: $vendeurId');
    print('🔍 [_showPaymentMethodSelection] _vendeurPaymentMethods keys: ${_vendeurPaymentMethods?.keys.toList()}');
    final paymentMethods = _vendeurPaymentMethods?[vendeurId];
    print('🔍 [_showPaymentMethodSelection] paymentMethods pour $vendeurId: ${paymentMethods?.length ?? 0} méthodes');
    if (paymentMethods == null || paymentMethods.isEmpty) {
      print('⚠️ [_showPaymentMethodSelection] Aucun moyen de paiement disponible pour vendeurId: $vendeurId');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun moyen de paiement disponible'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Extraire les IDs des commandes de ce vendeur avec vérification de sécurité
    final orderIds = vendeurOrders
        .map((order) {
          final id = order['id'];
          if (id == null) return null;
          // Convertir en int si c'est un String ou un int
          if (id is int) return id;
          if (id is String) {
            final parsed = int.tryParse(id);
            return parsed;
          }
          return null;
        })
        .where((id) => id != null)
        .cast<int>()
        .toList();
    
    print('🔍 [PendingPaymentScreen] Modification du moyen de paiement');
    print('   👤 VendeurId: $vendeurId');
    print('   📦 Nombre de commandes pour ce vendeur: ${vendeurOrders.length}');
    print('   📋 IDs des commandes à mettre à jour: $orderIds');
    for (var order in vendeurOrders) {
      print('      - Commande ID: ${order['id']}, OrderId: ${order['orderId']}, Status: ${order['status']}');
    }

    // Vérifier que paymentMethods n'est pas null et n'est pas vide
    if (paymentMethods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun moyen de paiement disponible'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentMethodSelectionScreen(
          vendeurId: vendeurId,
          paymentMethods: paymentMethods,
          currentPaymentMethod: currentPaymentMethod,
          orderIds: orderIds,
        ),
      ),
    ).then((result) {
      // result contient {paymentMethod: {...}, numeroPayment: '...'} ou null
      print('📥 [_showPaymentMethodSelection] Résultat reçu: $result');
      if (result != null && result is Map<String, dynamic>) {
        print('📥 [_showPaymentMethodSelection] paymentMethod: ${result['paymentMethod']}');
        print('📥 [_showPaymentMethodSelection] paymentMethod id: ${result['paymentMethod']?['id']}');
        
        // Rediriger vers l'écran de récapitulatif au lieu de stocker dans le state
        final firstOrder = vendeurOrders.first;
        final vendeur = firstOrder['vendeur'] as Map<String, dynamic>? ?? {};
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderReviewScreen(
              vendeurId: vendeurId,
              vendeurOrders: vendeurOrders,
              paymentMethod: result['paymentMethod'] as Map<String, dynamic>,
              numeroPayment: result['numeroPayment']?.toString(),
              vendeur: vendeur,
            ),
          ),
        );
      } else {
        print('⚠️ [_showPaymentMethodSelection] Résultat null ou invalide');
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    // Charger les commandes au premier build seulement (sans actualisation automatique)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isFetchingOrders) return;
      
      final orderListState = context.read<OrderCubit>().orderListState;
      
      // Si les commandes sont vides et qu'on n'est pas en train de charger, charger une fois
      // Mais seulement si on n'a pas déjà fait le fetch initial (éviter la boucle)
      if (orderListState.orders.isEmpty && !orderListState.isLoading && !_hasInitiallyFetched) {
        _isFetchingOrders = true;
        _hasInitiallyFetched = true; // Marquer qu'on a fait le fetch initial
        context.read<OrderCubit>().fetchOrders().then((_) {
          if (mounted) {
            _loadPaymentMethods(context);
            _isFetchingOrders = false;
          }
        }).catchError((e) {
          if (mounted) {
            _isFetchingOrders = false;
          }
        });
      } else if (_vendeurPaymentMethods == null && orderListState.orders.isNotEmpty) {
        // Charger les moyens de paiement si les commandes existent déjà
        _loadPaymentMethods(context);
      }
    });

    return BlocConsumer<OrderCubit, OrderState>(
      listener: (context, state) {
        if (!mounted) return;
        // Retirer les actualisations automatiques pour éviter que la liste disparaisse
        if (state.error != null) {
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
        final orders = orderListState.orders;
        
        // Trier les commandes par date de création (les plus récentes en premier)
        final sortedOrders = List<dynamic>.from(orders);
        sortedOrders.sort((a, b) {
          final aCreatedAt = a['createdAt']?.toString() ?? '';
          final bCreatedAt = b['createdAt']?.toString() ?? '';
          if (aCreatedAt.isEmpty && bCreatedAt.isEmpty) return 0;
          if (aCreatedAt.isEmpty) return 1;
          if (bCreatedAt.isEmpty) return -1;
          return bCreatedAt.compareTo(aCreatedAt); // Plus récent en premier
        });
        
        final displayOrders = sortedOrders;
        
        // Ne plus initialiser automatiquement les moyens de paiement
        // Seuls les moyens de paiement modifiés par l'utilisateur seront affichés
        
        // Récupérer les stats pour détecter si toutes les commandes sont finalisées
        // On vérifie les stats AVANT le loader pour éviter le clignotement
        final stats = orderListState.stats;
        final pendingPaymentCount = (stats['pending_payment'] ?? 0) as int;
        final pendingCount = (stats['pending'] ?? 0) as int;
        final totalPending = pendingPaymentCount + pendingCount;

        // Afficher un loading de 3 secondes lors de l'ouverture initiale de l'écran
        // pour éviter d'afficher immédiatement le message "Toutes vos commandes sont effectuées"
        if (_isInitialLoading) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(
                'Mes commandes',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.home),
                onPressed: _showHomeWarningDialog,
                tooltip: 'Retour à l\'accueil',
              ),
            ),
            body: const Center(
              child: EcommerceLoading.overlay(),
            ),
          );
        }

        // Si la liste est vide ET qu'il n'y a plus de commandes en attente dans les stats,
        // cela signifie que toutes les commandes sont finalisées
        // On vérifie cela même pendant le chargement pour éviter le clignotement
        if (!orderListState.isLoading && orders.isEmpty && totalPending == 0 && stats.isNotEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(
                'Mes commandes',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.home),
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/',
                    (route) => false,
                  );
                },
                tooltip: 'Retour à l\'accueil',
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle_outline,
                        size: 60,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Toutes vos commandes sont effectuées',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Vous avez finalisé toutes vos commandes en attente.',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            '/',
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Retourner à l\'accueil',
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
            ),
          );
        }

        // Filtrer les commandes en attente de paiement ou en attente
        final pendingOrders = displayOrders.where((order) {
          final status = order['status']?.toString().toLowerCase() ?? '';
          return status == 'pending_payment' || status == 'pending';
        }).toList();

        // Afficher le loader si on est en train de charger (seulement si on n'a pas déjà affiché le message)
        if (orderListState.isLoading) {
          return Scaffold(
            appBar: AppBar(
            title: const Text(
              'Mes commandes',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.home),
                onPressed: _showHomeWarningDialog,
                tooltip: 'Retour à l\'accueil',
              ),
            ),
            body: const Center(
              child: EcommerceLoading.overlay(),
            ),
          );
        }

        // Si on a des commandes mais aucune en attente, afficher le message de finalisation
        if (orders.isNotEmpty && pendingOrders.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(
                'Mes commandes',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.home),
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/',
                    (route) => false,
                  );
                },
                tooltip: 'Retour à l\'accueil',
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        size: 60,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Toutes vos commandes sont effectuées',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Vous avez finalisé toutes vos commandes en attente.',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            '/',
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Retourner à l\'accueil',
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
            ),
          );
        }

        if (orders.isEmpty) {
          return Scaffold(
            appBar: AppBar(
            title: const Text(
              'Mes commandes',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.home),
                onPressed: _showHomeWarningDialog,
                tooltip: 'Retour à l\'accueil',
              ),
            ),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.payment_outlined,
                    size: 64,
                    color: Color(0xFFBDBDBD),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Aucune commande',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF757575),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Grouper les commandes par vendeur (seulement les commandes en attente)
        final groupedOrders = _groupOrdersByVendeur(pendingOrders);
        final globalTotals = _calculateGlobalTotals(pendingOrders);

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Mes commandes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.home),
              onPressed: _showHomeWarningDialog,
              tooltip: 'Retour à l\'accueil',
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                onPressed: () {
                  _generatePDF(displayOrders, groupedOrders);
                },
                tooltip: 'Générer PDF',
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: groupedOrders.isEmpty
                      ? SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: const SizedBox(
                            height: 400,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.payment_outlined,
                                    size: 48,
                                    color: Color(0xFFBDBDBD),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Aucune commande',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF757575),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Message informatif compact et attrayant
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.primary.withOpacity(0.1),
                                      AppColors.primary.withOpacity(0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.primary.withOpacity(0.25),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.08),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.primary,
                                            AppColors.primary.withOpacity(0.85),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary.withOpacity(0.25),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.shopping_bag_outlined,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Tu es en train de commander chez ${groupedOrders.length} vendeur${groupedOrders.length > 1 ? 's' : ''}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                              height: 1.2,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.local_shipping_outlined,
                                                size: 14,
                                                color: Colors.grey.shade600,
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  'Frais de livraison calculé pour chaque vendeur selon la distance',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey.shade700,
                                                    height: 1.3,
                                                  ),
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

                              // Afficher chaque marchand dans son container
                              ...groupedOrders.entries.map((entry) {
                                final vendeurId = entry.key;
                                final vendeurOrders = entry.value;
                                final firstOrder = vendeurOrders.first;
                                final vendeur = firstOrder['vendeur'] as Map<String, dynamic>? ?? {};
                                final vendeurName = '${vendeur['firstName'] ?? ''} ${vendeur['lastName'] ?? ''}'.trim();
                                final vendeurTotals = _calculateVendeurTotals(vendeurOrders);
                                final selectedPaymentMethod = _selectedPaymentMethods[vendeurId] ?? firstOrder['paymentMethod'] as Map<String, dynamic>?;
                                
                                // Vérifier si toutes les commandes sont annulées
                                final allCancelled = vendeurOrders.every((order) {
                                  final status = order['status']?.toString().toLowerCase() ?? '';
                                  return status == 'cancelled';
                                });
                                
                                // Vérifier si toutes les commandes sont en attente (pending)
                                final allPending = vendeurOrders.every((order) {
                                  final status = order['status']?.toString().toLowerCase() ?? '';
                                  return status == 'pending';
                                });

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.06),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // En-tête vendeur
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.1),
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(11),
                                            topRight: Radius.circular(11),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Icon(
                                                Icons.store,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    vendeurName,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                                  if (vendeur['phone'] != null)
                                                    Text(
                                                      vendeur['phone'],
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.grey.shade600,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                '${vendeurOrders.length}',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Liste des commandes du vendeur
                                            ...vendeurOrders.map((order) {
                                              final products = order['products'] as List? ?? [];
                                              final orderId = order['orderId']?.toString() ?? '';
                                              final address = order['address'] as Map<String, dynamic>? ?? {};
                                              final distanceKm = order['distanceKm']?.toString() ?? '';

                                              return Container(
                                                margin: const EdgeInsets.only(bottom: 8),
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade50,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: Colors.grey.shade200),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    // Numéro de commande et statut
                                                    Row(
                                                      children: [
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: AppColors.primary.withOpacity(0.1),
                                                            borderRadius: BorderRadius.circular(5),
                                                          ),
                                                          child: Text(
                                                            '#${orderId.length > 8 ? orderId.substring(0, 8) : orderId}',
                                                            style: const TextStyle(
                                                              fontSize: 9,
                                                              fontWeight: FontWeight.bold,
                                                              color: AppColors.primary,
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 6),
                                                        if (order['status'] != null)
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(
                                                              horizontal: 5,
                                                              vertical: 2,
                                                            ),
                                                            decoration: BoxDecoration(
                                                              color: _statusColor(order['status'].toString()).withOpacity(0.15),
                                                              borderRadius: BorderRadius.circular(5),
                                                              border: Border.all(
                                                                color: _statusColor(order['status'].toString()).withOpacity(0.3),
                                                                width: 0.5,
                                                              ),
                                                            ),
                                                            child: Text(
                                                              _translateStatus(order['status'].toString()),
                                                              style: TextStyle(
                                                                color: _statusColor(order['status'].toString()),
                                                                fontSize: 8,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 6),
                                                    // Adresse
                                                    Row(
                                                      children: [
                                                        Icon(Icons.location_on, size: 12, color: AppColors.primary),
                                                        const SizedBox(width: 5),
                                                        Expanded(
                                                          child: Text(
                                                            '${address['avenue'] ?? ''}, ${address['numero'] ?? ''}',
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              color: Colors.grey.shade700,
                                                              fontWeight: FontWeight.w500,
                                                            ),
                                                          ),
                                                        ),
                                                        if (distanceKm.isNotEmpty && distanceKm != '0')
                                                          Text(
                                                            '$distanceKm km',
                                                            style: TextStyle(
                                                              fontSize: 9,
                                                              fontWeight: FontWeight.w600,
                                                              color: AppColors.primary,
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 6),
                                                    // Produits
                                                    ...products.map((product) {
                                                      final productName = product['name']?.toString() ?? 'Produit';
                                                      final quantity = product['quantity'] as int? ?? 1;
                                                      final price = _parseAmount(product['price']);
                                                      final productTotal = price * quantity;
                                                      return Container(
                                                        margin: const EdgeInsets.only(bottom: 4),
                                                        padding: const EdgeInsets.all(6),
                                                        decoration: BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius: BorderRadius.circular(5),
                                                          border: Border.all(color: Colors.grey.shade200),
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            Expanded(
                                                              child: Column(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                  Text(
                                                                    productName,
                                                                    style: const TextStyle(
                                                                      fontSize: 11,
                                                                      fontWeight: FontWeight.w600,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(height: 2),
                                                                  Text(
                                                                    '$quantity × ${price.toStringAsFixed(0)} FC',
                                                                    style: TextStyle(
                                                                      fontSize: 9,
                                                                      color: Colors.grey.shade600,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            Text(
                                                              '${productTotal.toStringAsFixed(0)} FC',
                                                              style: const TextStyle(
                                                                fontSize: 12,
                                                                fontWeight: FontWeight.bold,
                                                                color: AppColors.primary,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    }).toList(),
                                                  ],
                                                ),
                                              );
                                            }).toList(),

                                            const SizedBox(height: 12),

                                            // Récap pour ce vendeur
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withOpacity(0.08),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                                              ),
                                              child: Column(
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      const Text(
                                                        'Total produits',
                                                        style: TextStyle(fontSize: 11),
                                                      ),
                                                      Text(
                                                        '${vendeurTotals['products']!.toStringAsFixed(0)} FC',
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      const Text(
                                                        'Total livraison',
                                                        style: TextStyle(fontSize: 11),
                                                      ),
                                                      Text(
                                                        '${vendeurTotals['delivery']!.toStringAsFixed(0)} FC',
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const Divider(height: 10),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      const Text(
                                                        'Total',
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      Text(
                                                        '${vendeurTotals['total']!.toStringAsFixed(0)} FC',
                                                        style: const TextStyle(
                                                          fontSize: 15,
                                                          fontWeight: FontWeight.bold,
                                                          color: AppColors.primary,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),

                                            const SizedBox(height: 16),

                                            // Bouton "Commander chez ce vendeur" - affiché après le total
                                            if (!allCancelled)
                                              SizedBox(
                                                width: double.infinity,
                                                child: ElevatedButton.icon(
                                                  onPressed: () {
                                                    print('🔘 [Button] Commander chez vendeur $vendeurId');
                                                    _showPaymentMethodSelection(vendeurId, selectedPaymentMethod ?? {}, vendeurOrders);
                                                  },
                                                  icon: const Icon(Icons.shopping_cart, size: 20),
                                                  label: const Text(
                                                    'Commander chez ce vendeur',
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: AppColors.primary,
                                                    foregroundColor: Colors.white,
                                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                                    elevation: 3,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                  ),
                                                ),
                                              ),

                                            // Boutons Confirmer et Annuler (affichés si moyen de paiement sélectionné - pending ou validé)
                                            // Si toutes les commandes sont annulées, ne rien afficher
                                            if (!allCancelled && (_selectedPaymentMethods[vendeurId] != null || _pendingPaymentMethods[vendeurId] != null)) ...[
                                              const SizedBox(height: 12),
                                              // Bouton Confirmer Commande
                                              SizedBox(
                                                width: double.infinity,
                                                child: OutlinedButton.icon(
                                                  onPressed: (_isConfirming[vendeurId] == true)
                                                      ? null
                                                      : () => _confirmOrder(vendeurId, vendeurOrders),
                                                  icon: _isConfirming[vendeurId] == true
                                                      ? const SizedBox(
                                                          width: 14,
                                                          height: 14,
                                                          child: CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                                          ),
                                                        )
                                                      : const Icon(Icons.check_circle, size: 16),
                                                  label: Text(
                                                    _isConfirming[vendeurId] == true
                                                        ? 'Confirmation...'
                                                        : 'Confirmer commande',
                                                  ),
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor: AppColors.primary,
                                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                                    side: BorderSide(color: AppColors.primary, width: 1.5),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    textStyle: const TextStyle(fontSize: 13),
                                                  ),
                                                ),
                                              ),
                                              // Bouton Annuler Commande (caché si toutes les commandes sont en attente)
                                              if (!allPending) ...[
                                                const SizedBox(height: 12),
                                                SizedBox(
                                                  width: double.infinity,
                                                  child: OutlinedButton.icon(
                                                    onPressed: (_isCancelling[vendeurId] == true)
                                                        ? null
                                                        : () => _showCancelOrderDialog(vendeurId, vendeurOrders),
                                                    icon: _isCancelling[vendeurId] == true
                                                        ? const SizedBox(
                                                            width: 14,
                                                            height: 14,
                                                            child: CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                                                            ),
                                                          )
                                                        : const Icon(Icons.cancel_outlined, size: 16),
                                                    label: Text(
                                                      _isCancelling[vendeurId] == true
                                                          ? 'Annulation...'
                                                          : 'Annuler',
                                                    ),
                                                    style: OutlinedButton.styleFrom(
                                                      foregroundColor: Colors.red,
                                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                                      side: const BorderSide(color: Colors.red, width: 1.5),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      textStyle: const TextStyle(fontSize: 13),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),

                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
              ),
              
              // Récap total et bouton en bas
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primary, width: 1.5),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total produits',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                '${globalTotals['products']!.toStringAsFixed(0)} FC',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total livraison',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                '${globalTotals['delivery']!.toStringAsFixed(0)} FC',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total à payer',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${globalTotals['total']!.toStringAsFixed(0)} FC',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Espace supplémentaire en bas pour éviter que le contenu soit coupé
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}



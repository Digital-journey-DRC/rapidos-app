import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:immo/constants.dart';
import 'package:immo/cubit/order_cubit.dart';
import 'package:immo/widgets/ecommerce_loading.dart';
import 'package:immo/services/payment_method_service.dart';
import 'package:immo/services/order_service.dart';
import 'payment_method_selection_screen.dart';
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

class _PendingPaymentScreenState extends State<PendingPaymentScreen> with WidgetsBindingObserver {
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPaymentMethods(context);
    // Rafraîchir les commandes toutes les 10 secondes pour détecter les changements de statut
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        context.read<OrderCubit>().fetchOrders().then((_) {
          _loadPaymentMethods(context);
        });
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Rafraîchir les commandes quand l'app revient au premier plan
      context.read<OrderCubit>().fetchOrders().then((_) {
        _loadPaymentMethods(context);
      });
    }
  }

  Future<void> _loadPaymentMethods(BuildContext context) async {
    final orderListState = context.read<OrderCubit>().orderListState;
    final orders = orderListState.orders;
    
    // Extraire les IDs des vendeurs uniques
    final vendeurIds = orders
        .map((order) => order['vendeurId'] as int? ?? 0)
        .where((id) => id > 0)
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
    
    setState(() {
      _vendeurPaymentMethods = paymentMethodsMap;
    });
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
    // Utiliser les données pending si disponibles, sinon selected
    Map<String, dynamic>? paymentMethod;
    String? numeroPayment;
    
    if (_pendingPaymentMethods[vendeurId] != null) {
      paymentMethod = _pendingPaymentMethods[vendeurId]!['paymentMethod'] as Map<String, dynamic>?;
      numeroPayment = _pendingPaymentMethods[vendeurId]!['numeroPayment']?.toString();
    } else if (_selectedPaymentMethods[vendeurId] != null) {
      paymentMethod = _selectedPaymentMethods[vendeurId];
      numeroPayment = _numeroPayments[vendeurId];
    }
    
    if (paymentMethod == null) {
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

      if (mounted) {
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

  void _showPaymentMethodSelection(int vendeurId, Map<String, dynamic> currentPaymentMethod, List<Map<String, dynamic>> vendeurOrders) {
    final paymentMethods = _vendeurPaymentMethods?[vendeurId];
    if (paymentMethods == null || paymentMethods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun moyen de paiement disponible'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Extraire les IDs des commandes de ce vendeur
    final orderIds = vendeurOrders.map((order) => order['id'] as int).toList();
    
    print('🔍 [PendingPaymentScreen] Modification du moyen de paiement');
    print('   👤 VendeurId: $vendeurId');
    print('   📦 Nombre de commandes pour ce vendeur: ${vendeurOrders.length}');
    print('   📋 IDs des commandes à mettre à jour: $orderIds');
    for (var order in vendeurOrders) {
      print('      - Commande ID: ${order['id']}, OrderId: ${order['orderId']}, Status: ${order['status']}');
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
      if (result != null && result is Map<String, dynamic>) {
        setState(() {
          // Stocker dans le state temporaire (non validé)
          _pendingPaymentMethods[vendeurId] = result;
        });
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    // Charger les commandes au premier build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orderListState = context.read<OrderCubit>().orderListState;
      if (orderListState.orders.isEmpty && !orderListState.isLoading) {
        context.read<OrderCubit>().fetchOrders().then((_) {
          _loadPaymentMethods(context);
        });
      } else if (_vendeurPaymentMethods == null) {
        _loadPaymentMethods(context);
      }
    });

    return BlocConsumer<OrderCubit, OrderState>(
      listener: (context, state) {
        if (state.success) {
          // Recharger les moyens de paiement après mise à jour
          _loadPaymentMethods(context);
          // Rafraîchir les commandes pour avoir les dernières données
          context.read<OrderCubit>().fetchOrders();
        } else if (state.error != null) {
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
        
        // Grouper les commandes par vendeur
        final groupedOrders = _groupOrdersByVendeur(displayOrders);
        final globalTotals = _calculateGlobalTotals(displayOrders);

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
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/',
                    (route) => false,
                  );
                },
                tooltip: 'Retour à l\'accueil',
              ),
            ),
            body: const Center(
              child: EcommerceLoading.overlay(),
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.payment_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune commande',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

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
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/',
                  (route) => false,
                );
              },
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
                child: RefreshIndicator(
                  onRefresh: () async {
                    await context.read<OrderCubit>().fetchOrders();
                    _loadPaymentMethods(context);
                  },
                  child: groupedOrders.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.5,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.payment_outlined,
                                      size: 48,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Aucune commande',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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


                                            // Moyen de paiement pour ce vendeur
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade50,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: Colors.grey.shade200),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      const Icon(Icons.payment, size: 16, color: AppColors.primary),
                                                      const SizedBox(width: 6),
                                                      const Text(
                                                        'Moyen de paiement',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      const Spacer(),
                                                      // Afficher le bouton "ajouter moyen de paiement" si pas de moyen de paiement modifié (pending ou validé)
                                                      if (_selectedPaymentMethods[vendeurId] == null && _pendingPaymentMethods[vendeurId] == null)
                                                        ElevatedButton.icon(
                                                          onPressed: () => _showPaymentMethodSelection(vendeurId, selectedPaymentMethod ?? {}, vendeurOrders),
                                                          icon: const Icon(Icons.add, size: 14),
                                                          label: const Text(
                                                            'Ajouter moyen de paiement',
                                                            style: TextStyle(fontSize: 11),
                                                          ),
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: AppColors.primary,
                                                            foregroundColor: Colors.white,
                                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                            minimumSize: Size.zero,
                                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                          ),
                                                        )
                                                      else
                                                        IconButton(
                                                          icon: const Icon(Icons.edit, size: 16),
                                                          onPressed: () => _showPaymentMethodSelection(vendeurId, _selectedPaymentMethods[vendeurId] ?? _pendingPaymentMethods[vendeurId]?['paymentMethod'] ?? selectedPaymentMethod ?? {}, vendeurOrders),
                                                          color: AppColors.primary,
                                                          padding: EdgeInsets.zero,
                                                          constraints: const BoxConstraints(),
                                                        ),
                                                    ],
                                                  ),
                                                  // Afficher le moyen de paiement validé ou en attente
                                                  if (_selectedPaymentMethods[vendeurId] != null) ...[
                                                    const SizedBox(height: 8),
                                                    Row(
                                                      children: [
                                                        if (_selectedPaymentMethods[vendeurId]!['imageUrl'] != null)
                                                          ClipRRect(
                                                            borderRadius: BorderRadius.circular(6),
                                                            child: CachedNetworkImage(
                                                              imageUrl: _selectedPaymentMethods[vendeurId]!['imageUrl'],
                                                              width: 32,
                                                              height: 32,
                                                              fit: BoxFit.cover,
                                                            ),
                                                          )
                                                        else
                                                          Container(
                                                            width: 32,
                                                            height: 32,
                                                            decoration: BoxDecoration(
                                                              color: Colors.grey.shade200,
                                                              borderRadius: BorderRadius.circular(6),
                                                            ),
                                                            child: const Icon(Icons.payment, size: 16),
                                                          ),
                                                        const SizedBox(width: 8),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Text(
                                                                _selectedPaymentMethods[vendeurId]!['name'] ?? 'Cash',
                                                                style: const TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight: FontWeight.w600,
                                                                ),
                                                              ),
                                                              if (_selectedPaymentMethods[vendeurId]!['numeroCompte'] != null)
                                                                Text(
                                                                  _selectedPaymentMethods[vendeurId]!['numeroCompte'],
                                                                  style: TextStyle(
                                                                    fontSize: 10,
                                                                    color: Colors.grey.shade600,
                                                                  ),
                                                                ),
                                                              if (_numeroPayments[vendeurId] != null)
                                                                Text(
                                                                  'Numéro: ${_numeroPayments[vendeurId]}',
                                                                  style: TextStyle(
                                                                    fontSize: 10,
                                                                    color: Colors.grey.shade600,
                                                                  ),
                                                                ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ] else if (_pendingPaymentMethods[vendeurId] != null) ...[
                                                    // Afficher le moyen de paiement en attente
                                                    const SizedBox(height: 8),
                                                    Row(
                                                      children: [
                                                        if (_pendingPaymentMethods[vendeurId]!['paymentMethod']?['imageUrl'] != null)
                                                          ClipRRect(
                                                            borderRadius: BorderRadius.circular(6),
                                                            child: CachedNetworkImage(
                                                              imageUrl: _pendingPaymentMethods[vendeurId]!['paymentMethod']!['imageUrl'],
                                                              width: 32,
                                                              height: 32,
                                                              fit: BoxFit.cover,
                                                            ),
                                                          )
                                                        else
                                                          Container(
                                                            width: 32,
                                                            height: 32,
                                                            decoration: BoxDecoration(
                                                              color: Colors.grey.shade200,
                                                              borderRadius: BorderRadius.circular(6),
                                                            ),
                                                            child: const Icon(Icons.payment, size: 16),
                                                          ),
                                                        const SizedBox(width: 8),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Text(
                                                                _pendingPaymentMethods[vendeurId]!['paymentMethod']?['name'] ?? 'Cash',
                                                                style: const TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight: FontWeight.w600,
                                                                ),
                                                              ),
                                                              if (_pendingPaymentMethods[vendeurId]!['numeroPayment'] != null)
                                                                Text(
                                                                  'Numéro: ${_pendingPaymentMethods[vendeurId]!['numeroPayment']}',
                                                                  style: TextStyle(
                                                                    fontSize: 10,
                                                                    color: Colors.grey.shade600,
                                                                  ),
                                                                ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),

                                            const SizedBox(height: 10),

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



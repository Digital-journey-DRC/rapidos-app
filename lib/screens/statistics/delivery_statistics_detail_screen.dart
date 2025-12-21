import 'package:flutter/material.dart';
import 'package:immo/constants.dart';
import 'package:immo/services/delivery_statistics_service.dart';
import 'package:immo/cubit/auth_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';

class DeliveryStatisticsDetailScreen extends StatefulWidget {
  final String period; // 'daily', 'weekly', 'monthly', 'semester', 'yearly'
  final String livreurId;

  const DeliveryStatisticsDetailScreen({
    Key? key,
    required this.period,
    required this.livreurId,
  }) : super(key: key);

  @override
  State<DeliveryStatisticsDetailScreen> createState() => _DeliveryStatisticsDetailScreenState();
}

class _DeliveryStatisticsDetailScreenState extends State<DeliveryStatisticsDetailScreen> {
  final DeliveryStatisticsService _statisticsService = DeliveryStatisticsService();
  Map<String, dynamic>? _statistics;
  bool _isLoading = true;
  Map<String, dynamic>? _livreurInfo;
  double? _unitPrice;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
    _loadLivreurInfo();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    try {
      final result = await _statisticsService.getDeliveryStatistics(widget.livreurId);
      if (result['success'] == true) {
        setState(() {
          _statistics = result[widget.period];
          _unitPrice = result['unitPrice'] as double?;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${result['error']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
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

  Future<void> _loadLivreurInfo() async {
    try {
      final authState = context.read<AuthCubit>().state;
      if (authState is AuthSuccess && authState.user != null) {
        final user = authState.user!;
        setState(() {
          _livreurInfo = {
            'firstName': user['firstName'] ?? '',
            'lastName': user['lastName'] ?? '',
            'email': user['email'] ?? '',
            'phone': user['phone'] ?? '',
          };
        });
      } else {
        setState(() {
          _livreurInfo = {
            'firstName': 'Livreur',
            'lastName': '',
            'email': '',
            'phone': '',
          };
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des infos livreur: $e');
    }
  }

  String _getPeriodLabel() {
    switch (widget.period) {
      case 'daily':
        return 'Journalière';
      case 'weekly':
        return 'Hebdomadaire';
      case 'monthly':
        return 'Mensuelle';
      case 'semester':
        return 'Semestrielle';
      case 'yearly':
        return 'Annuelle';
      default:
        return 'Période';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Statistiques ${_getPeriodLabel()}',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_statistics != null && _livreurInfo != null)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: AppColors.primary),
              onPressed: _generatePdfReport,
              tooltip: 'Générer PDF',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _statistics == null
              ? const Center(child: Text('Aucune donnée disponible'))
              : RefreshIndicator(
                  onRefresh: _loadStatistics,
                  color: AppColors.primary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.only(
                      left: 12,
                      right: 12,
                      top: 12,
                      bottom: MediaQuery.of(context).padding.bottom + 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummarySection(),
                        const SizedBox(height: 16),
                        _buildDeliveriesList(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSummarySection() {
    final total = _statistics!['total'] as double? ?? 0.0;
    final count = _statistics!['count'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Icon(
                  Icons.summarize,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Résumé',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  Icons.local_shipping,
                  'Livraisons',
                  count.toString(),
                  AppColors.primary,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey.shade300,
              ),
              Expanded(
                child: _buildSummaryItem(
                  Icons.attach_money,
                  'Total',
                  '${NumberFormat('#,###').format(total)} FC',
                  AppColors.primary,
                ),
              ),
            ],
          ),
          if (_unitPrice != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text(
                    'Prix unitaire: ${NumberFormat('#,###').format(_unitPrice)} FC',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveriesList() {
    final deliveries = _statistics!['deliveries'] as List<dynamic>? ?? [];

    if (deliveries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Aucune livraison',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            'Liste des livraisons (${deliveries.length})',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: deliveries.length,
          itemBuilder: (context, index) {
            final delivery = deliveries[index];
            return _buildDeliveryCard(delivery);
          },
        ),
      ],
    );
  }

  Widget _buildDeliveryCard(Map<String, dynamic> delivery) {
    final orderId = delivery['orderId'] ?? 'N/A';
    final clientName = delivery['clientName'] ?? 'Client inconnu';
    final address = delivery['deliveryAddress'] ?? 'Adresse non disponible';
    final total = delivery['total'] as double? ?? 0.0;
    final date = delivery['date'] as DateTime?;
    final unitPrice = delivery['unitPrice'] as double? ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  Icons.local_shipping_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clientName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Commande: $orderId',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${NumberFormat('#,###').format(total)} FC',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, size: 12, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        address,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (date != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 10, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd/MM/yyyy à HH:mm').format(date),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.attach_money, size: 10, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Prix unitaire: ${NumberFormat('#,###').format(unitPrice)} FC',
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
        ],
      ),
    );
  }

  Future<void> _generatePdfReport() async {
    if (_statistics == null || _livreurInfo == null) return;

    try {
      final pdf = pw.Document();
      final logo = await _loadLogo();
      final deliveries = _statistics!['deliveries'] as List<dynamic>? ?? [];
      final total = _statistics!['total'] as double? ?? 0.0;
      final count = _statistics!['count'] as int? ?? 0;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              // En-tête
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (logo != null)
                        pw.Image(
                          pw.MemoryImage(logo),
                          width: 80,
                          height: 80,
                        ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Rapport de Livraisons',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromInt(0xFF2B2D42),
                        ),
                      ),
                      pw.Text(
                        'Période: ${_getPeriodLabel()}',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.Text(
                        'Date: ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now())}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFF2B2D42),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      'LIVREUR',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Informations livreur
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFF5F5F5),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Informations Livreur',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF2B2D42),
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      '${_livreurInfo!['firstName']} ${_livreurInfo!['lastName']}',
                      style: pw.TextStyle(fontSize: 11),
                    ),
                    if (_livreurInfo!['email'] != null && _livreurInfo!['email'].toString().isNotEmpty)
                      pw.Text(
                        'Email: ${_livreurInfo!['email']}',
                        style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                    if (_livreurInfo!['phone'] != null && _livreurInfo!['phone'].toString().isNotEmpty)
                      pw.Text(
                        'Téléphone: ${_livreurInfo!['phone']}',
                        style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Résumé
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  border: pw.Border.all(color: PdfColor.fromInt(0xFFE0E0E0)),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildPdfSummaryItem('Livraisons', count.toString()),
                    _buildPdfSummaryItem('Total', '${NumberFormat('#,###').format(total)} FC'),
                    if (_unitPrice != null)
                      _buildPdfSummaryItem('Prix unitaire', '${NumberFormat('#,###').format(_unitPrice)} FC'),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Table des livraisons
              pw.Text(
                'Détail des livraisons',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF2B2D42),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColor.fromInt(0xFFE0E0E0)),
                children: [
                  // En-tête
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFFF5F5F5),
                    ),
                    children: [
                      _buildPdfTableCell('Date', isHeader: true),
                      _buildPdfTableCell('Client', isHeader: true),
                      _buildPdfTableCell('Commande', isHeader: true),
                      _buildPdfTableCell('Montant', isHeader: true),
                    ],
                  ),
                  // Données
                  ...deliveries.map((delivery) {
                    final date = delivery['date'] as DateTime?;
                    final clientName = delivery['clientName'] ?? 'N/A';
                    final orderId = delivery['orderId'] ?? 'N/A';
                    final total = delivery['total'] as double? ?? 0.0;

                    return pw.TableRow(
                      children: [
                        _buildPdfTableCell(
                          date != null ? DateFormat('dd/MM/yyyy').format(date) : 'N/A',
                        ),
                        _buildPdfTableCell(clientName),
                        _buildPdfTableCell(orderId),
                        _buildPdfTableCell('${NumberFormat('#,###').format(total)} FC'),
                      ],
                    );
                  }).toList(),
                  // Total
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFFE8F5E9),
                    ),
                    children: [
                      _buildPdfTableCell('TOTAL', isHeader: true, colspan: 3),
                      _buildPdfTableCell(
                        '${NumberFormat('#,###').format(total)} FC',
                        isHeader: true,
                        isTotal: true,
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),

              // Pied de page
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  if (logo != null)
                    pw.Image(
                      pw.MemoryImage(logo),
                      width: 40,
                      height: 40,
                    ),
                  pw.SizedBox(width: 8),
                  pw.Text(
                    'Rapidos - Votre partenaire de confiance',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Document confidentiel',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey500,
                ),
              ),
            ];
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
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
    }
  }

  pw.Widget _buildPdfSummaryItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromInt(0xFF147C3C),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey700,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPdfTableCell(String text, {bool isHeader = false, bool isTotal = false, int colspan = 1}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader || isTotal ? 10 : 9,
          fontWeight: isHeader || isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader || isTotal ? PdfColor.fromInt(0xFF2B2D42) : PdfColors.black,
        ),
      ),
    );
  }

  Future<Uint8List?> _loadLogo() async {
    try {
      final ByteData data = await rootBundle.load('assets/images/logo.png');
      return data.buffer.asUint8List();
    } catch (e) {
      print('Erreur lors du chargement du logo: $e');
      return null;
    }
  }
}


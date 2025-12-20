import 'package:flutter/material.dart';
import 'package:immo/constants.dart';
import 'package:immo/widgets/app_logo.dart';
import 'package:immo/services/sales_statistics_service.dart';
import 'package:immo/cubit/auth_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';

class SalesStatisticsDetailScreen extends StatefulWidget {
  final String period; // 'daily', 'weekly', 'monthly', 'semester', 'yearly'
  final String merchantId;

  const SalesStatisticsDetailScreen({
    Key? key,
    required this.period,
    required this.merchantId,
  }) : super(key: key);

  @override
  State<SalesStatisticsDetailScreen> createState() => _SalesStatisticsDetailScreenState();
}

class _SalesStatisticsDetailScreenState extends State<SalesStatisticsDetailScreen> {
  final SalesStatisticsService _statisticsService = SalesStatisticsService();
  Map<String, dynamic>? _statistics;
  bool _isLoading = true;
  Map<String, dynamic>? _merchantInfo;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
    _loadMerchantInfo();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    try {
      final result = await _statisticsService.getSalesStatistics(widget.merchantId);
      if (result['success'] == true) {
        setState(() {
          _statistics = result[widget.period];
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

  Future<void> _loadMerchantInfo() async {
    try {
      // Récupérer les informations du marchand connecté depuis AuthCubit
      final authState = context.read<AuthCubit>().state;
      if (authState is AuthSuccess && authState.user != null) {
        final user = authState.user!;
        setState(() {
          _merchantInfo = {
            'firstName': user['firstName'] ?? '',
            'lastName': user['lastName'] ?? '',
            'email': user['email'] ?? '',
            'phone': user['phone'] ?? '',
          };
        });
      } else {
        // Fallback si pas d'utilisateur connecté
        setState(() {
          _merchantInfo = {
            'firstName': 'Marchand',
            'lastName': '',
            'email': '',
            'phone': '',
          };
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des infos marchand: $e');
      // Fallback en cas d'erreur
      setState(() {
        _merchantInfo = {
          'firstName': 'Marchand',
          'lastName': '',
          'email': '',
          'phone': '',
        };
      });
    }
  }

  String _getPeriodTitle() {
    switch (widget.period) {
      case 'daily':
        return 'Ventes Journalières';
      case 'weekly':
        return 'Ventes Hebdomadaires';
      case 'monthly':
        return 'Ventes Mensuelles';
      case 'semester':
        return 'Ventes Semestrielles';
      case 'yearly':
        return 'Ventes Annuelles';
      default:
        return 'Statistiques';
    }
  }

  /// Charge le logo depuis les assets
  Future<pw.ImageProvider?> _loadLogo() async {
    try {
      final ByteData data = await rootBundle.load('assets/images/logo-rapidons.png');
      final Uint8List bytes = data.buffer.asUint8List();
      final image = pw.MemoryImage(bytes);
      return image;
    } catch (e) {
      print('Erreur lors du chargement du logo: $e');
      return null;
    }
  }

  Future<void> _generatePDF() async {
    if (_statistics == null || _merchantInfo == null) return;

    final sales = _statistics!['sales'] as List<Map<String, dynamic>>;
    final total = _statistics!['total'] as double;
    final count = _statistics!['count'] as int;

    // Calculer le total de produits vendus
    int totalProductsSold = 0;
    for (var sale in sales) {
      final items = sale['items'] as List<dynamic>? ?? [];
      for (var item in items) {
        totalProductsSold += (item['quantity'] ?? 1) as int;
      }
    }

    // Calculer le nombre de clients uniques
    final uniqueClients = <String>{};
    for (var sale in sales) {
      final clientName = sale['clientName']?.toString() ?? '';
      if (clientName.isNotEmpty) {
        uniqueClients.add(clientName);
      }
    }
    final totalClients = uniqueClients.length;

    // Calculer des statistiques supplémentaires
    final averageOrderValue = count > 0 ? total / count : 0.0;
    final averageProductsPerOrder = count > 0 ? totalProductsSold / count : 0.0;
    
    // Période couverte
    DateTime? startDate;
    DateTime? endDate;
    if (sales.isNotEmpty) {
      final dates = sales.map((s) => s['date'] as DateTime).toList();
      dates.sort();
      startDate = dates.first;
      endDate = dates.last;
    }

    // Charger le logo
    final logoImage = await _loadLogo();

    // Couleurs avec vert pâle
    final primaryColorLight = PdfColor.fromInt(0xFFE8F5E9); // Vert pâle
    final primaryColor = PdfColor.fromInt(0xFF147C3C); // Vert principal (pour accents)
    final textColor = PdfColor.fromInt(0xFF2B2D42); // Texte principal
    final textLightColor = PdfColor.fromInt(0xFF8D99AE); // Texte secondaire
    final backgroundColor = PdfColor.fromInt(0xFFF8F9FA); // Arrière-plan clair
    final borderColor = PdfColor.fromInt(0xFFE0E0E0); // Bordure grise claire

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // En-tête avec logo et titre
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Logo Rapidos
                      if (logoImage != null)
                        pw.Container(
                          width: 60,
                          height: 60,
                          margin: const pw.EdgeInsets.only(bottom: 12),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.white,
                            borderRadius: pw.BorderRadius.circular(6),
                          ),
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                        ),
                      pw.Text(
                        'RAPPORT DE VENTES',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                        pw.Text(
                          _getPeriodTitle(),
                          style: pw.TextStyle(
                            fontSize: 13,
                            color: textColor,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Date de génération',
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: textLightColor,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        DateFormat('dd/MM/yyyy').format(DateTime.now()),
                        style: pw.TextStyle(
                          fontSize: 11,
                          color: textColor,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        DateFormat('HH:mm').format(DateTime.now()),
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: textLightColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Divider(color: borderColor, height: 1),
              pw.SizedBox(height: 20),
              pw.SizedBox(height: 30),

              // Informations du marchand et résumé côte à côte
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Informations du marchand
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(14),
                      decoration: pw.BoxDecoration(
                        color: backgroundColor,
                        borderRadius: pw.BorderRadius.circular(8),
                        border: pw.Border.all(color: borderColor, width: 1),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'INFORMATIONS MARCHAND',
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: primaryColor,
                              fontWeight: pw.FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          pw.SizedBox(height: 10),
                          pw.Text(
                            '${_merchantInfo!['firstName'] ?? ''} ${_merchantInfo!['lastName'] ?? ''}',
                            style: pw.TextStyle(
                              fontSize: 13,
                              fontWeight: pw.FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          if (_merchantInfo!['email'] != null) ...[
                            pw.SizedBox(height: 6),
                            pw.Row(
                              children: [
                                pw.Text(
                                  'Email: ',
                                  style: pw.TextStyle(
                                    fontSize: 10,
                                    color: textLightColor,
                                  ),
                                ),
                                pw.Expanded(
                                  child: pw.Text(
                                    _merchantInfo!['email'],
                                    style: pw.TextStyle(
                                      fontSize: 10,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (_merchantInfo!['phone'] != null) ...[
                            pw.SizedBox(height: 4),
                            pw.Row(
                              children: [
                                pw.Text(
                                  'Tél: ',
                                  style: pw.TextStyle(
                                    fontSize: 10,
                                    color: textLightColor,
                                  ),
                                ),
                                pw.Text(
                                  _merchantInfo!['phone'],
                                  style: pw.TextStyle(
                                    fontSize: 10,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  // Période et référence
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(14),
                      decoration: pw.BoxDecoration(
                        color: backgroundColor,
                        borderRadius: pw.BorderRadius.circular(8),
                        border: pw.Border.all(color: borderColor, width: 1),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'PÉRIODE',
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: primaryColor,
                              fontWeight: pw.FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          pw.SizedBox(height: 10),
                          if (startDate != null && endDate != null) ...[
                            pw.Text(
                              'Du ${DateFormat('dd/MM/yyyy').format(startDate)}',
                              style: pw.TextStyle(
                                fontSize: 10,
                                color: textColor,
                              ),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'Au ${DateFormat('dd/MM/yyyy').format(endDate)}',
                              style: pw.TextStyle(
                                fontSize: 10,
                                color: textColor,
                              ),
                            ),
                          ] else
                            pw.Text(
                              'Période en cours',
                              style: pw.TextStyle(
                                fontSize: 10,
                                color: textColor,
                              ),
                            ),
                          pw.SizedBox(height: 8),
                          pw.Divider(color: borderColor, height: 1),
                          pw.SizedBox(height: 8),
                          pw.Text(
                            'Réf. Rapport',
                            style: pw.TextStyle(
                              fontSize: 9,
                              color: textLightColor,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'RAP-${DateFormat('yyyyMMdd').format(DateTime.now())}-${widget.period.toUpperCase()}',
                            style: pw.TextStyle(
                              fontSize: 9,
                              color: textColor,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Résumé avec 4 éléments
              pw.Container(
                padding: const pw.EdgeInsets.all(18),
                decoration: pw.BoxDecoration(
                  color: primaryColorLight, // Vert pâle
                  borderRadius: pw.BorderRadius.circular(10),
                  border: pw.Border.all(color: PdfColor.fromInt(0x4D147C3C), width: 1),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'RÉSUMÉ EXÉCUTIF',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    pw.SizedBox(height: 16),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                      children: [
                        pw.Expanded(
                          child: pw.Container(
                            padding: const pw.EdgeInsets.all(10),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.white,
                              borderRadius: pw.BorderRadius.circular(6),
                            ),
                            child: pw.Column(
                              children: [
                                pw.Text(
                                  'Total ventes',
                                  style: pw.TextStyle(
                                    fontSize: 9,
                                    color: textLightColor,
                                  ),
                                ),
                                pw.SizedBox(height: 6),
                                pw.Text(
                                  '${total.toStringAsFixed(0)} FC',
                                  style: pw.TextStyle(
                                    fontSize: 18,
                                    fontWeight: pw.FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Expanded(
                          child: pw.Container(
                            padding: const pw.EdgeInsets.all(10),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.white,
                              borderRadius: pw.BorderRadius.circular(6),
                            ),
                            child: pw.Column(
                              children: [
                                pw.Text(
                                  'Total commandes',
                                  style: pw.TextStyle(
                                    fontSize: 9,
                                    color: textLightColor,
                                  ),
                                ),
                                pw.SizedBox(height: 6),
                                pw.Text(
                                  count.toString(),
                                  style: pw.TextStyle(
                                    fontSize: 18,
                                    fontWeight: pw.FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 10),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                      children: [
                        pw.Expanded(
                          child: pw.Container(
                            padding: const pw.EdgeInsets.all(10),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.white,
                              borderRadius: pw.BorderRadius.circular(6),
                            ),
                            child: pw.Column(
                              children: [
                                pw.Text(
                                  'Total produits vendus',
                                  style: pw.TextStyle(
                                    fontSize: 9,
                                    color: textLightColor,
                                  ),
                                ),
                                pw.SizedBox(height: 6),
                                pw.Text(
                                  totalProductsSold.toString(),
                                  style: pw.TextStyle(
                                    fontSize: 18,
                                    fontWeight: pw.FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Expanded(
                          child: pw.Container(
                            padding: const pw.EdgeInsets.all(10),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.white,
                              borderRadius: pw.BorderRadius.circular(6),
                            ),
                            child: pw.Column(
                              children: [
                                pw.Text(
                                  'Total clients',
                                  style: pw.TextStyle(
                                    fontSize: 9,
                                    color: textLightColor,
                                  ),
                                ),
                                pw.SizedBox(height: 6),
                                pw.Text(
                                  totalClients.toString(),
                                  style: pw.TextStyle(
                                    fontSize: 18,
                                    fontWeight: pw.FontWeight.bold,
                                    color: primaryColor,
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
              pw.SizedBox(height: 20),

              // Statistiques supplémentaires
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: backgroundColor,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: borderColor, width: 1),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Statistiques complémentaires',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'Panier moyen',
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  color: textLightColor,
                                ),
                              ),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                '${averageOrderValue.toStringAsFixed(0)} FC',
                                style: pw.TextStyle(
                                  fontSize: 13,
                                  fontWeight: pw.FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        pw.Container(
                          width: 1,
                          height: 40,
                          color: borderColor,
                        ),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'Moyenne produits/commande',
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  color: textLightColor,
                                ),
                              ),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                averageProductsPerOrder.toStringAsFixed(1),
                                style: pw.TextStyle(
                                  fontSize: 13,
                                  fontWeight: pw.FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (startDate != null && endDate != null) ...[
                          pw.Container(
                            width: 1,
                            height: 40,
                            color: borderColor,
                          ),
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'Période couverte',
                                  style: pw.TextStyle(
                                    fontSize: 9,
                                    color: textLightColor,
                                  ),
                                ),
                                pw.SizedBox(height: 4),
                                pw.Text(
                                  '${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}',
                                  style: pw.TextStyle(
                                    fontSize: 9,
                                    fontWeight: pw.FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Table des ventes
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: borderColor, width: 1),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Table(
                  border: pw.TableBorder(
                    verticalInside: pw.BorderSide(color: borderColor, width: 0.5),
                    horizontalInside: pw.BorderSide(color: borderColor, width: 0.5),
                  ),
                  children: [
                    // En-tête
                    pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: primaryColorLight, // Vert pâle
                        borderRadius: const pw.BorderRadius.only(
                          topLeft: pw.Radius.circular(8),
                          topRight: pw.Radius.circular(8),
                        ),
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          child: pw.Text(
                            'DATE',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: primaryColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          child: pw.Text(
                            'CLIENT',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: primaryColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          child: pw.Text(
                            'MONTANT',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: primaryColor,
                              letterSpacing: 0.5,
                            ),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    // Données
                    ...sales.asMap().entries.map((entry) {
                      final index = entry.key;
                      final sale = entry.value;
                      return pw.TableRow(
                        decoration: pw.BoxDecoration(
                          color: index % 2 == 0 ? PdfColors.white : backgroundColor,
                        ),
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: pw.Text(
                              DateFormat('dd/MM/yyyy').format(sale['date'] as DateTime),
                              style: pw.TextStyle(
                                fontSize: 10,
                                color: textColor,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: pw.Text(
                              sale['clientName'] ?? 'Client inconnu',
                              style: pw.TextStyle(
                                fontSize: 10,
                                color: textColor,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: pw.Text(
                              '${(sale['total'] as double).toStringAsFixed(0)} FC',
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: primaryColor,
                              ),
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                    // Ligne de total
                    pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: primaryColorLight,
                        borderRadius: const pw.BorderRadius.only(
                          bottomLeft: pw.Radius.circular(8),
                          bottomRight: pw.Radius.circular(8),
                        ),
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          child: pw.Text(
                            'TOTAL',
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          child: pw.Text(
                            '${sales.length} vente${sales.length > 1 ? 's' : ''}',
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: textColor,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          child: pw.Text(
                            '${total.toStringAsFixed(0)} FC',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: primaryColor,
                            ),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),

              // Pied de page
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 16, horizontal: 0),
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(color: borderColor, width: 1),
                  ),
                ),
                child: pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              if (logoImage != null)
                                pw.Container(
                                  width: 40,
                                  height: 40,
                                  margin: const pw.EdgeInsets.only(bottom: 8),
                                  child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                                ),
                              pw.Text(
                                'Rapidos',
                                style: pw.TextStyle(
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                'Votre partenaire de confiance',
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  color: textLightColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text(
                                'Rapport généré le',
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  color: textLightColor,
                                ),
                              ),
                              pw.SizedBox(height: 2),
                              pw.Text(
                                DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now()),
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  color: textColor,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.SizedBox(height: 8),
                              pw.Text(
                                'Document confidentiel',
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  color: textLightColor,
                                  fontStyle: pw.FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWithLogo(
        title: _getPeriodTitle(),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_statistics != null && _merchantInfo != null)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: AppColors.primary),
              onPressed: _generatePDF,
              tooltip: 'Générer PDF',
            ),
        ],
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _statistics == null
              ? const Center(child: Text('Aucune donnée disponible'))
              : RefreshIndicator(
                  onRefresh: _loadStatistics,
                  child: Column(
                    children: [
                      // Résumé
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.all(10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200, width: 0.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.05),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
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
                                    Icons.bar_chart_rounded,
                                    color: AppColors.primary,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Résumé',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFF2B2D42),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildSummaryItem(
                                    'Total ventes',
                                    '${_statistics!['total'].toStringAsFixed(0)} FC',
                                    Icons.attach_money_rounded,
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: Colors.grey.shade300,
                                ),
                                Expanded(
                                  child: _buildSummaryItem(
                                    'Total commandes',
                                    _statistics!['count'].toString(),
                                    Icons.shopping_cart_rounded,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Liste des ventes
                      Expanded(
                        child: (_statistics!['sales'] as List).isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Aucune vente pour cette période',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                itemCount: (_statistics!['sales'] as List).length,
                                itemBuilder: (context, index) {
                                  final sale = (_statistics!['sales'] as List)[index] as Map<String, dynamic>;
                                  return _buildSaleCard(sale);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF147C3C),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSaleCard(Map<String, dynamic> sale) {
    final date = sale['date'] as DateTime;
    final clientName = sale['clientName'] ?? 'Client inconnu';
    final total = sale['total'] as double;
    final items = sale['items'] as List<dynamic>? ?? [];
    final productCount = items.fold<int>(0, (sum, item) => sum + ((item['quantity'] ?? 1) as int));
    final orderId = sale['orderId']?.toString() ?? 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              clientName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF2B2D42),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              '${total.toStringAsFixed(0)} FC',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 11,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            DateFormat('dd/MM/yyyy').format(date),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            Icons.access_time_rounded,
                            size: 11,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            DateFormat('HH:mm').format(date),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 10,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                _buildInfoChip(
                  Icons.shopping_bag_rounded,
                  '$productCount produit${productCount > 1 ? 's' : ''}',
                ),
                const SizedBox(width: 6),
                _buildInfoChip(
                  Icons.tag_rounded,
                  'Commande #$orderId',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.grey.shade700),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}


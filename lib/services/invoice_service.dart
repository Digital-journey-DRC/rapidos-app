import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';

class InvoiceService {
  /// Génère et affiche une facture PDF pour une commande avec possibilité de sauvegarder ou imprimer
  static Future<void> generateInvoice({
    required BuildContext context,
    required Map<String, dynamic> orderData,
    required String orderId,
    required Map<String, dynamic> merchantInfo,
    required Map<String, dynamic> clientInfo,
  }) async {
    try {
      final pdf = await _createInvoicePDF(
        orderData: orderData,
        orderId: orderId,
        merchantInfo: merchantInfo,
        clientInfo: clientInfo,
      );

      // Afficher le dialogue d'impression avec options de sauvegarde et d'impression
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Facture_Rapid_${orderId.substring(0, 8)}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la génération de la facture: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Charge le logo depuis les assets
  static Future<pw.ImageProvider?> _loadLogo() async {
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

  /// Crée le document PDF de la facture
  static Future<pw.Document> _createInvoicePDF({
    required Map<String, dynamic> orderData,
    required String orderId,
    required Map<String, dynamic> merchantInfo,
    required Map<String, dynamic> clientInfo,
  }) async {
    // Charger le logo
    final logoImage = await _loadLogo();
    final pdf = pw.Document();
    final items = orderData['items'] as List? ?? [];
    final timestamp = orderData['timestamp'];
    final adresse = orderData['adresse']?.toString() ?? 'Adresse non spécifiée';
    final phone = orderData['phone']?.toString() ?? '';
    final clientName = orderData['client']?.toString() ?? 'Client';
    final total = double.tryParse(orderData['total']?.toString() ?? '0') ?? 0.0;

    // Note: Le total est déjà calculé dans orderData['total']

    // Format de date
    String formattedDate = '';
    if (timestamp != null) {
      try {
        final date = timestamp.toDate();
        formattedDate = DateFormat('dd/MM/yyyy à HH:mm').format(date);
      } catch (e) {
        formattedDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
      }
    } else {
      formattedDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
    }

    // Informations du marchand
    String merchantName = merchantInfo['name']?.toString() ?? '';
    if (merchantName.isEmpty) {
      final firstName = merchantInfo['firstName']?.toString() ?? '';
      final lastName = merchantInfo['lastName']?.toString() ?? '';
      merchantName = '$firstName $lastName'.trim();
      if (merchantName.isEmpty) {
        merchantName = 'Marchand';
      }
    }
    final merchantPhone = merchantInfo['phone']?.toString() ?? '';
    final merchantEmail = merchantInfo['email']?.toString() ?? '';

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
                      pw.Text(
                        'FACTURE',
                        style: pw.TextStyle(
                          fontSize: 32,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Rapid#${orderId.substring(0, 8).toUpperCase()}',
                        style: pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  // Logo Rapidos
                  if (logoImage != null)
                    pw.Container(
                      width: 80,
                      height: 80,
                      child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                    )
                  else
                    pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue900,
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Text(
                        'RAPIDOS',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              pw.SizedBox(height: 30),

              // Informations du marchand et du client
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Informations du marchand
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(16),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Vendeur',
                            style: pw.TextStyle(
                              fontSize: 12,
                              color: PdfColors.grey700,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          pw.Text(
                            merchantName,
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          ...(merchantPhone.isNotEmpty ? [
                            pw.SizedBox(height: 4),
                            pw.Text(
                              'Tél: $merchantPhone',
                              style: const pw.TextStyle(fontSize: 12),
                            ),
                          ] : []),
                          ...(merchantEmail.isNotEmpty ? [
                            pw.SizedBox(height: 4),
                            pw.Text(
                              merchantEmail,
                              style: const pw.TextStyle(fontSize: 12),
                            ),
                          ] : []),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  // Informations du client
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(16),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Client',
                            style: pw.TextStyle(
                              fontSize: 12,
                              color: PdfColors.grey700,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          pw.Text(
                            clientName,
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          ...(phone.isNotEmpty ? [
                            pw.SizedBox(height: 4),
                            pw.Text(
                              'Tél: $phone',
                              style: const pw.TextStyle(fontSize: 12),
                            ),
                          ] : []),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            adresse,
                            style: const pw.TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 30),

              // Date de la commande
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  children: [
                    pw.Text(
                      'Date de commande: ',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      formattedDate,
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Tableau des produits
              pw.Text(
                'Articles',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  // En-tête du tableau
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.blue900,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Produit',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Qté',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Prix unitaire',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                          ),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Total',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                          ),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  // Lignes des produits
                  ...items.map((item) {
                    final name = item['name']?.toString() ?? 'Produit';
                    final quantity = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
                    final price = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
                    final itemTotal = quantity * price;

                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            name,
                            style: const pw.TextStyle(fontSize: 11),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            quantity.toString(),
                            style: const pw.TextStyle(fontSize: 11),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '${price.toStringAsFixed(2)} FC',
                            style: const pw.TextStyle(fontSize: 11),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '${itemTotal.toStringAsFixed(2)} FC',
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
              pw.SizedBox(height: 20),

              // Total
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue900,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Row(
                          mainAxisSize: pw.MainAxisSize.min,
                          children: [
                            pw.Text(
                              'Total TTC: ',
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              '${total.toStringAsFixed(2)} FC',
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontSize: 18,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 40),

              // Pied de page
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 12),
              pw.Center(
                child: pw.Text(
                  'Merci pour votre confiance !',
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey600,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'Rapidos - Votre partenaire de confiance',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey500,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }
}


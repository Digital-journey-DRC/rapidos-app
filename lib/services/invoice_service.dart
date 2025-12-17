import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';

class InvoiceService {
  // Couleurs de la charte graphique Rapidos
  static final PdfColor _primaryColor = PdfColor.fromInt(0xFF147C3C); // Vert principal
  static final PdfColor _primaryColorDark = PdfColor.fromInt(0xFF0F5A2A); // Vert principal foncé
  static final PdfColor _primaryColorLight = PdfColor.fromInt(0xFFE8F5E9); // Vert principal clair
  static final PdfColor _accentColor = PdfColor.fromInt(0xFFF3B30C); // Jaune/Orange accent
  static final PdfColor _textColor = PdfColor.fromInt(0xFF2B2D42); // Texte principal
  static final PdfColor _textLightColor = PdfColor.fromInt(0xFF8D99AE); // Texte secondaire
  static final PdfColor _backgroundColor = PdfColor.fromInt(0xFFF8F9FA); // Arrière-plan clair
  static final PdfColor _borderColor = PdfColor.fromInt(0xFFE0E0E0); // Bordure grise claire
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
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: _primaryColor, // Vert principal de la charte
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'FACTURE',
                          style: pw.TextStyle(
                            fontSize: 32,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.SizedBox(height: 6),
                        pw.Text(
                          'Rapid#${orderId.substring(0, 8).toUpperCase()}',
                          style: pw.TextStyle(
                            fontSize: 14,
                            color: PdfColor.fromInt(0xE6FFFFFF), // Blanc avec opacité 90%
                          ),
                        ),
                      ],
                    ),
                    // Logo Rapidos
                    if (logoImage != null)
                      pw.Container(
                        width: 70,
                        height: 70,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                      )
                    else
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromInt(0x33FFFFFF), // Blanc avec opacité
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
                        color: _backgroundColor,
                        borderRadius: pw.BorderRadius.circular(8),
                        border: pw.Border.all(color: _borderColor, width: 1),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: pw.BoxDecoration(
                              color: _primaryColor,
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                            child: pw.Text(
                              'Vendeur',
                              style: pw.TextStyle(
                                fontSize: 11,
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          pw.SizedBox(height: 8),
                          pw.Text(
                            merchantName,
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: _textColor,
                            ),
                          ),
                          ...(merchantPhone.isNotEmpty ? [
                            pw.SizedBox(height: 4),
                            pw.Text(
                              'Tél: $merchantPhone',
                              style: pw.TextStyle(
                                fontSize: 12,
                                color: _textLightColor,
                              ),
                            ),
                          ] : []),
                          ...(merchantEmail.isNotEmpty ? [
                            pw.SizedBox(height: 4),
                            pw.Text(
                              merchantEmail,
                              style: pw.TextStyle(
                                fontSize: 12,
                                color: _textLightColor,
                              ),
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
                        color: _backgroundColor,
                        borderRadius: pw.BorderRadius.circular(8),
                        border: pw.Border.all(color: _borderColor, width: 1),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: pw.BoxDecoration(
                              color: _accentColor,
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                            child: pw.Text(
                              'Client',
                              style: pw.TextStyle(
                                fontSize: 11,
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          pw.Text(
                            clientName,
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: _textColor,
                            ),
                          ),
                          ...(phone.isNotEmpty ? [
                            pw.SizedBox(height: 4),
                            pw.Text(
                              'Tél: $phone',
                              style: pw.TextStyle(
                                fontSize: 12,
                                color: _textLightColor,
                              ),
                            ),
                          ] : []),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            adresse,
                            style: pw.TextStyle(
                              fontSize: 12,
                              color: _textLightColor,
                            ),
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
                  color: _primaryColorLight,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: _primaryColor, width: 1),
                ),
                child: pw.Row(
                  children: [
                    pw.Icon(
                      pw.IconData(0xe192), // Icône calendrier
                      size: 14,
                      color: _primaryColor,
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      'Date de commande: ',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: _textColor,
                      ),
                    ),
                    pw.Text(
                      formattedDate,
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: _primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Tableau des produits
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Text(
                  'Articles',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Table(
                border: pw.TableBorder.all(color: _borderColor, width: 1),
                children: [
                  // En-tête du tableau
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: _primaryColor,
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
                  ...items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final name = item['name']?.toString() ?? 'Produit';
                    final quantity = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
                    final price = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
                    final itemTotal = quantity * price;

                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: index % 2 == 0 ? PdfColors.white : _backgroundColor,
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            name,
                            style: pw.TextStyle(
                              fontSize: 11,
                              color: _textColor,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            quantity.toString(),
                            style: pw.TextStyle(
                              fontSize: 11,
                              color: _textColor,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '${price.toStringAsFixed(2)} FC',
                            style: pw.TextStyle(
                              fontSize: 11,
                              color: _textColor,
                            ),
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
                              color: _primaryColor,
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
                    padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: pw.BoxDecoration(
                      gradient: pw.LinearGradient(
                        colors: [_primaryColor, _primaryColorDark],
                      ),
                      borderRadius: pw.BorderRadius.circular(12),
                    ),
                    child: pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Text(
                          'Total TTC: ',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          '${total.toStringAsFixed(2)} FC',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 40),

              // Pied de page
              pw.Divider(color: _borderColor, height: 2),
              pw.SizedBox(height: 16),
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: _backgroundColor,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Merci pour votre confiance !',
                      style: pw.TextStyle(
                        fontSize: 14,
                        color: _primaryColor,
                        fontWeight: pw.FontWeight.bold,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        if (logoImage != null)
                          pw.Container(
                            width: 24,
                            height: 24,
                            margin: const pw.EdgeInsets.only(right: 8),
                            child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                          ),
                        pw.Text(
                          'Rapidos - Votre partenaire de confiance',
                          style: pw.TextStyle(
                            fontSize: 11,
                            color: _textLightColor,
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

    return pdf;
  }
}


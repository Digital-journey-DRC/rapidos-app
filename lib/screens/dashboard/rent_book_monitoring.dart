import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:immo/constants.dart';
import 'package:immo/screens/dashboard/monitoring_payment.dart';
import 'package:immo/screens/dashboard/taxe_screen.dart';
import 'package:immo/widgets/custom_skeletons.dart';
import 'package:intl/intl.dart';
import '../../cubit/auth_cubit.dart';
import '../../cubits/rentbook/rentbook_cubit.dart';
import '../../cubits/rentbook/rentbook_state.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

class RentBookMonitoring extends StatefulWidget {
  const RentBookMonitoring({Key? key}) : super(key: key);

  @override
  State<RentBookMonitoring> createState() => _RentBookMonitoringState();
}

class _RentBookMonitoringState extends State<RentBookMonitoring> {
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _loadRentbooks();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent &&
          _hasMoreData &&
          _scrollController.position.maxScrollExtent > 0) {
        _loadMoreRentbooks();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadRentbooks() {
    setState(() {
      _hasMoreData = true;
      _currentPage = 1;
    });

    final authState = context.read<AuthCubit>().state;
    if (authState is AuthSuccess && authState.token != null) {
      context.read<RentbookCubit>().getOwnerRentbooks(
            token: authState.token!,
            page: 1,
            limit: 10,
          );
    }
  }

  void _loadMoreRentbooks() {
    final authState = context.read<AuthCubit>().state;
    final state = context.read<RentbookCubit>().state;

    if (authState is AuthSuccess &&
        authState.token != null &&
        state is RentbooksLoaded) {
      if (_currentPage < state.totalPages) {
        _currentPage++;
        context.read<RentbookCubit>().getOwnerRentbooks(
              token: authState.token!,
              page: _currentPage,
              limit: 10,
            );
      } else {
        setState(() {
          _hasMoreData = false;
        });
      }
    }
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _getRemainingDays(String endDateString) {
    final endDate = DateTime.parse(endDateString);
    final today = DateTime.now();
    final difference = endDate.difference(today).inDays;

    if (difference < 0) {
      return 'Expiré';
    } else if (difference == 0) {
      return 'Expire aujourd\'hui';
    } else {
      return '$difference jours restants';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'actif':
        return Colors.green;
      case 'terminé':
        return Colors.red;
      case 'en attente':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<void> generateContract({
    required String currency,
    required String province,
    required String ville,
    required String territoire,
    required String cite,
    required String bailleur,
    required String locataire,
    required String adresse,
    required String montantLoyer,
    required String montantLoyerLettres,
    required String usage,
    required String garantie,
    required String dureeContrat,
    required String dateContrat,
  }) async {
    final pdf = pw.Document();

    // 🔥 Charger l'image du logo
    final ByteData data = await rootBundle.load('assets/images/kin.png');
    final Uint8List logoBytes = data.buffer.asUint8List();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Center(
            child: pw.Image(pw.MemoryImage(logoBytes), width: 50),
          ),
          pw.SizedBox(height: 10),
          pw.Center(
            child: pw.Text(
              'CONTRAT DE LOCATION',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text('Province de : $province'),
          pw.Text('Ville de : $ville'),
          pw.Text('Territoire de : $territoire'),
          pw.Text('Cité de : $cite'),
          pw.SizedBox(height: 10),
          pw.Text(
            'Entre les soussignés :',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 5),
          pw.Text('- Bailleur : $bailleur'),
          pw.Text('- Locataire : $locataire'),
          pw.SizedBox(height: 10),
          pw.Header(level: 1, text: 'I. Description du bien'),
          pw.Text('Adresse : $adresse'),
          pw.SizedBox(height: 10),
          pw.Header(level: 1, text: 'II. Usage'),
          pw.Text('Usage : $usage'),
          pw.SizedBox(height: 10),
          pw.Header(level: 1, text: 'III. Loyer'),
          pw.Text('Montant du loyer : $montantLoyer $currency'),
          pw.SizedBox(height: 10),
          pw.Header(level: 1, text: 'IV. Modalités de paiement'),
          pw.Text(
            'Le paiement s’effectue en espèces, par chèque certifié ou par virement bancaire, anticipativement ou à terme échu selon l’accord des parties.',
          ),
          pw.SizedBox(height: 10),
          pw.Header(level: 1, text: 'V. Garantie'),
          pw.Text('Montant de la garantie locative : $garantie'),
          pw.SizedBox(height: 10),
          pw.Header(level: 1, text: 'VI. Durée'),
          pw.Text('Durée du contrat : $dureeContrat an(s)'),
          pw.SizedBox(height: 10),
          pw.Header(level: 1, text: 'VII. Obligations du Bailleur'),
          pw.Bullet(text: 'Mettre à disposition un bien en bon état'),
          pw.Bullet(text: 'Garantir la jouissance paisible du bien loué'),
          pw.Bullet(text: 'S’acquitter des taxes légales'),
          pw.SizedBox(height: 10),
          pw.Header(level: 1, text: 'VIII. Obligations du Locataire'),
          pw.Bullet(text: 'Payer son loyer régulièrement'),
          pw.Bullet(text: 'User du bien en bon père de famille'),
          pw.Bullet(
              text: 'Ne pas modifier le bien sans accord écrit du bailleur'),
          pw.SizedBox(height: 10),
          pw.Header(level: 1, text: 'IX. Résiliation'),
          pw.Text(
            'Le contrat prend fin à l’expiration du terme convenu, sur accord des parties, ou en cas de destruction du bien.',
          ),
          pw.SizedBox(height: 10),
          pw.Header(level: 1, text: 'X. Conditions de résiliation'),
          pw.Bullet(text: "Expiration du terme et non-renouvellement"),
          pw.Bullet(text: "Accord mutuel des parties"),
          pw.Bullet(text: "Non-respect des obligations par une des parties"),
          pw.Bullet(text: "Perte du bien loué dû à un désastre naturel"),
          pw.SizedBox(height: 10),
          pw.Header(level: 1, text: 'XI. Instance d’arbitrage'),
          pw.Text(
            'En cas de litige, l’affaire est soumise au Service local de l’Habitat.',
          ),
          pw.SizedBox(height: 10),
          pw.Header(level: 1, text: 'XII. Sanction'),
          pw.Text(
            'Tout contrat non légalisé sous 72h entraîne une amende équivalente à un mois de loyer.',
          ),
          pw.SizedBox(height: 20),
          pw.Text('Fait à $ville, le $dateContrat',
              style: pw.TextStyle(fontSize: 14)),
          pw.SizedBox(height: 30),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                children: [
                  pw.Text('Le Bailleur',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 40),
                  pw.Text('(Signature)'),
                ],
              ),
              pw.Column(
                children: [
                  pw.Text('Le Locataire',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 40),
                  pw.Text('(Signature)'),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/contrat_bail.pdf');
    await file.writeAsBytes(await pdf.save());

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Carnets de Loyer',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRentbooks,
          ),
        ],
      ),
      body: BlocBuilder<RentbookCubit, RentbookState>(
        builder: (context, state) {
          if (state is RentbookLoading && _currentPage == 1) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title skeleton
                  const SkeletonLine(
                    style: SkeletonLineStyle(
                      width: 200,
                      height: 24,
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Rentbook cards skeletons
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 5,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Property name skeleton
                                  const SkeletonLine(
                                    style: SkeletonLineStyle(
                                      width: 180,
                                      height: 18,
                                      borderRadius: BorderRadius.all(Radius.circular(8)),
                                    ),
                                  ),
                                  // Status tag skeleton
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const SkeletonLine(
                                      style: SkeletonLineStyle(
                                        width: 60,
                                        height: 12,
                                        borderRadius: BorderRadius.all(Radius.circular(8)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              // Info rows skeletons
                              for (int i = 0; i < 4; i++)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    children: [
                                      // Icon skeleton
                                      SkeletonAvatar(
                                        style: SkeletonAvatarStyle(
                                          width: 24,
                                          height: 24,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Title skeleton
                                      const SkeletonLine(
                                        style: SkeletonLineStyle(
                                          width: 80,
                                          height: 14,
                                          borderRadius: BorderRadius.all(Radius.circular(4)),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Value skeleton
                                      const SkeletonLine(
                                        style: SkeletonLineStyle(
                                          width: 120,
                                          height: 14,
                                          borderRadius: BorderRadius.all(Radius.circular(4)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              
                              const SizedBox(height: 16),
                              
                              // Action buttons skeletons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  SkeletonButton(
                                    width: 100,
                                    height: 36,
                                    color: AppColors.buttonColor.withOpacity(0.2),
                                  ),
                                  const SizedBox(width: 8),
                                  SkeletonButton(
                                    width: 100,
                                    height: 36,
                                    color: Colors.green.withOpacity(0.2),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          } else if (state is RentbookError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur: ${state.message}',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadRentbooks,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          } else if (state is RentbooksLoaded) {
            if (state.rentbooks.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.book_outlined,
                        size: 60, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'Aucun carnet de loyer trouvé',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Vous n\'avez pas encore créé de carnet de loyer',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey.shade100,
                  child: Row(
                    children: [
                      Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.buttonColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.book, color: Colors.white)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Total: ${state.total} carnet${state.total > 1 ? 's' : ''} de loyer',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      _loadRentbooks();
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: state.rentbooks.length +
                          (_hasMoreData && state.currentPage < state.totalPages
                              ? 1
                              : 0),
                      itemBuilder: (context, index) {
                        if (index == state.rentbooks.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: SkeletonLine(
                                style: SkeletonLineStyle(
                                  width: 80,
                                  height: 16,
                                  borderRadius: BorderRadius.all(Radius.circular(8)),
                                ),
                              ),
                            ),
                          );
                        }

                        final rentbook = state.rentbooks[index];
                        final apartment = rentbook['apartmentId'];
                        final tenant = rentbook['tenantId'];

                        return Card(
                          color: Colors.white,
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(
                              color: AppColors.buttonColor,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: () {
                              // Naviguer vers les détails du carnet de loyer
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: const BoxDecoration(
                                    color: AppColors.buttonColor,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      topRight: Radius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.apartment,
                                          size: 24, color: Colors.white),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Appartement ${apartment['number']}, Étage ${apartment['floor']}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const Spacer(),
                                      InkWell(
                                        onTap: () {
                                          final rentbook =
                                              state.rentbooks[index];
                                          final apartment =
                                              rentbook['apartmentId'];
                                          final building =
                                              apartment['buildingId'];
                                          final images =
                                              apartment['images'] as List?;
                                          final image = (images != null &&
                                                  images.isNotEmpty)
                                              ? images[0]
                                              : 'https://via.placeholder.com/150';
                                          generateContract(
                                            currency: apartment['price']
                                                ['currency'],
                                            province: "Kinshasa",
                                            ville: "Kinshasa",
                                            territoire: "N/A",
                                            cite: "N/A",
                                            bailleur: rentbook['ownerId']
                                                    ['firstName'] +
                                                // ignore: prefer_interpolation_to_compose_strings
                                                " " +
                                                rentbook['ownerId']['lastName'],
                                            locataire: rentbook['tenantId']
                                                    ['firstName'] +
                                                // ignore: prefer_interpolation_to_compose_strings
                                                " " +
                                                rentbook['tenantId']
                                                    ['lastName'],
                                            adresse: building['address'] != null
                                                ? '${building['address']['street']}, ${building['address']['city']}, ${building['address']['country']}'
                                                : 'Adresse non disponible',
                                            montantLoyer:
                                                rentbook['monthlyRent']
                                                    .toString(),
                                            montantLoyerLettres: "N/A",
                                            usage: "Résidentiel",
                                            garantie: "3 mois de loyer",
                                            dureeContrat: "1",
                                            dateContrat: _formatDate(
                                                rentbook['leaseStartDate']),
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Text(
                                            "Contrat",
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildInfoRow(
                                        icon: Icons.person,
                                        title: 'Locataire',
                                        value:
                                            '${tenant['firstName']} ${tenant['lastName']}',
                                      ),
                                      const Divider(),
                                      _buildInfoRow(
                                        icon: Icons.phone,
                                        title: 'Téléphone',
                                        value: tenant['phone'],
                                      ),
                                      const Divider(),
                                      _buildInfoRow(
                                        icon: Icons.calendar_today,
                                        title: 'Période',
                                        value:
                                            '${_formatDate(rentbook['leaseStartDate'])} - ${_formatDate(rentbook['leaseEndDate'])}',
                                      ),
                                      const Divider(),
                                      _buildInfoRow(
                                        icon: Icons.timer,
                                        title: 'Statut',
                                        value: _getRemainingDays(
                                            rentbook['leaseEndDate']),
                                        valueColor: _getRemainingDays(
                                                    rentbook['leaseEndDate']) ==
                                                'Expiré'
                                            ? Colors.red
                                            : null,
                                      ),
                                      const Divider(),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildInfoRow(
                                              icon: Icons.attach_money,
                                              title: 'Loyer',
                                              value:
                                                  '${rentbook['monthlyRent']} ${apartment['price']['currency']}',
                                            ),
                                          ),
                                          Expanded(
                                            child: _buildInfoRow(
                                              icon: Icons.security,
                                              title: 'Caution',
                                              value:
                                                  '${rentbook['securityDeposit']} ${apartment['price']['currency']}',
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildInfoRow(
                                              icon: Icons.date_range,
                                              title: 'Date de Création',
                                              value:
                                                  'Le ${_formatDate(rentbook['createdAt'])}',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(12),
                                      bottomRight: Radius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  MonitoringPayment( rentbook: rentbook['paymentHistory'], currency: apartment['price']['currency']),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: AppColors.buttonColor,
                                            borderRadius: BorderRadius.circular(10)
                                            
                                          ),
                                          child: const Text(
                                            'Historique de paiement',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold
                                            ),
                                          ),
                                        ),
                                      ),
                                      apartment.containsKey('taxe') &&
                                              apartment['taxe'] == true
                                          ? InkWell(
                                              onTap: () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        SelectPageTaxe(
                                                            apartmentId:
                                                                apartment),
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.payment,
                                                      size: 16,
                                                      color: Colors.white,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    const Text(
                                                      'Payer la taxe',
                                                      style: TextStyle(
                                                          color: Colors.white),
                                                    )
                                                  ],
                                                ),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  color: AppColors.buttonColor,
                                                ),
                                              ),
                                            )
                                          : Container(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          } else {
            return const Center(
                child: Text('Chargement des carnets de loyer...'));
          }
        },
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

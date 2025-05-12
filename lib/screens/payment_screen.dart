import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:immo/constants.dart';
import 'package:immo/cubit/auth_cubit.dart';
import 'package:immo/cubits/payment/payment_cubit.dart';
import 'package:immo/cubits/payment/payment_state.dart';
import 'package:immo/cubits/tenant_rentbook/tenant_rentbook_cubit.dart';
import 'package:immo/cubits/tenant_rentbook/tenant_rentbook_state.dart';
import 'package:immo/cubits/utility_bill/utility_bill_cubit.dart';
import 'package:immo/cubits/utility_bill/utility_bill_state.dart';
import 'package:immo/screens/dashboard/setting_screen.dart';
import 'package:immo/screens/maintenance_screen.dart';
import 'package:immo/screens/mobile_payment_screen.dart';
import 'package:immo/screens/payment_facture.dart';
import 'package:immo/services/payment_storage_service.dart';
import 'package:immo/widgets/image_viewer.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart' show DateFormat, toBeginningOfSentenceCase;
import 'dart:developer' as developer;
import 'package:immo/widgets/custom_skeletons.dart';

class ListPayment extends StatefulWidget {
  const ListPayment({super.key});

  @override
  State<ListPayment> createState() => _ListPaymentState();
}

class _ListPaymentState extends State<ListPayment> {
  @override
  void initState() {
    super.initState();
    _loadRentbooks();
  }

  void _loadRentbooks() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthSuccess && authState.token != null) {
      context.read<TenantRentbookCubit>().getTenantRentbooks(
            token: authState.token!,
            page: 1,
            limit: 10,
          );
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Non spécifié';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'actif':
      case 'payé':
        return Colors.green;
      case 'terminé':
        return Colors.red;
      case 'en attente':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    bool isAuthenticated = authState is AuthSuccess && authState.token != null;

    if (!isAuthenticated) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text(
              'Veuillez vous connecter pour accéder à vos carnets de loyer'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        leading: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            if (state is AuthSuccess && 
                state.user != null && 
                state.user!['profileImage'] != null) {
              // Display profile image if available
              return CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.white,
                child: CircleAvatar(
                  radius: 23,
                  backgroundColor: AppColors.buttonColor,
                  backgroundImage: NetworkImage(state.user!['profileImage']),
                  child: IconButton(
                    icon: const Icon(Icons.person, color: Colors.transparent),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SettingScreen()));
                    },
                  ),
                ),
              );
            } else {
              // Show default person icon if no profile image
              return CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.white,
                child: CircleAvatar(
                  radius: 23,
                  backgroundColor: AppColors.buttonColor,
                  child: CircleAvatar(
                    backgroundColor: AppColors.white,
                    child: IconButton(
                      icon: const Icon(Icons.person, color: AppColors.buttonColor),
                      onPressed: () {
                        Navigator.push(context, 
                        MaterialPageRoute(builder: (context) => const SettingScreen()));
                      },
                    ),
                  ),
                ),
              );
            }
          },
        ),
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Text('Mes Paiements de loyer',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRentbooks,
          ),
        ],
      ),
      body: BlocBuilder<TenantRentbookCubit, TenantRentbookState>(
        builder: (context, state) {
          if (state is TenantRentbookLoading) {
            return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 3, // Show 3 skeleton cards
            itemBuilder: (context, index) {
              return Card(
                color: Colors.grey.withOpacity(0.1),
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(
                    color: AppColors.buttonColor,
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SkeletonAvatar(
                            style: SkeletonAvatarStyle(
                              width: 80,
                              height: 80,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SkeletonLine(
                                  style: SkeletonLineStyle(
                                    width: 150,
                                    height: 16,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SkeletonLine(
                                  style: SkeletonLineStyle(
                                    width: 100,
                                    height: 12,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.buttonColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SkeletonLine(
                              style: SkeletonLineStyle(
                                width: 40,
                                height: 10,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SkeletonLine(
                            style: SkeletonLineStyle(
                              width: 120,
                              height: 14,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          SkeletonLine(
                            style: SkeletonLineStyle(
                              width: 80,
                              height: 14,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
          } else if (state is TenantRentbookError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Image.asset(
                    'assets/images/no-connect.png',
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  const Text(
                    'Pas de connexion',
                    style: TextStyle(
                      fontSize: 18,
                    ),
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
          } else if (state is TenantRentbookLoaded) {
            if (state.rentbooks.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.book_outlined, size: 60, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Aucun carnet de loyer trouvé',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Vous n\'avez pas encore de carnet de loyer',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: state.rentbooks.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final rentbook = state.rentbooks[index];
                final apartment = rentbook['apartmentId'];
                final building = apartment['buildingId'];
                final images = apartment['images'] as List?;
                final image = (images != null && images.isNotEmpty)
                    ? images[0]
                    : 'https://via.placeholder.com/150';

                return Card(
                  color: Colors.grey.withOpacity(0.1),
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(
                      color: AppColors.buttonColor,
                      width: 2,
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PaymentScreen(rentbookData: rentbook, currency: apartment['price']['currency'] ?? 'USD'),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ImageViewerWidget(
                                  url: image,
                                  width: 80,
                                  height: 80,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.grey.withOpacity(0.5),
                                      width: 1)),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      building['name'] ?? 'Appartement',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Appartement ${apartment['number'] ?? ''}, Étage ${apartment['floor'] ?? ''}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.buttonColor,
                                  // color: _getStatusColor(
                                  //     rentbook['status'] ?? 'inconnu'),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  ("Voir").toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Loyer: ${rentbook['monthlyRent']} ${apartment['price']['currency']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Fin: ${_formatDate(rentbook['leaseEndDate'])}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
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

          return const Center(child: Text('Chargement...'));
        },
      ),
    );
  }
}

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, required this.rentbookData, required this.currency});
  final Map<String, dynamic> rentbookData;
  final String currency;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedPaymentMethod;
  final List<String> _paymentMethods = [
    'mobile_money',
    'espèces'
    // 'virement',
    // 'chèque',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRentbooks();
    _selectedPaymentMethod = _paymentMethods.first;

    loadBills();

    // final authState = context.read<AuthCubit>().state;
    // if (authState is AuthSuccess && authState.token != null) {
    //   final apartmentId = widget.rentbookData['apartmentId']['_id'];
    //   context.read<UtilityBillCubit>().getUtilityBillsByApartment(
    //       token: authState.token!, apartmentId: apartmentId);
    // }
  }

  void loadBills() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthSuccess && authState.token != null) {
      final apartmentId = widget.rentbookData['apartmentId']['_id'];
      context.read<UtilityBillCubit>().getUtilityBillsByApartment(
            token: authState.token!,
            apartmentId: apartmentId,
          );
    }
  }

  void _loadRentbooks() {
    developer.log('Chargement des carnets de loyer...');
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthSuccess && authState.token != null) {
      developer.log('Token trouvé: ${authState.token!.substring(0, 10)}...');
      context.read<TenantRentbookCubit>().getTenantRentbooks(
            token: authState.token!,
            page: 1,
            limit: 10,
          );
    } else {
      developer.log('Pas de token disponible ou utilisateur non authentifié');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Mes Paiements',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.buttonColor,
          tabs: const [
            Tab(
              icon: Icon(Icons.home_outlined),
              text: 'Loyer',
            ),
            Tab(
              icon: Icon(Icons.receipt_long_outlined),
              text: 'Factures',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRentPaymentTab(),
          _buildBillsPaymentTab(),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Non spécifié';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _formatCurrentDate() {
    final now = DateTime.now();
    final day = now.day;
    final months = ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
    final month = months[now.month - 1];
    final year = now.year;
    return '$day $month $year';
  }

  /// Builds a tab displaying utility bills, handling loading, error, and data states.
  ///
  /// - Displays a loading indicator while bills are being fetched.
  /// - Shows an error message if there's an error fetching bills.
  /// - Lists bills if they're successfully loaded, or shows a message if no bills are present.
  /// - Allows marking a bill as paid with an HTTP PATCH request.
  ///
  /// Returns a widget representing the state of the utility bills.
  Widget _buildBillsPaymentTab() {
    return BlocBuilder<UtilityBillCubit, UtilityBillState>(
      builder: (context, state) {
        if (state is UtilityBillLoading) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 3, // Show 3 skeleton cards
            itemBuilder: (context, index) {
              return Card(
                color: Colors.grey.withOpacity(0.1),
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(
                    color: AppColors.buttonColor,
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SkeletonAvatar(
                            style: SkeletonAvatarStyle(
                              width: 80,
                              height: 80,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SkeletonLine(
                                  style: SkeletonLineStyle(
                                    width: 150,
                                    height: 16,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SkeletonLine(
                                  style: SkeletonLineStyle(
                                    width: 100,
                                    height: 12,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.buttonColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SkeletonLine(
                              style: SkeletonLineStyle(
                                width: 40,
                                height: 10,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SkeletonLine(
                            style: SkeletonLineStyle(
                              width: 120,
                              height: 14,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          SkeletonLine(
                            style: SkeletonLineStyle(
                              width: 80,
                              height: 14,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        } else if (state is UtilityBillError) {
          return Center(child: Text('Erreur: ${state.message}'));
        } else if (state is UtilityBillsLoaded) {
          final bills = state.bills;

          if (bills.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Aucune facture à payer pour le moment.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: bills.length,
            itemBuilder: (context, index) {
              final bill = bills[index];
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  color: Colors.red.shade50,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.red.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          bill['type'] == 'eau'
                              ? Icons.water_drop
                              : Icons.electric_bolt,
                          color: bill['type'] == 'eau'
                              ? Colors.blue.shade400
                              : Colors.amber,
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              toBeginningOfSentenceCase(bill['type']) ??
                                  bill['type'],
                              style:
                                  const TextStyle(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Text('Montant: '),
                                Text(
                                  bill['apartmentAmount'] != null
                                      ? '${bill['apartmentAmount']} ${bill['totalAmount']['currency']}'
                                      : '${bill['apartmentAmount'] ?? 0} \$',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Échéance: ${_formatDate(bill['dueDate'])}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (bill['isPaid'])
                          Text(
                            "Payée",
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Colors.green.shade400,
                            ),
                          )
                        else
                          GestureDetector(
                            onTap: () async {

                              Navigator.push(context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PayementFacture(
                                    billData: bill,
                                    currency: bill['totalAmount']!= null
                                        ? bill['totalAmount']['currency']
                                        : 'USD',
                                  ),
                                ),

                              
                              );


                              // try {
                              //   final authState =
                              //       context.read<AuthCubit>().state;
                              //   if (authState is AuthSuccess &&
                              //       authState.token != null) {
                              //     final response = await http.patch(
                              //       Uri.parse(
                              //           'http://68.183.30.146:8000/api/v1/utility-bills/${bill['billId']}/apartment/${widget.rentbookData['apartmentId']['_id']}/mark-paid'),
                              //       headers: {
                              //         'Authorization':
                              //             'Bearer ${authState.token}',
                              //         'Content-Type': 'application/json',
                              //       },
                              //     );

                              //     if (response.statusCode == 200) {
                              //       loadBills();

                              //       ScaffoldMessenger.of(context).showSnackBar(
                              //         const SnackBar(
                              //           content: Text(
                              //               'Paiement effectué avec succès!'),
                              //           backgroundColor: Colors.green,
                              //         ),
                              //       );
                              //     } else {
                              //       throw Exception('Échec du paiement');
                              //     }
                              //   }
                              // } catch (e) {
                              //   ScaffoldMessenger.of(context).showSnackBar(
                              //     SnackBar(
                              //       content: Text('Erreur: ${e.toString()}'),
                              //       backgroundColor: Colors.red,
                              //     ),
                              //   );
                              // }




                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: AppColors.buttonColor,
                              ),
                              child: const Text(
                                'Payer la facture',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
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
            },
          );
        }
        return const Center(child: Text('Aucune facture à afficher.'));
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildNextPaymentCard(
      [dynamic rentbook,
      dynamic apartment,
      dynamic building,
      List<dynamic>? paymentHistory]) {
    // Si nous avons des données de loyer
    final bool hasData =
        rentbook != null && apartment != null && building != null;

    // Ajouter des logs pour le débogage
    if (hasData) {
      developer.log(
          'Type de rentbook[monthlyRent]: ${rentbook['monthlyRent'].runtimeType}');
      developer
          .log('Valeur de rentbook[monthlyRent]: ${rentbook['monthlyRent']}');
    }

    // Récupérer le rentbookId
    String id = hasData ? rentbook['_id'] ?? '' : '';

    // Vérifier si nous avons des informations sur le prochain paiement dans Hive
    Map<String, dynamic>? nextPaymentFromStorage;
    if (hasData && id.isNotEmpty) {
      nextPaymentFromStorage = PaymentStorageService.getNextPayment(id);
      if (nextPaymentFromStorage != null) {
        developer.log(
            'Prochain paiement trouvé dans le stockage: $nextPaymentFromStorage');
      }
    }

    // Trouver le prochain paiement (celui qui n'est pas encore payé)
    dynamic nextPayment;
    if (paymentHistory != null && paymentHistory.isNotEmpty) {
      for (var payment in paymentHistory) {
        if (payment['status'] == 'En attente') {
          nextPayment = payment;
          break;
        }
      }
    }

    final String propertyName =
        hasData ? building['name'] ?? 'Appartement' : 'Appartement';
    final String address = hasData && building['address'] != null
        ? '${building['address']['street']}, ${building['address']['city']}'
        : 'Adresse non disponible';

    // Utiliser les données du stockage si disponibles, sinon utiliser les données de l'API
    final String rentMonth = nextPaymentFromStorage != null
        ? nextPaymentFromStorage['month']
        : (nextPayment != null
            ? nextPayment['month'] ?? 'Mars 2025'
            : 'Mars 2025');

    final String dueDate = nextPaymentFromStorage != null
        ? nextPaymentFromStorage['dueDate']
        : (nextPayment != null
            ? nextPayment['dueDate'] ?? _formatCurrentDate()
            : _formatCurrentDate());

    final double amount = hasData
        ? (rentbook['monthlyRent'] is int
            ? (rentbook['monthlyRent'] as int).toDouble()
            : (rentbook['monthlyRent'] ?? 750.0))
        : 750.0;

    final String status = nextPaymentFromStorage != null
        ? nextPaymentFromStorage['status']
        : (nextPayment != null
            ? nextPayment['status'] ?? 'En attente'
            : 'En attente');

    return BlocListener<PaymentCubit, PaymentState>(
      listener: (context, state) {
        if (state is PaymentSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Paiement effectué avec succès!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );

          // Recharger les données après le paiement
          _loadRentbooks();

          // Réinitialiser l'état du paiement
          context.read<PaymentCubit>().resetState();
        } else if (state is PaymentError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${state.message}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
        }
      },
      child: Card(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Loyer $rentMonth',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Échéance: $dueDate',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.home_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$propertyName, $address',
                      style: const TextStyle(color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Montant',
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    paymentHistory != null && paymentHistory.isNotEmpty
                        ? paymentHistory[0]['totalAmount'] != null
                            ? '${paymentHistory[0]['totalAmount']['value']} ${paymentHistory[0]['totalAmount']['currency']}'
                            : '${paymentHistory[0]['amount'] ?? 0} ${widget.currency}'
                        : amount.toString() + ' ${widget.currency}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (hasData) ...[
                const Text(
                  'Méthode de paiement',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedPaymentMethod,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _paymentMethods.map((method) {
                    String label;
                    IconData icon;

                    switch (method) {
                      case 'mobile_money':
                        label = 'Mobile Money';
                        icon = Icons.phone_android;
                        break;
                      case 'espèces':
                        label = 'Espèces';
                        icon = Icons.money;
                        break;
                      // case 'virement':
                      //   label = 'Virement bancaire';
                      //   icon = Icons.account_balance;
                      //   break;
                      // case 'chèque':
                      //   label = 'Chèque';
                      //   icon = Icons.payment;
                      //   break;
                      // case 'mobile_money':
                      //   label = 'Mobile Money';
                      //   icon = Icons.phone_android;
                      //   break;
                      default:
                        label = method;
                        icon = Icons.payment;
                    }

                    return DropdownMenuItem<String>(
                      value: method,
                      child: Row(
                        children: [
                          Icon(icon, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(label),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPaymentMethod = value;
                    });
                  },
                ),
              ],
              const SizedBox(height: 24),
              BlocBuilder<PaymentCubit, PaymentState>(
                builder: (context, state) {
                  final bool isLoading = state is PaymentLoading;

                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final rentBookId = rentbook['_id'];
                        final amount = rentbook['monthlyRent'];
                        final devise = apartment['price']['currency'] ??
                            'USD'; // Default to USD if not specified
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MobilePaymentScreen(
                              rentBookId: rentBookId,
                              amount: amount,
                              devise: widget.currency,
                            ),
                          ),
                        );
                      },
                      // onPressed: hasData && !isLoading
                      //     ? () => _makePayment(id, amount)
                      //     : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Payer maintenant',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _makePayment(String id, double amount) {
    // Ajouter des logs pour le débogage
    developer.log('Type de amount dans _makePayment: ${amount.runtimeType}');
    developer.log('Valeur de amount dans _makePayment: $amount');

    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Impossible de traiter le paiement: ID du carnet de loyer manquant'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthSuccess || authState.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous devez être connecté pour effectuer un paiement'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Afficher une boîte de dialogue de confirmation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Confirmer le paiement',
          style: TextStyle(color: Colors.black),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Montant: $amount \$'),
            const SizedBox(height: 8),
            Text(
                'Méthode: ${_getPaymentMethodLabel(_selectedPaymentMethod ?? 'mobile_money')}'),
            const SizedBox(height: 16),
            const Text('Voulez-vous procéder au paiement?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);

              final String currentMonth = _getCurrentMonth();
              final String comment = 'Paiement du loyer de $currentMonth';

              context.read<PaymentCubit>().makePayment(
                    rentbookId: id,
                    amount: amount,
                    paymentMethod: _selectedPaymentMethod ?? 'mobile_money',
                    comment: comment,
                    token: authState.token!,
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text(
              'Confirmer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceCard(
      [dynamic rentbook,
      dynamic apartment,
      dynamic building,
      List<dynamic>? paymentHistory]) {
    // Si nous avons des données de loyer
    final bool hasData =
        rentbook != null && apartment != null && building != null;

    // Ajouter des logs pour le débogage
    if (hasData) {
      developer.log(
          'Type de rentbook[monthlyRent]: ${rentbook['monthlyRent'].runtimeType}');
      developer
          .log('Valeur de rentbook[monthlyRent]: ${rentbook['monthlyRent']}');
    }

    // Récupérer le rentbookId
    String id = hasData ? rentbook['_id'] ?? '' : '';

    // Vérifier si nous avons des informations sur le prochain paiement dans Hive
    Map<String, dynamic>? nextPaymentFromStorage;
    if (hasData && id.isNotEmpty) {
      nextPaymentFromStorage = PaymentStorageService.getNextPayment(id);
      if (nextPaymentFromStorage != null) {
        developer.log(
            'Prochain paiement trouvé dans le stockage: $nextPaymentFromStorage');
      }
    }

    // Trouver le prochain paiement (celui qui n'est pas encore payé)
    dynamic nextPayment;
    if (paymentHistory != null && paymentHistory.isNotEmpty) {
      for (var payment in paymentHistory) {
        if (payment['status'] == 'En attente') {
          nextPayment = payment;
          break;
        }
      }
    }

    final String propertyName =
        hasData ? building['name'] ?? 'Appartement' : 'Appartement';
    final String address = hasData && building['address'] != null
        ? '${building['address']['street']}, ${building['address']['city']}'
        : 'Adresse non disponible';

    // Utiliser les données du stockage si disponibles, sinon utiliser les données de l'API
    final String rentMonth = nextPaymentFromStorage != null
        ? nextPaymentFromStorage['month']
        : (nextPayment != null
            ? nextPayment['month'] ?? 'Mars 2025'
            : 'Mars 2025');

    final String dueDate = nextPaymentFromStorage != null
        ? nextPaymentFromStorage['dueDate']
        : (nextPayment != null
            ? nextPayment['dueDate'] ?? _formatCurrentDate()
            : _formatCurrentDate());

    final double amount = hasData
        ? (rentbook['monthlyRent'] is int
            ? (rentbook['monthlyRent'] as int).toDouble()
            : (rentbook['monthlyRent'] ?? 750.0))
        : 750.0;

    final String status = nextPaymentFromStorage != null
        ? nextPaymentFromStorage['status']
        : (nextPayment != null
            ? nextPayment['status'] ?? 'En attente'
            : 'En attente');

    return BlocListener<PaymentCubit, PaymentState>(
      listener: (context, state) {
        if (state is PaymentSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Paiement effectué avec succès!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );

          // Recharger les données après le paiement
          _loadRentbooks();

          // Réinitialiser l'état du paiement
          context.read<PaymentCubit>().resetState();
        } else if (state is PaymentError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${state.message}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
        }
      },
      child: Card(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            // crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Demander une maintenance \npour votre appartement.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(Icons.engineering_outlined, size: 30, color: Colors.grey)
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              BlocBuilder<PaymentCubit, PaymentState>(
                builder: (context, state) {
                  final bool isLoading = state is PaymentLoading;

                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        print(apartment);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MaintenanceScreen(
                              apartmentId: apartment['_id'],
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Maintenance',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCurrentMonth() {
    final now = DateTime.now();
    final months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre'
    ];
    return '${months[now.month - 1]} ${now.year}';
  }

  String _getPaymentMethodLabel(String method) {
    switch (method) {
      case 'mobile_money':
        return 'Mobile Money';
      case 'espèces':
        return 'Espèces';
      // case 'virement':
      //   return 'Virement bancaire';
      // case 'chèque':
      //   return 'Chèque';

      default:
        return 'Mobile Money';
    }
  }

  Widget _buildPaymentHistoryList([List<dynamic>? paymentHistory, apartment]) {
    // List<Map<String, dynamic>> historyItems = [];

    // Récupérer le rentbookId
    String rentbookId = '';
    final state = context.read<TenantRentbookCubit>().state;
    // if (state is TenantRentbookLoaded && state.rentbooks.isNotEmpty) {
    //   rentbookId = state.rentbooks[0]['_id'] ?? '';
    // }

    // Si nous avons un rentbookId, essayer de récupérer l'historique depuis Hive
    // if (rentbookId.isNotEmpty) {
    //   final storedHistory = PaymentStorageService.getPaymentHistory(rentbookId);
    //   if (storedHistory.isNotEmpty) {
    //     developer.log(
    //         'Historique de paiement trouvé dans le stockage: ${storedHistory.length} éléments');
    //     historyItems = storedHistory;
    //   }
    // }

    // Si aucun historique n'est trouvé dans Hive, utiliser les données de l'API
    if (paymentHistory!.isEmpty &&
        paymentHistory != null &&
        paymentHistory.isNotEmpty) {
      for (var payment in paymentHistory) {
        if (payment['status'] == 'Payé') {
          paymentHistory.add(Map<String, dynamic>.from(payment));
        }
      }
    }

    // Si aucun paiement trouvé, utiliser des données fictives
    if (paymentHistory.isEmpty) {
      paymentHistory.addAll([
        // {
        //   'month': 'Février 2025',
        //   'date': '15/02/2025',
        //   'amount': 750.0,
        //   'status': 'Payé',
        //   'paymentMethod': 'mobile_money',
        // },
        // {
        //   'month': 'Janvier 2025',
        //   'date': '15/01/2025',
        //   'amount': 750.0,
        //   'status': 'Payé',
        //   'paymentMethod': 'virement',
        // },
        // {
        //   'month': 'Décembre 2024',
        //   'date': '15/12/2024',
        //   'amount': 750.0,
        //   'status': 'Payé',
        //   'paymentMethod': 'espèces',
        // },
      ]);
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: paymentHistory.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final payment = paymentHistory[index];

        var inputFormat = DateFormat('dd/MM/yyyy HH:mm');

        // Déterminer l'icône de la méthode de paiement
        IconData paymentIcon;
        switch (payment['paymentMethod']) {
          case 'espèces':
            paymentIcon = Icons.money;
            break;
          case 'mobile_money':
            paymentIcon = Icons.phone_android;
            break;
          // case 'virement':
          //   paymentIcon = Icons.account_balance;
          //   break;
          // case 'chèque':
          //   paymentIcon = Icons.payment;
          //   break;
          // case 'mobile_money':
          //   paymentIcon = Icons.phone_android;
          //   break;
          default:
            paymentIcon = Icons.payment;
        }

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Icon(paymentIcon, color: AppColors.primary, size: 20),
          ),
          title: const Text(
            'Loyer ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text('Payé le ${_formatDate(payment['date'])}'),
          trailing: Text(
            payment['totalAmount'] != null
                ? '${payment['totalAmount']['value']} ${payment['totalAmount']['currency']}'
                : '${payment['amount'] ?? 0} ${apartment['price']['currency']} ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.primary,
            ),
          ),
          onTap: () {
            // Afficher les détails du paiement
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Détails du paiement '),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(
                        'Montant',
                        payment['totalAmount'] != null
                            ? '${payment['totalAmount']['value']} ${payment['totalAmount']['currency']}'
                            : '${payment['amount'] ?? 0} ${payment['currency'] }'),
                    _buildDetailRow(
                        'Date',
                        _formatDate(
                          payment['date'],
                        ).toString()),
                    _buildDetailRow('Statut', payment['status']),
                    _buildDetailRow(
                        'Méthode',
                        _getPaymentMethodLabel(
                            payment['paymentMethod'] ?? 'mobile_money')),
                    if (payment['reference'] != null)
                      _buildDetailRow('Référence', payment['reference']),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fermer'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String formatDate(String isoDate) {
    try {
      // First try standard ISO format parsing
      DateTime dateTime = DateTime.parse(isoDate).toLocal();
      return DateFormat("dd-MM-yyyy HH:mm").format(dateTime);
    } catch (e) {
      try {
        // If standard parsing fails, try with a specific format
        // This handles the format that might be coming from the API
        final DateFormat inputFormat = DateFormat("yyyy-MM-ddTHH:mm:ssZ");
        DateTime dateTime = inputFormat.parse(isoDate).toLocal();
        return DateFormat("dd-MM-yyyy HH:mm").format(dateTime);
      } catch (e) {
        developer.log("Error formatting date: $e");
        // Return the original string if all parsing attempts fail
        return isoDate;
      }
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingBillsList() {
    return BlocBuilder<UtilityBillCubit, UtilityBillState>(
      builder: (context, state) {
        if (state is UtilityBillLoading) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 3, // Show 3 skeleton cards
            itemBuilder: (context, index) {
              return Card(
                color: Colors.grey.withOpacity(0.1),
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(
                    color: AppColors.buttonColor,
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SkeletonAvatar(
                            style: SkeletonAvatarStyle(
                              width: 80,
                              height: 80,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SkeletonLine(
                                  style: SkeletonLineStyle(
                                    width: 150,
                                    height: 16,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SkeletonLine(
                                  style: SkeletonLineStyle(
                                    width: 100,
                                    height: 12,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.buttonColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SkeletonLine(
                              style: SkeletonLineStyle(
                                width: 40,
                                height: 10,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SkeletonLine(
                            style: SkeletonLineStyle(
                              width: 120,
                              height: 14,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          SkeletonLine(
                            style: SkeletonLineStyle(
                              width: 80,
                              height: 14,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        } else if (state is UtilityBillError) {
          return Center(child: Text('Erreur: ${state.message}'));
        } else if (state is UtilityBillsLoaded) {
          final bills = state.bills;

          // Filtrer les factures en fonction des services inclus
          List<Map<String, dynamic>> pendingBills = [];

          // Ajouter la facture d'électricité seulement si elle n'est pas incluse
          if (!bills.any((bill) =>
              bill['type'] == 'Électricité' && bill['isPaid'] == true)) {
            pendingBills.add({
              'type': 'Électricité',
              'icon': Icons.bolt,
              'iconColor': Colors.amber,
              'period': 'Février 2025',
              'amount': '85,30 \$',
              'dueDate': '20/03/2025',
            });
          }

          // Ajouter la facture d'eau seulement si elle n'est pas incluse
          if (!bills
              .any((bill) => bill['type'] == 'eau' && bill['isPaid'] == true)) {
            pendingBills.add({
              'type': 'Eau',
              'icon': Icons.water_drop,
              'iconColor': Colors.blue,
              'period': 'Janvier-Février 2025',
              'amount': '42,15 \$',
              'dueDate': '25/03/2025',
            });
          }

          if (pendingBills.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Aucune facture à payer pour le moment.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
            );
          }

          // Afficher les factures en attente
          return ListView.builder(
            itemCount: pendingBills.length,
            itemBuilder: (context, index) {
              final bill = pendingBills[index];
              return ListTile(
                leading: Icon(bill['icon'], color: bill['iconColor']),
                title: Text(bill['type']),
                subtitle: Text(
                    'Montant: ${bill['amount']} - Échéance: ${bill['dueDate']}'),
              );
            },
          );
        }
        return const Center(child: Text('Aucune facture à afficher.'));
      },
    );
  }

  // Widget _buildPendingBillsList() {
  //   // Get the apartment data from the state
  //   final state = context.read<TenantRentbookCubit>().state;
  //   Map<String, dynamic>? apartment;

  //   if (state is TenantRentbookLoaded && state.rentbooks.isNotEmpty) {
  //     apartment = state.rentbooks[0]['apartmentId'];
  //   }

  //   // Check if water and electricity are included in the rent
  //   final bool waterIncluded = apartment != null &&
  //       apartment['features'] != null &&
  //       apartment['features']['water'] == true;

  //   final bool electricityIncluded = apartment != null &&
  //       apartment['features'] != null &&
  //       apartment['features']['electricity'] == true;

  //   // Filtrer les factures en fonction des services inclus
  //   List<Map<String, dynamic>> pendingBills = [];

  //   // Ajouter la facture d'électricité seulement si elle n'est pas incluse
  //   if (!electricityIncluded) {
  //     pendingBills.add({
  //       'type': 'Électricité',
  //       'icon': Icons.bolt,
  //       'iconColor': Colors.amber,
  //       'period': 'Février 2025',
  //       'amount': '85,30 \$',
  //       'dueDate': '20/03/2025',
  //     });
  //   }

  //   // Ajouter la facture d'eau seulement si elle n'est pas incluse
  //   if (!waterIncluded) {
  //     pendingBills.add({
  //       'type': 'Eau',
  //       'icon': Icons.water_drop,
  //       'iconColor': Colors.blue,
  //       'period': 'Janvier-Février 2025',
  //       'amount': '42,15 \$',
  //       'dueDate': '25/03/2025',
  //     });
  //   }

  //   if (pendingBills.isEmpty) {
  //     return const Center(
  //       child: Padding(
  //         padding: EdgeInsets.all(16.0),
  //         child: Text(
  //           'Aucune facture à payer pour le moment.',
  //           style: TextStyle(
  //             fontSize: 16,
  //             color: Colors.grey,
  //           ),
  //         ),
  //       ),
  //     );
  //   }

  //   return ListView.separated(
  //     shrinkWrap: true,
  //     physics: const NeverScrollableScrollPhysics(),
  //     itemCount: pendingBills.length,
  //     separatorBuilder: (context, index) => const SizedBox(height: 8),
  //     itemBuilder: (context, index) {
  //       final bill = pendingBills[index];
  //       return Card(
  //         color: Colors.white,
  //         elevation: 2,
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(12),
  //         ),
  //         child: Padding(
  //           padding: const EdgeInsets.all(16),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Row(
  //                 children: [
  //                   Container(
  //                     padding: const EdgeInsets.all(8),
  //                     decoration: BoxDecoration(
  //                       color: bill['iconColor'].withOpacity(0.1),
  //                       borderRadius: BorderRadius.circular(8),
  //                     ),
  //                     child: Icon(
  //                       bill['icon'],
  //                       color: bill['iconColor'],
  //                     ),
  //                   ),
  //                   const SizedBox(width: 12),
  //                   Column(
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     children: [
  //                       Text(
  //                         bill['type'],
  //                         style: const TextStyle(
  //                           fontWeight: FontWeight.bold,
  //                           fontSize: 16,
  //                         ),
  //                       ),
  //                       Text(
  //                         'Période: ${bill['period']}',
  //                         style: TextStyle(
  //                           color: Colors.grey[600],
  //                           fontSize: 14,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                   const Spacer(),
  //                   Text(
  //                     bill['amount'],
  //                     style: const TextStyle(
  //                       fontWeight: FontWeight.bold,
  //                       fontSize: 18,
  //                       color: AppColors.primary,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //               const SizedBox(height: 16),
  //               Row(
  //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                 children: [
  //                   Text(
  //                     'Échéance: ${bill['dueDate']}',
  //                     style: TextStyle(
  //                       color: Colors.grey[600],
  //                     ),
  //                   ),
  //                   TextButton(
  //                     onPressed: () {
  //                       // Action pour payer la facture
  //                     },
  //                     style: TextButton.styleFrom(
  //                       backgroundColor: AppColors.primary,
  //                       padding: const EdgeInsets.symmetric(
  //                           horizontal: 16, vertical: 8),
  //                       shape: RoundedRectangleBorder(
  //                         borderRadius: BorderRadius.circular(8),
  //                       ),
  //                     ),
  //                     child: const Text(
  //                       'Payer',
  //                       style: TextStyle(
  //                         color: Colors.white,
  //                         fontWeight: FontWeight.bold,
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

  Widget _buildPaidBillsList() {
    // Get the apartment data from the state
    final state = context.read<TenantRentbookCubit>().state;
    Map<String, dynamic>? apartment;

    if (state is TenantRentbookLoaded && state.rentbooks.isNotEmpty) {
      apartment = state.rentbooks[0]['apartmentId'];
    }

    // Check if water and electricity are included in the rent
    final bool waterIncluded = apartment != null &&
        apartment['features'] != null &&
        apartment['features']['water'] == true;

    final bool electricityIncluded = apartment != null &&
        apartment['features'] != null &&
        apartment['features']['electricity'] == true;

    // Filtrer les factures en fonction des services inclus
    List<Map<String, dynamic>> paidBills = [];

    // Ajouter la facture d'électricité seulement si elle n'est pas incluse
    if (!electricityIncluded) {
      paidBills.add({
        'type': 'Électricité',
        'icon': Icons.bolt,
        'iconColor': Colors.amber,
        'period': 'Janvier 2025',
        'amount': '78,45 \$',
        'paidDate': '18/02/2025',
      });
    }

    // Ajouter la facture d'eau seulement si elle n'est pas incluse
    if (!waterIncluded) {
      paidBills.add({
        'type': 'Eau',
        'icon': Icons.water_drop,
        'iconColor': Colors.blue,
        'period': 'Novembre-Décembre 2024',
        'amount': '38,20 \$',
        'paidDate': '25/01/2025',
      });
    }

    if (paidBills.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Aucune facture payée pour le moment.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: paidBills.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final bill = paidBills[index];
        return Card(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: bill['iconColor'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        bill['icon'],
                        color: bill['iconColor'],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bill['type'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Période: ${bill['period']}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      bill['amount'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Payé le: ${bill['paidDate']}',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Payé',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRentPaymentTab() {
    return BlocBuilder<TenantRentbookCubit, TenantRentbookState>(
      builder: (context, state) {
        developer
            .log('État actuel du TenantRentbookCubit: ${state.runtimeType}');

        if (state is TenantRentbookLoading) {
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: 3,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  color: Colors.red.shade50,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.red.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        SkeletonAvatar(
                          style: SkeletonAvatarStyle(
                            width: 24,
                            height: 24,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonLine(
                              style: SkeletonLineStyle(
                                width: 80,
                                height: 16,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Text('Montant: '),
                                SkeletonLine(
                                  style: SkeletonLineStyle(
                                    width: 100,
                                    height: 16,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            SkeletonLine(
                              style: SkeletonLineStyle(
                                width: 120,
                                height: 11,
                                borderRadius: BorderRadius.circular(8),
                              ),
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
        } else if (state is TenantRentbookError) {
          developer.log('Erreur: ${state.message}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Image.asset(
                  'assets/images/no-connect.png',
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                ),
                // Text(
                //   'Erreur: ${state.message}',
                //   style: const TextStyle(color: Colors.red),
                // ),
                Image.asset(
                  'assets/images/no-connect.png',
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadRentbooks,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        } else if (state is TenantRentbookLoaded) {
          developer.log(
              'Données chargées: ${state.rentbooks.length} carnets trouvés');

          if (state.rentbooks.isEmpty) {
            return const Center(
              child: Text('Aucun paiement de loyer trouvé'),
            );
          }

          // Afficher le premier carnet de loyer (généralement un locataire n'en a qu'un)
          final rentbook = widget.rentbookData;
          developer.log('Premier carnet: $rentbook');

          final apartment = widget.rentbookData['apartmentId'];
          final building = apartment['buildingId'];
          final paymentHistory = rentbook['paymentHistory'] ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Prochain paiement'),
                const SizedBox(height: 16),
                _buildNextPaymentCard(
                    rentbook, apartment, building, paymentHistory),
                const SizedBox(height: 16),
                _buildMaintenanceCard(
                    rentbook, apartment, building, paymentHistory),
                const SizedBox(height: 16),
                _buildSectionHeader('Historique des paiements'),
                const SizedBox(height: 16),
                _buildPaymentHistoryList(paymentHistory, apartment),
              ],
            ),
          );
        }

        // État initial ou autre
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Prochain paiement'),
              const SizedBox(height: 16),
              _buildNextPaymentCard(null, null, null, null),
              const SizedBox(height: 24),
              _buildSectionHeader('Historique des paiements'),
              const SizedBox(height: 16),
              _buildPaymentHistoryList(null),
            ],
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:immo/constants.dart';
import 'package:immo/cubit/auth_cubit.dart';
import 'package:immo/cubits/utility_bill/utility_bill_cubit.dart';
import 'package:immo/cubits/utility_bill/utility_bill_state.dart';
import 'package:immo/models/building.dart';
import 'package:intl/intl.dart';

class SelectPageFacture extends StatefulWidget {
  const SelectPageFacture({super.key, required this.building});
  final Building building;

  @override
  State<SelectPageFacture> createState() => _SelectPageFactureState();
}

class _SelectPageFactureState extends State<SelectPageFacture> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Charger les factures au démarrage
    _loadUtilityBills();
  }
  
  void _loadUtilityBills() {
    // Récupérer le token
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthSuccess && authState.token != null) {
      // Charger les factures
      context.read<UtilityBillCubit>().getUtilityBills(
        token: authState.token!,
        buildingId: widget.building.id.toString(), // Corriger le type de buildingId
      );
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
        title: Text(
          widget.building.name,
          style: const TextStyle(
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
              icon: Icon(Icons.receipt_outlined),
              text: 'Répartir une facture',
            ),
            Tab(
              icon: Icon(Icons.list_alt_outlined),
              text: 'Liste des factures',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDistributeInvoiceTab(),
          _buildInvoiceListTab(),
        ],
      ),
    );
  }

  Widget _buildDistributeInvoiceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Nouvelle facture à répartir'),
          const SizedBox(height: 16),
          _buildInvoiceForm(),
        ],
      ),
    );
  }

  Widget _buildInvoiceListTab() {
    return BlocBuilder<UtilityBillCubit, UtilityBillState>(
      builder: (context, state) {
        if (state is UtilityBillLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (state is UtilityBillsLoaded) {
          // Afficher les données brutes en mode debug
          print('Factures récupérées dans la vue: ${state.bills}');
          
          if (state.bills.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_long_outlined, size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucune facture trouvée',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Créez une nouvelle facture en utilisant l\'onglet "Répartir une facture"',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          
          // Séparer les factures en attente et payées
          final pendingBills = state.bills.where((bill) => 
              _getBillStatus(bill) == 'pending').toList();
          final paidBills = state.bills.where((bill) => 
              _getBillStatus(bill) == 'paid').toList();
          
          return RefreshIndicator(
            onRefresh: () async {
              _loadUtilityBills();
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Factures en attente (${pendingBills.length})'),
                  const SizedBox(height: 16),
                  pendingBills.isEmpty 
                      ? _buildEmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: 'Aucune facture en attente',
                          subtitle: 'Les factures en attente de paiement apparaîtront ici',
                        )
                      : _buildBillsList(pendingBills),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Factures payées (${paidBills.length})'),
                  const SizedBox(height: 16),
                  paidBills.isEmpty 
                      ? _buildEmptyState(
                          icon: Icons.check_circle_outline,
                          title: 'Aucune facture payée',
                          subtitle: 'L\'historique des factures payées apparaîtra ici',
                        )
                      : _buildBillsList(paidBills),
                ],
              ),
            ),
          );
        }
        
        if (state is UtilityBillError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Erreur lors du chargement des factures',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.message,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadUtilityBills,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Réessayer', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        }
        
        // État par défaut ou erreur
        return RefreshIndicator(
          onRefresh: () async {
            _loadUtilityBills();
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Factures en attente'),
                const SizedBox(height: 16),
                _buildEmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'Chargement des factures...',
                  subtitle: 'Veuillez patienter',
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('Factures payées'),
                const SizedBox(height: 16),
                _buildEmptyState(
                  icon: Icons.check_circle_outline,
                  title: 'Chargement des factures...',
                  subtitle: 'Veuillez patienter',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // Fonctions utilitaires pour extraire les données des factures de manière sécurisée
  String _getBillStatus(dynamic bill) {
    // Essayer différentes structures possibles
    if (bill is Map) {
      // Structure directe
      if (bill.containsKey('status')) {
        return bill['status']?.toString() ?? 'pending';
      }
      
      // Structure imbriquée
      if (bill.containsKey('data') && bill['data'] is Map && bill['data'].containsKey('status')) {
        return bill['data']['status']?.toString() ?? 'pending';
      }
    }
    
    // Valeur par défaut
    return 'pending';
  }
  
  String _getBillType(dynamic bill) {
    if (bill is Map) {
      // Structure directe
      if (bill.containsKey('type')) {
        return bill['type']?.toString() ?? 'unknown';
      }
      
      // Structure imbriquée
      if (bill.containsKey('data') && bill['data'] is Map && bill['data'].containsKey('type')) {
        return bill['data']['type']?.toString() ?? 'unknown';
      }
    }
    
    return 'unknown';
  }
  
  double _getBillAmount(dynamic bill) {
    if (bill is Map) {
      // Structure directe avec objet amount
      if (bill.containsKey('amount') && bill['amount'] is Map && bill['amount'].containsKey('value')) {
        final value = bill['amount']['value'];
        if (value is num) {
          return value.toDouble();
        }
        return double.tryParse(value.toString()) ?? 0.0;
      }
      
      // Structure directe avec valeur amount
      if (bill.containsKey('amount') && bill['amount'] is num) {
        return bill['amount'].toDouble();
      }
      
      // Structure imbriquée
      if (bill.containsKey('data') && bill['data'] is Map) {
        final data = bill['data'];
        
        // Cas où data contient un objet amount
        if (data.containsKey('amount') && data['amount'] is Map && data['amount'].containsKey('value')) {
          final value = data['amount']['value'];
          if (value is num) {
            return value.toDouble();
          }
          return double.tryParse(value.toString()) ?? 0.0;
        }
        
        // Cas où data contient une valeur amount directe
        if (data.containsKey('amount') && data['amount'] is num) {
          return data['amount'].toDouble();
        }
      }
    }
    
    return 0.0;
  }
  
  String _getBillCurrency(dynamic bill) {
    if (bill is Map) {
      // Structure directe
      if (bill.containsKey('amount') && bill['amount'] is Map && bill['amount'].containsKey('currency')) {
        return bill['amount']['currency']?.toString() ?? 'USD';
      }
      
      // Structure imbriquée
      if (bill.containsKey('data') && bill['data'] is Map) {
        final data = bill['data'];
        if (data.containsKey('amount') && data['amount'] is Map && data['amount'].containsKey('currency')) {
          return data['amount']['currency']?.toString() ?? 'USD';
        }
      }
    }
    
    return 'USD';
  }
  
  DateTime? _getBillCreatedAt(dynamic bill) {
    String? dateStr;
    
    if (bill is Map) {
      // Structure directe
      if (bill.containsKey('createdAt')) {
        dateStr = bill['createdAt']?.toString();
      } else if (bill.containsKey('created_at')) {
        dateStr = bill['created_at']?.toString();
      }
      
      // Structure imbriquée
      if (dateStr == null && bill.containsKey('data') && bill['data'] is Map) {
        final data = bill['data'];
        if (data.containsKey('createdAt')) {
          dateStr = data['createdAt']?.toString();
        } else if (data.containsKey('created_at')) {
          dateStr = data['created_at']?.toString();
        }
      }
    }
    
    if (dateStr != null) {
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        print('Erreur lors du parsing de la date: $e');
      }
    }
    
    return null;
  }
  
  Widget _buildBillsList(List<dynamic> bills) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: bills.length,
      itemBuilder: (context, index) {
        final bill = bills[index];
        // Afficher les données brutes de chaque facture en mode debug
        print('Facture $index: $bill');
        
        final String type = _getBillType(bill);
        final double amount = _getBillAmount(bill);
        final String currency = _getBillCurrency(bill);
        final String status = _getBillStatus(bill);
        final DateTime? createdAt = _getBillCreatedAt(bill);
        
        return Card(
          color: Colors.white,
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getBillTypeColor(type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getBillTypeIcon(type),
                    color: _getBillTypeColor(type),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getBillTypeName(type),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (createdAt != null)
                        Text(
                          'Créée le ${DateFormat('dd/MM/yyyy').format(createdAt)}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$amount $currency',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: status == 'paid' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status == 'paid' ? 'Payée' : 'En attente',
                        style: TextStyle(
                          color: status == 'paid' ? Colors.green : Colors.orange,
                          fontSize: 12,
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
  
  Color _getBillTypeColor(String type) {
    switch (type) {
      case 'eau':
        return Colors.blue;
      case 'electricite':
        return Colors.yellow.shade800;
      default:
        return Colors.grey;
    }
  }
  
  IconData _getBillTypeIcon(String type) {
    switch (type) {
      case 'eau':
        return Icons.water_drop;
      case 'electricite':
        return Icons.electric_bolt;
      default:
        return Icons.receipt;
    }
  }
  
  String _getBillTypeName(String type) {
    switch (type) {
      case 'eau':
        return 'Facture d\'eau';
      case 'electricite':
        return 'Facture d\'électricité';
      default:
        return 'Facture';
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceForm() {
    final List<String> invoiceTypes = ['eau', 'electricite'];
    String selectedInvoiceType = invoiceTypes[0];
    final amountController = TextEditingController();
    final List<String> currencies = ['USD', 'CDF'];
    String selectedCurrency = currencies[0];

    return BlocListener<UtilityBillCubit, UtilityBillState>(
      listener: (context, state) {
        if (state is UtilityBillCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
          // Réinitialiser le formulaire
          amountController.clear();
          
          // Recharger la liste des factures
          _loadUtilityBills();
          
          // Basculer vers l'onglet de liste des factures
          _tabController.animateTo(1);
        } else if (state is UtilityBillError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Building info header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.apartment, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.building.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${widget.building.address.city}, ${widget.building.address.country}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              
              // Invoice type dropdown
              StatefulBuilder(
                builder: (context, setState) {
                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Type de facture',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedInvoiceType,
                    items: invoiceTypes.map((type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type == 'eau' ? 'Eau' : 'Électricité'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedInvoiceType = value;
                        });
                      }
                    },
                  );
                }
              ),
              const SizedBox(height: 16),
              
              // Amount field
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Montant',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              
              // Currency dropdown
              StatefulBuilder(
                builder: (context, setState) {
                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Devise',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedCurrency,
                    items: currencies.map((currency) {
                      return DropdownMenuItem<String>(
                        value: currency,
                        child: Text(currency),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedCurrency = value;
                        });
                      }
                    },
                  );
                }
              ),
              const SizedBox(height: 24),
              
              // Submit button
              BlocBuilder<UtilityBillCubit, UtilityBillState>(
                builder: (context, state) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: state is UtilityBillLoading
                          ? null
                          : () {
                              // Validation
                              if (amountController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Veuillez saisir un montant'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              
                              final double? amount = double.tryParse(amountController.text);
                              if (amount == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Montant invalide'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              
                              // Get token from AuthCubit
                              final authState = context.read<AuthCubit>().state;
                              if (authState is! AuthSuccess || authState.token == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Vous devez être connecté pour créer une facture'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              
                              // Create utility bill
                              context.read<UtilityBillCubit>().createUtilityBill(
                                    token: authState.token!,
                                    buildingId: widget.building.id.toString(), // Corriger le type de buildingId
                                    type: selectedInvoiceType,
                                    value: amount,
                                    currency: selectedCurrency,
                                  );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: state is UtilityBillLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Répartir la facture',
                              style: TextStyle(fontSize: 16, color: Colors.white),
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
}

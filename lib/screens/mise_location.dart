import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:immo/constants.dart';
import 'package:intl/intl.dart';
import '../cubit/auth_cubit.dart';
import '../cubits/user/user_cubit.dart';
import '../cubits/user/user_state.dart';
import '../cubits/rentbook/rentbook_cubit.dart';
import '../cubits/rentbook/rentbook_state.dart';

class LocationPage extends StatefulWidget {
  final String? apartmentId, currency;
  final int amount;
  
  const LocationPage({super.key, this.apartmentId, required this.amount, required this.currency});

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';
  bool _isSearchButtonVisible = true;
  
  // Contrôleurs pour le formulaire de contrat
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _securityDepositController = TextEditingController();
  
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    // Initialiser le cubit
    context.read<UserCubit>();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _securityDepositController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.isEmpty) return;

    // Remplacer le signe + par %2B pour les numéros de téléphone
    String formattedQuery = query.replaceAll('+', '%2B');

    setState(() {
      _searchQuery = formattedQuery;
    });

    final authState = context.read<AuthCubit>().state;
    if (authState is AuthSuccess && authState.token != null) {
      context.read<UserCubit>().searchUsers(
            query: formattedQuery,
            token: authState.token!,
          );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous devez être connecté pour effectuer une recherche'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Nom du locataire...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  // Ne pas déclencher la recherche à chaque frappe
                },
                onSubmitted: _performSearch,
              )
            : const Text('Mettre en location'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintStyle: TextStyle(fontSize: 14),
                        hintText: 'Nom du locataire...',
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onSubmitted: _performSearch,
                      textInputAction: TextInputAction.search,
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                        });
                      },
                    ),
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: ElevatedButton(
                      onPressed: () => _performSearch(_searchController.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      child: const Text('Rechercher'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<UserCubit, UserState>(
              builder: (context, state) {
                if (state is UserLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (state is UserError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 80,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Erreur',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.message,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                } else if (state is UserSearchSuccess) {
                  if (state.users.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun locataire trouvé',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Essayez avec un autre nom ou numéro',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.users.length,
                    itemBuilder: (context, index) {
                      final tenant = state.users[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          title: Text(
                            '${tenant['firstName']} ${tenant['lastName']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.phone, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(tenant['phone'] ?? 'N/A'),
                                ],
                              ),
                            ],
                          ),
                          trailing: ElevatedButton(
                            onPressed: () {
                              // Action pour sélectionner ce locataire
                              _showTenantSelectionDialog(context, tenant);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.buttonColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Ajouter', style: TextStyle(fontSize: 11)),
                          ),
                        ),
                      );
                    },
                  );
                } else {
                  // État initial ou aucune recherche effectuée
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Recherchez un locataire',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Entrez un nom ou un numéro de téléphone',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showTenantSelectionDialog(BuildContext context, Map<String, dynamic> tenant) {
    // Réinitialiser les contrôleurs
    _startDateController.clear();
    _endDateController.clear();
    _securityDepositController.clear();
    _startDate = null;
    _endDate = null;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Confirmer la sélection'),
        content: BlocListener<RentbookCubit, RentbookState>(
          listener: (context, state) {
            if (state is RentbookCreated) {
              // Navigator.pop(context);
              Navigator.pushReplacementNamed(context, AppRoutes.main);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${tenant['firstName']} ${tenant['lastName']} a été ajouté comme locataire'),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state is RentbookError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erreur: ${state.message}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Voulez-vous sélectionner ${tenant['firstName']} ${tenant['lastName']} comme locataire pour cet appartement?'),
                const SizedBox(height: 16),
                const Text('Détails du contrat:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildDatePickerField(
                  label: 'Date de début (obligatoire)',
                  controller: _startDateController,
                  onTap: () => _selectDate(context, isStartDate: true),
                ),
                _buildDatePickerField(
                  label: 'Date de fin (optionnel)',
                  controller: _endDateController,
                  onTap: () => _selectDate(context, isStartDate: false),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    
                    borderRadius: BorderRadius.circular(10),
                      color: Colors.grey[200],
                      border: Border.all(color: AppColors.primary),
                    
                  ),
                  child:Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Montant du loyer : ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[500])),
                      Text(widget.amount.toString()+" ${widget.currency}", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[500])),
                      
                    ],
                  )
                ),
                // _buildContractDetailsField(
                //   label: 'Montant du loyer (USD)',
                //   hint: 'Ex: 500',
                //   controller: _monthlyRentController,
                //   keyboardType: TextInputType.number,
                // ),
                _buildContractDetailsField(
                  label: 'Caution (${widget.currency})',
                  hint: 'Ex: 1000',
                  controller: _securityDepositController,
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          BlocBuilder<RentbookCubit, RentbookState>(
            builder: (context, state) {
              return ElevatedButton(
                onPressed: state is RentbookLoading 
                    ? null 
                    : () => _createRentbook(context, tenant),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonColor,
                ),
                child: state is RentbookLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Valider', style: TextStyle(color: Colors.white, fontSize: 12)),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContractDetailsField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }

  Widget _buildDatePickerField({
    String? label,
    TextEditingController? controller,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextField(
        controller: controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        onTap: onTap,
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, {required bool isStartDate}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          _startDateController.text = DateFormat('yyyy-MM-dd').format(picked);
        } else {
          _endDate = picked;
          _endDateController.text = DateFormat('yyyy-MM-dd').format(picked);
        }
      });
    }
  }

  void _createRentbook(BuildContext context, Map<String, dynamic> tenant) {
    // Validation des champs
    if (_startDate == null) {
      _showValidationError('Veuillez sélectionner une date de début');
      return;
    }
    
    if (_securityDepositController.text.isEmpty) {
      _showValidationError('Veuillez entrer le montant de la caution');
      return;
    }
    
    // Si la date de fin est spécifiée, vérifier qu'elle est après la date de début
    if (_endDate != null && _endDate!.isBefore(_startDate!)) {
      _showValidationError('La date de fin doit être après la date de début');
      return;
    }
    
    if (widget.apartmentId == null) {
      _showValidationError('ID d\'appartement non disponible');
      return;
    }
    
    // Récupérer le token d'authentification
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthSuccess && authState.token != null) {
      // Créer le carnet de loyer
      context.read<RentbookCubit>().createRentbook(
        apartmentId: widget.apartmentId!,
        tenantId: tenant['_id'],
        leaseStartDate: _startDate!,
        leaseEndDate: _endDate ?? _startDate!.add(const Duration(days: 365)), // Par défaut, bail d'un an
        monthlyRent: double.parse(widget.amount.toString()),
        securityDeposit: double.parse(_securityDepositController.text),
        token: authState.token!,
      );
    } else {
      _showValidationError('Vous devez être connecté pour créer un carnet de loyer');
    }
  }
  
  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
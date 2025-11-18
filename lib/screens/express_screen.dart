import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:country_picker/country_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import '../cubits/express/express_cubit.dart';
import '../cubits/express/express_state.dart';
import '../cubit/auth_cubit.dart';
import '../constants.dart';
import '../services/express_service.dart';
import '../widgets/app_logo.dart';

class ExpressScreen extends StatefulWidget {
  const ExpressScreen({super.key});

  @override
  State<ExpressScreen> createState() => _ExpressScreenState();
}

class _ExpressScreenState extends State<ExpressScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _packageValueController = TextEditingController();
  final _packageDescriptionController = TextEditingController();
  final _pickupAddressController = TextEditingController();
  final _deliveryAddressController = TextEditingController();

  // Pour la recherche de clients
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredClients = [];
  List<Map<String, dynamic>> _allClients = [];
  
  // Pour le sélecteur de pays
  Country _selectedCountry = Country(
    phoneCode: "243",
    countryCode: "CD",
    e164Sc: 0,
    geographic: true,
    level: 1,
    name: "DR Congo",
    example: "DR Congo",
    displayName: "DR Congo",
    displayNameNoCountryCode: "CD",
    e164Key: "",
  );

  bool _isNewClient = true;
  Map<String, dynamic>? _selectedClient;
  bool _newClientCreated = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    print('🚀 ExpressScreen initState - Début du chargement des clients');
    _loadVendeurClients();
  }

  void _loadVendeurClients() async {
    print('🔍 _loadVendeurClients() - Début de la méthode');
    try {
      // Essayer d'abord depuis AuthCubit
      final authState = context.read<AuthCubit>().state;
      print('📱 État AuthCubit: ${authState.runtimeType}');
      
      String? vendeurId;
      
      if (authState is AuthSuccess && authState.user != null) {
        vendeurId = authState.user!['id']?.toString();
        print('📱 ID vendeur depuis AuthCubit: $vendeurId');
        print('📱 Données utilisateur complètes: ${authState.user}');
      } else {
        print('⚠️ AuthCubit non disponible, tentative depuis SharedPreferences');
        // Si pas dans AuthCubit, essayer depuis SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final userDataStr = prefs.getString('user_data');
        print('📱 User data depuis SharedPreferences: $userDataStr');
        
        if (userDataStr != null) {
          try {
            final userData = jsonDecode(userDataStr);
            vendeurId = userData['id']?.toString();
            print('📱 ID vendeur depuis SharedPreferences: $vendeurId');
            print('📱 Données utilisateur complètes: $userData');
          } catch (e) {
            print('❌ Erreur parsing user data: $e');
          }
        } else {
          print('❌ Aucune donnée utilisateur trouvée dans SharedPreferences');
        }
      }

      if (vendeurId != null && vendeurId.isNotEmpty) {
        print('✅ Chargement des clients pour le vendeur: $vendeurId');
        context.read<ExpressCubit>().loadClientsByVendeur(vendeurId);
        // Charger aussi les commandes express du vendeur
        context.read<ExpressCubit>().loadExpressOrdersByVendeur(vendeurId);
      } else {
        print('⚠️ Aucun ID vendeur trouvé, chargement de tous les clients');
        context.read<ExpressCubit>().loadClients();
        context.read<ExpressCubit>().loadExpressOrders();
      }
    } catch (e) {
      print('❌ Erreur lors du chargement des clients: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      context.read<ExpressCubit>().loadClients();
      context.read<ExpressCubit>().loadExpressOrders();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _packageValueController.dispose();
    _packageDescriptionController.dispose();
    _pickupAddressController.dispose();
    _deliveryAddressController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showClientSelectionDialog(List<Map<String, dynamic>> clients) {
    // Initialiser les clients filtrés
    _filteredClients = List.from(clients);
    
    // Si aucun client n'est chargé, essayer de recharger
    if (clients.isEmpty) {
      print('📋 Aucun client trouvé, tentative de rechargement...');
      _loadVendeurClients();
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.people, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            const Text('Sélectionner un client', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              // Barre de recherche
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterClients,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un client...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primary, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              
              // Liste des clients
              Expanded(
                child: _filteredClients.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isEmpty 
                                  ? 'Aucun client trouvé'
                                  : 'Aucun client correspondant à "${_searchController.text}"',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'Créez d\'abord un nouveau client'
                                  : 'Essayez avec d\'autres termes',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                            if (_searchController.text.isEmpty) ...[
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  setState(() {
                                    _isNewClient = true;
                                  });
                                },
                                icon: const Icon(Icons.person_add),
                                label: const Text('Créer un nouveau client'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredClients.length,
                        itemBuilder: (context, index) {
                          final client = _filteredClients[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primary.withOpacity(0.1),
                                child: Text(
                                  client['firstName'][0].toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                '${client['firstName']} ${client['lastName']}',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                client['phone'],
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              onTap: () {
                                setState(() {
                                  _selectedClient = client;
                                  _firstNameController.text = client['firstName'];
                                  _lastNameController.text = client['lastName'];
                                  _phoneController.text = client['phone'].replaceAll(RegExp(r'^\+\d+'), '');
                                  _addressController.text = client['address'] ?? '';
                                  _newClientCreated = false;
                                });
                                Navigator.pop(context);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              Navigator.pop(context);
            },
            child: Text(
              'Annuler',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  void _createExpressOrder() async {
    if (!_formKey.currentState!.validate()) return;

    // Récupérer l'ID utilisateur depuis AuthCubit ou SharedPreferences
    String? userId;
    final authState = context.read<AuthCubit>().state;
    
    if (authState is AuthSuccess && authState.user != null) {
      userId = authState.user!['id']?.toString();
      print('📱 ID utilisateur depuis AuthCubit: $userId');
    } else {
      // Si pas dans AuthCubit, essayer depuis SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userDataStr = prefs.getString('user_data');
      
      if (userDataStr != null) {
        try {
          final userData = jsonDecode(userDataStr);
          userId = userData['id']?.toString();
          print('📱 ID utilisateur depuis SharedPreferences: $userId');
        } catch (e) {
          print('❌ Erreur parsing user data: $e');
        }
      }
    }

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez vous connecter'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validation supplémentaire
    if (_packageValueController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La valeur du colis est obligatoire'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_firstNameController.text.trim().isEmpty || _lastNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Les informations du client sont obligatoires'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final orderData = {
      'clientId': _selectedClient?['id'] ?? '',
      'clientName': '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
      'clientPhone': _selectedClient?['phone'] ?? '+${_selectedCountry.phoneCode}${_phoneController.text.trim()}',
      'packageValue': _packageValueController.text.trim(),
      'packageDescription': _packageDescriptionController.text.trim(),
      'pickupAddress': _pickupAddressController.text.trim(),
      'deliveryAddress': _deliveryAddressController.text.trim(),
      'createdBy': userId,
    };

    try {
      print('📦 Création de commande express avec les données: $orderData');
      context.read<ExpressCubit>().createExpressOrder(orderData);
    } catch (e) {
      print('❌ Erreur lors de la création de la commande: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _filterClients(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredClients = List.from(_allClients);
      } else {
        _filteredClients = _allClients.where((client) {
          final firstName = client['firstName']?.toString().toLowerCase() ?? '';
          final lastName = client['lastName']?.toString().toLowerCase() ?? '';
          final phone = client['phone']?.toString().toLowerCase() ?? '';
          final searchQuery = query.toLowerCase();
          
          return firstName.contains(searchQuery) ||
                 lastName.contains(searchQuery) ||
                 phone.contains(searchQuery) ||
                 '${firstName} ${lastName}'.contains(searchQuery);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBarWithLogo(
        title: 'Commande Express',
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.refresh, size: 18, color: AppColors.primary),
            ),
            onPressed: () {
              print('🔄 Bouton refresh pressé');
              _loadVendeurClients();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // TabBar
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[600],
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 10,
              ),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(
                  icon: Icon(Icons.add_circle_outline, size: 20),
                  text: 'Nouvelle commande',
                ),
                Tab(
                  icon: Icon(Icons.list_alt, size: 20),
                  text: 'Mes commandes',
                ),
              ],
            ),
          ),
          
          // TabBarView
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Premier onglet: Nouvelle commande
                _buildNewOrderTab(),
                
                // Deuxième onglet: Mes commandes
                _buildOrdersListTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 0 && _isNewClient
          ? Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: () async {
                  print('🔄 FloatingActionButton pressé - Création de client');
                  
                  if (_formKey.currentState!.validate()) {
                    print('✅ Validation du formulaire réussie');
                    
                    // Récupérer l'ID utilisateur depuis AuthCubit ou SharedPreferences
                    String? userId;
                    final authState = context.read<AuthCubit>().state;
                    
                    print('📱 État AuthCubit: ${authState.runtimeType}');
                    
                    if (authState is AuthSuccess && authState.user != null) {
                      userId = authState.user!['id']?.toString();
                      print('📱 ID utilisateur depuis AuthCubit: $userId');
                      print('📱 Données utilisateur: ${authState.user}');
                    } else {
                      print('⚠️ AuthCubit non disponible, tentative depuis SharedPreferences');
                      // Si pas dans AuthCubit, essayer depuis SharedPreferences
                      final prefs = await SharedPreferences.getInstance();
                      final userDataStr = prefs.getString('user_data');
                      print('📱 User data depuis SharedPreferences: $userDataStr');
                      
                      if (userDataStr != null) {
                        try {
                          final userData = jsonDecode(userDataStr);
                          userId = userData['id']?.toString();
                          print('📱 ID utilisateur depuis SharedPreferences: $userId');
                          print('📱 Données utilisateur: $userData');
                        } catch (e) {
                          print('❌ Erreur parsing user data: $e');
                        }
                      } else {
                        print('❌ Aucune donnée utilisateur trouvée dans SharedPreferences');
                      }
                    }

                    if (userId == null || userId.isEmpty) {
                      print('❌ ID utilisateur non trouvé');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Veuillez vous connecter'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    print('📝 Préparation des données client...');
                    print('📝 Prénom: ${_firstNameController.text.trim()}');
                    print('📝 Nom: ${_lastNameController.text.trim()}');
                    print('📝 Téléphone: ${_phoneController.text.trim()}');
                    print('📝 Code pays: ${_selectedCountry.phoneCode}');
                    print('📝 Adresse: ${_addressController.text.trim()}');

                    // Vérifier que les données ne sont pas vides
                    if (_firstNameController.text.trim().isEmpty ||
                        _lastNameController.text.trim().isEmpty ||
                        _phoneController.text.trim().isEmpty) {
                      print('❌ Données manquantes dans le formulaire');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Veuillez remplir tous les champs obligatoires'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final clientData = {
                      'firstName': _firstNameController.text.trim(),
                      'lastName': _lastNameController.text.trim(),
                      'phone': '+${_selectedCountry.phoneCode}${_phoneController.text.trim()}',
                      'email': '', // Champ supprimé mais gardé pour compatibilité
                      'address': _addressController.text.trim(),
                      'createdBy': userId,
                    };

                    print('👤 Création de client avec les données: $clientData');
                    
                    try {
                      // Utiliser directement Firebase comme dans le test qui fonctionne
                      final firestore = FirebaseFirestore.instance;
                      
                      final dataToSave = {
                        ...clientData,
                        'vendeurId': clientData['createdBy'], // S'assurer que vendeurId est défini
                        'createdAt': FieldValue.serverTimestamp(),
                      };
                      
                      print('📝 Données finales à sauvegarder: $dataToSave');
                      
                      final docRef = await firestore.collection('clients').add(dataToSave);
                      print('✅ Client créé avec succès, ID: ${docRef.id}');
                      
                      // Vérifier que le client a été créé
                      final createdDoc = await docRef.get();
                      if (createdDoc.exists) {
                        print('✅ Document confirmé dans Firestore');
                        print('✅ Données sauvegardées: ${createdDoc.data()}');
                        
                        // Marquer le client comme créé et activer le formulaire de commande
                        setState(() {
                          _newClientCreated = true;
                          _selectedClient = {
                            'id': docRef.id,
                            'firstName': clientData['firstName'],
                            'lastName': clientData['lastName'],
                            'phone': clientData['phone'],
                            'address': clientData['address'],
                          };
                        });
                      } else {
                        print('❌ Document non trouvé après création');
                      }
                      
                      // Afficher le message de succès
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Client ${clientData['firstName']} ${clientData['lastName']} créé avec succès!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      
                      // Vider le formulaire
                      _firstNameController.clear();
                      _lastNameController.clear();
                      _phoneController.clear();
                      _addressController.clear();
                      
                      // Recharger les clients
                      _loadVendeurClients();
                      
                    } catch (e) {
                      print('❌ Erreur lors de la création du client: $e');
                      print('❌ Stack trace: ${StackTrace.current}');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } else {
                    print('❌ Validation du formulaire échouée');
                  }
                },
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: const Icon(Icons.person_add, color: Colors.white),
              ),
            )
          : null,
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.primary : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isSelected ? AppColors.primary.withOpacity(0.8) : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[300]!),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  void _clearClientFields() {
    _firstNameController.clear();
    _lastNameController.clear();
    _phoneController.clear();
    _addressController.clear();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'in_progress':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'En attente';
      case 'accepted':
        return 'Acceptée';
      case 'in_progress':
        return 'En cours';
      case 'delivered':
        return 'Livrée';
      case 'cancelled':
        return 'Annulée';
      default:
        return status;
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      } else if (timestamp is String) {
        final date = DateTime.parse(timestamp);
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  void _showCallOptionsDialog(String clientPhone, String clientName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.phone, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Contacter le client',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Choisissez comment contacter $clientName',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Option Appel normal
                InkWell(
                  onTap: () async {
                    print(clientPhone);
                    Navigator.pop(context);
                    final phoneNumber = clientPhone.startsWith('+') ? clientPhone : '+$clientPhone';
                    final uri = Uri.parse('tel:$phoneNumber');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Impossible d\'appeler $phoneNumber'),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.phone, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Appel normal',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Appeler $clientPhone',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Option WhatsApp
                InkWell(
                  onTap: () async {
                    Navigator.pop(context);
                    String phone = clientPhone.replaceAll(RegExp(r'[^0-9+]'), '');
                    if (!phone.startsWith('+')) {
                      phone = '+$phone';
                    }
                    final whatsappUrl = Uri.parse('https://wa.me/${phone.replaceAll('+', '')}');
                    if (await canLaunchUrl(whatsappUrl)) {
                      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Impossible d\'ouvrir WhatsApp pour $phone'),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFF25D366).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Color(0xFF25D366).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Color(0xFF25D366),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.chat, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'WhatsApp',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Ouvrir WhatsApp',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Bouton Annuler
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Annuler',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNewOrderTab() {
    return BlocConsumer<ExpressCubit, ExpressState>(
      listener: (context, state) {
        print('🎯 ExpressScreen - État reçu: ${state.runtimeType}');
        
        if (state is ClientCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Client créé avec succès!'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Vider le formulaire
          _firstNameController.clear();
          _lastNameController.clear();
          _phoneController.clear();
          _addressController.clear();
          
          // Recharger les clients
          _loadVendeurClients();
        } else if (state is ExpressOrderCreated) {
          print('✅ Commande express créée avec succès, ID: ${state.orderId}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.local_shipping, color: Colors.white),
                  const SizedBox(width: 12),
                  const Text('Commande envoyée aux livreurs'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          // Recharger les commandes après création
          _loadVendeurClients();
        } else if (state is ExpressError) {
          print('❌ Erreur Express: ${state.message}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(state.message),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        } else if (state is ClientsLoaded) {
          print('📋 Clients chargés: ${state.clients.length} clients');
          _allClients = state.clients;
          _filteredClients = state.clients;
          
          // Si on est en mode "Client récurrent" et qu'aucun client n'est sélectionné, 
          // afficher automatiquement le dialogue de sélection
          if (!_isNewClient && _selectedClient == null && state.clients.isNotEmpty) {
            // Petit délai pour éviter les problèmes de contexte
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) {
                _showClientSelectionDialog(state.clients);
              }
            });
          }
        } else if (state is ExpressLoading) {
          print('⏳ Chargement en cours...');
        }
      },
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Debug info (temporaire)
                if (state is ExpressLoading)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const CircularProgressIndicator(color: Colors.blue),
                        const SizedBox(width: 12),
                        const Text(
                          'Chargement des clients...',
                          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                
                if (state is ExpressError)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Erreur: ${state.message}',
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Header avec gradient
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.flash_on,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Livraison Express',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Livraison rapide et sécurisée',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Options de client
                _buildSectionCard(
                  title: 'Type de client',
                  icon: Icons.person_outline,
                  child: Column(
                    children: [
                      _buildOptionCard(
                        title: 'Nouveau client',
                        subtitle: 'Créer un nouveau client',
                        icon: Icons.person_add,
                        isSelected: _isNewClient,
                        onTap: () {
                          setState(() {
                            _isNewClient = true;
                            _selectedClient = null;
                            _newClientCreated = false;
                            _clearClientFields();
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildOptionCard(
                        title: 'Client récurrent',
                        subtitle: 'Sélectionner un client existant',
                        icon: Icons.people,
                        isSelected: !_isNewClient,
                        onTap: () {
                          setState(() {
                            _isNewClient = false;
                            _newClientCreated = false;
                            _clearClientFields();
                          });
                          // Afficher le dialogue même si les clients ne sont pas encore chargés
                          _showClientSelectionDialog(_allClients);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Informations client
                if (_isNewClient) ...[
                  _buildSectionCard(
                    title: 'Informations du client',
                    icon: Icons.person,
                    child: Column(
                      children: [
                        // Prénom seulement en haut
                                       
                        
                        // Nom en bas
                        _buildTextField(
                          controller: _lastNameController,
                          label: 'Nom',
                          icon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Le nom est requis';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _firstNameController,
                          label: 'Prénom',
                          icon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Le prénom est requis';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Téléphone avec sélecteur de pays
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Le téléphone est requis';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: 'Téléphone',
                            prefixIcon: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              child: InkWell(
                                onTap: () {
                                  showCountryPicker(
                                    context: context,
                                    showPhoneCode: true,
                                    favorite: [
                                      'CD',
                                      'RW',
                                      'BI',
                                      'UG',
                                      'KE',
                                      'TZ'
                                    ],
                                    countryListTheme: CountryListThemeData(
                                      borderRadius: BorderRadius.circular(12),
                                      inputDecoration: InputDecoration(
                                        labelText: 'Rechercher un pays',
                                        prefixIcon: const Icon(Icons.search),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                    onSelect: (Country country) {
                                      setState(() {
                                        _selectedCountry = country;
                                      });
                                    },
                                  );
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _selectedCountry.flagEmoji,
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '+${_selectedCountry.phoneCode}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const Icon(Icons.arrow_drop_down),
                                  ],
                                ),
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.primary, width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.red[300]!),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.red, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Adresse
                        _buildTextField(
                          controller: _addressController,
                          label: 'Adresse',
                          icon: Icons.location_on,
                          maxLines: 2,
                        ),
         
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ] else ...[
                  if (_selectedClient != null)
                    _buildSectionCard(
                      title: 'Client sélectionné',
                      icon: Icons.check_circle,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.green.withOpacity(0.2),
                              child: Icon(Icons.person, color: Colors.green),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_selectedClient!['firstName']} ${_selectedClient!['lastName']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    _selectedClient!['phone'],
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.edit, color: AppColors.primary),
                              onPressed: () {
                                if (state is ClientsLoaded) {
                                  _showClientSelectionDialog(state.clients);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                ],

                // Informations du colis - seulement si un client est sélectionné
                if (_selectedClient != null || _newClientCreated) ...[
                  _buildSectionCard(
                    title: 'Informations du colis',
                    icon: Icons.inventory,
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _packageValueController,
                          label: 'Valeur du colis',
                          icon: Icons.attach_money,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'La valeur du colis est requise';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _packageDescriptionController,
                          label: 'Description du colis',
                          icon: Icons.description,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _pickupAddressController,
                          label: 'Adresse de ramassage',
                          icon: Icons.location_on,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _deliveryAddressController,
                          label: 'Adresse de livraison',
                          icon: Icons.location_on,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Bouton Rapidos - seulement si un client est sélectionné
                  Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.8),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: state is ExpressLoading ? null : _createExpressOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: state is ExpressLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.flash_on,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Rapidos',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ] else ...[
                  // Message d'instruction si aucun client n'est sélectionné
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 48,
                          color: Colors.blue[600],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Sélectionnez ou créez un client',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Vous devez d\'abord sélectionner un client récurrent ou créer un nouveau client pour continuer.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrdersListTab() {
    return BlocConsumer<ExpressCubit, ExpressState>(
      listener: (context, state) {
        if (state is ExpressOrdersLoaded) {
          print('📦 Commandes express chargées: ${state.orders.length} commandes');
        }
      },
      builder: (context, state) {
        if (state is ExpressLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (state is ExpressError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Erreur: ${state.message}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.red[600],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => _loadVendeurClients(),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        List<Map<String, dynamic>> orders = [];
        if (state is ExpressOrdersLoaded) {
          orders = state.orders;
        }

        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Aucune commande express',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vous n\'avez pas encore créé de commandes express',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    _tabController.animateTo(0);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Créer une commande'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            _loadVendeurClients();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final status = order['status']?.toString() ?? 'pending';
              final createdAt = order['createdAt'];
              final clientName = order['clientName']?.toString() ?? 'Client inconnu';
              final clientPhone = order['clientPhone']?.toString() ?? '';
              final packageValue = order['packageValue']?.toString() ?? '0';
              final pickupAddress = order['pickupAddress']?.toString() ?? 'Non spécifié';
              final deliveryAddress = order['deliveryAddress']?.toString() ?? 'Non spécifié';

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header avec statut
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.local_shipping,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Commande Express',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: _getStatusColor(status),
                                  ),
                                ),
                                Text(
                                  _formatDate(createdAt),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _getStatusText(status),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Contenu de la commande
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Client
                          Row(
                            children: [
                              Icon(Icons.person, color: Colors.grey[600], size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Client: $clientName',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              if (clientPhone.isNotEmpty)
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.phone, color: Colors.white, size: 18),
                                    onPressed: () => _showCallOptionsDialog(clientPhone, clientName),
                                    padding: const EdgeInsets.all(8),
                                    constraints: const BoxConstraints(
                                      minWidth: 36,
                                      minHeight: 36,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          
                          // Valeur du colis
                          Row(
                            children: [
                              Icon(Icons.attach_money, color: Colors.grey[600], size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'Valeur: $packageValue FC',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // Adresses
                          if (pickupAddress.isNotEmpty && pickupAddress != 'Non spécifié') ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.location_on, color: Colors.grey[600], size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Ramassage:',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        pickupAddress,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                          
                          if (deliveryAddress.isNotEmpty && deliveryAddress != 'Non spécifié') ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.location_on, color: Colors.grey[600], size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Livraison:',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        deliveryAddress,
                                        style: const TextStyle(fontSize: 14),
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
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
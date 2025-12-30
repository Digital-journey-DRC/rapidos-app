import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:immo/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:immo/widgets/cart_badge.dart';
import 'package:immo/widgets/app_logo.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:immo/cubit/cart_cubit.dart';
import 'package:immo/cubit/order_cubit.dart';
import 'package:immo/cubit/auth_cubit.dart';
import 'package:immo/services/event_service.dart';
import 'package:immo/widgets/ecommerce_loading.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:immo/services/payment_method_service.dart';
import 'payment_method_selection_screen.dart';
import 'address_selection_screen.dart';
import '../order_screen.dart';

class CartScreen extends StatefulWidget {
  final bool backNavigaton;
  const CartScreen({Key? key, this.backNavigaton = true}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Map<String, dynamic>> savedAddresses = [];
  final ValueNotifier<bool> useNewAddress = ValueNotifier<bool>(false);

  // Variables pour la recherche d'adresse
  final TextEditingController _searchAddressController =
      TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Map<String, dynamic>> _searchResults = [];
  Timer? _searchDebounceTimer;
  bool _isSearching = false;
  bool _isGettingCurrentLocation = false;

  // Variable pour suivre l'adresse sélectionnée depuis Google
  Map<String, dynamic>? _selectedGoogleAddress;

  // Variables pour stocker les données extraites du geocoding
  String _extractedVille = '';
  String _extractedCommune = '';
  String _extractedQuartier = '';
  String _extractedAvenue = '';

  // Variable pour stocker les données extraites de manière persistante
  Map<String, String> _extractedAddressData = {};

  // Variable pour stocker le moyen de paiement sélectionné
  Map<String, dynamic>? _selectedPaymentMethod;

  // Contrôleurs pour les champs d'adresse
  final TextEditingController _villeController = TextEditingController();
  final TextEditingController _communeController = TextEditingController();
  final TextEditingController _quartierController = TextEditingController();
  final TextEditingController _avenueController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _paysController =
      TextEditingController(text: 'RDC');

  @override
  void initState() {
    super.initState();
    _loadSavedAddresses();
  }

  Future<void> _saveCurrentLocation(double longitude, double latitude) async {
    try {
      // Vérifier et demander les permissions de localisation
      // LocationPermission permission = await Geolocator.checkPermission();
      // if (permission == LocationPermission.denied) {
      //   permission = await Geolocator.requestPermission();
      //   if (permission == LocationPermission.denied) {
      //     return;
      //   }
      // }

      // if (permission == LocationPermission.deniedForever) {
      //   return;
      // }

      // Obtenir la position actuelle
      // Position position = await Geolocator.getCurrentPosition(
      //   desiredAccuracy: LocationAccuracy.high,
      // );

      // Récupérer l'utilisateur connecté
      final authState = context.read<AuthCubit>().state;
      if (authState is AuthSuccess && authState.user != null) {
        final user = authState.user!;
        final userId = user['id']?.toString() ?? '';
        final userRole = user['role']?.toString() ?? '';
        final phone = user['phone']?.toString() ?? '';

        // Vérifier si un enregistrement existe déjà pour cet utilisateur
        final locationQuery = await FirebaseFirestore.instance
            .collection('locations')
            .where('userId', isEqualTo: userId)
            .get();

        if (locationQuery.docs.isNotEmpty) {
          // Mettre à jour l'enregistrement existant
          await locationQuery.docs.first.reference.update({
            'longitude': longitude,
            'latitude': latitude,
            'timestamp': FieldValue.serverTimestamp(),
          });
          print('✅ Position mise à jour avec succès');
        } else {
          // Créer un nouvel enregistrement
          await FirebaseFirestore.instance.collection('locations').add({
            'userId': userId,
            'role': userRole,
            'longitude': longitude,
            'latitude': latitude,
            'phone': phone,
            'timestamp': FieldValue.serverTimestamp(),
          });
          print('✅ Nouvelle position enregistrée avec succès');
        }
      }
    } catch (e) {
      print('❌ Erreur lors de la récupération de la position: $e');
    }
  }

  @override
  void dispose() {
    useNewAddress.dispose();
    _searchAddressController.dispose();
    _searchFocusNode.dispose();
    _villeController.dispose();
    _communeController.dispose();
    _quartierController.dispose();
    _avenueController.dispose();
    _numeroController.dispose();
    _paysController.dispose();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSavedAddresses() async {
    setState(() {
      useNewAddress.value = false;
    });
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthSuccess && authState.user != null) {
      final user = authState.user!;
      final userId = user['id']?.toString() ?? '';

      print(
          'Chargement des adresses pour l\'utilisateur: $userId'); // Debug log

      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('delivery_addresses')
            .where('userId', isEqualTo: userId)
            .get();

        print(
            'Nombre d\'adresses trouvées: ${snapshot.docs.length}'); // Debug log

        if (snapshot.docs.isNotEmpty) {
          // Trier côté client par timestamp décroissant
          final addresses = snapshot.docs.toList()
            ..sort((a, b) {
              final aData = a.data();
              final bData = b.data();
              final aTime = aData['timestamp'] as Timestamp?;
              final bTime = bData['timestamp'] as Timestamp?;
              if (aTime == null && bTime == null) return 0;
              if (aTime == null) return 1;
              if (bTime == null) return -1;
              return bTime.compareTo(aTime); // Décroissant
            });
          
          setState(() {
            savedAddresses = addresses.map((doc) => doc.data()).toList();
          });
          print('Adresses chargées: $savedAddresses'); // Debug log
        } else {
          print(
              'Aucune adresse trouvée pour l\'utilisateur $userId'); // Debug log
        }
      } catch (e) {
        print('Erreur lors du chargement des adresses: $e');
        // En cas d'erreur, essayer sans tri
        try {
          final snapshot = await FirebaseFirestore.instance
              .collection('delivery_addresses')
              .where('userId', isEqualTo: userId)
              .get();
          if (snapshot.docs.isNotEmpty) {
            setState(() {
              savedAddresses = snapshot.docs.map((doc) => doc.data()).toList();
            });
          }
        } catch (e2) {
          print('Erreur lors du chargement des adresses (sans tri): $e2');
        }
      }
    } else {
      print('Utilisateur non connecté ou état invalide'); // Debug log
    }
  }

  void saveCart(
    BuildContext context,
    List<Map<String, dynamic>> cartItems,
    String ville,
    String commune,
    String quartier,
    String avenue,
    String numero,
    String pays,
    double longitude,
    double latitude,
  ) async {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthSuccess && authState.user != null) {
      final user = authState.user!;
      final userId = user['id']?.toString() ?? '';
      final userName =
          '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();

      // Construire l'adresse complète
      final adresse = '$avenue, $numero, $quartier, $commune, $ville, $pays';

      // Enregistrer la commande
      DocumentReference commandeRef =
          await FirebaseFirestore.instance.collection('carts').add({
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'phone': user['phone'] ?? '',
        'items': cartItems,
        'client': userName,
        'adresse': adresse, // ID du vendeur par défaut
        'idClient': userId,
        'ville': ville,
        'commune': commune,
        'quartier': quartier,
        'avenue': avenue,
        'numero': numero,
        'pays': pays,
        'longitude': longitude,
        'latitude': latitude,
        'total': cartItems.fold(
            0.0,
            (sum, item) =>
                sum +
                ((item['price'] ?? 0.0) *
                    (item['quantity'] ??
                        1))), // Calculate total from cart items
      });

      print("✅ Commande enregistrée avec succès: ${commandeRef.id}");
      // Navigator.pop(context);
      // context.read<CartCubit>().clearCart();
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(
      //     content: Text('Commande créée avec succès!'),
      //     backgroundColor: AppColors.success,
      //   ),
      // );
      // context.read<CartCubit>().clearCart();
    } else {
      print("❌ Utilisateur non connecté");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous devez être connecté pour passer une commande'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Liste des villes de la RDC
  static const List<String> villes = [
    'Kinshasa',
    'Lubumbashi',
    'Mbuji-Mayi',
    'Kananga',
    'Kisangani',
    'Bukavu',
    'Goma',
    'Kolwezi',
    'Likasi',
    'Matadi',
    'Kikwit',
    'Tshikapa',
    'Uvira',
    'Bunia',
    'Kalemie',
    'Kindu',
    'Mbandaka',
    'Mbanza-Ngungu',
    'Boma',
    'Kamina',
  ];

  // Liste des communes de Kinshasa
  static const List<String> communesKinshasa = [
    'Bandalungwa',
    'Barumbu',
    'Bumbu',
    'Gombe',
    'Kalamu',
    'Kasa-Vubu',
    'Kimbanseke',
    'Kinshasa',
    'Kintambo',
    'Kisenso',
    'Lemba',
    'Limete',
    'Lingwala',
    'Makala',
    'Maluku',
    'Masina',
    'Matete',
    'Mont Ngafula',
    'Ndjili',
    'Ngaba',
    'Ngaliema',
    'Ngiri-Ngiri',
    'Nsele',
    'Selembao',
  ];

  void _showPaymentMethodSelection(
      BuildContext context, List<Map<String, dynamic>> cartItems) async {
    // Récupérer l'ID du vendeur depuis le premier item du panier
    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Votre panier est vide'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Récupérer l'ID du vendeur (on suppose que tous les items sont du même vendeur)
    final firstItem = cartItems.first;
    final vendeurId = firstItem['idVendeur'];
    
    if (vendeurId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de déterminer le vendeur'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Convertir vendeurId en int
    int? vendeurIdInt;
    if (vendeurId is int) {
      vendeurIdInt = vendeurId;
    } else if (vendeurId is String) {
      vendeurIdInt = int.tryParse(vendeurId);
    } else {
      vendeurIdInt = int.tryParse(vendeurId.toString());
    }

    if (vendeurIdInt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID du vendeur invalide'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

      // Charger les moyens de paiement du vendeur
      try {
        final paymentMethodService = PaymentMethodService();
        final result = await paymentMethodService.getVendeurPaymentMethodsForClient(vendeurIdInt);
      
      if (result['success'] != true || (result['paymentMethods'] as List?)?.isEmpty == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucun moyen de paiement disponible pour ce vendeur'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final paymentMethods = List<Map<String, dynamic>>.from(result['paymentMethods'] ?? []);

      // Afficher l'écran de sélection des moyens de paiement
      final selectedPaymentMethod = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentMethodSelectionScreen(
            vendeurId: vendeurIdInt!,
            paymentMethods: paymentMethods,
            currentPaymentMethod: null,
            orderIds: [], // Pas encore de commandes, liste vide
          ),
        ),
      );

      // Si un moyen de paiement a été sélectionné, afficher l'écran d'adresse
      if (selectedPaymentMethod != null && mounted) {
        setState(() {
          _selectedPaymentMethod = selectedPaymentMethod;
        });
        _showAddressBottomSheet(context, cartItems, selectedPaymentMethod);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement des moyens de paiement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddressBottomSheet(
      BuildContext context, List<Map<String, dynamic>> cartItems, Map<String, dynamic> selectedPaymentMethod) {
    // Réinitialiser la sélection d'adresse
    setState(() {
      _selectedGoogleAddress = null;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return BlocConsumer<OrderCubit, OrderState>(
          listener: (context, state) {
            if (state.success) {
              Navigator.pop(context);
              context.read<CartCubit>().clearCart();
              // Rafraîchir les commandes
              context.read<OrderCubit>().fetchOrders();
              // Naviguer vers l'écran des commandes avec filtre sur pending_payment
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OrderScreen(
                    backNavigation: true,
                    initialStatusFilter: 'pending_payment', // Afficher les commandes initialisées
                  ),
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Commande(s) initialisée(s) avec succès!'),
                  backgroundColor: AppColors.success,
                ),
              );
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
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 32,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: DraggableScrollableSheet(
                initialChildSize: 0.9,
                minChildSize: 0.5,
                maxChildSize: 0.95,
                expand: false,
                builder: (context, scrollController) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    controller: scrollController,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const Text(
                          'Adresse de livraison',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        StreamBuilder<QuerySnapshot>(
                          stream: () {
                            final authState = context.read<AuthCubit>().state;
                            final userId = authState is AuthSuccess &&
                                    authState.user != null
                                ? authState.user!['id']?.toString() ?? ''
                                : '';
                            return FirebaseFirestore.instance
                                .collection('delivery_addresses')
                                .where('userId', isEqualTo: userId)
                                .snapshots();
                          }(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Text('Erreur: ${snapshot.error}');
                            }

                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return Column(
                                children: [
                                  Text(
                                    'Aucune adresse enregistrée',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextButton.icon(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _showNewAddressForm(context, cartItems);
                                    },
                                    icon: const Icon(Icons.add_location_alt),
                                    label: const Text(
                                        'Ajouter une nouvelle adresse'),
                                  ),
                                ],
                              );
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Vos adresses enregistrées :',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...snapshot.data!.docs.map((doc) {
                                  final address =
                                      doc.data() as Map<String, dynamic>;
                                  return Card(
                                    color: Colors.white,
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              '${address['avenue']}, ${address['numero']}'),
                                          Text(
                                              '${address['quartier']}, ${address['commune']}'),
                                          Text(
                                              '${address['ville']}, ${address['pays']}'),
                                          const SizedBox(height: 8),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              onPressed: state.isLoading
                                                  ? null
                                                  : () async {
                                                      // Utiliser exactement les champs de la collection delivery_addresses
                                                      final ville =
                                                          address['ville'] ??
                                                              '';
                                                      final commune =
                                                          address['commune'] ??
                                                              '';
                                                      final quartier =
                                                          address['quartier'] ??
                                                              '';
                                                      final avenue =
                                                          address['avenue'] ??
                                                              '';
                                                      final numero =
                                                          address['numero'] ??
                                                              '';
                                                      final pays =
                                                          address['pays'] ?? '';

                                                      print(
                                                          '🔍 Adresse de la collection:');
                                                      print('   Ville: $ville');
                                                      print(
                                                          '   Commune: $commune');
                                                      print(
                                                          '   Quartier: $quartier');
                                                      print(
                                                          '   Avenue: $avenue');
                                                      print(
                                                          '   Numero: $numero');
                                                      print('   Pays: $pays');

                                                      // Obtenir les coordonnées GPS depuis l'adresse
                                                      final latitude = address['latitude']?.toDouble() ?? 0.0;
                                                      final longitude = address['longitude']?.toDouble() ?? 0.0;

                                                      // Si les coordonnées ne sont pas disponibles, les obtenir depuis l'adresse
                                                      double finalLatitude = latitude;
                                                      double finalLongitude = longitude;
                                                      
                                                      if (latitude == 0.0 || longitude == 0.0) {
                                                        try {
                                                          String fullAddress = '$quartier, $commune, $ville, $numero, RDC';
                                                          final coordinates = await getCoordinatesFromGoogle(fullAddress);
                                                          finalLatitude = coordinates['latitude']?.toDouble() ?? 0.0;
                                                          finalLongitude = coordinates['longitude']?.toDouble() ?? 0.0;
                                                        } catch (e) {
                                                          print('Erreur lors de la récupération des coordonnées: $e');
                                                        }
                                                      }

                                                      // Vérifier que les coordonnées sont valides
                                                      if (finalLatitude == 0.0 || finalLongitude == 0.0) {
                                                        if (context.mounted) {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            const SnackBar(
                                                              content: Text('Impossible d\'obtenir les coordonnées GPS. Veuillez réessayer.'),
                                                              backgroundColor: Colors.red,
                                                            ),
                                                          );
                                                        }
                                                        return;
                                                      }

                                                      // Préparer les produits pour l'initialisation (avec quantite au lieu de quantity)
                                                      final productsToSend = cartItems
                                                          .map((item) {
                                                        return {
                                                          "productId": int.parse(
                                                              item['id']
                                                                  .toString()),
                                                          "quantite": item[
                                                              'quantity'] is int 
                                                              ? item['quantity'] 
                                                              : int.tryParse(item['quantity'].toString()) ?? 1,
                                                        };
                                                      }).toList();

                                                      // Préparer l'adresse complète
                                                      final addressToSend = {
                                                        "pays": pays.isNotEmpty ? pays : "RDC",
                                                        "ville": ville.isNotEmpty ? ville : "",
                                                        "commune": commune.isNotEmpty ? commune : "",
                                                        "quartier": quartier.isNotEmpty ? quartier : "",
                                                        "avenue": avenue.isNotEmpty ? avenue : "",
                                                        "numero": numero.isNotEmpty ? numero : "",
                                                        "codePostale": "012",
                                                      };

                                                      // Print du body avant initialisation
                                                      print('═══════════════════════════════════════════════════════');
                                                      print('🛑 BREAKPOINT: Avant initialisation de la commande');
                                                      print('📍 Coordonnées GPS:');
                                                      print('   Latitude: $finalLatitude');
                                                      print('   Longitude: $finalLongitude');
                                                      print('📦 Produits à envoyer:');
                                                      for (var product in productsToSend) {
                                                        print('   - ProductId: ${product['productId']}, Quantite: ${product['quantite']}');
                                                      }
                                                      print('🏠 Adresse:');
                                                      print('   Pays: ${addressToSend['pays']}');
                                                      print('   Ville: ${addressToSend['ville']}');
                                                      print('   Commune: ${addressToSend['commune']}');
                                                      print('   Quartier: ${addressToSend['quartier']}');
                                                      print('   Avenue: ${addressToSend['avenue']}');
                                                      print('   Numero: ${addressToSend['numero']}');
                                                      print('📋 Body JSON qui sera envoyé:');
                                                      print(jsonEncode({
                                                        'products': productsToSend,
                                                        'latitude': finalLatitude,
                                                        'longitude': finalLongitude,
                                                        'address': addressToSend,
                                                      }));
                                                      print('═══════════════════════════════════════════════════════');
                                                      
                                                      // Breakpoint virtuel
                                                      assert(() {
                                                        print('🛑 BREAKPOINT: Cliquez ici pour déboguer avant initialisation');
                                                        return true;
                                                      }());

                                                      // Initialiser la commande avec la nouvelle API multi-vendeurs
                                                      context
                                                          .read<OrderCubit>()
                                                          .initializeOrder(
                                                            products: productsToSend,
                                                            latitude: finalLatitude,
                                                            longitude: finalLongitude,
                                                            address: addressToSend,
                                                          );

                                                      saveCart(
                                                        context,
                                                        cartItems,
                                                        ville,
                                                        commune,
                                                        quartier,
                                                        avenue,
                                                        numero,
                                                        pays,
                                                        finalLongitude,
                                                        finalLatitude,
                                                      );
                                                    },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    AppColors.primary,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                              child: state.isLoading
                                                  ? const EcommerceLoading.inline(color: Colors.white)
                                                  : const Text(
                                                      'UTILISER CETTE ADRESSE',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                                const SizedBox(height: 16),
                                TextButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _showNewAddressForm(context, cartItems);
                                  },
                                  icon: const Icon(Icons.add_location_alt),
                                  label: const Text(
                                      'Ajouter une nouvelle adresse'),
                                ),
                                const SizedBox(height: 50),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  void _showNewAddressForm(
      BuildContext context, List<Map<String, dynamic>> cartItems) {
    final _numeroController = TextEditingController();
    bool saveAddress = false;

    // Variable locale pour suivre l'adresse sélectionnée dans le modal
    Map<String, dynamic>? selectedAddress;

    // Variable pour stocker l'ID de l'adresse sélectionnée
    String? selectedAddressId;

    // Nettoyer le cache des adresses au début
    setState(() {
      _extractedAddressData.clear();
      _extractedVille = '';
      _extractedCommune = '';
      _extractedQuartier = '';
      _extractedAvenue = '';
      _selectedGoogleAddress = null;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return BlocConsumer<OrderCubit, OrderState>(
              listener: (context, state) {
                if (state.success) {
                  // Track purchase events for all products in background
                  final authState = context.read<AuthCubit>().state;
                  if (authState is AuthSuccess && authState.user != null) {
                    final userId = authState.user!['id'];
                    if (userId != null) {
                      final eventService = EventService();
                      for (var item in cartItems) {
                        final productId = item['id'];
                        if (productId != null) {
                          eventService.trackPurchase(
                            productId: productId is int ? productId : int.tryParse(productId.toString()) ?? 0,
                            userId: userId is int ? userId : int.tryParse(userId.toString()) ?? 0,
                          );
                        }
                      }
                    }
                  }
                  
                  Navigator.pop(context);
                  context.read<CartCubit>().clearCart();
                  // Rafraîchir les commandes
                  context.read<OrderCubit>().fetchOrders();
                  // Naviguer vers l'écran des commandes avec filtre sur pending_payment
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OrderScreen(
                        backNavigation: true,
                        initialStatusFilter: 'pending_payment', // Afficher les commandes initialisées
                      ),
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Commande(s) initialisée(s) avec succès!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
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
                return Padding(
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 32,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed: () {
                                // Nettoyer le cache avant de revenir
                                setState(() {
                                  _extractedAddressData.clear();
                                  _extractedVille = '';
                                  _extractedCommune = '';
                                  _extractedQuartier = '';
                                  _extractedAvenue = '';
                                  _selectedGoogleAddress = null;
                                });
                                Navigator.pop(context);
                                _showPaymentMethodSelection(context, cartItems);
                              },
                            ),
                            const Text(
                              'Nouvelle adresse',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: _isGettingCurrentLocation
                                ? null
                                : () async {
                                    setState(() {
                                      _isGettingCurrentLocation = true;
                                    });
                                    
                                    // Désactiver le champ de recherche
                                    _searchAddressController.clear();
                                    _searchResults.clear();
                                    
                                    // Afficher un indicateur de chargement
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Row(
                                          children: [
                                            const EcommerceLoading.inline(),
                                            SizedBox(width: 16),
                                            Text('Récupération de votre position...'),
                                          ],
                                        ),
                                        duration: Duration(seconds: 3),
                                      ),
                                    );

                              try {
                                // Vérifier et demander les permissions de localisation
                                LocationPermission permission =
                                    await Geolocator.checkPermission();
                                if (permission == LocationPermission.denied) {
                                  permission =
                                      await Geolocator.requestPermission();
                                                                  if (permission == LocationPermission.denied) {
                                  setState(() {
                                    _isGettingCurrentLocation = false;
                                  });
                                  
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Permission de localisation refusée'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                }

                                if (permission ==
                                    LocationPermission.deniedForever) {
                                  setState(() {
                                    _isGettingCurrentLocation = false;
                                  });
                                  
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Permission de localisation refusée définitivement'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                // Obtenir la position actuelle
                                Position position =
                                    await Geolocator.getCurrentPosition(
                                  desiredAccuracy: LocationAccuracy.high,
                                );

                                print(
                                    '📍 Position actuelle obtenue: ${position.latitude}, ${position.longitude}');

                                // Récupérer l'adresse depuis les coordonnées
                                final addressData =
                                    await getAddressFromGoogleAPI(
                                  position.latitude,
                                  position.longitude,
                                );

                                print(
                                    '📍 Données d\'adresse extraites: $addressData');

                                // Vérifier que les données ne sont pas vides
                                if (addressData.isEmpty ||
                                    (addressData['ville']?.isEmpty == true &&
                                        addressData['commune']?.isEmpty ==
                                            true &&
                                        addressData['quartier']?.isEmpty ==
                                            true &&
                                        addressData['avenue']?.isEmpty ==
                                            true)) {
                                  setState(() {
                                    _isGettingCurrentLocation = false;
                                  });
                                  
                                  print('⚠️ Aucune donnée d\'adresse extraite');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Impossible d\'extraire l\'adresse depuis votre position actuelle. Veuillez essayer une autre méthode.'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }

                                // Stocker les données extraites dans les variables d'état
                                setState(() {
                                  _extractedVille = addressData['ville'] ?? '';
                                  _extractedCommune =
                                      addressData['commune'] ?? '';
                                  _extractedQuartier =
                                      addressData['quartier'] ?? '';
                                  _extractedAvenue =
                                      addressData['avenue'] ?? '';

                                  // Stocker aussi dans la map persistante
                                  _extractedAddressData = {
                                    'ville': addressData['ville'] ?? '',
                                    'commune': addressData['commune'] ?? '',
                                    'quartier': addressData['quartier'] ?? '',
                                    'avenue': addressData['avenue'] ?? '',
                                  };

                                  // Vider les champs de recherche
                                  _searchResults.clear();
                                  _searchAddressController.clear();
                                  _numeroController.text =
                                      ''; // Champ vide pour que l'utilisateur le remplisse
                                });

                                setState(() {
                                  _isGettingCurrentLocation = false;
                                });
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Position actuelle utilisée avec succès !'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } catch (e) {
                                setState(() {
                                  _isGettingCurrentLocation = false;
                                });
                                
                                print(
                                    '❌ Erreur lors de la récupération de la position: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Erreur lors de la récupération de la position: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: _isGettingCurrentLocation 
                                    ? Colors.grey 
                                    : AppColors.primary
                              ),
                              backgroundColor: _isGettingCurrentLocation 
                                  ? Colors.grey 
                                  : AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: _isGettingCurrentLocation
                                ? const EcommerceLoading.inline(color: Colors.white)
                                : const Icon(Icons.location_on,
                                    color: Colors.white),
                            label: Text(
                              _isGettingCurrentLocation 
                                  ? 'Récupération en cours...'
                                  : 'Utiliser ma position actuelle',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                        // Suggestions rapides pour les villes populaires
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              'Kinshasa',
                              'Lubumbashi',
                              'Goma',
                              'Bukavu',
                              'Matadi',
                              'Kananga',
                              'Kisangani',
                            ]
                                .map((city) => GestureDetector(
                                      onTap: _isGettingCurrentLocation
                                          ? null
                                          : () {
                                              _searchAddressController.text =
                                                  '$city ';
                                              // Mettre le focus sur le champ de recherche
                                              FocusScope.of(context)
                                                  .requestFocus(FocusNode());
                                              Future.delayed(
                                                  const Duration(milliseconds: 100),
                                                  () {
                                                FocusScope.of(context)
                                                    .requestFocus(_searchFocusNode);
                                              });
                                              setState(() {
                                                _isSearching = true;
                                              });
                                              _searchAddress('$city ');
                                            },
                                                                              child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: _isGettingCurrentLocation
                                                ? Colors.grey.withOpacity(0.1)
                                                : AppColors.primary
                                                    .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                                color: _isGettingCurrentLocation
                                                    ? Colors.grey.withOpacity(0.3)
                                                    : AppColors.primary
                                                        .withOpacity(0.3)),
                                          ),
                                        child: Text(
                                          city,
                                          style: TextStyle(
                                            color: _isGettingCurrentLocation
                                                ? Colors.grey
                                                : AppColors.primary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),

                        TextFormField(
                          controller: _searchAddressController,
                          focusNode: _searchFocusNode,
                          enabled: !_isGettingCurrentLocation,
                          decoration: InputDecoration(
                            labelText: 'Rechercher une adresse',
                            hintText: _isGettingCurrentLocation
                                ? 'Champ désactivé pendant la récupération de position...'
                                : 'Ex: Kinshasa, Lemba, Avenue du Commerce, Kinshasa...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _isSearching
                                ? const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: const EcommerceLoading.inline(),
                                  )
                                : _searchResults.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: _isGettingCurrentLocation
                                            ? null
                                            : () {
                                                setState(() {
                                                  _searchResults.clear();
                                                  _searchAddressController.clear();
                                                  selectedAddress = null;
                                                  selectedAddressId = null;
                                                });
                                              },
                                      )
                                    : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: _isGettingCurrentLocation 
                                ? Colors.grey.shade100 
                                : Colors.white,
                          ),
                          onChanged: _isGettingCurrentLocation
                              ? null
                              : (value) {
                                  if (value.length > 1) {
                                    // Réduit à 1 caractère pour plus de réactivité
                                    setState(() {
                                      _isSearching = true;
                                    });
                                    _searchAddress(value);
                                  } else {
                                    setState(() {
                                      _searchResults.clear();
                                      _isSearching = false;
                                      selectedAddress = null;
                                      selectedAddressId = null;
                                    });
                                  }
                                },
                          onFieldSubmitted: _isGettingCurrentLocation
                              ? null
                              : (value) {
                                  // Recherche immédiate quand l'utilisateur appuie sur Entrée
                                  if (value.isNotEmpty) {
                                    setState(() {
                                      _isSearching = true;
                                    });
                                    _searchAddress(value);
                                  }
                                },
                        ),

                        if (_searchResults.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            constraints: const BoxConstraints(maxHeight: 250),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _searchResults.length,
                              itemBuilder: (context, index) {
                                final result = _searchResults[index];
                                final isSelected = selectedAddressId != null &&
                                    selectedAddressId == result['place_id'];
                                final sourceType =
                                    result['source_type'] ?? 'geocode';
                                final relevanceScore =
                                    result['relevance_score'] ?? 0.0;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary.withOpacity(0.08)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : Colors.grey.shade200,
                                      width: isSelected ? 2 : 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isSelected
                                            ? AppColors.primary
                                                .withOpacity(0.15)
                                            : Colors.black.withOpacity(0.05),
                                        blurRadius: isSelected ? 8 : 4,
                                        offset: const Offset(0, 2),
                                        spreadRadius: isSelected ? 1 : 0,
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () {
                                        print(
                                            '📍 Adresse sélectionnée: ${result['description']}');
                                        setState(() {
                                          selectedAddress = result;
                                          selectedAddressId =
                                              result['place_id'];
                                        });
                                        _selectAddress(result);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? AppColors.primary
                                                        .withOpacity(0.15)
                                                    : _getSourceTypeColor(
                                                            sourceType)
                                                        .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                isSelected
                                                    ? Icons.location_on
                                                    : _getSourceTypeIcon(
                                                        sourceType),
                                                color: isSelected
                                                    ? AppColors.primary
                                                    : _getSourceTypeColor(
                                                        sourceType),
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    result['description'] ??
                                                        result[
                                                            'formatted_address'] ??
                                                        '',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: isSelected
                                                          ? FontWeight.w600
                                                          : FontWeight.w500,
                                                      color: isSelected
                                                          ? AppColors.primary
                                                          : Colors.black87,
                                                      height: 1.3,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 6,
                                                                vertical: 2),
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              _getSourceTypeColor(
                                                                      sourceType)
                                                                  .withOpacity(
                                                                      0.1),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                        child: Text(
                                                          sourceType ==
                                                                  'geocode'
                                                              ? 'Adresse'
                                                              : 'Établissement',
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            color:
                                                                _getSourceTypeColor(
                                                                    sourceType),
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      if (relevanceScore > 5)
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal: 4,
                                                                  vertical: 1),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors.green
                                                                .withOpacity(
                                                                    0.1),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        4),
                                                          ),
                                                          child: Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              Icon(
                                                                Icons.star,
                                                                size: 10,
                                                                color: Colors
                                                                    .green,
                                                              ),
                                                              const SizedBox(
                                                                  width: 2),
                                                              Text(
                                                                'Pertinent',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 9,
                                                                  color: Colors
                                                                      .green,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
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
                                            if (isSelected)
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: const Icon(
                                                  Icons.check,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info_outline,
                                      color: Colors.green.shade700),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Adresse sélectionnée',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (_extractedAddressData.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.green.shade300),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '📍 Adresse extraite :',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade700,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      if (_extractedAddressData['ville']
                                              ?.isNotEmpty ==
                                          true)
                                        Text(
                                          '🏙️ ${_extractedAddressData['ville']}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      if (_extractedAddressData['commune']
                                              ?.isNotEmpty ==
                                          true)
                                        Text(
                                          '🏘️ ${_extractedAddressData['commune']}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      if (_extractedAddressData['quartier']
                                              ?.isNotEmpty ==
                                          true)
                                        Text(
                                          '🏠 ${_extractedAddressData['quartier']}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      if (_extractedAddressData['avenue']
                                              ?.isNotEmpty ==
                                          true)
                                        Text(
                                          '🛣️ ${_extractedAddressData['avenue']}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ] else ...[
                                Text(
                                  'L\'adresse sera automatiquement extraite de votre sélection Google.',
                                  style: TextStyle(
                                    color: Colors.green.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _numeroController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: "Référence de l'adresse",
                            hintText:
                                'Ex : N°7A, 2ème étage, Appartement 15, Référence: près du marché, etc.',
                            prefixIcon: const Icon(Icons.info_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        CheckboxListTile(
                          value: saveAddress,
                          onChanged: (bool? value) {
                            // Utiliser seulement le setState du StatefulBuilder
                            setState(() {
                              saveAddress = value ?? false;
                            });
                          },
                          title: const Text(
                            'Enregistrer cette adresse pour mes futures commandes',
                            style: TextStyle(fontSize: 14),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: state.isLoading
                                ? null
                                : () async {
                                    // Vérifier qu'une adresse a été sélectionnée en utilisant la map persistante
                                    if (_extractedAddressData.isEmpty) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Veuillez sélectionner une adresse depuis la recherche Google'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }

                                    // Vérifier que le champ détail adresse n'est pas vide
                                    if (_numeroController.text.trim().isEmpty) {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title:
                                                const Text('Champ obligatoire'),
                                            content: const Text(
                                                'Le champ "Référence de l\'adresse" est obligatoire. Veuillez entrer un numéro, étage, référence ou autre détail pour que le livreur puisse vous trouver.'),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                                child: const Text('OK'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                      return;
                                    }

                                    // Utiliser les données extraites du geocoding depuis la map persistante
                                    final detailAdresse =
                                        _numeroController.text.trim();
                                    final ville =
                                        _extractedAddressData['ville'] ?? '';
                                    final commune =
                                        _extractedAddressData['commune'] ?? '';
                                    final quartier =
                                        _extractedAddressData['quartier'] ?? '';
                                    final avenue =
                                        _extractedAddressData['avenue'] ?? '';

                                    print(
                                        '🚀 Tentative de création de commande avec données geocoding...');
                                    print('   Ville: $ville');
                                    print('   Commune: $commune');
                                    print('   Quartier: $quartier');
                                    print('   Avenue: $avenue');
                                    print('   Détail: $detailAdresse');

                                    // Obtenir les coordonnées GPS depuis l'adresse complète
                                    String fullAddress =
                                        '$quartier, $commune, $ville, $detailAdresse, RDC';
                                    final coordinates =
                                        await getCoordinatesFromGoogle(
                                            fullAddress);

                                    final latitude = coordinates['latitude']?.toDouble() ?? 0.0;
                                    final longitude = coordinates['longitude']?.toDouble() ?? 0.0;

                                    // Vérifier que les coordonnées sont valides
                                    if (latitude == 0.0 || longitude == 0.0) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Impossible d\'obtenir les coordonnées GPS. Veuillez réessayer.'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }

                                    // Préparer les produits pour l'initialisation (avec quantite au lieu de quantity)
                                    final productsToSend = cartItems.map((item) {
                                      // Convertir la quantité en int
                                      int quantite = 1;
                                      if (item['quantity'] != null) {
                                        if (item['quantity'] is int) {
                                          quantite = item['quantity'] as int;
                                        } else {
                                          quantite = int.tryParse(item['quantity'].toString()) ?? 1;
                                        }
                                      }
                                      
                                      return {
                                        "productId": int.parse(item['id'].toString()),
                                        "quantite": quantite,
                                      };
                                    }).toList();

                                    // Préparer l'adresse complète
                                    final addressToSend = {
                                      "pays": "RDC",
                                      "ville": ville.isNotEmpty ? ville : "",
                                      "commune": commune.isNotEmpty ? commune : "",
                                      "quartier": quartier.isNotEmpty ? quartier : "",
                                      "avenue": avenue.isNotEmpty ? avenue : "",
                                      "numero": detailAdresse.isNotEmpty ? detailAdresse : "",
                                      "codePostale": "012",
                                    };

                                    // Print du body avant initialisation
                                    print('═══════════════════════════════════════════════════════');
                                    print('🛑 BREAKPOINT: Avant initialisation de la commande (Formulaire)');
                                    print('📍 Coordonnées GPS:');
                                    print('   Latitude: $latitude');
                                    print('   Longitude: $longitude');
                                    print('📦 Produits à envoyer:');
                                    for (var product in productsToSend) {
                                      print('   - ProductId: ${product['productId']}, Quantite: ${product['quantite']}');
                                    }
                                    print('🏠 Adresse:');
                                    print('   Pays: ${addressToSend['pays']}');
                                    print('   Ville: ${addressToSend['ville']}');
                                    print('   Commune: ${addressToSend['commune']}');
                                    print('   Quartier: ${addressToSend['quartier']}');
                                    print('   Avenue: ${addressToSend['avenue']}');
                                    print('   Numero: ${addressToSend['numero']}');
                                    print('📋 Body JSON qui sera envoyé:');
                                    print(jsonEncode({
                                      'products': productsToSend,
                                      'latitude': latitude,
                                      'longitude': longitude,
                                      'address': addressToSend,
                                    }));
                                    print('═══════════════════════════════════════════════════════');
                                    
                                    // Breakpoint virtuel
                                    assert(() {
                                      print('🛑 BREAKPOINT: Cliquez ici pour déboguer avant initialisation');
                                      return true;
                                    }());

                                    // Initialiser la commande avec la nouvelle API multi-vendeurs
                                    context.read<OrderCubit>().initializeOrder(
                                          products: productsToSend,
                                          latitude: latitude,
                                          longitude: longitude,
                                          address: addressToSend,
                                        );

                                    saveCart(
                                        context,
                                        cartItems,
                                        ville.isNotEmpty ? ville : 'N/A',
                                        commune.isNotEmpty ? commune : 'N/A',
                                        quartier.isNotEmpty ? quartier : 'N/A',
                                        avenue.isNotEmpty ? avenue : 'N/A',
                                        detailAdresse,
                                        'RDC',
                                        coordinates['longitude'] ?? 0.0,
                                        coordinates['latitude'] ?? 0.0);

                                    if (saveAddress) {
                                      // Obtenir les coordonnées depuis l'adresse complète
                                      String fullAddress =
                                          '$quartier, $commune, $ville, $detailAdresse, RDC';
                                      final coordinates =
                                          await getCoordinatesFromGoogle(
                                              fullAddress);

                                      _saveDeliveryAddressWithCoordinates(
                                        coordinates['latitude'] ?? 0.0,
                                        coordinates['longitude'] ?? 0.0,
                                        ville.isNotEmpty ? ville : 'N/A',
                                        commune.isNotEmpty ? commune : 'N/A',
                                        quartier.isNotEmpty ? quartier : 'N/A',
                                        avenue.isNotEmpty ? avenue : 'N/A',
                                        detailAdresse,
                                        'RDC',
                                        fullAddress,
                                      );
                                    }

                                    // Vider le cache des adresses extraites après la commande
                                    setState(() {
                                      _extractedAddressData.clear();
                                      _extractedVille = '';
                                      _extractedCommune = '';
                                      _extractedQuartier = '';
                                      _extractedAvenue = '';
                                      _selectedGoogleAddress = null;
                                    });
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: state.isLoading
                                ? const EcommerceLoading.inline(color: Colors.white)
                                : const Text(
                                    'CONFIRMER LA COMMANDE',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<Map<String, double>> getCoordinatesFromGoogle(String address) async {
    const apiKey = 'AIzaSyCpJzuEa7jLAcP8ub8AVM8flT2aK5cPdh0';
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'OK') {
          final location = data['results'][0]['geometry']['location'];
          final lat = location['lat'];
          final lng = location['lng'];

          print('Latitude: $lat, Longitude: $lng');

          return {
            'latitude': lat,
            'longitude': lng,
          };
        } else {
          print('Adresse introuvable: ${data['status']}');
          throw Exception('Adresse introuvable: ${data['status']}');
        }
      } else {
        print('Erreur serveur: ${response.statusCode}');
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur lors de la récupération des coordonnées: $e');
      throw Exception('Erreur lors de la récupération des coordonnées: $e');
    }
  }

  Future<Map<String, String>> getAddressFromGoogleAPI(
      double lat, double lng) async {
    const apiKey = 'AIzaSyCpJzuEa7jLAcP8ub8AVM8flT2aK5cPdh0';
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey&language=fr';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          final results = data['results'];
          if (results.isNotEmpty) {
            final addressComponents = results[0]['address_components'];

            String ville = '';
            String commune = '';
            String quartier = '';
            String avenue = '';

            for (var component in addressComponents) {
              final types = component['types'] as List;
              if (types.contains('locality') ||
                  types.contains('administrative_area_level_1')) {
                ville = component['long_name'];
              } else if (types.contains('administrative_area_level_2')) {
                commune = component['long_name'];
              } else if (types.contains('sublocality') ||
                  types.contains('neighborhood')) {
                quartier = component['long_name'];
              } else if (types.contains('route')) {
                avenue = component['long_name'];
              }
            }

            print('📍 Adresse extraite depuis les coordonnées:');
            print('   Ville: $ville');
            print('   Commune: $commune');
            print('   Quartier: $quartier');
            print('   Avenue: $avenue');

            final result = {
              'ville': ville,
              'commune': commune,
              'quartier': quartier,
              'avenue': avenue,
            };

            print('📍 Résultat final: $result');

            // Sauvegarder l'adresse avec les coordonnées dans delivery_addresses
            await _saveDeliveryAddressWithCoordinates(
              lat,
              lng,
              ville,
              commune,
              quartier,
              avenue,
              '', // numero vide pour l'instant
              'RDC',
              results[0]['formatted_address'] ?? '',
            );

            return result;
          }
        } else {
          print('❌ Erreur Google API: ${data['status']}');
          throw Exception('Erreur Google API: ${data['status']}');
        }
      } else {
        print('❌ Erreur HTTP: ${response.statusCode}');
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erreur lors de la récupération de l\'adresse: $e');
      throw Exception('Erreur lors de la récupération de l\'adresse: $e');
    }

    return {};
  }

  // Méthode pour rechercher des adresses avec l'API Google Places
  Future<void> _searchAddress(String query) async {
    print('🔍 Recherche d\'adresse: $query'); // Debug log

    // Annuler la recherche précédente si elle est en cours
    _searchDebounceTimer?.cancel();

    // Debounce intelligent : plus court pour les requêtes courtes, plus long pour les longues
    final debounceTime = query.length < 5 ? 200 : 500;

    _searchDebounceTimer =
        Timer(Duration(milliseconds: debounceTime), () async {
      const apiKey = 'AIzaSyCpJzuEa7jLAcP8ub8AVM8flT2aK5cPdh0';

      // Recherche plus intelligente avec plusieurs types de résultats
      final List<String> searchUrls = [
        // Recherche principale avec géocodage
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
            '?input=${Uri.encodeComponent(query)}'
            '&types=geocode'
            '&components=country:cd'
            '&key=$apiKey',

        // Recherche d'établissements pour plus de précision
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
            '?input=${Uri.encodeComponent(query)}'
            '&types=establishment'
            '&components=country:cd'
            '&key=$apiKey',
      ];

      print('🌐 URLs de recherche: $searchUrls'); // Debug log

      try {
        final List<Map<String, dynamic>> allResults = [];

        // Effectuer les recherches en parallèle
        final List<Future<http.Response>> requests =
            searchUrls.map((url) => http.get(Uri.parse(url))).toList();

        final responses = await Future.wait(requests);

        for (int i = 0; i < responses.length; i++) {
          final response = responses[i];
          print('📡 Réponse $i reçue: ${response.statusCode}'); // Debug log

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            print('📊 Données reçues: ${data['status']}'); // Debug log

            if (data['status'] == 'OK') {
              final predictions =
                  List<Map<String, dynamic>>.from(data['predictions']);

              // Ajouter un type pour identifier la source
              for (var prediction in predictions) {
                prediction['source_type'] =
                    i == 0 ? 'geocode' : 'establishment';
                prediction['relevance_score'] =
                    _calculateRelevanceScore(query, prediction['description']);
              }

              allResults.addAll(predictions);
              print(
                  '📍 Prédictions trouvées: ${predictions.length}'); // Debug log
            } else {
              print('❌ Erreur de recherche $i: ${data['status']}');
            }
          } else {
            print('❌ Erreur serveur $i: ${response.statusCode}');
          }
        }

        // Trier et dédupliquer les résultats
        final uniqueResults = _deduplicateAndSortResults(allResults, query);

        setState(() {
          _searchResults = uniqueResults;
          _isSearching = false;
        });

        print('✅ Résultats finaux: ${uniqueResults.length}');
      } catch (e) {
        print('❌ Erreur lors de la recherche d\'adresse: $e');
        setState(() {
          _searchResults.clear();
          _isSearching = false;
        });

        // Afficher un message d'erreur à l'utilisateur
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Erreur de connexion. Vérifiez votre connexion internet.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  // Calculer un score de pertinence pour trier les résultats
  double _calculateRelevanceScore(String query, String description) {
    final queryLower = query.toLowerCase();
    final descLower = description.toLowerCase();

    double score = 0.0;

    // Bonus pour les correspondances exactes au début
    if (descLower.startsWith(queryLower)) {
      score += 10.0;
    }

    // Bonus pour les mots-clés importants
    final keywords = [
      'kinshasa',
      'lubumbashi',
      'goma',
      'bukavu',
      'matadi',
      'avenue',
      'boulevard',
      'rue'
    ];
    for (final keyword in keywords) {
      if (descLower.contains(keyword)) {
        score += 2.0;
      }
    }

    // Bonus pour la longueur (adresses plus complètes)
    score += descLower.length * 0.1;

    // Malus pour les adresses trop longues
    if (descLower.length > 100) {
      score -= 5.0;
    }

    return score;
  }

  // Dédupliquer et trier les résultats
  List<Map<String, dynamic>> _deduplicateAndSortResults(
      List<Map<String, dynamic>> results, String query) {
    final Map<String, Map<String, dynamic>> uniqueResults = {};

    for (final result in results) {
      final description = result['description'] as String;
      final placeId = result['place_id'] as String;

      // Garder le résultat avec le meilleur score
      if (!uniqueResults.containsKey(placeId) ||
          (result['relevance_score'] ?? 0.0) >
              (uniqueResults[placeId]?['relevance_score'] ?? 0.0)) {
        uniqueResults[placeId] = result;
      }
    }

    // Trier par score de pertinence décroissant
    final sortedResults = uniqueResults.values.toList();
    sortedResults.sort((a, b) =>
        (b['relevance_score'] ?? 0.0).compareTo(a['relevance_score'] ?? 0.0));

    // Limiter à 10 résultats pour éviter la surcharge
    return sortedResults.take(10).toList();
  }

  // Obtenir la couleur selon le type de source
  Color _getSourceTypeColor(String sourceType) {
    switch (sourceType) {
      case 'geocode':
        return Colors.blue;
      case 'establishment':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Obtenir l'icône selon le type de source
  IconData _getSourceTypeIcon(String sourceType) {
    switch (sourceType) {
      case 'geocode':
        return Icons.location_on_outlined;
      case 'establishment':
        return Icons.business;
      default:
        return Icons.location_on_outlined;
    }
  }

  // Méthode pour sélectionner une adresse et récupérer ses coordonnées
  Future<void> _selectAddress(Map<String, dynamic> place) async {
    print('🎯 Sélection d\'adresse: ${place['description']}');

    const apiKey = 'AIzaSyCpJzuEa7jLAcP8ub8AVM8flT2aK5cPdh0';
    final placeId = place['place_id'];
    final url = 'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=$placeId'
        '&fields=geometry,formatted_address,address_components'
        '&key=$apiKey';

    print('🌐 URL de détails: $url'); // Debug log

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'OK') {
          final result = data['result'];
          final location = result['geometry']['location'];
          final addressComponents = result['address_components'] as List;

          // Extraire les composants d'adresse avec une approche plus robuste
          String ville = '';
          String commune = '';
          String quartier = '';
          String avenue = '';
          String numero = '';

          print(
              '🔍 Composants d\'adresse trouvés: ${addressComponents.length}');

          for (var component in addressComponents) {
            final types = List<String>.from(component['types']);
            final longName = component['long_name'] ?? '';
            final shortName = component['short_name'] ?? '';

            print('📍 Composant: $longName - Types: $types');

            if (types.contains('locality') ||
                types.contains('administrative_area_level_1')) {
              ville = longName;
              print('🏙️ Ville trouvée: $ville');
            } else if (types.contains('sublocality_level_1') ||
                types.contains('sublocality') ||
                types.contains('administrative_area_level_2')) {
              commune = longName;
              print('🏘️ Commune trouvée: $commune');
            } else if (types.contains('sublocality_level_2') ||
                types.contains('neighborhood')) {
              quartier = longName;
              print('🏠 Quartier trouvé: $quartier');
            } else if (types.contains('route')) {
              avenue = longName;
              print('🛣️ Avenue trouvée: $avenue');
            } else if (types.contains('street_number')) {
              numero = longName;
              print('🏠 Numéro trouvé: $numero');
            }
          }

          // Si on n'a pas trouvé de ville, essayer de l'extraire de l'adresse complète
          if (ville.isEmpty) {
            final formattedAddress = result['formatted_address'] ?? '';
            if (formattedAddress.contains('Kinshasa')) {
              ville = 'Kinshasa';
            } else if (formattedAddress.contains('Lubumbashi')) {
              ville = 'Lubumbashi';
            } else if (formattedAddress.contains('Goma')) {
              ville = 'Goma';
            } else if (formattedAddress.contains('Bukavu')) {
              ville = 'Bukavu';
            } else if (formattedAddress.contains('Matadi')) {
              ville = 'Matadi';
            } else if (formattedAddress.contains('Kananga')) {
              ville = 'Kananga';
            } else if (formattedAddress.contains('Kisangani')) {
              ville = 'Kisangani';
            } else if (formattedAddress.contains('Kolwezi')) {
              ville = 'Kolwezi';
            } else if (formattedAddress.contains('Likasi')) {
              ville = 'Likasi';
            } else if (formattedAddress.contains('Kikwit')) {
              ville = 'Kikwit';
            } else if (formattedAddress.contains('Tshikapa')) {
              ville = 'Tshikapa';
            } else if (formattedAddress.contains('Uvira')) {
              ville = 'Uvira';
            } else if (formattedAddress.contains('Bunia')) {
              ville = 'Bunia';
            } else if (formattedAddress.contains('Kalemie')) {
              ville = 'Kalemie';
            } else if (formattedAddress.contains('Kindu')) {
              ville = 'Kindu';
            } else if (formattedAddress.contains('Mbandaka')) {
              ville = 'Mbandaka';
            } else if (formattedAddress.contains('Mbanza-Ngungu')) {
              ville = 'Mbanza-Ngungu';
            } else if (formattedAddress.contains('Boma')) {
              ville = 'Boma';
            } else if (formattedAddress.contains('Kamina')) {
              ville = 'Kamina';
            }
            print('🏙️ Ville extraite de l\'adresse: $ville');
          }

          // Si on n'a pas trouvé de commune, essayer de l'extraire
          if (commune.isEmpty && quartier.isNotEmpty) {
            // Parfois le quartier est stocké comme commune
            commune = quartier;
            quartier = '';
            print('🏘️ Commune extraite du quartier: $commune');
          }

          // Essayer d'extraire plus d'informations de l'adresse complète si nécessaire
          if (avenue.isEmpty || quartier.isEmpty) {
            final formattedAddress = result['formatted_address'] ?? '';
            final addressParts = formattedAddress.split(',');

            // Essayer de trouver l'avenue dans les parties de l'adresse
            if (avenue.isEmpty) {
              for (var part in addressParts) {
                final trimmedPart = part.trim();
                if (trimmedPart.contains('Avenue') ||
                    trimmedPart.contains('Boulevard') ||
                    trimmedPart.contains('Rue') ||
                    trimmedPart.contains('Route')) {
                  avenue = trimmedPart;
                  print('🛣️ Avenue extraite: $avenue');
                  break;
                }
              }
            }

            // Essayer de trouver le quartier dans les parties de l'adresse
            if (quartier.isEmpty) {
              for (var part in addressParts) {
                final trimmedPart = part.trim();
                if (!trimmedPart.contains('Kinshasa') &&
                    !trimmedPart.contains('RDC') &&
                    !trimmedPart.contains('Congo') &&
                    trimmedPart.length > 3) {
                  quartier = trimmedPart;
                  print('🏠 Quartier extrait: $quartier');
                  break;
                }
              }
            }
          }

          // Stocker les données extraites dans les variables d'état et dans la map persistante
          setState(() {
            _extractedVille = ville.isNotEmpty ? ville : '';
            _extractedCommune = commune.isNotEmpty ? commune : '';
            _extractedQuartier = quartier.isNotEmpty ? quartier : '';
            _extractedAvenue = avenue.isNotEmpty ? avenue : '';

            // Stocker aussi dans la map persistante
            _extractedAddressData = {
              'ville': ville.isNotEmpty ? ville : '',
              'commune': commune.isNotEmpty ? commune : '',
              'quartier': quartier.isNotEmpty ? quartier : '',
              'avenue': avenue.isNotEmpty ? avenue : '',
            };

            _numeroController.text =
                ''; // Champ vide pour que l'utilisateur le remplisse
            _searchResults.clear();
            _searchAddressController.clear();
          });

          print('✅ Champs mis à jour:');
          print('   Ville: ${_villeController.text}');
          print('   Commune: ${_communeController.text}');
          print('   Quartier: ${_quartierController.text}');
          print('   Avenue: ${_avenueController.text}');
          print('   Numéro: ${_numeroController.text}');

          // Afficher les coordonnées trouvées
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Adresse sélectionnée: ${result['formatted_address']}'),
              backgroundColor: AppColors.primary,
              duration: const Duration(seconds: 2),
            ),
          );

          // Sauvegarder les coordonnées GeoJSON
          final coordinates = {
            'type': 'Point',
            'coordinates': [location['lng'], location['lat']]
          };

          print('📍 Coordonnées GeoJSON: $coordinates');

          // Sauvegarder les coordonnées GeoJSON dans Firestore
          // await _saveGeoJSONCoordinates(
          //     coordinates, result['formatted_address']);

          // Sauvegarder l'adresse avec les coordonnées dans delivery_addresses
          await _saveDeliveryAddressWithCoordinates(
            location['lat'],
            location['lng'],
            ville,
            commune,
            quartier,
            avenue,
            numero,
            'RDC',
            result['formatted_address'],
          );
        } else {
          print(
              '❌ Erreur lors de la récupération des détails: ${data['status']}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Erreur lors de la récupération des détails: ${data['status']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        print('❌ Erreur serveur: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur serveur: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur lors de la sélection d\'adresse: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sélection d\'adresse: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Méthode pour sauvegarder les coordonnées GeoJSON
  // Future<void> _saveGeoJSONCoordinates(
  //     Map<String, dynamic> coordinates, String address) async {
  //   final authState = context.read<AuthCubit>().state;
  //   if (authState is AuthSuccess && authState.user != null) {
  //     final user = authState.user!;
  //     final userId = user['id']?.toString() ?? '';

  //     try {
  //       await FirebaseFirestore.instance.collection('geo_coordinates').add({
  //         'userId': userId,
  //         'address': address,
  //         'coordinates': coordinates,
  //         'timestamp': FieldValue.serverTimestamp(),
  //       });

  //       print('✅ Coordonnées GeoJSON sauvegardées avec succès');
  //     } catch (e) {
  //       print('❌ Erreur lors de la sauvegarde des coordonnées: $e');
  //     }
  //   }
  // }

  // Méthode pour sauvegarder l'adresse de livraison avec coordonnées
  Future<void> _saveDeliveryAddressWithCoordinates(
    double latitude,
    double longitude,
    String ville,
    String commune,
    String quartier,
    String avenue,
    String numero,
    String pays,
    String fullAddress,
  ) async {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthSuccess && authState.user != null) {
      final user = authState.user!;
      final userId = user['id']?.toString() ?? '';
      final userName =
          '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();

      try {
        await FirebaseFirestore.instance.collection('delivery_addresses').add({
          'timestamp': FieldValue.serverTimestamp(),
          'userId': userId,
          'userName': userName,
          'ville': ville,
          'commune': commune,
          'quartier': quartier,
          'avenue': avenue,
          'numero': numero,
          'pays': pays,
          'phone': user['phone'] ?? '',
          'latitude': latitude,
          'longitude': longitude,
          'fullAddress': fullAddress,
          'source': 'google_geocoding',
        });
        _saveCurrentLocation(longitude, latitude);

        print('✅ Adresse avec coordonnées sauvegardée dans delivery_addresses');
      } catch (e) {
        print(
            '❌ Erreur lors de la sauvegarde de l\'adresse avec coordonnées: $e');
      }
    }
  }

  // Méthode pour sauvegarder l'adresse de livraison
  Future<void> _saveDeliveryAddress(
    BuildContext context,
    String ville,
    String commune,
    String quartier,
    String avenue,
    String numero,
    String pays,
  ) async {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthSuccess && authState.user != null) {
      final user = authState.user!;
      final userId = user['id']?.toString() ?? '';
      final userName =
          '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();

      try {
        // Obtenir les coordonnées depuis l'adresse
        String fullAddress = '$quartier, $commune, $ville, $numero, RDC';
        final coordinates = await getCoordinatesFromGoogle(fullAddress);

        await FirebaseFirestore.instance.collection('delivery_addresses').add({
          'timestamp': FieldValue.serverTimestamp(),
          'userId': userId,
          'userName': userName,
          'ville': ville,
          'commune': commune,
          'quartier': quartier,
          'avenue': avenue,
          'numero': numero,
          'pays': pays,
          'phone': user['phone'] ?? '',
          'latitude': coordinates['latitude'],
          'longitude': coordinates['longitude'],
        });

        _saveCurrentLocation(
            coordinates['longitude'] ?? 0.0, coordinates['latitude'] ?? 0.0);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Adresse de livraison enregistrée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Erreur lors de l\'enregistrement de l\'adresse: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        final cartItems = state.items;
        final total = cartItems.fold<double>(0, (sum, item) {
          final price = double.tryParse(item['price']
                  .toString()
                  .replaceAll(RegExp(r'[^0-9.]'), '')) ??
              0;
          return sum + (price * (item['quantity'] as int));
        });
        return Scaffold(
          appBar: AppBarWithLogo(
            title: 'Mon Panier',
            backgroundColor: Colors.white,
            elevation: 0,
            leading: widget.backNavigaton
                ? IconButton(
                    icon:
                        const Icon(Icons.arrow_back, color: AppColors.primary),
                    onPressed: () => Navigator.pop(context),
                  )
                : null,
          ),
          backgroundColor: Colors.grey.shade50,
          body: cartItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.shopping_cart_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Votre panier est vide',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ajoutez des articles pour commencer vos achats',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Header avec résumé
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.shopping_cart_rounded,
                              color: AppColors.primary,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${cartItems.length} article${cartItems.length > 1 ? 's' : ''}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  'Sous-total: ${total.toStringAsFixed(0)} FC',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) {
                          final item = cartItems[index];
                          final unitPrice = double.tryParse(item['price']
                                      .toString()
                                      .replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
                          final itemTotal = unitPrice * (item['quantity'] as int);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 0.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Image du produit avec badge
                                  Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: CachedNetworkImage(
                                          imageUrl: item['imagePath'],
                                          width: 65,
                                          height: 65,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Container(
                                            width: 65,
                                            height: 65,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Center(
                                              child: EcommerceImageLoading(size: 25),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) => Container(
                                            width: 65,
                                            height: 65,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.shopping_bag_outlined,
                                              color: Colors.grey.shade400,
                                              size: 22,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Badge quantité
                                      Positioned(
                                        top: -3,
                                        right: -3,
                                        child: Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Text(
                                            '${item['quantity']}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 10),
                                  // Détails du produit
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          item['name'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                            color: Colors.black87,
                                            height: 1.2,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(
                                              color: AppColors.primary.withOpacity(0.2),
                                              width: 0.5,
                                            ),
                                          ),
                                          child: Text(
                                            item['category'],
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontSize: 8,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (item['quantity'] > 1)
                                                  Text(
                                                    '${unitPrice.toStringAsFixed(0)} FC',
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      color: Colors.grey.shade500,
                                                      decoration: TextDecoration.lineThrough,
                                                    ),
                                                  ),
                                                Text(
                                                  '${itemTotal.toStringAsFixed(0)} FC',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: AppColors.primary,
                                                    height: 1.1,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (item['quantity'] > 1) ...[
                                              const Spacer(),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 5,
                                                  vertical: 1,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.shade50,
                                                  borderRadius: BorderRadius.circular(3),
                                                ),
                                                child: Text(
                                                  '${item['quantity']}x',
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    color: Colors.green.shade700,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        // Contrôles de quantité
                                        Row(
                                          children: [
                                            // Contrôles quantité
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade50,
                                                border: Border.all(
                                                  color: Colors.grey.shade300,
                                                  width: 1,
                                                ),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Material(
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      onTap: () {
                                                        final newQty = (item['quantity'] as int) - 1;
                                                        if (newQty > 0) {
                                                          context.read<CartCubit>().updateQuantity(
                                                            item['name'], newQty);
                                                        }
                                                      },
                                                      borderRadius: const BorderRadius.only(
                                                        topLeft: Radius.circular(6),
                                                        bottomLeft: Radius.circular(6),
                                                      ),
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 8, vertical: 4),
                                                        child: const Icon(
                                                          Icons.remove_rounded,
                                                          size: 14,
                                                          color: Colors.black87,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                                    decoration: BoxDecoration(
                                                      border: Border.symmetric(
                                                        vertical: BorderSide(
                                                          color: Colors.grey.shade300,
                                                          width: 1,
                                                        ),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      '${item['quantity']}',
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 11,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                  ),
                                                  Material(
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      onTap: () async {
                                                        final newQty = (item['quantity'] as int) + 1;
                                                        final stock = item['stock'] ?? 1;
                                                        if (newQty > stock) {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(
                                                              content: Text('Stock insuffisant : il ne reste que $stock en stock.'),
                                                              backgroundColor: Colors.red,
                                                              behavior: SnackBarBehavior.floating,
                                                            ),
                                                          );
                                                          return;
                                                        }
                                                        final success = await context.read<CartCubit>().updateQuantity(
                                                          item['name'], newQty);
                                                        if (!success) {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(
                                                              content: Text('Stock insuffisant : il ne reste que $stock en stock.'),
                                                              backgroundColor: Colors.red,
                                                              behavior: SnackBarBehavior.floating,
                                                            ),
                                                          );
                                                        }
                                                      },
                                                      borderRadius: const BorderRadius.only(
                                                        topRight: Radius.circular(6),
                                                        bottomRight: Radius.circular(6),
                                                      ),
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 8, vertical: 4),
                                                        child: const Icon(
                                                          Icons.add_rounded,
                                                          size: 14,
                                                          color: Colors.black87,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Spacer(),
                                            // Bouton supprimer
                                            Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: () {
                                                  context.read<CartCubit>().removeFromCart(item['name']);
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('Article retiré du panier'),
                                                      backgroundColor: AppColors.primary,
                                                      duration: Duration(seconds: 2),
                                                      behavior: SnackBarBehavior.floating,
                                                    ),
                                                  );
                                                },
                                                borderRadius: BorderRadius.circular(6),
                                                child: Container(
                                                  padding: const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red.shade50,
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(
                                                      color: Colors.red.shade200,
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Icon(
                                                    Icons.delete_outline_rounded,
                                                    size: 16,
                                                    color: Colors.red.shade700,
                                                  ),
                                                ),
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
                          );
                        },
                      ),
                    ),
                    // Résumé et bouton de paiement
                    Container(
                      padding: EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 16,
                        bottom: MediaQuery.of(context).padding.bottom + 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 15,
                            offset: const Offset(0, -4),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Détails du résumé
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.grey.shade50,
                                  Colors.white,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 0.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.receipt_long_rounded,
                                          size: 18,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Sous-total',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '${total.toStringAsFixed(0)} FC',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Icon(
                                            Icons.payments_rounded,
                                            size: 16,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Total',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '${total.toStringAsFixed(0)} FC',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddressSelectionScreen(
                                      cartItems: cartItems,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shadowColor: AppColors.primary.withOpacity(0.3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.arrow_forward, size: 18),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'SUIVANT',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
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

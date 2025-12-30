import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:immo/constants.dart';
import 'package:immo/cubit/auth_cubit.dart';
import 'package:immo/cubit/order_cubit.dart';
import 'package:immo/cubit/cart_cubit.dart';
import 'package:immo/widgets/ecommerce_loading.dart';
// import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// import 'dart:async';
import 'pending_payment_screen.dart';

class AddressSelectionScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;

  const AddressSelectionScreen({
    Key? key,
    required this.cartItems,
  }) : super(key: key);

  @override
  State<AddressSelectionScreen> createState() => _AddressSelectionScreenState();
}

class _AddressSelectionScreenState extends State<AddressSelectionScreen> {
  // Variables pour la recherche d'adresse
  // final TextEditingController _searchAddressController = TextEditingController();
  // final FocusNode _searchFocusNode = FocusNode();
  // List<Map<String, dynamic>> _searchResults = [];
  // Timer? _searchDebounceTimer;
  // bool _isSearching = false;
  // bool _isGettingCurrentLocation = false;

  // Variable pour suivre l'adresse sélectionnée depuis Google
  // Map<String, dynamic>? _selectedGoogleAddress;

  // Variable pour stocker les données extraites de manière persistante
  // Map<String, String> _extractedAddressData = {};

  // Contrôleur pour le champ détail adresse
  // final TextEditingController _numeroController = TextEditingController();

  // Variable pour stocker l'adresse sélectionnée
  Map<String, dynamic>? selectedAddress;
  String? selectedAddressId;
  
  // Flag pour éviter les appels multiples du listener
  bool _isProcessingRedirect = false;

  @override
  void initState() {
    super.initState();
    // _searchAddressController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    // _searchDebounceTimer?.cancel();
    // _searchAddressController.dispose();
    // _searchFocusNode.dispose();
    // _numeroController.dispose();
    super.dispose();
  }

  // void _onSearchChanged() {
  //   _searchDebounceTimer?.cancel();
  //   _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
  //     final query = _searchAddressController.text;
  //     if (query.length > 1) {
  //       setState(() {
  //         _isSearching = true;
  //       });
  //       _searchAddress(query);
  //     } else {
  //       setState(() {
  //         _searchResults.clear();
  //         _isSearching = false;
  //       });
  //     }
  //   });
  // }

  // Future<void> _searchAddress(String query) async {
  //   const apiKey = 'AIzaSyCpJzuEa7jLAcP8ub8AVM8flT2aK5cPdh0';
  //   final url =
  //       'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(query)}&key=$apiKey&components=country:cd&language=fr';

  //   try {
  //     final response = await http.get(Uri.parse(url));
  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);
  //       if (data['status'] == 'OK') {
  //         setState(() {
  //           _searchResults = List<Map<String, dynamic>>.from(
  //             data['predictions'].map((prediction) => {
  //               'description': prediction['description'],
  //               'place_id': prediction['place_id'],
  //               'source_type': 'autocomplete',
  //               'relevance_score': 1.0,
  //             }),
  //           );
  //           _isSearching = false;
  //         });
  //       } else {
  //         setState(() {
  //           _searchResults = [];
  //           _isSearching = false;
  //         });
  //       }
  //     }
  //   } catch (e) {
  //     setState(() {
  //       _isSearching = false;
  //     });
  //   }
  // }

  // Future<void> _selectAddress(Map<String, dynamic> result) async {
  //   const apiKey = 'AIzaSyCpJzuEa7jLAcP8ub8AVM8flT2aK5cPdh0';
  //   final url =
  //       'https://maps.googleapis.com/maps/api/place/details/json?place_id=${result['place_id']}&key=$apiKey&language=fr';

  //   try {
  //     final response = await http.get(Uri.parse(url));
  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);
  //       if (data['status'] == 'OK') {
  //         final resultData = data['result'];
  //         final addressComponents = resultData['address_components'] as List;

  //         String ville = '';
  //         String commune = '';
  //         String quartier = '';
  //         String avenue = '';

  //         for (var component in addressComponents) {
  //           final types = component['types'] as List;
  //           if (types.contains('locality') ||
  //               types.contains('administrative_area_level_1')) {
  //             ville = component['long_name'];
  //           } else if (types.contains('administrative_area_level_2')) {
  //             commune = component['long_name'];
  //           } else if (types.contains('sublocality') ||
  //               types.contains('neighborhood')) {
  //             quartier = component['long_name'];
  //           } else if (types.contains('route')) {
  //             avenue = component['long_name'];
  //           }
  //         }

  //         setState(() {
  //           _extractedAddressData = {
  //             'ville': ville,
  //             'commune': commune,
  //             'quartier': quartier,
  //             'avenue': avenue,
  //           };
  //           _selectedGoogleAddress = result;
  //           _searchResults.clear();
  //           _searchAddressController.clear();
  //         });
  //       }
  //     }
  //   } catch (e) {
  //     print('Erreur lors de la sélection de l\'adresse: $e');
  //   }
  // }

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
          return {
            'latitude': location['lat'].toDouble(),
            'longitude': location['lng'].toDouble(),
          };
        }
      }
      throw Exception('Adresse introuvable');
    } catch (e) {
      throw Exception('Erreur lors de la récupération des coordonnées: $e');
    }
  }

  // Future<Map<String, String>> getAddressFromGoogleAPI(
  //     double lat, double lng) async {
  //   const apiKey = 'AIzaSyCpJzuEa7jLAcP8ub8AVM8flT2aK5cPdh0';
  //   final url =
  //       'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey&language=fr';

  //   try {
  //     final response = await http.get(Uri.parse(url));
  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);
  //       if (data['status'] == 'OK') {
  //         final results = data['results'];
  //         if (results.isNotEmpty) {
  //           final addressComponents = results[0]['address_components'];

  //           String ville = '';
  //           String commune = '';
  //           String quartier = '';
  //           String avenue = '';

  //           for (var component in addressComponents) {
  //             final types = component['types'] as List;
  //             if (types.contains('locality') ||
  //                 types.contains('administrative_area_level_1')) {
  //               ville = component['long_name'];
  //             } else if (types.contains('administrative_area_level_2')) {
  //               commune = component['long_name'];
  //             } else if (types.contains('sublocality') ||
  //                 types.contains('neighborhood')) {
  //               quartier = component['long_name'];
  //             } else if (types.contains('route')) {
  //               avenue = component['long_name'];
  //             }
  //           }

  //           return {
  //             'ville': ville,
  //             'commune': commune,
  //             'quartier': quartier,
  //             'avenue': avenue,
  //           };
  //         }
  //       }
  //     }
  //     return {};
  //   } catch (e) {
  //     return {};
  //   }
  // }

  Future<void> _initializeOrder() async {
    print('🚀 [AddressSelectionScreen] _initializeOrder - Début');
    print('   Selected Address: ${selectedAddress != null ? 'Oui' : 'Non'}');
    // print('   Extracted Address Data: ${_extractedAddressData.isNotEmpty ? 'Oui' : 'Non'}');
    // print('   Numero Controller: ${_numeroController.text.trim()}');
    
    // Vérifier qu'une adresse a été sélectionnée
    Map<String, dynamic>? addressToUse;
    double latitude = 0.0;
    double longitude = 0.0;

    if (selectedAddress != null) {
      print('📍 [AddressSelectionScreen] Utilisation de l\'adresse enregistrée');
      // Utiliser l'adresse enregistrée
      final address = selectedAddress as Map<String, dynamic>;
      latitude = address['latitude']?.toDouble() ?? 0.0;
      longitude = address['longitude']?.toDouble() ?? 0.0;

      if (latitude == 0.0 || longitude == 0.0) {
        try {
          String fullAddress =
              '${address['quartier']}, ${address['commune']}, ${address['ville']}, ${address['numero']}, RDC';
          final coordinates = await getCoordinatesFromGoogle(fullAddress);
          latitude = coordinates['latitude'] ?? 0.0;
          longitude = coordinates['longitude'] ?? 0.0;
        } catch (e) {
          print('Erreur lors de la récupération des coordonnées: $e');
        }
      }

      addressToUse = {
        "pays": address['pays'] ?? "RDC",
        "ville": address['ville'] ?? "",
        "commune": address['commune'] ?? "",
        "quartier": address['quartier'] ?? "",
        "avenue": address['avenue'] ?? "",
        "numero": address['numero'] ?? "",
        "codePostale": "012",
      };
    } 
    // else if (_extractedAddressData.isNotEmpty) {
    //   print('📍 [AddressSelectionScreen] Utilisation de l\'adresse recherchée');
    //   // Utiliser l'adresse recherchée
    //   if (_numeroController.text.trim().isEmpty) {
    //     print('❌ [AddressSelectionScreen] Numéro d\'adresse manquant');
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       const SnackBar(
    //         content: Text(
    //             'Veuillez entrer une référence d\'adresse (numéro, étage, etc.)'),
    //         backgroundColor: Colors.red,
    //       ),
    //     );
    //     return;
    //   }

    //   String fullAddress =
    //       '${_extractedAddressData['quartier']}, ${_extractedAddressData['commune']}, ${_extractedAddressData['ville']}, ${_numeroController.text.trim()}, RDC';
    //   print('🌐 [AddressSelectionScreen] Récupération des coordonnées pour: $fullAddress');
    //   final coordinates = await getCoordinatesFromGoogle(fullAddress);
    //   latitude = coordinates['latitude'] ?? 0.0;
    //   longitude = coordinates['longitude'] ?? 0.0;
    //   print('📍 [AddressSelectionScreen] Coordonnées obtenues: lat=$latitude, lng=$longitude');

    //   addressToUse = {
    //     "pays": "RDC",
    //     "ville": _extractedAddressData['ville'] ?? "",
    //     "commune": _extractedAddressData['commune'] ?? "",
    //     "quartier": _extractedAddressData['quartier'] ?? "",
    //     "avenue": _extractedAddressData['avenue'] ?? "",
    //     "numero": _numeroController.text.trim(),
    //     "codePostale": "012",
    //   };
    // } 
    else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une adresse'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (latitude == 0.0 || longitude == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'obtenir les coordonnées GPS. Veuillez réessayer.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Préparer les produits
    print('📦 [AddressSelectionScreen] Préparation des produits...');
    final productsToSend = widget.cartItems.map((item) {
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
    
    print('📦 [AddressSelectionScreen] Produits préparés: ${productsToSend.length}');
    print('   Products: $productsToSend');
    print('   Address: $addressToUse');
    print('   Coordinates: lat=$latitude, lng=$longitude');

    // Initialiser la commande
    print('🔄 [AddressSelectionScreen] Appel de initializeOrder...');
    await context.read<OrderCubit>().initializeOrder(
          products: productsToSend,
          latitude: latitude,
          longitude: longitude,
          address: addressToUse,
        );
    print('✅ [AddressSelectionScreen] initializeOrder appelé');
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrderCubit, OrderState>(
      listener: (context, state) {
        print('👂 [AddressSelectionScreen] Listener appelé');
        print('   isLoading: ${state.isLoading}');
        print('   success: ${state.success}');
        print('   error: ${state.error}');
        print('   _isProcessingRedirect: $_isProcessingRedirect');
        
        if (state.success && !_isProcessingRedirect) {
          print('✅ [AddressSelectionScreen] État success détecté - Début de la redirection');
          
          // Marquer comme en cours de traitement pour éviter les appels multiples
          _isProcessingRedirect = true;
          
          // Afficher un loader simple
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext dialogContext) {
              return WillPopScope(
                onWillPop: () async => false,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                ),
              );
            },
          );

          // Vider le panier
          print('🛒 [AddressSelectionScreen] Vidage du panier...');
          context.read<CartCubit>().clearCart();
          
          // Rafraîchir les commandes de manière asynchrone
          print('📥 [AddressSelectionScreen] Récupération des commandes...');
          context.read<OrderCubit>().fetchOrders(status: 'pending_payment').then((_) {
            print('✅ [AddressSelectionScreen] Commandes récupérées avec succès');
            
            // Fermer le loader si le contexte est encore monté
            if (context.mounted) {
              Navigator.of(context, rootNavigator: true).pop();
              print('🚪 [AddressSelectionScreen] Loader fermé');
            }
            
            // Naviguer vers l'écran de paiement en attente
            if (context.mounted) {
              print('🧭 [AddressSelectionScreen] Navigation vers PendingPaymentScreen...');
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const PendingPaymentScreen(),
                ),
                (route) => false,
              );
              print('✅ [AddressSelectionScreen] Navigation effectuée');
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Commande(s) initialisée(s) avec succès!'),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          }).catchError((error) {
            print('❌ [AddressSelectionScreen] Erreur lors de la récupération des commandes: $error');
            // Fermer le loader même en cas d'erreur
            if (context.mounted) {
              Navigator.of(context, rootNavigator: true).pop();
              // Naviguer quand même vers l'écran de paiement en attente
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const PendingPaymentScreen(),
                ),
                (route) => false,
              );
            }
          });
        } else if (state.error != null) {
          print('❌ [AddressSelectionScreen] Erreur détectée: ${state.error}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, orderState) {
        return StatefulBuilder(
          builder: (context, setStateButton) {
            return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sélectionner une adresse',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section des adresses enregistrées
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

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.bookmark,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Vos adresses enregistrées',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...snapshot.data!.docs.map((doc) {
                          final address =
                              doc.data() as Map<String, dynamic>;
                          final isSelected = selectedAddressId == doc.id;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withOpacity(0.08)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.grey.shade200,
                                width: isSelected ? 2.5 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ? AppColors.primary.withOpacity(0.15)
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
                                  print('📍 [AddressSelectionScreen] Adresse sélectionnée: ${doc.id}');
                                  setState(() {
                                    selectedAddress = {
                                      ...address,
                                      'id': doc.id,
                                    };
                                    selectedAddressId = doc.id;
                                    print('📍 [AddressSelectionScreen] selectedAddress mis à jour: ${selectedAddress != null ? 'Oui' : 'Non'}');
                                    print('📍 [AddressSelectionScreen] selectedAddressId: $selectedAddressId');
                                  });
                                  // Forcer la mise à jour du bouton via StatefulBuilder
                                  setStateButton(() {});
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.primary
                                              : Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          isSelected
                                              ? Icons.check_circle
                                              : Icons.location_on_rounded,
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.grey.shade600,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${address['avenue'] ?? ''}, ${address['numero'] ?? ''}',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: isSelected
                                                    ? AppColors.primary
                                                    : Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.location_city,
                                                  size: 14,
                                                  color: Colors.grey.shade500,
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    '${address['quartier'] ?? ''}, ${address['commune'] ?? ''}',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.public,
                                                  size: 14,
                                                  color: Colors.grey.shade500,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${address['ville'] ?? ''}, ${address['pays'] ?? 'RDC'}',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            shape: BoxShape.circle,
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
                        }).toList(),
                        const SizedBox(height: 32),
                      ],
                    );
                  },
                ),

                // Section recherche d'adresse
                // Row(
                //   children: [
                //     Container(
                //       padding: const EdgeInsets.all(8),
                //       decoration: BoxDecoration(
                //         color: AppColors.primary.withOpacity(0.1),
                //         borderRadius: BorderRadius.circular(8),
                //       ),
                //       child: Icon(
                //         Icons.search,
                //         color: AppColors.primary,
                //         size: 20,
                //       ),
                //     ),
                //     const SizedBox(width: 12),
                //     const Text(
                //       'Rechercher une nouvelle adresse',
                //       style: TextStyle(
                //         fontSize: 20,
                //         fontWeight: FontWeight.bold,
                //         color: Colors.black87,
                //       ),
                //     ),
                //   ],
                // ),
                // const SizedBox(height: 16),

                // // Bouton utiliser position actuelle
                // Container(
                //   width: double.infinity,
                //   height: 56,
                //   decoration: BoxDecoration(
                //     gradient: _isGettingCurrentLocation
                //         ? null
                //         : LinearGradient(
                //             colors: [
                //               AppColors.primary,
                //               AppColors.primary.withOpacity(0.8),
                //             ],
                //           ),
                //     color: _isGettingCurrentLocation
                //         ? Colors.grey.shade200
                //         : null,
                //     borderRadius: BorderRadius.circular(14),
                //     boxShadow: _isGettingCurrentLocation
                //         ? null
                //         : [
                //             BoxShadow(
                //               color: AppColors.primary.withOpacity(0.3),
                //               blurRadius: 8,
                //               offset: const Offset(0, 4),
                //             ),
                //           ],
                //   ),
                //   child: Material(
                //     color: Colors.transparent,
                //     child: InkWell(
                //       borderRadius: BorderRadius.circular(14),
                //       onTap: _isGettingCurrentLocation
                //           ? null
                //           : () async {
                //             setState(() {
                //               _isGettingCurrentLocation = true;
                //             });

                //             try {
                //               LocationPermission permission =
                //                   await Geolocator.checkPermission();
                //               if (permission == LocationPermission.denied) {
                //                 permission =
                //                     await Geolocator.requestPermission();
                //                 if (permission == LocationPermission.denied) {
                //                   setState(() {
                //                     _isGettingCurrentLocation = false;
                //                   });
                //                   ScaffoldMessenger.of(context).showSnackBar(
                //                     const SnackBar(
                //                       content: Text(
                //                           'Permission de localisation refusée'),
                //                       backgroundColor: Colors.red,
                //                     ),
                //                   );
                //                   return;
                //                 }
                //               }

                //               if (permission ==
                //                   LocationPermission.deniedForever) {
                //                 setState(() {
                //                   _isGettingCurrentLocation = false;
                //                 });
                //                 ScaffoldMessenger.of(context).showSnackBar(
                //                   const SnackBar(
                //                     content: Text(
                //                         'Permission de localisation refusée définitivement'),
                //                     backgroundColor: Colors.red,
                //                   ),
                //                 );
                //                 return;
                //               }

                //               Position position =
                //                   await Geolocator.getCurrentPosition(
                //                 desiredAccuracy: LocationAccuracy.high,
                //               );

                //               final addressData = await getAddressFromGoogleAPI(
                //                 position.latitude,
                //                 position.longitude,
                //               );

                //               if (addressData.isEmpty) {
                //                 setState(() {
                //                   _isGettingCurrentLocation = false;
                //                 });
                //                 ScaffoldMessenger.of(context).showSnackBar(
                //                   const SnackBar(
                //                     content: Text(
                //                         'Impossible d\'extraire l\'adresse depuis votre position actuelle.'),
                //                     backgroundColor: Colors.orange,
                //                   ),
                //                 );
                //                 return;
                //               }

                //               setState(() {
                //                 _extractedAddressData = addressData;
                //                 selectedAddress = null;
                //                 selectedAddressId = null;
                //                 _isGettingCurrentLocation = false;
                //               });

                //               ScaffoldMessenger.of(context).showSnackBar(
                //                 const SnackBar(
                //                   content: Text(
                //                       'Position actuelle utilisée avec succès !'),
                //                   backgroundColor: Colors.green,
                //                 ),
                //               );
                //             } catch (e) {
                //               setState(() {
                //                 _isGettingCurrentLocation = false;
                //               });
                //               ScaffoldMessenger.of(context).showSnackBar(
                //                 SnackBar(
                //                   content: Text(
                //                       'Erreur lors de la récupération de la position: $e'),
                //                   backgroundColor: Colors.red,
                //                 ),
                //               );
                //             }
                //           },
                //       child: Padding(
                //         padding: const EdgeInsets.symmetric(horizontal: 16),
                //         child: Row(
                //           mainAxisAlignment: MainAxisAlignment.center,
                //           children: [
                //             _isGettingCurrentLocation
                //                 ? const EcommerceLoading.inline(color: Colors.white)
                //                 : const Icon(
                //                     Icons.location_on_rounded,
                //                     color: Colors.white,
                //                     size: 22,
                //                   ),
                //             const SizedBox(width: 12),
                //             Text(
                //               _isGettingCurrentLocation
                //                   ? 'Récupération en cours...'
                //                   : 'Utiliser ma position actuelle',
                //               style: const TextStyle(
                //                 color: Colors.white,
                //                 fontWeight: FontWeight.bold,
                //                 fontSize: 15,
                //               ),
                //             ),
                //           ],
                //         ),
                //       ),
                //     ),
                //   ),
                // ),
                // const SizedBox(height: 16),

                // // Champ de recherche
                // Container(
                //   decoration: BoxDecoration(
                //     borderRadius: BorderRadius.circular(14),
                //     boxShadow: [
                //       BoxShadow(
                //         color: Colors.black.withOpacity(0.05),
                //         blurRadius: 8,
                //         offset: const Offset(0, 2),
                //       ),
                //     ],
                //   ),
                //   child: TextFormField(
                //     controller: _searchAddressController,
                //     focusNode: _searchFocusNode,
                //     enabled: !_isGettingCurrentLocation,
                //     decoration: InputDecoration(
                //       labelText: 'Rechercher une adresse',
                //       hintText: 'Ex: Kinshasa, Lemba, Avenue du Commerce...',
                //       prefixIcon: Icon(
                //         Icons.search_rounded,
                //         color: AppColors.primary,
                //       ),
                //       suffixIcon: _isSearching
                //           ? const Padding(
                //               padding: EdgeInsets.all(8.0),
                //               child: EcommerceLoading.inline(),
                //             )
                //           : _searchResults.isNotEmpty
                //               ? IconButton(
                //                   icon: Icon(
                //                     Icons.clear_rounded,
                //                     color: Colors.grey.shade600,
                //                   ),
                //                   onPressed: () {
                //                     setState(() {
                //                       _searchResults.clear();
                //                       _searchAddressController.clear();
                //                     });
                //                   },
                //                 )
                //               : null,
                //       border: OutlineInputBorder(
                //         borderRadius: BorderRadius.circular(14),
                //         borderSide: BorderSide(color: Colors.grey.shade300),
                //       ),
                //       enabledBorder: OutlineInputBorder(
                //         borderRadius: BorderRadius.circular(14),
                //         borderSide: BorderSide(color: Colors.grey.shade300),
                //       ),
                //       focusedBorder: OutlineInputBorder(
                //         borderRadius: BorderRadius.circular(14),
                //         borderSide: BorderSide(
                //           color: AppColors.primary,
                //           width: 2,
                //         ),
                //       ),
                //       filled: true,
                //       fillColor: Colors.white,
                //       contentPadding: const EdgeInsets.symmetric(
                //         horizontal: 16,
                //         vertical: 16,
                //       ),
                //     ),
                //   ),
                // ),

                // // Résultats de recherche
                // if (_searchResults.isNotEmpty)
                //   Container(
                //     margin: const EdgeInsets.only(top: 12),
                //     constraints: const BoxConstraints(maxHeight: 250),
                //     decoration: BoxDecoration(
                //       color: Colors.white,
                //       borderRadius: BorderRadius.circular(12),
                //       border: Border.all(color: Colors.grey.shade300),
                //       boxShadow: [
                //         BoxShadow(
                //           color: Colors.black.withOpacity(0.1),
                //           blurRadius: 4,
                //           offset: const Offset(0, 2),
                //         ),
                //       ],
                //     ),
                //     child: ListView.builder(
                //       shrinkWrap: true,
                //       itemCount: _searchResults.length,
                //       itemBuilder: (context, index) {
                //         final result = _searchResults[index];
                //         final isSelected = _selectedGoogleAddress != null &&
                //             _selectedGoogleAddress!['place_id'] ==
                //                 result['place_id'];
                //         return Container(
                //           margin: const EdgeInsets.only(bottom: 8),
                //           decoration: BoxDecoration(
                //             color: isSelected
                //                 ? AppColors.primary.withOpacity(0.08)
                //                 : Colors.white,
                //             borderRadius: BorderRadius.circular(12),
                //             border: Border.all(
                //               color: isSelected
                //                   ? AppColors.primary
                //                   : Colors.grey.shade200,
                //               width: isSelected ? 2 : 1,
                //             ),
                //           ),
                //           child: Material(
                //             color: Colors.transparent,
                //             child: InkWell(
                //               borderRadius: BorderRadius.circular(12),
                //               onTap: () {
                //                 setState(() {
                //                   selectedAddress = null;
                //                   selectedAddressId = null;
                //                 });
                //                 _selectAddress(result);
                //               },
                //               child: Padding(
                //                 padding: const EdgeInsets.all(16),
                //                 child: Row(
                //                   children: [
                //                     Icon(
                //                       Icons.location_on,
                //                       color: isSelected
                //                           ? AppColors.primary
                //                           : Colors.grey.shade600,
                //                       size: 20,
                //                     ),
                //                     const SizedBox(width: 12),
                //                     Expanded(
                //                       child: Text(
                //                         result['description'] ?? '',
                //                         style: TextStyle(
                //                           fontSize: 14,
                //                           fontWeight: isSelected
                //                               ? FontWeight.w600
                //                               : FontWeight.w500,
                //                           color: isSelected
                //                               ? AppColors.primary
                //                               : Colors.black87,
                //                         ),
                //                         maxLines: 2,
                //                         overflow: TextOverflow.ellipsis,
                //                       ),
                //                     ),
                //                   ],
                //                 ),
                //               ),
                //             ),
                //           ),
                //         );
                //       },
                //     ),
                //   ),

                // // Affichage de l'adresse sélectionnée
                // if (_extractedAddressData.isNotEmpty &&
                //     _selectedGoogleAddress != null)
                //   Container(
                //     margin: const EdgeInsets.only(top: 16),
                //     padding: const EdgeInsets.all(20),
                //     decoration: BoxDecoration(
                //       gradient: LinearGradient(
                //         colors: [
                //           AppColors.primary.withOpacity(0.1),
                //           AppColors.primary.withOpacity(0.05),
                //         ],
                //         begin: Alignment.topLeft,
                //         end: Alignment.bottomRight,
                //       ),
                //       borderRadius: BorderRadius.circular(16),
                //       border: Border.all(
                //         color: AppColors.primary,
                //         width: 2,
                //       ),
                //       boxShadow: [
                //         BoxShadow(
                //           color: AppColors.primary.withOpacity(0.1),
                //           blurRadius: 8,
                //           offset: const Offset(0, 4),
                //         ),
                //       ],
                //     ),
                //     child: Column(
                //       crossAxisAlignment: CrossAxisAlignment.start,
                //       children: [
                //         Row(
                //           children: [
                //             Container(
                //               padding: const EdgeInsets.all(8),
                //               decoration: BoxDecoration(
                //                 color: AppColors.primary,
                //                 borderRadius: BorderRadius.circular(8),
                //               ),
                //               child: const Icon(
                //                 Icons.check_circle,
                //                 color: Colors.white,
                //                 size: 20,
                //               ),
                //             ),
                //             const SizedBox(width: 12),
                //             const Text(
                //               'Adresse sélectionnée',
                //               style: TextStyle(
                //                 fontWeight: FontWeight.bold,
                //                 fontSize: 16,
                //                 color: AppColors.primary,
                //               ),
                //             ),
                //           ],
                //         ),
                //         const SizedBox(height: 16),
                //         Container(
                //           padding: const EdgeInsets.all(12),
                //           decoration: BoxDecoration(
                //             color: Colors.white,
                //             borderRadius: BorderRadius.circular(12),
                //           ),
                //           child: Column(
                //             crossAxisAlignment: CrossAxisAlignment.start,
                //             children: [
                //               Row(
                //                 children: [
                //                   Icon(
                //                     Icons.location_on_rounded,
                //                     size: 16,
                //                     color: Colors.grey.shade600,
                //                   ),
                //                   const SizedBox(width: 8),
                //                   Expanded(
                //                     child: Text(
                //                       '${_extractedAddressData['avenue'] ?? ''}, ${_extractedAddressData['quartier'] ?? ''}',
                //                       style: TextStyle(
                //                         fontSize: 14,
                //                         fontWeight: FontWeight.w600,
                //                         color: Colors.grey.shade800,
                //                       ),
                //                     ),
                //                   ),
                //                 ],
                //               ),
                //               const SizedBox(height: 4),
                //               Padding(
                //                 padding: const EdgeInsets.only(left: 24),
                //                 child: Text(
                //                   '${_extractedAddressData['commune'] ?? ''}, ${_extractedAddressData['ville'] ?? ''}',
                //                   style: TextStyle(
                //                     fontSize: 13,
                //                     color: Colors.grey.shade600,
                //                   ),
                //                 ),
                //               ),
                //             ],
                //           ),
                //         ),
                //         const SizedBox(height: 16),
                //         TextFormField(
                //           controller: _numeroController,
                //           decoration: InputDecoration(
                //             labelText: 'Référence de l\'adresse *',
                //             hintText: 'Numéro, étage, référence...',
                //             prefixIcon: Icon(
                //               Icons.home_work_rounded,
                //               color: AppColors.primary,
                //             ),
                //             border: OutlineInputBorder(
                //               borderRadius: BorderRadius.circular(12),
                //               borderSide: BorderSide(color: Colors.grey.shade300),
                //             ),
                //             enabledBorder: OutlineInputBorder(
                //               borderRadius: BorderRadius.circular(12),
                //               borderSide: BorderSide(color: Colors.grey.shade300),
                //             ),
                //             focusedBorder: OutlineInputBorder(
                //               borderRadius: BorderRadius.circular(12),
                //               borderSide: BorderSide(
                //                 color: AppColors.primary,
                //                 width: 2,
                //               ),
                //             ),
                //             filled: true,
                //             fillColor: Colors.white,
                //             contentPadding: const EdgeInsets.symmetric(
                //               horizontal: 16,
                //               vertical: 16,
                //             ),
                //           ),
                //         ),
                //       ],
                //     ),
                //   ),

                const SizedBox(height: 32),
              ],
            ),
          ),
          // Bouton SUIVANT fixe en bas
          bottomNavigationBar: BlocBuilder<OrderCubit, OrderState>(
            builder: (context, currentOrderState) {
              // Le bouton est toujours actif sauf pendant le chargement
              final isButtonEnabled = !currentOrderState.isLoading && !_isProcessingRedirect;
              
              print('🔘 [AddressSelectionScreen] Bouton - isLoading: ${currentOrderState.isLoading}, enabled: $isButtonEnabled');
              
              return Container(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: MediaQuery.of(context).padding.bottom + 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isButtonEnabled
                        ? () {
                            print('🔘 [AddressSelectionScreen] Bouton SUIVANT cliqué');
                            print('🔘 [AddressSelectionScreen] selectedAddress: ${selectedAddress != null ? 'Oui' : 'Non'}');
                            print('🔘 [AddressSelectionScreen] selectedAddressId: $selectedAddressId');
                            
                            // Vérifier si une adresse est sélectionnée avant de continuer
                            if (selectedAddress == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Veuillez sélectionner une adresse de livraison'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }
                            
                            _initializeOrder();
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey.shade600,
                      elevation: 2,
                      shadowColor: AppColors.primary.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: currentOrderState.isLoading
                        ? const EcommerceLoading.inline(color: Colors.white)
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'SUIVANT',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 20),
                            ],
                          ),
                  ),
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
}


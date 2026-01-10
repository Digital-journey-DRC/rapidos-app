import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:immo/constants.dart';
import 'package:immo/cubit/auth_cubit.dart';
import 'package:immo/cubit/order_cubit.dart';
import 'package:immo/cubit/cart_cubit.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
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
  final TextEditingController _searchAddressController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Map<String, dynamic>> _searchResults = [];
  Timer? _searchDebounceTimer;
  bool _isSearching = false;
  bool _isGettingCurrentLocation = false;

  // Variable pour suivre l'adresse sélectionnée depuis Google
  Map<String, dynamic>? _selectedGoogleAddress;

  // Variable pour stocker les données extraites de manière persistante
  Map<String, String> _extractedAddressData = {};

  // Contrôleur pour le champ détail adresse
  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _refAdresseController = TextEditingController();

  // Variable pour stocker l'adresse sélectionnée
  Map<String, dynamic>? selectedAddress;
  String? selectedAddressId;
  
  // Flag pour éviter les appels multiples du listener
  bool _isProcessingRedirect = false;
  // Flag local pour gérer le chargement du bouton
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    _searchAddressController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchAddressController.dispose();
    _searchFocusNode.dispose();
    _numeroController.dispose();
    _refAdresseController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchAddressController.text.trim();
    
    // Si le texte est vide, effacer les résultats immédiatement
    if (query.isEmpty) {
      _searchDebounceTimer?.cancel();
      setState(() {
        _searchResults.clear();
        _isSearching = false;
      });
      return;
    }
    
    // Annuler la recherche précédente
    _searchDebounceTimer?.cancel();
    
    // Debounce simple
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted && _searchAddressController.text.trim() == query && query.isNotEmpty) {
        _searchAddress(query);
      }
    });
  }

  Future<void> _searchAddress(String query) async {
    if (!mounted || query.isEmpty) return;
    
    setState(() {
      _isSearching = true;
    });
    
    const apiKey = 'AIzaSyCpJzuEa7jLAcP8ub8AVM8flT2aK5cPdh0';
    final url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(query)}&key=$apiKey&components=country:cd&language=fr&types=geocode|establishment';

    try {
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('La recherche a pris trop de temps');
        },
      );
      
      if (!mounted) return;
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List? ?? [];
          setState(() {
            _searchResults = List<Map<String, dynamic>>.from(
              predictions.map((prediction) => {
                'description': prediction['description'],
                'place_id': prediction['place_id'],
              }),
            );
            _isSearching = false;
          });
        } else {
          setState(() {
            _searchResults = [];
            _isSearching = false;
          });
        }
      } else {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _selectAddress(Map<String, dynamic> result) async {
    const apiKey = 'AIzaSyCpJzuEa7jLAcP8ub8AVM8flT2aK5cPdh0';
    final url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=${result['place_id']}&key=$apiKey&language=fr';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          final resultData = data['result'];
          final addressComponents = resultData['address_components'] as List;
          final location = resultData['geometry']['location'];

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

          setState(() {
            _extractedAddressData = {
              'ville': ville,
              'commune': commune,
              'quartier': quartier,
              'avenue': avenue,
            };
            _selectedGoogleAddress = result;
            _searchResults.clear();
            _searchAddressController.clear();
          });

          // Sauvegarder l'adresse avec coordonnées
          await _saveAddressFromGoogle(
            ville,
            commune,
            quartier,
            avenue,
            location['lat'].toDouble(),
            location['lng'].toDouble(),
            result['description'],
            isFromCurrentLocation: false,
          );
        }
      }
    } catch (e) {
      print('Erreur lors de la sélection de l\'adresse: $e');
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

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingCurrentLocation = true;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isGettingCurrentLocation = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Permission de localisation refusée'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isGettingCurrentLocation = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permission de localisation refusée définitivement'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Obtenir l'adresse depuis les coordonnées
      final addressData = await getAddressFromGoogleAPI(
        position.latitude,
        position.longitude,
      );

      if (addressData.isNotEmpty) {
        // Sauvegarder l'adresse avec coordonnées
        await _saveAddressFromGoogle(
          addressData['ville'] ?? '',
          addressData['commune'] ?? '',
          addressData['quartier'] ?? '',
          addressData['avenue'] ?? '',
          position.latitude,
          position.longitude,
          '',
          isFromCurrentLocation: true,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible de récupérer l\'adresse depuis la position'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('Erreur lors de la récupération de la position: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGettingCurrentLocation = false;
        });
      }
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

            return {
              'ville': ville,
              'commune': commune,
              'quartier': quartier,
              'avenue': avenue,
            };
          }
        }
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  Future<void> _saveAddressFromGoogle(
    String ville,
    String commune,
    String quartier,
    String avenue,
    double latitude,
    double longitude,
    String fullAddress, {
    bool isFromCurrentLocation = false,
  }) async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthSuccess || authState.user == null) {
      return;
    }

    // Afficher un dialog pour demander le numéro et la référence
    final TextEditingController numeroController = TextEditingController();
    final TextEditingController refAdresseController = TextEditingController();

    final shouldSave = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.location_on, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Compléter l\'adresse'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$avenue, $quartier, $commune, $ville',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: refAdresseController,
                  decoration: const InputDecoration(
                    labelText: 'Référence de l\'adresse',
                    hintText: 'Ex: Près du marché, en face de...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.info_outline),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );

    if (shouldSave != true || !mounted) {
      return;
    }

    final userId = authState.user!['id']?.toString() ?? '';
    final userName =
        '${authState.user!['firstName'] ?? ''} ${authState.user!['lastName'] ?? ''}'.trim();

    // Variable pour stocker le dialog du loader
    BuildContext? loaderContext;

    try {
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            loaderContext = dialogContext;
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        );
      }

      final docRef = await FirebaseFirestore.instance
          .collection('delivery_addresses')
          .add({
        'timestamp': FieldValue.serverTimestamp(),
        'userId': userId,
        'userName': userName,
        'ville': ville,
        'commune': commune,
        'quartier': quartier,
        'avenue': avenue,
        'numero': numeroController.text.trim(),
        'refAdresse': refAdresseController.text.trim(),
        'pays': 'RDC',
        'phone': authState.user!['phone'] ?? '',
        'latitude': latitude,
        'longitude': longitude,
        'fullAddress': fullAddress.isNotEmpty ? fullAddress : '$quartier, $commune, $ville',
        'source': 'google',
      });

      // Récupérer l'adresse créée
      final addressDoc = await docRef.get();
      final addressData = addressDoc.data() as Map<String, dynamic>;
      final addressId = addressDoc.id;

      // Fermer le loader AVANT d'afficher le dialogue de confirmation
      if (context.mounted && loaderContext != null) {
        Navigator.of(loaderContext!).pop();
        loaderContext = null;
      }

      // Attendre un peu pour s'assurer que le loader est bien fermé
      await Future.delayed(const Duration(milliseconds: 100));

      // Demander confirmation
      if (context.mounted) {
        _showAddressConfirmationDialog(
          context,
          addressId,
          addressData,
        );
      }
    } catch (e) {
      // Fermer le loader en cas d'erreur
      if (context.mounted && loaderContext != null) {
        Navigator.of(loaderContext!).pop();
        loaderContext = null;
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  // Widget affiché quand aucune adresse n'est trouvée
  Widget _buildNoAddressWidget(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.orange.shade200,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.location_off_outlined,
                size: 36,
                color: Colors.orange.shade700,
              ),
              const SizedBox(height: 12),
              const Text(
                'Aucune adresse de livraison trouvée',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Créez une adresse de livraison pour continuer votre commande.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        // Recherche d'adresse Google
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.search, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Text(
                    'Rechercher une adresse',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchAddressController,
                focusNode: _searchFocusNode,
                onSubmitted: (value) {
                  // Si l'utilisateur appuie sur Entrée et qu'il y a du texte, rechercher
                  if (value.trim().isNotEmpty) {
                    setState(() {
                      _isSearching = true;
                    });
                    _searchAddress(value.trim());
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Tapez une adresse...',
                  prefixIcon: const Icon(Icons.location_on),
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _searchAddressController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchAddressController.clear();
                                setState(() {
                                  _searchResults.clear();
                                });
                              },
                            )
                          : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              if (_searchResults.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _searchResults.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.grey.shade100,
                      indent: 48,
                    ),
                    itemBuilder: (context, index) {
                      final result = _searchResults[index];
                      final description = result['description']?.toString() ?? '';
                      // Séparer l'adresse principale et les détails
                      final parts = description.split(', ');
                      final mainAddress = parts.isNotEmpty ? parts[0] : description;
                      final details = parts.length > 1 ? parts.sublist(1).join(', ') : '';
                      
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _selectAddress(result),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.place,
                                    color: AppColors.primary,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        mainAddress,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (details.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          details,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 14,
                                  color: Colors.grey.shade400,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Bouton position actuelle
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isGettingCurrentLocation ? null : _getCurrentLocation,
            icon: _isGettingCurrentLocation
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
            label: Text(_isGettingCurrentLocation
                ? 'Récupération de la position...'
                : 'Utiliser ma position actuelle'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Divider avec "OU"
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey.shade300)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'OU',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey.shade300)),
          ],
        ),
        const SizedBox(height: 12),
        // Bouton créer manuellement
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showCreateAddressDialog(context),
            icon: const Icon(Icons.add_location_alt),
            label: const Text('Créer une adresse manuellement'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Widget pour le bouton "Ajouter une nouvelle adresse" (quand des adresses existent)
  Widget _buildAddNewAddressButton(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête section actions
        Container(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.add_location_alt_rounded,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Ajouter une adresse',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        
        // Recherche d'adresse Google - Design compact
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.search_rounded,
                      color: AppColors.primary,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Rechercher',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _searchAddressController,
                focusNode: _searchFocusNode,
                autofocus: false,
                decoration: InputDecoration(
                  hintText: 'Rechercher une adresse...',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  suffixIcon: _isSearching
                      ? Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          ),
                        )
                      : _searchAddressController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                size: 18,
                                color: Colors.grey.shade600,
                              ),
                              onPressed: () {
                                _searchAddressController.clear();
                                setState(() {
                                  _searchResults.clear();
                                  _isSearching = false;
                                });
                              },
                            )
                          : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                style: const TextStyle(fontSize: 14),
              ),
              if (_searchResults.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _searchResults.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.grey.shade100,
                      indent: 48,
                    ),
                    itemBuilder: (context, index) {
                      final result = _searchResults[index];
                      final description = result['description']?.toString() ?? '';
                      // Séparer l'adresse principale et les détails
                      final parts = description.split(', ');
                      final mainAddress = parts.isNotEmpty ? parts[0] : description;
                      final details = parts.length > 1 ? parts.sublist(1).join(', ') : '';
                      
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _selectAddress(result),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.place,
                                    color: AppColors.primary,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        mainAddress,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (details.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          details,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 14,
                                  color: Colors.grey.shade400,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        
        // Boutons d'action rapides - Design compact en ligne
        Row(
          children: [
            // Bouton position actuelle
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isGettingCurrentLocation ? null : _getCurrentLocation,
                icon: _isGettingCurrentLocation
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      )
                    : Icon(Icons.my_location_rounded, size: 18, color: AppColors.primary),
                label: Text(
                  _isGettingCurrentLocation
                      ? 'Chargement...'
                      : 'Position actuelle',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: AppColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Bouton créer manuellement
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showCreateAddressDialog(context),
                icon: Icon(Icons.add_rounded, size: 18, color: AppColors.primary),
                label: const Text(
                  'Créer manuellement',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: AppColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Affiche le dialogue de création d'adresse
  Future<void> _showCreateAddressDialog(BuildContext context) async {
    final TextEditingController villeController = TextEditingController();
    final TextEditingController communeController = TextEditingController();
    final TextEditingController quartierController = TextEditingController();
    final TextEditingController avenueController = TextEditingController();
    final TextEditingController numeroController = TextEditingController();
    final TextEditingController refAdresseController = TextEditingController();
    final TextEditingController paysController = TextEditingController(text: 'RDC');

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.add_location_alt, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Nouvelle adresse'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: paysController,
                  decoration: const InputDecoration(
                    labelText: 'Pays',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.flag),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: villeController,
                  decoration: const InputDecoration(
                    labelText: 'Ville *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_city),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: communeController,
                  decoration: const InputDecoration(
                    labelText: 'Commune *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: quartierController,
                  decoration: const InputDecoration(
                    labelText: 'Quartier *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.home),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: avenueController,
                  decoration: const InputDecoration(
                    labelText: 'Avenue',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.streetview),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: numeroController,
                  decoration: const InputDecoration(
                    labelText: 'Numéro',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.numbers),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: refAdresseController,
                  decoration: const InputDecoration(
                    labelText: 'Référence de l\'adresse',
                    hintText: 'Ex: Près du marché, en face de...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.info_outline),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (villeController.text.trim().isEmpty ||
                    communeController.text.trim().isEmpty ||
                    quartierController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez remplir les champs obligatoires (*)'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                Navigator.pop(context);
                _createAddress(
                  context,
                  villeController.text.trim(),
                  communeController.text.trim(),
                  quartierController.text.trim(),
                  avenueController.text.trim(),
                  numeroController.text.trim(),
                  paysController.text.trim(),
                  refAdresseController.text.trim(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Créer'),
            ),
          ],
        );
      },
    );
  }

  // Crée une adresse dans Firestore
  Future<void> _createAddress(
    BuildContext context,
    String ville,
    String commune,
    String quartier,
    String avenue,
    String numero,
    String pays,
    String refAdresse,
  ) async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthSuccess || authState.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur: Utilisateur non connecté'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final userId = authState.user!['id']?.toString() ?? '';
    final userName =
        '${authState.user!['firstName'] ?? ''} ${authState.user!['lastName'] ?? ''}'.trim();

    // Variable pour stocker le dialog du loader
    BuildContext? loaderContext;
    
    try {
      // Afficher un loader
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            loaderContext = dialogContext;
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        );
      }

      final docRef = await FirebaseFirestore.instance
          .collection('delivery_addresses')
          .add({
        'timestamp': FieldValue.serverTimestamp(),
        'userId': userId,
        'userName': userName,
        'ville': ville,
        'commune': commune,
        'quartier': quartier,
        'avenue': avenue,
        'numero': numero,
        'refAdresse': refAdresse,
        'pays': pays,
        'phone': authState.user!['phone'] ?? '',
        'latitude': 0.0,
        'longitude': 0.0,
      });

      // Récupérer l'adresse créée
      final addressDoc = await docRef.get();
      final addressData = addressDoc.data() as Map<String, dynamic>;
      final addressId = addressDoc.id;

      // Fermer le loader AVANT d'afficher le dialogue de confirmation
      if (context.mounted && loaderContext != null) {
        Navigator.of(loaderContext!).pop();
        loaderContext = null;
      }

      // Attendre un peu pour s'assurer que le loader est bien fermé
      await Future.delayed(const Duration(milliseconds: 100));

      // Afficher le dialogue de confirmation
      if (context.mounted) {
        _showAddressConfirmationDialog(
          context,
          addressId,
          addressData,
        );
      }
    } catch (e) {
      // Fermer le loader en cas d'erreur
      if (context.mounted && loaderContext != null) {
        Navigator.of(loaderContext!).pop();
        loaderContext = null;
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la création: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Affiche le dialogue de confirmation pour utiliser l'adresse ou en créer une autre
  Future<void> _showAddressConfirmationDialog(
    BuildContext context,
    String addressId,
    Map<String, dynamic> addressData,
  ) async {
    final addressString =
        '${addressData['quartier'] ?? ''}, ${addressData['commune'] ?? ''}, ${addressData['ville'] ?? ''}';

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.green),
              SizedBox(width: 8),
              Text('Adresse créée'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Votre adresse a été créée avec succès !',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  addressString,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Voulez-vous utiliser cette adresse pour votre commande ?',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Créer une autre adresse'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Utiliser cette adresse'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      // Utiliser l'adresse créée
      setState(() {
        selectedAddress = {
          ...addressData,
          'id': addressId,
        };
        selectedAddressId = addressId;
        // Réinitialiser le flag pour permettre une nouvelle initialisation
        _isProcessingRedirect = false;
        _isInitializing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adresse sélectionnée avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (result == false) {
      // Créer une autre adresse
      _showCreateAddressDialog(context);
    }
  }

  Future<void> _initializeOrder() async {
    // Empêcher les appels multiples
    if (_isInitializing) {
      print('⚠️ [AddressSelectionScreen] Initialisation déjà en cours');
      return;
    }
    
    setState(() {
      _isInitializing = true;
    });
    
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
          print('🌐 [AddressSelectionScreen] Récupération des coordonnées pour: $fullAddress');
          final coordinates = await getCoordinatesFromGoogle(fullAddress);
          latitude = coordinates['latitude'] ?? 0.0;
          longitude = coordinates['longitude'] ?? 0.0;
          print('📍 [AddressSelectionScreen] Coordonnées obtenues: lat=$latitude, lng=$longitude');
          
          if (latitude == 0.0 || longitude == 0.0) {
            print('⚠️ [AddressSelectionScreen] Les coordonnées sont toujours à 0.0 après récupération');
          }
        } catch (e) {
          print('❌ [AddressSelectionScreen] Erreur lors de la récupération des coordonnées: $e');
          // Ne pas bloquer, continuer avec les coordonnées à 0.0
          // Le code suivant vérifiera et affichera un message d'erreur approprié
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
      setState(() {
        _isInitializing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une adresse'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (latitude == 0.0 || longitude == 0.0) {
      setState(() {
        _isInitializing = false;
      });
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
    try {
      await context.read<OrderCubit>().initializeOrder(
            products: productsToSend,
            latitude: latitude,
            longitude: longitude,
            address: addressToUse,
          );
      print('✅ [AddressSelectionScreen] initializeOrder appelé');
    } catch (e) {
      print('❌ [AddressSelectionScreen] Erreur lors de l\'initialisation: $e');
      // Réinitialiser le loader en cas d'erreur
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'initialisation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
        
        // Gérer le succès - navigation directe sans fetchOrders supplémentaire
        if (state.success && !_isProcessingRedirect && !state.isLoading) {
          print('✅ [AddressSelectionScreen] État success détecté - Navigation directe');
          
          // Marquer comme en cours de traitement pour éviter les appels multiples
          _isProcessingRedirect = true;
          
          // Réinitialiser le flag local
          if (mounted) {
            setState(() {
              _isInitializing = false;
            });
          }
          
          // Vider le panier
          print('🛒 [AddressSelectionScreen] Vidage du panier...');
          context.read<CartCubit>().clearCart();
          
          // Naviguer directement vers l'écran de paiement en attente
          // L'écran suivant chargera les commandes lui-même
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
          }
        }
        
        // Gérer les erreurs
        if (state.error != null) {
          print('❌ [AddressSelectionScreen] Erreur détectée: ${state.error}');
          // Réinitialiser le flag pour permettre une nouvelle tentative
          _isProcessingRedirect = false;
          if (mounted) {
            setState(() {
              _isInitializing = false;
            });
          }
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: Colors.red,
              ),
            );
          }
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      // Aucune adresse trouvée - proposer d'en créer une
                      return _buildNoAddressWidget(context);
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // En-tête de section compact
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.bookmark_rounded,
                                  color: AppColors.primary,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Adresses enregistrées',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Liste des adresses (limité aux 2 premières)
                        ...snapshot.data!.docs.take(2).map((doc) {
                          final address =
                              doc.data() as Map<String, dynamic>;
                          final isSelected = selectedAddressId == doc.id;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withOpacity(0.08)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.grey.shade200,
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ? AppColors.primary.withOpacity(0.1)
                                      : Colors.black.withOpacity(0.03),
                                  blurRadius: isSelected ? 6 : 2,
                                  offset: const Offset(0, 2),
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  print('📍 [AddressSelectionScreen] Adresse sélectionnée: ${doc.id}');
                                  setState(() {
                                    selectedAddress = {
                                      ...address,
                                      'id': doc.id,
                                    };
                                    selectedAddressId = doc.id;
                                    _isProcessingRedirect = false;
                                    _isInitializing = false;
                                  });
                                  setStateButton(() {});
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.primary
                                              : AppColors.primary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          isSelected
                                              ? Icons.check_circle_rounded
                                              : Icons.location_on_rounded,
                                          color: isSelected
                                              ? Colors.white
                                              : AppColors.primary,
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
                                              '${address['avenue'] ?? ''}, ${address['numero'] ?? ''}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: isSelected
                                                    ? AppColors.primary
                                                    : Colors.black87,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${address['quartier'] ?? ''}, ${address['commune'] ?? ''}, ${address['ville'] ?? ''}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                        // Bouton "Voir plus" si plus de 2 adresses
                        if (snapshot.data!.docs.length > 2)
                          Container(
                            margin: const EdgeInsets.only(top: 8, bottom: 8),
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // Afficher toutes les adresses dans un dialog
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Toutes vos adresses'),
                                    content: SizedBox(
                                      width: double.maxFinite,
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: snapshot.data!.docs.length,
                                        itemBuilder: (context, index) {
                                          final doc = snapshot.data!.docs[index];
                                          final address = doc.data() as Map<String, dynamic>;
                                          final isSelected = selectedAddressId == doc.id;
                                          return Container(
                                            margin: const EdgeInsets.only(bottom: 8),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? AppColors.primary.withOpacity(0.08)
                                                  : Colors.white,
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(
                                                color: isSelected
                                                    ? AppColors.primary
                                                    : Colors.grey.shade200,
                                                width: isSelected ? 1.5 : 1,
                                              ),
                                            ),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                borderRadius: BorderRadius.circular(10),
                                                onTap: () {
                                                  setState(() {
                                                    selectedAddress = {
                                                      ...address,
                                                      'id': doc.id,
                                                    };
                                                    selectedAddressId = doc.id;
                                                    _isProcessingRedirect = false;
                                                    _isInitializing = false;
                                                  });
                                                  setStateButton(() {});
                                                  Navigator.pop(context);
                                                },
                                                child: Padding(
                                                  padding: const EdgeInsets.all(12),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        width: 32,
                                                        height: 32,
                                                        decoration: BoxDecoration(
                                                          color: isSelected
                                                              ? AppColors.primary
                                                              : Colors.grey.shade100,
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        child: Icon(
                                                          isSelected
                                                              ? Icons.check_circle
                                                              : Icons.location_on_rounded,
                                                          color: isSelected
                                                              ? Colors.white
                                                              : Colors.grey.shade600,
                                                          size: 18,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              '${address['avenue'] ?? ''}, ${address['numero'] ?? ''}',
                                                              style: TextStyle(
                                                                fontSize: 14,
                                                                fontWeight: FontWeight.w600,
                                                                color: isSelected
                                                                    ? AppColors.primary
                                                                    : Colors.black87,
                                                              ),
                                                            ),
                                                            const SizedBox(height: 4),
                                                            Text(
                                                              '${address['quartier'] ?? ''}, ${address['commune'] ?? ''}, ${address['ville'] ?? ''}',
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color: Colors.grey.shade600,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      if (isSelected)
                                                        Icon(
                                                          Icons.check_circle,
                                                          color: AppColors.primary,
                                                          size: 20,
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
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Fermer'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                side: BorderSide(
                                  color: AppColors.primary,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: Icon(
                                Icons.expand_more,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              label: Text(
                                'Voir ${snapshot.data!.docs.length - 2} adresse${snapshot.data!.docs.length - 2 > 1 ? 's' : ''} de plus',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                      ],
                    );
                  },
                ),

                // Séparateur visuel
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  height: 1,
                  color: Colors.grey.shade200,
                ),

                // Section actions rapides
                _buildAddNewAddressButton(context),
                
                const SizedBox(height: 16),
              ],
            ),
          ),
          // Bouton SUIVANT fixe en bas
          bottomNavigationBar: BlocBuilder<OrderCubit, OrderState>(
            builder: (context, currentOrderState) {
              // Le bouton est toujours actif, mais désactivé pendant le chargement
              final isLoading = currentOrderState.isLoading || _isInitializing;
              final isButtonEnabled = !isLoading && !_isProcessingRedirect;
              
              print('🔘 [AddressSelectionScreen] Bouton - isLoading: $isLoading, enabled: $isButtonEnabled');
              
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
                            
                            // Initialiser la commande (le loader sera géré dans _initializeOrder)
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
                    child: isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Traitement...',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          )
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


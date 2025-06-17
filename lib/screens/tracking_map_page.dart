import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:immo/constants.dart';
import 'package:immo/cubit/auth_cubit.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:url_launcher/url_launcher.dart';

class TrackingMapPage extends StatefulWidget {
  const TrackingMapPage({Key? key}) : super(key: key);

  @override
  State<TrackingMapPage> createState() => _TrackingMapPageState();
}

class _TrackingMapPageState extends State<TrackingMapPage> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  bool _isLoading = true;
  String? _currentOrderId;
  late BitmapDescriptor livreurIcon; // icon du livreur (non nullable)
  MapType _currentMapType = MapType.normal;
  String? _livreurPhone; // Stockage du numéro de téléphone du livreur
  String? _acheteurPhone; // Stockage du numéro de téléphone de l'acheteur

  @override
  void initState() {
    super.initState();
    // Initialiser l'icône du livreur avant tout
    _initializeMarkerIcon();
    // Centrer la carte sur la position de l'utilisateur après un court délai
    Future.delayed(const Duration(milliseconds: 500), () {
      _centerMapOnUserLocation();
    });
  }

  Future<void> _initializeMarkerIcon() async {
    try {
      print('Loading livreur icon from assets...'); // Debug log

      // Charger l'image depuis les assets
      final ByteData bytes =
          await rootBundle.load('assets/images/pin-livreur.png');
      final Uint8List data = bytes.buffer.asUint8List();

      // Redimensionner l'image pour qu'elle soit adaptée à la carte
      final Uint8List resizedData = await _resizeImage(data, 150, 150);

      // Créer l'icône à partir des données de l'image
      livreurIcon = BitmapDescriptor.fromBytes(resizedData);

      print('Livreur icon loaded successfully with custom size'); // Debug log

      // Une fois l'icône chargée, initialiser le reste de l'application
      _setupLocationUpdates();
      _setMapStyle();
    } catch (e) {
      print('Error loading livreur icon: $e'); // Debug log
      // En cas d'erreur, utiliser l'icône bleue par défaut
      livreurIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      // Quand même initialiser le reste de l'application
      _setupLocationUpdates();
      _setMapStyle();
    }
  }

  Future<Uint8List> _resizeImage(Uint8List data, int width, int height) async {
    // Décoder l'image
    final ui.Codec codec = await ui.instantiateImageCodec(data,
        targetWidth: width, targetHeight: height);

    // Obtenir le cadre de l'image
    final ui.FrameInfo frameInfo = await codec.getNextFrame();

    // Convertir l'image en bytes
    final ByteData? byteData =
        await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  void _setupLocationUpdates() {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthSuccess || authState.user == null) return;

    final userRole = authState.user!['role'];
    final userId = authState.user!['id'].toString();

    print('User Role: $userRole, User ID: $userId'); // Debug log

    // Écouter toutes les positions pertinentes
    FirebaseFirestore.instance
        .collection('locations')
        .where('role', whereIn: ['livreur', 'acheteur'])
        .snapshots()
        .listen((snapshot) {
          print('Received ${snapshot.docs.length} location updates'); // Debug log
          for (var doc in snapshot.docs) {
            final data = doc.data();
            print('Location data: ${data.toString()}'); // Debug log for each document
          }
          if (snapshot.docs.isNotEmpty) {
            _updateMarkers(snapshot.docs, userRole);
          }
        });
  }

  void _updateMarkers(List<QueryDocumentSnapshot> locations, String userRole) {
    final markers = <Marker>{};
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthSuccess || authState.user == null) return;
    
    final userId = authState.user!['id'].toString();
    LatLng? myPosition;

    print('Updating markers for role: $userRole'); // Debug log
    print('Livreur icon personnalisée utilisée'); // Debug log

    // Filtrer les positions pour n'avoir qu'une seule position par utilisateur
    final Map<String, QueryDocumentSnapshot> latestPositions = {};
    for (var doc in locations) {
      final data = doc.data() as Map<String, dynamic>;
      final locationUserId = data['userId'] as String;
      latestPositions[locationUserId] = doc;
    }

    // Traiter les positions filtrées
    for (var doc in latestPositions.values) {
      final data = doc.data() as Map<String, dynamic>;
      final role = data['role'] as String;
      final locationUserId = data['userId'] as String;
      final phone = data['phone'] as String?; // Récupérer le numéro de téléphone

      print('Processing location - Role: $role, UserId: $locationUserId, Phone: $phone'); // Debug log
      
      // Stocker le numéro de téléphone selon le rôle
      if (role == 'livreur') {
        setState(() {
          _livreurPhone = phone;
          print('Updated livreur phone to: $_livreurPhone'); // Debug log
        });
      } else if (role == 'acheteur') {
        setState(() {
          _acheteurPhone = phone;
          print('Updated acheteur phone to: $_acheteurPhone'); // Debug log
        });
      }
      
      // Afficher la position de l'utilisateur connecté
      if (locationUserId == userId) {
        myPosition = LatLng(
          data['latitude'] as double,
          data['longitude'] as double,
        );
        markers.add(
          Marker(
            markerId: MarkerId('my_position'),
            position: myPosition,
            icon: userRole == 'livreur' 
                ? livreurIcon
                : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(
              title: userRole == 'livreur' ? 'Ma position (Livreur)' : 'Ma position',
              snippet: 'Position actuelle',
            ),
            zIndex: 2,
            visible: true,
          ),
        );
        print('Added my position marker'); // Debug log
      }
      
      // Afficher la position de l'autre partie (livreur ou acheteur)
      if ((userRole == 'livreur' && role == 'acheteur') ||
          (userRole == 'acheteur' && role == 'livreur')) {
        final otherPosition = LatLng(
          data['latitude'] as double,
          data['longitude'] as double,
        );

        if (role == 'livreur') {
          markers.add(
            Marker(
              markerId: MarkerId('${role}_${data['userId']}'),
              position: otherPosition,
              icon: livreurIcon,
              infoWindow: InfoWindow(
                title: 'Position du livreur',
                snippet: phone != null ? 'Tél: $phone' : 'En route vers vous',
              ),
              zIndex: 1,
              anchor: const Offset(0.5, 0.5),
            ),
          );
        } else {
          markers.add(
            Marker(
              markerId: MarkerId('${role}_${data['userId']}'),
              position: otherPosition,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
              infoWindow: InfoWindow(
                title: 'Position de l\'acheteur',
                snippet: phone != null ? 'Tél: $phone' : 'En attente de livraison',
              ),
              zIndex: 1,
            ),
          );
        }
        print('Added other party marker for role: $role'); // Debug log
      }
    }

    setState(() {
      _markers = markers;
      _isLoading = false;
    });
    print('Total markers on map: ${_markers.length}'); // Debug log

    // Forcer le centrage sur la position de l'utilisateur
    if (myPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: myPosition,
            zoom: 15,
            tilt: 0,
            bearing: 0,
          ),
        ),
      );
    }
  }

  void _setMapStyle() async {
    String style = '''
    [
      {
        "featureType": "administrative",
        "elementType": "geometry",
        "stylers": [
          {
            "visibility": "on"
          }
        ]
      },
      {
        "featureType": "administrative.locality",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#2c2c2c"
          }
        ]
      },
      {
        "featureType": "administrative.neighborhood",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#2c2c2c"
          }
        ]
      },
      {
        "featureType": "road",
        "elementType": "geometry",
        "stylers": [
          {
            "visibility": "on"
          }
        ]
      },
      {
        "featureType": "road",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#2c2c2c"
          }
        ]
      },
      {
        "featureType": "road.highway",
        "elementType": "geometry",
        "stylers": [
          {
            "visibility": "on"
          }
        ]
      },
      {
        "featureType": "road.highway",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#2c2c2c"
          }
        ]
      },
      {
        "featureType": "water",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#a2daf2"
          }
        ]
      },
      {
        "featureType": "poi",
        "elementType": "labels",
        "stylers": [
          {
            "visibility": "off"
          }
        ]
      }
    ]
    ''';

    if (_mapController != null) {
      await _mapController!.setMapStyle(style);
    }
  }

  void _centerMapOnUserLocation() {
    if (_mapController != null && _markers.isNotEmpty) {
      // Trouver le marqueur de la position de l'utilisateur
      final myMarker = _markers.firstWhere(
        (marker) => marker.markerId.value == 'my_position',
        orElse: () => _markers.first,
      );

      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: myMarker.position,
            zoom: 15,
            tilt: 0,
            bearing: 0,
          ),
        ),
      );
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _setMapStyle();
    // Centrer la carte une fois que le contrôleur est créé
    _centerMapOnUserLocation();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    print('Attempting to call: $phoneNumber'); // Debug log
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impossible de lancer l\'appel')),
          );
        }
      }
    } catch (e) {
      print('Error making phone call: $e'); // Debug log
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'appel')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final authState = context.read<AuthCubit>().state;
    String? userRole;
    if (authState is AuthSuccess && authState.user != null) {
      userRole = authState.user!['role'] as String?;
    }
    final bool isLivreur = userRole == 'livreur';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi de livraison'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _centerMapOnUserLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(-4.325, 15.308),
              zoom: 15,
            ),
            onMapCreated: _onMapCreated,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            mapToolbarEnabled: false,
            mapType: _currentMapType,
            compassEnabled: true,
            zoomGesturesEnabled: true,
            rotateGesturesEnabled: true,
            scrollGesturesEnabled: true,
            tiltGesturesEnabled: true,
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isLivreur
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isLivreur
                            ? Icons.location_on
                            : Icons.delivery_dining,
                        color: isLivreur
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isLivreur
                            ? 'Position de l\'acheteur'
                            : 'Position du livreur',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          final phoneToCall = isLivreur
                              ? _acheteurPhone
                              : _livreurPhone;
                          print('Current livreur phone: $_livreurPhone'); // Debug log
                          print('Current acheteur phone: $_acheteurPhone'); // Debug log
                          print('Attempting to call: $phoneToCall'); // Debug log
                          if (phoneToCall != null && phoneToCall.isNotEmpty) {
                            _makePhoneCall(phoneToCall);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Numéro de téléphone non disponible'),
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Appeler',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

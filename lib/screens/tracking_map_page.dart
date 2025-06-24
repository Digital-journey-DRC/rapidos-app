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
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class TrackingMapPage extends StatefulWidget {
  const TrackingMapPage({Key? key}) : super(key: key);

  @override
  State<TrackingMapPage> createState() => _TrackingMapPageState();
}

class _TrackingMapPageState extends State<TrackingMapPage> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isLoading = true;
  String? _currentOrderId;
  late BitmapDescriptor livreurIcon; // icon du livreur (non nullable)
  MapType _currentMapType = MapType.normal;
  String? _livreurPhone; // Stockage du numéro de téléphone du livreur
  String? _acheteurPhone; // Stockage du numéro de téléphone de l'acheteur
  LatLng? _livreurPosition;
  LatLng? _acheteurPosition;
  String? _routeDistance;
  String? _routeDuration;
  bool _hasActiveOrders = false;

  @override
  void initState() {
    super.initState();
    // Initialiser l'icône du livreur et démarrer immédiatement
    _initializeMarkerIcon();
    // Démarrer immédiatement les mises à jour de localisation
    _setupLocationUpdates();
    // Réduire le délai pour un chargement plus rapide
    Future.delayed(const Duration(milliseconds: 100), () {
      _centerMapOnUserLocation();
    });
  }

  Future<void> _initializeMarkerIcon() async {
    try {
      print('Loading livreur icon from assets...');

      // Charger l'image depuis les assets
      final ByteData bytes =
          await rootBundle.load('assets/images/pin-livreur.png');
      final Uint8List data = bytes.buffer.asUint8List();

      // Réduire la taille de l'image pour améliorer les performances
      final Uint8List resizedData = await _resizeImage(data, 80, 80);

      // Créer l'icône à partir des données de l'image
      livreurIcon = BitmapDescriptor.fromBytes(resizedData);

      print('Livreur icon loaded successfully with optimized size');

      // Appliquer le style de la carte
      _setMapStyle();
    } catch (e) {
      print('Error loading livreur icon: $e');
      // En cas d'erreur, utiliser l'icône bleue par défaut immédiatement
      livreurIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      // Appliquer le style de la carte
      _setMapStyle();
    }
  }

  Future<Uint8List> _resizeImage(Uint8List data, int width, int height) async {
    final ui.Codec codec = await ui.instantiateImageCodec(data,
        targetWidth: width, targetHeight: height);

    final ui.FrameInfo frameInfo = await codec.getNextFrame();

    final ByteData? byteData =
        await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  void _setupLocationUpdates() {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthSuccess || authState.user == null) return;

    final userRole = authState.user!['role'];
    final userId = authState.user!['id'].toString();

    print('User Role: $userRole, User ID: $userId');

    // Filtrer les commandes selon le rôle de l'utilisateur connecté
    Query cartQuery = FirebaseFirestore.instance
        .collection('carts')
        .where('status', isEqualTo: 'en route pour livraison');

    if (userRole == 'acheteur') {
      // Si l'utilisateur est un acheteur, filtrer par idClient
      cartQuery = cartQuery.where('idClient', isEqualTo: userId);
    } else if (userRole == 'livreur') {
      // Si l'utilisateur est un livreur, filtrer par le champ livreur
      cartQuery = cartQuery.where('livreur', isEqualTo: userId);
    }

    // Écouter les commandes filtrées avec une fréquence optimisée
    cartQuery.snapshots().listen((cartSnapshot) {
      print('Received ${cartSnapshot.docs.length} cart updates for user $userId with role $userRole');
      
      // Mettre à jour immédiatement l'état des commandes actives
      setState(() {
        _hasActiveOrders = cartSnapshot.docs.isNotEmpty;
        _isLoading = false;
      });
      
      if (cartSnapshot.docs.isNotEmpty) {
        print('Active orders found, setting up location tracking...');
        
        if (userRole == 'acheteur') {
          // Pour un acheteur, récupérer l'ID du livreur depuis la commande
          final livreurIds = cartSnapshot.docs
              .map((doc) => (doc.data() as Map<String, dynamic>)['livreur'] as String?)
              .where((id) => id != null && id!.isNotEmpty)
              .map((id) => id!)
              .toSet();
          
          print('Livreur IDs from carts for acheteur: $livreurIds');
          
          if (livreurIds.isNotEmpty) {
            // Écouter les positions des livreurs avec une fréquence optimisée
            FirebaseFirestore.instance
                .collection('locations')
                .where('userId', whereIn: livreurIds.toList())
                .where('role', isEqualTo: 'livreur')
                .snapshots()
                .listen((locationSnapshot) {
                  print('Received ${locationSnapshot.docs.length} livreur location updates');
                  _updateMarkers(locationSnapshot.docs, userRole, cartSnapshot.docs);
                });
          }
        } else if (userRole == 'livreur') {
          // Pour un livreur, récupérer l'ID du client depuis la commande
          final clientIds = cartSnapshot.docs
              .map((doc) => (doc.data() as Map<String, dynamic>)['idClient'] as String?)
              .where((id) => id != null && id!.isNotEmpty)
              .map((id) => id!)
              .toSet();
          
          print('Client IDs from carts for livreur: $clientIds');
          
          if (clientIds.isNotEmpty) {
            // Écouter les positions des clients avec une fréquence optimisée
            FirebaseFirestore.instance
                .collection('locations')
                .where('userId', whereIn: clientIds.toList())
                .where('role', isEqualTo: 'acheteur')
                .snapshots()
                .listen((locationSnapshot) {
                  print('Received ${locationSnapshot.docs.length} client location updates');
                  _updateMarkers(locationSnapshot.docs, userRole, cartSnapshot.docs);
                });
          }
        }
      } else {
        // Si aucune commande, nettoyer les marqueurs et polylines
        setState(() {
          _markers.clear();
          _polylines.clear();
          _livreurPosition = null;
          _acheteurPosition = null;
          _routeDistance = null;
          _routeDuration = null;
        });
        print('No active orders, cleared map data');
      }
    });
  }

  void _updateMarkers(List<QueryDocumentSnapshot> otherLocations, String userRole, List<QueryDocumentSnapshot> carts) {
    final markers = <Marker>{};
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthSuccess || authState.user == null) return;
    
    final userId = authState.user!['id'].toString();
    LatLng? myPosition;

    print('Updating markers for role: $userRole');
    print('Livreur icon personnalisée utilisée');

    // Filtrer les positions pour n'avoir qu'une seule position par utilisateur
    final Map<String, QueryDocumentSnapshot> latestPositions = {};
    for (var doc in otherLocations) {
      final data = doc.data() as Map<String, dynamic>;
      final locationUserId = data['userId'] as String;
      latestPositions[locationUserId] = doc;
    }

    if (userRole == 'acheteur') {
      // Pour un acheteur, afficher la position du livreur
      for (var doc in latestPositions.values) {
        final data = doc.data() as Map<String, dynamic>;
        final locationUserId = data['userId'] as String;
        final phone = data['phone'] as String?;

        print('Processing livreur location for acheteur - UserId: $locationUserId, Phone: $phone');
        
        // Stocker le numéro de téléphone du livreur
        setState(() {
          _livreurPhone = phone;
          print('Updated livreur phone to: $_livreurPhone');
        });
        
        // Afficher la position du livreur
        final livreurPosition = LatLng(
          data['latitude'] as double,
          data['longitude'] as double,
        );

        // Stocker la position du livreur pour le calcul d'itinéraire
        _livreurPosition = livreurPosition;

        markers.add(
          Marker(
            markerId: MarkerId('livreur_$locationUserId'),
            position: livreurPosition,
            icon: livreurIcon,
            infoWindow: InfoWindow(
              title: 'Position du livreur',
              snippet: phone != null ? 'Tél: $phone' : 'En route vers vous',
            ),
            zIndex: 1,
            anchor: const Offset(0.5, 0.5),
          ),
        );
        print('Added livreur marker for acheteur');
      }

      // Afficher la position de l'acheteur connecté
      FirebaseFirestore.instance
          .collection('locations')
          .where('userId', isEqualTo: userId)
          .where('role', isEqualTo: 'acheteur')
          .limit(1)
          .get()
          .then((acheteurSnapshot) {
            if (acheteurSnapshot.docs.isNotEmpty) {
              final acheteurData = acheteurSnapshot.docs.first.data();
              final acheteurPhone = acheteurData['phone'] as String?;
              
              setState(() {
                _acheteurPhone = acheteurPhone;
              });
              
              final acheteurPosition = LatLng(
                acheteurData['latitude'] as double,
                acheteurData['longitude'] as double,
              );
              
              // Stocker la position de l'acheteur pour le calcul d'itinéraire
              _acheteurPosition = acheteurPosition;
              
              markers.add(
                Marker(
                  markerId: MarkerId('my_position'),
                  position: acheteurPosition,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                  infoWindow: InfoWindow(
                    title: 'Ma position (Acheteur)',
                    snippet: 'Position actuelle',
                  ),
                  zIndex: 2,
                  visible: true,
                ),
              );
              
              myPosition = acheteurPosition;
              print('Added acheteur position marker');
              
              // Calculer l'itinéraire si les deux positions sont disponibles
              if (_livreurPosition != null && _acheteurPosition != null) {
                _calculateRoute(_livreurPosition!, _acheteurPosition!);
              }
            }
          });
    } else if (userRole == 'livreur') {
      // Pour un livreur, afficher la position du client
      for (var doc in latestPositions.values) {
        final data = doc.data() as Map<String, dynamic>;
        final locationUserId = data['userId'] as String;
        final phone = data['phone'] as String?;

        print('Processing client location for livreur - UserId: $locationUserId, Phone: $phone');
        
        // Stocker le numéro de téléphone du client
        setState(() {
          _acheteurPhone = phone;
          print('Updated client phone to: $_acheteurPhone');
        });
        
        // Afficher la position du client
        final clientPosition = LatLng(
          data['latitude'] as double,
          data['longitude'] as double,
        );

        // Stocker la position du client pour le calcul d'itinéraire
        _acheteurPosition = clientPosition;

        markers.add(
          Marker(
            markerId: MarkerId('client_$locationUserId'),
            position: clientPosition,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: InfoWindow(
              title: 'Position du client',
              snippet: phone != null ? 'Tél: $phone' : 'En attente de livraison',
            ),
            zIndex: 1,
          ),
        );
        print('Added client marker for livreur');
      }

      // Afficher la position du livreur connecté
      FirebaseFirestore.instance
          .collection('locations')
          .where('userId', isEqualTo: userId)
          .where('role', isEqualTo: 'livreur')
          .limit(1)
          .get()
          .then((livreurSnapshot) {
            if (livreurSnapshot.docs.isNotEmpty) {
              final livreurData = livreurSnapshot.docs.first.data();
              final livreurPhone = livreurData['phone'] as String?;
              
              setState(() {
                _livreurPhone = livreurPhone;
              });
              
              final livreurPosition = LatLng(
                livreurData['latitude'] as double,
                livreurData['longitude'] as double,
              );
              
              // Stocker la position du livreur pour le calcul d'itinéraire
              _livreurPosition = livreurPosition;
              
              markers.add(
                Marker(
                  markerId: MarkerId('my_position'),
                  position: livreurPosition,
                  icon: livreurIcon,
                  infoWindow: InfoWindow(
                    title: 'Ma position (Livreur)',
                    snippet: 'Position actuelle',
                  ),
                  zIndex: 2,
                  visible: true,
                ),
              );
              
              myPosition = livreurPosition;
              print('Added livreur position marker');
              
              // Calculer l'itinéraire si les deux positions sont disponibles
              if (_livreurPosition != null && _acheteurPosition != null) {
                _calculateRoute(_livreurPosition!, _acheteurPosition!);
              }
            }
          });
    }

    setState(() {
      _markers = markers;
      _isLoading = false;
    });
    print('Total markers on map: ${_markers.length}');

    // Centrer sur la position appropriée seulement si nécessaire
    if (myPosition != null && _mapController != null) {
      // Si les deux positions sont disponibles, ajuster la carte pour montrer l'itinéraire complet
      if (_livreurPosition != null && _acheteurPosition != null) {
        // Utiliser un délai court pour éviter les conflits
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) _fitMapToRoute();
        });
      } else {
        // Sinon, centrer sur la position de l'utilisateur
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: myPosition!,
              zoom: 15,
              tilt: 0,
              bearing: 0,
            ),
          ),
        );
      }
    } else if (latestPositions.isNotEmpty && _mapController != null) {
      // Centrer sur la position de l'autre partie
      final firstOtherData = latestPositions.values.first.data() as Map<String, dynamic>;
      final otherPosition = LatLng(
        firstOtherData['latitude'] as double,
        firstOtherData['longitude'] as double,
      );
      
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: otherPosition,
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
    // Centrer la carte immédiatement si des marqueurs sont déjà disponibles
    if (_markers.isNotEmpty) {
      _centerMapOnUserLocation();
    }
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

  void _fitMapToRoute() {
    if (_mapController != null && _markers.isNotEmpty) {
      double minLat = double.infinity;
      double maxLat = -double.infinity;
      double minLng = double.infinity;
      double maxLng = -double.infinity;

      // Calculer les limites basées sur les marqueurs
      for (var marker in _markers) {
        minLat = min(minLat, marker.position.latitude);
        maxLat = max(maxLat, marker.position.latitude);
        minLng = min(minLng, marker.position.longitude);
        maxLng = max(maxLng, marker.position.longitude);
      }

      // Ajouter un padding
      const double padding = 0.01; // Environ 1km
      minLat -= padding;
      maxLat += padding;
      minLng -= padding;
      maxLng += padding;

      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          50, // padding en pixels
        ),
      );
    }
  }

  Future<void> _calculateRoute(LatLng origin, LatLng destination) async {
    try {
      print('Calculating route from ${origin.latitude}, ${origin.longitude} to ${destination.latitude}, ${destination.longitude}');
      
      // Utiliser le package flutter_polyline_points pour l'itinéraire
      PolylinePoints polylinePoints = PolylinePoints();
      
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: 'AIzaSyCuLBjM3oTYfFSbJwXccj4xP8oynDV5JnM',
        request: PolylineRequest(
          origin: PointLatLng(origin.latitude, origin.longitude),
          destination: PointLatLng(destination.latitude, destination.longitude),
          mode: TravelMode.driving,
        ),
      );
      
      if (result.status == 'OK') {
        List<LatLng> polylineCoordinates = result.points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();
        
        print('Route calculated successfully with ${polylineCoordinates.length} points');
        
        setState(() {
          _polylines.clear();
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('route'),
              color: AppColors.primary,
              points: polylineCoordinates,
              width: 5,
            ),
          );
        });
        
        // Calculer la distance et durée approximatives
        if (polylineCoordinates.isNotEmpty) {
          double totalDistance = 0;
          for (int i = 1; i < polylineCoordinates.length; i++) {
            totalDistance += _calculateDistance(polylineCoordinates[i-1], polylineCoordinates[i]);
          }
          
          String distanceText = '${totalDistance.toStringAsFixed(1)} km';
          String durationText = '${(totalDistance * 2).round()} min'; // Estimation: 2 min par km
          
          setState(() {
            _routeDistance = distanceText;
            _routeDuration = durationText;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Itinéraire: $distanceText, $durationText'),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } else {
        print('Polyline API error: ${result.status}');
        print('Error message: ${result.errorMessage}');
        // En cas d'erreur, utiliser la ligne droite simple
        _calculateSimpleRoute(origin, destination);
      }
    } catch (e) {
      print('Error calculating route: $e');
      // En cas d'erreur, utiliser la ligne droite simple
      _calculateSimpleRoute(origin, destination);
    }
  }

  // Fonction pour calculer la distance entre deux points
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // Rayon de la Terre en km
    
    double lat1 = point1.latitude * pi / 180;
    double lat2 = point2.latitude * pi / 180;
    double deltaLat = (point2.latitude - point1.latitude) * pi / 180;
    double deltaLng = (point2.longitude - point1.longitude) * pi / 180;
    
    double a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1) * cos(lat2) * sin(deltaLng / 2) * sin(deltaLng / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  void _calculateSimpleRoute(LatLng origin, LatLng destination) {
    // Méthode de fallback : ligne droite entre les deux points
    List<LatLng> polylineCoordinates = [origin, destination];
    
    setState(() {
      _polylines.clear();
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          color: AppColors.primary,
          points: polylineCoordinates,
          width: 5,
        ),
      );
    });
    
    print('Simple route calculated as fallback');
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    String? userRole;
    if (authState is AuthSuccess && authState.user != null) {
      userRole = authState.user!['role'] as String?;
    }
    final bool isLivreur = userRole == 'livreur';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi de livraison',style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _markers.clear();
                _polylines.clear();
                _livreurPosition = null;
                _acheteurPosition = null;
                _routeDistance = null;
                _routeDuration = null;
              });
              // Re-démarrer les listeners
              _setupLocationUpdates();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Actualisation en cours...')),
              );
            },
            tooltip: 'Actualiser',
          ),
          IconButton(
            icon: const Icon(Icons.route),
            onPressed: () {
              if (_livreurPosition != null && _acheteurPosition != null) {
                _calculateRoute(_livreurPosition!, _acheteurPosition!);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Itinéraire recalculé')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Positions non disponibles pour calculer l\'itinéraire')),
                );
              }
            },
            tooltip: 'Recalculer l\'itinéraire',
          ),
          IconButton(
            icon: const Icon(Icons.fit_screen),
            onPressed: _fitMapToRoute,
            tooltip: 'Ajuster à l\'itinéraire',
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _centerMapOnUserLocation,
          ),
        ],
      ),
      body: _hasActiveOrders 
          ? Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(-4.325, 15.308),
                    zoom: 12,
                  ),
                  onMapCreated: _onMapCreated,
                  markers: _markers,
                  polylines: _polylines,
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
                // Indicateur de chargement seulement si vraiment nécessaire
                if (_isLoading && _markers.isEmpty)
                  const Positioned(
                    top: 100,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 16),
                              Text('Chargement de la carte...'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    children: [
                      // Carte d'informations d'itinéraire
                      if (_routeDistance != null && _routeDuration != null)
                        Card(
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
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.route,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Distance: $_routeDistance',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Durée: $_routeDuration',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      // Carte d'appel existante
                      Card(
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
                                    print('Current livreur phone: $_livreurPhone');
                                    print('Current acheteur phone: $_acheteurPhone');
                                    print('Attempting to call: $phoneToCall');
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
                    ],
                  ),
                ),
              ],
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.delivery_dining,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune livraison en cours',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vous n\'avez pas de commande\n en cours',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    // Nettoyer les ressources
    _mapController?.dispose();
    super.dispose();
  }
}

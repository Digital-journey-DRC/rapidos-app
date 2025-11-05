import 'package:flutter/material.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:immo/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:immo/cubit/auth_cubit.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';

class NavigationExample extends StatefulWidget {
  final bool backNavigation;
  const NavigationExample({Key? key, required this.backNavigation}) : super(key: key);

  @override
  State<NavigationExample> createState() => _NavigationExampleState();
}

class _NavigationExampleState extends State<NavigationExample> {
  bool _isNavigationActive = false;
  String _instruction = "";
  
  // Nouvelles variables pour le suivi en temps réel
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isLoading = true;
  MapType _currentMapType = MapType.normal;
  String? _livreurPhone;
  String? _acheteurPhone;
  LatLng? _livreurPosition;
  LatLng? _acheteurPosition;
  String? _routeDistance;
  String? _routeDuration;
  bool _hasActiveOrders = false;
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _initializeNavigation();
    _setupLocationUpdates();
    _updateLivreurPosition();
    _startLocationTracking();
  }

  Future<void> _initializeNavigation() async {
    try {
      MapBoxNavigation.instance.setDefaultOptions(MapBoxOptions(
        initialLatitude: 36.1175275,
        initialLongitude: -115.1839524,
        zoom: 13.0,
        tilt: 0.0,
        bearing: 0.0,
        enableRefresh: false,
        alternatives: true,
        voiceInstructionsEnabled: true,
        bannerInstructionsEnabled: true,
        allowsUTurnAtWayPoints: true,
        mode: MapBoxNavigationMode.drivingWithTraffic,
        units: VoiceUnits.metric,
        simulateRoute: false,
        language: "fr",
      ));

      MapBoxNavigation.instance.registerRouteEventListener(_onRouteEvent);
      print("✅ Navigation initialized successfully");
    } catch (e) {
      print("❌ Error initializing navigation: $e");
    }
  }

  // Mettre à jour la position du livreur connecté
  Future<void> _updateLivreurPosition() async {
    try {
      final authState = context.read<AuthCubit>().state;
      if (authState is! AuthSuccess || authState.user == null) return;

      final userRole = authState.user!['role'];
      final userId = authState.user!['id'].toString();
      final userPhone = authState.user!['phone'] as String?;

      // Vérifier si l'utilisateur est un livreur
      if (userRole != 'livreur') {
        print("ℹ️ Utilisateur n'est pas un livreur, pas de mise à jour de position");
        return;
      }

      print("🚚 Mise à jour de la position du livreur connecté...");

      // Obtenir la position actuelle
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      print("📍 Position obtenue: ${position.latitude}, ${position.longitude}");

      // Créer le document de position pour le livreur
      Map<String, dynamic> positionData = {
        'userId': userId,
        'role': 'livreur',
        'latitude': position.latitude,
        'longitude': position.longitude,
        'phone': userPhone,
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Sauvegarder la position dans Firestore
      await FirebaseFirestore.instance
          .collection('locations')
          .doc(userId)
          .set(positionData, SetOptions(merge: true));

      print("✅ Position du livreur mise à jour avec succès");

      // Mettre à jour la position locale pour l'affichage
      setState(() {
        _livreurPosition = LatLng(position.latitude, position.longitude);
        _livreurPhone = userPhone;
      });

    } catch (e) {
      print("❌ Erreur lors de la mise à jour de la position du livreur: $e");
    }
  }

  // Démarrer le suivi de position en temps réel
  void _startLocationTracking() {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthSuccess || authState.user == null) return;

    final userRole = authState.user!['role'];
    final userId = authState.user!['id'].toString();

    // Seuls les livreurs ont besoin du suivi de position en temps réel
    if (userRole != 'livreur') return;

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Mettre à jour toutes les 10 mètres
      ),
    ).listen((Position position) {
      _updateLivreurPositionInFirestore(position, userId);
    });
  }

  // Mettre à jour la position du livreur dans Firestore
  Future<void> _updateLivreurPositionInFirestore(Position position, String userId) async {
    try {
      final authState = context.read<AuthCubit>().state;
      if (authState is! AuthSuccess || authState.user == null) return;

      final userPhone = authState.user!['phone'] as String?;

      Map<String, dynamic> positionData = {
        'userId': userId,
        'role': 'livreur',
        'latitude': position.latitude,
        'longitude': position.longitude,
        'phone': userPhone,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('locations')
          .doc(userId)
          .set(positionData, SetOptions(merge: true));

      setState(() {
        _livreurPosition = LatLng(position.latitude, position.longitude);
      });

    } catch (e) {
      print("❌ Erreur lors de la mise à jour de position: $e");
    }
  }

  // Calculer la distance et la durée entre deux points
  Future<void> _calculateRouteInfo(LatLng start, LatLng end) async {
    try {
      // Calculer la distance en ligne droite
      double distance = Geolocator.distanceBetween(
        start.latitude,
        start.longitude,
        end.latitude,
        end.longitude,
      );

      // Convertir en kilomètres
      double distanceKm = distance / 1000;

      // Estimation de la durée (vitesse moyenne de 30 km/h en ville)
      double durationHours = distanceKm / 30;
      int durationMinutes = (durationHours * 60).round();

      setState(() {
        _routeDistance = '${distanceKm.toStringAsFixed(1)} km';
        _routeDuration = '${durationMinutes} min';
      });

      // Créer la polyline entre les deux points
      _createPolyline(start, end);

    } catch (e) {
      print("❌ Erreur lors du calcul de la route: $e");
    }
  }

  // Créer une polyline entre deux points
  void _createPolyline(LatLng start, LatLng end) {
    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: [start, end],
          color: Colors.blue,
          width: 4,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      };
    });

    // Centrer la carte sur les deux positions
    _centerMapOnPositions(start, end);
  }

  // Centrer la carte sur les deux positions
  void _centerMapOnPositions(LatLng start, LatLng end) {
    if (_mapController == null) return;

    // Calculer le centre entre les deux points
    double centerLat = (start.latitude + end.latitude) / 2;
    double centerLng = (start.longitude + end.longitude) / 2;

    // Calculer la distance pour déterminer le zoom approprié
    double distance = Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );

    // Ajuster le niveau de zoom selon la distance
    double zoom = 12.0;
    if (distance < 1000) {
      zoom = 15.0; // Zoom élevé pour les courtes distances
    } else if (distance < 5000) {
      zoom = 13.0; // Zoom moyen pour les distances moyennes
    } else {
      zoom = 11.0; // Zoom faible pour les longues distances
    }

    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(centerLat, centerLng),
          zoom: zoom,
        ),
      ),
    );
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
      cartQuery = cartQuery.where('idClient', isEqualTo: userId);
    } else if (userRole == 'livreur') {
      cartQuery = cartQuery.where('livreur', isEqualTo: userId);
    }

    // Écouter les commandes filtrées
    cartQuery.snapshots().listen((cartSnapshot) {
      print('Received ${cartSnapshot.docs.length} cart updates for user $userId with role $userRole');
      
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
              .where((id) => id != null && id.isNotEmpty)
              .map((id) => id)
              .toSet();
          
          if (livreurIds.isNotEmpty) {
            FirebaseFirestore.instance
                .collection('locations')
                .where('userId', whereIn: livreurIds.toList())
                .where('role', isEqualTo: 'livreur')
                .snapshots()
                .listen((locationSnapshot) {
                  _updateMarkers(locationSnapshot.docs, userRole, cartSnapshot.docs);
                });
          }
        } else if (userRole == 'livreur') {
          // Pour un livreur, récupérer l'ID du client depuis la commande
          final clientIds = cartSnapshot.docs
              .map((doc) => (doc.data() as Map<String, dynamic>)['idClient'] as String?)
              .where((id) => id != null && id.isNotEmpty)
              .map((id) => id)
              .toSet();
          
          if (clientIds.isNotEmpty) {
            FirebaseFirestore.instance
                .collection('locations')
                .where('userId', whereIn: clientIds.toList())
                .where('role', isEqualTo: 'acheteur')
                .snapshots()
                .listen((locationSnapshot) {
                  _updateMarkers(locationSnapshot.docs, userRole, cartSnapshot.docs);
                });
          }
        }
      } else {
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
        
        _livreurPhone = phone;
        
        final livreurPosition = LatLng(
          data['latitude'] as double,
          data['longitude'] as double,
        );

        _livreurPosition = livreurPosition;

        markers.add(
          Marker(
            markerId: MarkerId('livreur_$locationUserId'),
            position: livreurPosition,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: InfoWindow(
              title: 'Position du livreur',
              snippet: phone != null ? 'Tél: $phone' : 'En route vers vous',
            ),
          ),
        );
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
              
              _acheteurPhone = acheteurPhone;
              
              final acheteurPosition = LatLng(
                acheteurData['latitude'] as double,
                acheteurData['longitude'] as double,
              );
              
              _acheteurPosition = acheteurPosition;
              
              markers.add(
                Marker(
                  markerId: const MarkerId('my_position'),
                  position: acheteurPosition,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                  infoWindow: const InfoWindow(
                    title: 'Ma position (Acheteur)',
                    snippet: 'Position actuelle',
                  ),
                ),
              );
            }
          });
    } else if (userRole == 'livreur') {
      // Pour un livreur, afficher la position du client
      for (var doc in latestPositions.values) {
        final data = doc.data() as Map<String, dynamic>;
        final locationUserId = data['userId'] as String;
        final phone = data['phone'] as String?;
        
        _acheteurPhone = phone;
        
        final clientPosition = LatLng(
          data['latitude'] as double,
          data['longitude'] as double,
        );

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
          ),
        );
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
              
              _livreurPhone = livreurPhone;
              
              final livreurPosition = LatLng(
                livreurData['latitude'] as double,
                livreurData['longitude'] as double,
              );
              
              _livreurPosition = livreurPosition;
              
              markers.add(
                Marker(
                  markerId: const MarkerId('my_position'),
                  position: livreurPosition,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                  infoWindow: const InfoWindow(
                    title: 'Ma position (Livreur)',
                    snippet: 'Position actuelle',
                  ),
                ),
              );
            }
          });
    }

    setState(() {
      _markers = markers;
      _isLoading = false;
    });

    // Calculer la route si on a les deux positions
    if (_livreurPosition != null && _acheteurPosition != null) {
      _calculateRouteInfo(_livreurPosition!, _acheteurPosition!);
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    print('Attempting to call: $phoneNumber');
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
      print('Error making phone call: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'appel')),
        );
      }
    }
  }

  Future<void> _onRouteEvent(e) async {
    switch (e.eventType) {
      case MapBoxEvent.progress_change:
        var progressEvent = e.data as RouteProgressEvent;
        setState(() {
          if (progressEvent.currentStepInstruction != null) {
            _instruction = progressEvent.currentStepInstruction ?? "";
          }
        });
        break;
      case MapBoxEvent.route_building:
      case MapBoxEvent.route_built:
        print("✅ Route built successfully");
        break;
      case MapBoxEvent.route_build_failed:
        print("❌ Route build failed");
        break;
      case MapBoxEvent.navigation_running:
        setState(() {
          _isNavigationActive = true;
        });
        break;
      case MapBoxEvent.on_arrival:
        print("🎯 Arrived at destination");
        break;
      case MapBoxEvent.navigation_finished:
      case MapBoxEvent.navigation_cancelled:
        setState(() {
          _isNavigationActive = false;
        });
        print("🏁 Navigation finished or cancelled");
        break;
      default:
        break;
    }
  }

  Future<void> _startNavigation() async {
    try {
      // Utiliser les positions réelles du livreur et du client si disponibles
      if (_livreurPosition != null && _acheteurPosition != null) {
        final wayPoints = [
          WayPoint(
            name: "Ma position",
            latitude: _livreurPosition!.latitude,
            longitude: _livreurPosition!.longitude,
          ),
          WayPoint(
            name: "Destination",
            latitude: _acheteurPosition!.latitude,
            longitude: _acheteurPosition!.longitude,
          ),
        ];

        await MapBoxNavigation.instance.startNavigation(wayPoints: wayPoints);
        print("🚀 Navigation started with real positions");
      } else {
        // Fallback vers la méthode originale
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        final wayPoints = [
          WayPoint(
            name: "Ma position",
            latitude: position.latitude,
            longitude: position.longitude,
          ),
          WayPoint(
            name: "Destination",
            latitude: position.latitude + 0.01,
            longitude: position.longitude + 0.01,
          ),
        ];

        await MapBoxNavigation.instance.startNavigation(wayPoints: wayPoints);
        print("🚀 Navigation started with fallback positions");
      }
    } catch (e) {
      print("❌ Error starting navigation: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _finishNavigation() async {
    try {
      await MapBoxNavigation.instance.finishNavigation();
      setState(() {
        _isNavigationActive = false;
      });
      print("🏁 Navigation finished");
    } catch (e) {
      print("❌ Error finishing navigation: $e");
    }
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
        leading: widget.backNavigation == true ? IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ) : null,
        title: const Text('Navigation Avancée', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),),
        // backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
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
              _setupLocationUpdates();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Actualisation en cours...')),
              );
            },
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement des positions...'),
                ],
              ),
            )
          : _hasActiveOrders 
              ? Column(
                  children: [
                    // Carte Google Maps pour le suivi en temps réel
                    Expanded(
                      flex: 2,
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: GoogleMap(
                            initialCameraPosition: const CameraPosition(
                              target: LatLng(-4.325, 15.308),
                              zoom: 12,
                            ),
                            onMapCreated: (GoogleMapController controller) {
                              _mapController = controller;
                            },
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
                        ),
                      ),
                    ),
                
                // Cartes d'information
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // Carte d'appel
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
                        
                        const SizedBox(height: 8),
                        
                        // Carte d'information sur la route
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
                                        const Text(
                                          'Informations du trajet',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Distance: $_routeDistance',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        Text(
                                          'Durée estimée: $_routeDuration',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        
                        if (_routeDistance != null && _routeDuration != null)
                          const SizedBox(height: 8),
                        
                        // Contrôles de navigation Mapbox
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Navigation',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _isNavigationActive ? null : _startNavigation,
                                        icon: const Icon(Icons.navigation, color: Colors.white),
                                        label: const Text('Démarrer'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _isNavigationActive ? _finishNavigation : null,
                                        icon: const Icon(Icons.stop),
                                        label: const Text('Arrêter'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_instruction.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Instruction: $_instruction',
                                      style: const TextStyle(fontStyle: FontStyle.italic),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
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
    _positionStreamSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }
} 
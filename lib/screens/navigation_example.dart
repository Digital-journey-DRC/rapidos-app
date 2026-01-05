import 'package:flutter/material.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:immo/constants.dart';
import 'package:immo/widgets/app_logo.dart';
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

    print('📍 [Navigation] User Role: $userRole, User ID: $userId');

    // Écouter directement la collection locations basée sur le rôle et orderId
    if (userRole == 'acheteur') {
      // D'abord, écouter ma propre position pour obtenir l'orderId actuel
      FirebaseFirestore.instance
          .collection('locations')
          .where('userId', isEqualTo: userId)
          .where('role', isEqualTo: 'acheteur')
          .snapshots()
          .listen((myLocationSnapshot) {
            print('📍 [Navigation] Acheteur location docs: ${myLocationSnapshot.docs.length}');
            if (myLocationSnapshot.docs.isNotEmpty) {
              final myData = myLocationSnapshot.docs.first.data();
              final myOrderId = myData['orderId'] as String?;
              
              print('📍 [Navigation] Acheteur orderId actuel: $myOrderId');
              
              if (myOrderId != null && myOrderId.isNotEmpty) {
                // Écouter les livreurs avec le même orderId
                FirebaseFirestore.instance
                    .collection('locations')
                    .where('orderId', isEqualTo: myOrderId)
                    .where('role', isEqualTo: 'livreur')
                    .snapshots()
                    .listen((livreurSnapshot) {
                      print('📍 [Navigation] Received ${livreurSnapshot.docs.length} livreur locations for orderId: $myOrderId');
                      
                      setState(() {
                        _hasActiveOrders = livreurSnapshot.docs.isNotEmpty;
                        _isLoading = false;
                      });
                      
                      if (livreurSnapshot.docs.isNotEmpty) {
                        _updateMarkersFromLocations(livreurSnapshot.docs, userRole, userId);
                      } else {
                        _clearMapData();
                      }
                    });
              } else {
                setState(() {
                  _hasActiveOrders = false;
                  _isLoading = false;
                });
                _clearMapData();
              }
            } else {
              print('📍 [Navigation] Aucune position trouvée pour acheteur $userId');
              setState(() {
                _isLoading = false;
              });
            }
          });
    } else if (userRole == 'livreur') {
      // D'abord, écouter ma propre position pour obtenir l'orderId actuel
      FirebaseFirestore.instance
          .collection('locations')
          .where('userId', isEqualTo: userId)
          .where('role', isEqualTo: 'livreur')
          .snapshots()
          .listen((myLocationSnapshot) {
            print('📍 [Navigation] Livreur location docs: ${myLocationSnapshot.docs.length}');
            
            if (myLocationSnapshot.docs.isNotEmpty) {
              final myData = myLocationSnapshot.docs.first.data();
              final myOrderId = myData['orderId'] as String?;
              
              print('📍 [Navigation] Livreur orderId actuel: $myOrderId');
              
              if (myOrderId != null && myOrderId.isNotEmpty) {
                // Écouter les acheteurs avec le même orderId
                FirebaseFirestore.instance
                    .collection('locations')
                    .where('orderId', isEqualTo: myOrderId)
                    .where('role', isEqualTo: 'acheteur')
                    .snapshots()
                    .listen((acheteurSnapshot) {
                      print('📍 [Navigation] Received ${acheteurSnapshot.docs.length} acheteur locations for orderId: $myOrderId');
                      
                      setState(() {
                        _hasActiveOrders = acheteurSnapshot.docs.isNotEmpty;
                        _isLoading = false;
                      });
                      
                      if (acheteurSnapshot.docs.isNotEmpty) {
                        _updateMarkersFromLocations(acheteurSnapshot.docs, userRole, userId);
                      } else {
                        _clearMapData();
                      }
                    });
              } else {
                setState(() {
                  _hasActiveOrders = false;
                  _isLoading = false;
                });
                _clearMapData();
              }
            } else {
              print('📍 [Navigation] Aucune position trouvée pour livreur $userId');
              setState(() {
                _isLoading = false;
              });
            }
          });
    }
  }
  
  void _clearMapData() {
    setState(() {
      _markers.clear();
      _polylines.clear();
      _livreurPosition = null;
      _acheteurPosition = null;
      _routeDistance = null;
      _routeDuration = null;
    });
    print('📍 [Navigation] No active orders, cleared map data');
  }

  void _updateMarkersFromLocations(List<QueryDocumentSnapshot> locations, String userRole, String myUserId) {
    final markers = <Marker>{};
    
    print('📍 [Navigation] Updating markers for role: $userRole');
    
    for (var doc in locations) {
      final data = doc.data() as Map<String, dynamic>;
      final locationUserId = data['userId'] as String?;
      final role = data['role'] as String?;
      final phone = data['phone'] as String?;
      final lat = data['latitude'] as double?;
      final lng = data['longitude'] as double?;
      
      if (lat == null || lng == null) continue;
      
      final position = LatLng(lat, lng);
      
      if (userRole == 'acheteur' && role == 'livreur') {
        // Afficher le livreur (icône bleue)
        _livreurPosition = position;
        _livreurPhone = phone;
        
        markers.add(
          Marker(
            markerId: MarkerId('livreur_$locationUserId'),
            position: position,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: InfoWindow(
              title: 'Livreur',
              snippet: phone != null ? 'Tél: $phone' : 'En route vers vous',
            ),
          ),
        );
        print('📍 [Navigation] Added livreur marker at $position');
      } else if (userRole == 'livreur' && role == 'acheteur') {
        // Afficher l'acheteur (icône rouge)
        _acheteurPosition = position;
        _acheteurPhone = phone;
        
        markers.add(
          Marker(
            markerId: MarkerId('acheteur_$locationUserId'),
            position: position,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(
              title: 'Client',
              snippet: phone != null ? 'Tél: $phone' : 'En attente de livraison',
            ),
          ),
        );
        print('📍 [Navigation] Added acheteur marker at $position');
      }
    }
    
    // Ajouter ma propre position
    _addMyPositionMarker(markers, userRole, myUserId);
  }
  
  void _addMyPositionMarker(Set<Marker> markers, String userRole, String myUserId) {
    // Récupérer ma propre position depuis la collection locations
    FirebaseFirestore.instance
        .collection('locations')
        .where('userId', isEqualTo: myUserId)
        .limit(1)
        .get()
        .then((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final myData = snapshot.docs.first.data();
            final lat = myData['latitude'] as double?;
            final lng = myData['longitude'] as double?;
            final phone = myData['phone'] as String?;
            
            if (lat != null && lng != null) {
              final myPosition = LatLng(lat, lng);
              
              if (userRole == 'livreur') {
                _livreurPosition = myPosition;
                _livreurPhone = phone;
                
                markers.add(
                  Marker(
                    markerId: const MarkerId('my_position'),
                    position: myPosition,
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                    infoWindow: const InfoWindow(
                      title: 'Ma position (Livreur)',
                      snippet: 'Position actuelle',
                    ),
                  ),
                );
              } else if (userRole == 'acheteur') {
                _acheteurPosition = myPosition;
                _acheteurPhone = phone;
                
                markers.add(
                  Marker(
                    markerId: const MarkerId('my_position'),
                    position: myPosition,
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                    infoWindow: const InfoWindow(
                      title: 'Ma position',
                      snippet: 'Position actuelle',
                    ),
                  ),
                );
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
          }
        });
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    try {
      // Nettoyer et formater le numéro de téléphone
      String cleanedPhone = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
      
      // S'assurer que le numéro commence par +
      if (!cleanedPhone.startsWith('+')) {
        cleanedPhone = '+$cleanedPhone';
      }
      
      print('📞 Attempting to call: $cleanedPhone');
      
      final Uri phoneUri = Uri.parse('tel:$cleanedPhone');
      
      // Vérifier si l'URL peut être lancée
      bool canLaunch = await canLaunchUrl(phoneUri);
      print('📱 canLaunchUrl result: $canLaunch');
      
      if (canLaunch) {
        try {
          await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
          print('✅ Phone call launched successfully');
        } catch (launchError) {
          print('❌ Error launching URL: $launchError');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Impossible d\'ouvrir l\'application téléphone. Vérifiez que vous êtes sur un appareil réel et non un émulateur.'),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      } else {
        print('❌ Cannot launch phone call for: $cleanedPhone');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Impossible d\'appeler. Sur un émulateur, cette fonctionnalité n\'est pas disponible. Testez sur un appareil réel.'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error making phone call: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'appel: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
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
      appBar: AppBarWithLogo(
        leading: widget.backNavigation == true ? IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ) : null,
        title: 'Navigation Avancée',
        backgroundColor: Colors.white,
        elevation: 0,
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
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Chargement des positions...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
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
                
                // Cartes d'information avec scroll
                Container(
                  height: MediaQuery.of(context).size.height * 0.35,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 8,
                      bottom: MediaQuery.of(context).padding.bottom + 20,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Carte d'appel
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isLivreur
                                          ? [Colors.green.shade400, Colors.green.shade600]
                                          : [Colors.red.shade400, Colors.red.shade600],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (isLivreur ? Colors.green : Colors.red).withOpacity(0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    isLivreur
                                        ? Icons.location_on
                                        : Icons.delivery_dining,
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
                                        isLivreur
                                            ? 'Position de l\'acheteur'
                                            : 'Position du livreur',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        isLivreur
                                            ? 'Appeler le client'
                                            : 'Contacter le livreur',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primary,
                                        AppColors.primary.withOpacity(0.8),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(10),
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
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.phone,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 6),
                                            const Text(
                                              'Appeler',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Carte d'information sur la route
                        if (_routeDistance != null && _routeDuration != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.blue.shade400,
                                          Colors.blue.shade600,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blue.withOpacity(0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.route,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Informations du trajet',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.straighten,
                                              size: 14,
                                              color: Colors.grey.shade600,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              _routeDistance ?? 'N/A',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey.shade700,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.access_time,
                                              size: 14,
                                              color: Colors.grey.shade600,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              _routeDuration ?? 'N/A',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey.shade700,
                                                fontWeight: FontWeight.w500,
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
                          ),
                        
                        // Contrôles de navigation Mapbox
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.navigation,
                                        color: AppColors.primary,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'Navigation',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _isNavigationActive ? null : _startNavigation,
                                        icon: const Icon(Icons.play_arrow, size: 18),
                                        label: const Text('Démarrer'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.green.shade700,
                                          side: BorderSide(
                                            color: Colors.green.shade700,
                                            width: 1.5,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _isNavigationActive ? _finishNavigation : null,
                                        icon: const Icon(Icons.stop, size: 18),
                                        label: const Text('Arrêter'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red.shade700,
                                          side: BorderSide(
                                            color: _isNavigationActive ? Colors.red.shade700 : Colors.grey.shade300,
                                            width: 1.5,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_instruction.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.blue.shade50,
                                          Colors.blue.shade100.withOpacity(0.5),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.blue.shade200,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          color: Colors.blue.shade700,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            _instruction,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.blue.shade900,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
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
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.delivery_dining_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Aucune livraison en cours',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Vous n\'avez pas de commande\nen cours de livraison',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
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
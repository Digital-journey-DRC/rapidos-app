// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:immo/constants.dart';
// import 'package:immo/cubit/auth_cubit.dart';
// import 'package:flutter/services.dart';
// import 'dart:typed_data';
// import 'dart:ui' as ui;
// import 'package:url_launcher/url_launcher.dart';
// import 'dart:convert';
// import 'dart:math';
// import 'package:http/http.dart' as http;
// import 'dart:async';
// import 'package:geolocator/geolocator.dart';
// import 'package:immo/services/mapbox_navigation_service.dart';

// class TrackingMapBox extends StatefulWidget {
//   const TrackingMapBox({Key? key}) : super(key: key);

//   @override
//   State<TrackingMapBox> createState() => _TrackingMapBoxState();
// }

// class _TrackingMapBoxState extends State<TrackingMapBox> {
//   mapbox.MapboxMap? _mapboxMap;
//   mapbox.PointAnnotationManager? _pointAnnotationManager;
//   mapbox.LineLayer? _routeLineLayer;
//   mapbox.Source? _routeSource;
//   bool _isLoading = true;
//   String? _currentOrderId;
//   String? _livreurPhone;
//   String? _acheteurPhone;
//   mapbox.Point? _livreurPosition;
//   mapbox.Point? _acheteurPosition;
//   String? _routeDistance;
//   String? _routeDuration;
//   bool _hasActiveOrders = false;
//   Position? _currentPosition;
  
//   // Variables pour la navigation Mapbox
//   bool _isNavigationActive = false;
//   List<mapbox.Point> _routePoints = [];
//   List<Map<String, dynamic>> _navigationSteps = [];
//   int _currentStepIndex = 0;
//   Set<int> _alreadySpoken = {};
//   bool _isRealTimeNavigationActive = false;
  
//   // Token Mapbox
//   static const String MAPBOX_ACCESS_TOKEN = "pk.eyJ1Ijoic3R5bm9zIiwiYSI6ImNtY21ncHRsZjAyemYyanNlM3lxd2R6d28ifQ.X2fT6wYbpn3QvTSdQCCYgw";

//   // Navigation service
//   final NavigationService _navigationService = NavigationService();

//   @override
//   void initState() {
//     super.initState();
//     print("🗺️ Initialisation de TrackingMapBox");
//     print("🔑 Token Mapbox: $MAPBOX_ACCESS_TOKEN");
//     _setupLocationUpdates();
//     _centerMapOnUserLocation();
//     _initializeLocationPermissions();
//     _updateLivreurPosition();
//     _initializeNavigationService();
//   }

//   // Initialize navigation service
//   Future<void> _initializeNavigationService() async {
//     try {
//       await _navigationService.initializeNavigation();
//       print("✅ Navigation service initialized in TrackingMapBox");
//     } catch (e) {
//       print("❌ Error initializing navigation service: $e");
//     }
//   }

//   // Initialiser les permissions de géolocalisation
//   Future<void> _initializeLocationPermissions() async {
//     try {
//       bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) {
//         print("❌ Les services de localisation sont désactivés");
//         return;
//       }

//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//         if (permission == LocationPermission.denied) {
//           print("❌ Permissions de localisation refusées");
//           return;
//         }
//       }

//       if (permission == LocationPermission.deniedForever) {
//         print("❌ Permissions de localisation refusées définitivement");
//         return;
//       }

//       print("✅ Permissions de géolocalisation accordées");
//     } catch (e) {
//       print("❌ Erreur lors de l'initialisation des permissions: $e");
//     }
//   }

//   // Mettre à jour la position du livreur connecté
//   Future<void> _updateLivreurPosition() async {
//     try {
//       final authState = context.read<AuthCubit>().state;
//       if (authState is! AuthSuccess || authState.user == null) return;

//       final userRole = authState.user!['role'];
//       final userId = authState.user!['id'].toString();
//       final userPhone = authState.user!['phone'] as String?;

//       if (userRole != 'livreur') {
//         print("ℹ️ Utilisateur n'est pas un livreur, pas de mise à jour de position");
//         return;
//       }

//       print("🚚 Mise à jour de la position du livreur connecté...");

//       Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );

//       print("📍 Position obtenue: ${position.latitude}, ${position.longitude}");

//       Map<String, dynamic> positionData = {
//         'userId': userId,
//         'role': 'livreur',
//         'latitude': position.latitude,
//         'longitude': position.longitude,
//         'phone': userPhone,
//         'timestamp': FieldValue.serverTimestamp(),
//       };

//       await FirebaseFirestore.instance
//           .collection('locations')
//           .doc(userId)
//           .set(positionData, SetOptions(merge: true));

//       print("✅ Position du livreur mise à jour avec succès");

//       setState(() {
//         _livreurPosition = mapbox.Point(coordinates: mapbox.Position(position.longitude, position.latitude));
//         _livreurPhone = userPhone;
//       });

//     } catch (e) {
//       print("❌ Erreur lors de la mise à jour de la position du livreur: $e");
//     }
//   }

//   void _setupLocationUpdates() {
//     final authState = context.read<AuthCubit>().state;
//     if (authState is! AuthSuccess || authState.user == null) return;

//     final userRole = authState.user!['role'];
//     final userId = authState.user!['id'].toString();

//     print('User Role: $userRole, User ID: $userId');

//     Query cartQuery = FirebaseFirestore.instance
//         .collection('carts')
//         .where('status', isEqualTo: 'en route pour livraison');

//     if (userRole == 'acheteur') {
//       cartQuery = cartQuery.where('idClient', isEqualTo: userId);
//     } else if (userRole == 'livreur') {
//       cartQuery = cartQuery.where('livreur', isEqualTo: userId);
//     }

//     cartQuery.snapshots().listen((cartSnapshot) {
//       print('Received ${cartSnapshot.docs.length} cart updates for user $userId with role $userRole');
      
//       setState(() {
//         _hasActiveOrders = cartSnapshot.docs.isNotEmpty;
//         _isLoading = false;
//       });
      
//       if (cartSnapshot.docs.isNotEmpty) {
//         print('Active orders found, setting up location tracking...');
        
//         if (userRole == 'acheteur') {
//           final livreurIds = cartSnapshot.docs
//               .map((doc) => (doc.data() as Map<String, dynamic>)['livreur'] as String?)
//               .where((id) => id != null && id!.isNotEmpty)
//               .map((id) => id!)
//               .toSet();
          
//           print('Livreur IDs from carts for acheteur: $livreurIds');
          
//           if (livreurIds.isNotEmpty) {
//             FirebaseFirestore.instance
//                 .collection('locations')
//                 .where('userId', whereIn: livreurIds.toList())
//                 .where('role', isEqualTo: 'livreur')
//                 .snapshots()
//                 .listen((locationSnapshot) {
//                   print('Received ${locationSnapshot.docs.length} livreur location updates');
//                   _updateMarkers(locationSnapshot.docs, userRole, cartSnapshot.docs);
//                 });
//           }
//         } else if (userRole == 'livreur') {
//           final clientIds = cartSnapshot.docs
//               .map((doc) => (doc.data() as Map<String, dynamic>)['idClient'] as String?)
//               .where((id) => id != null && id!.isNotEmpty)
//               .map((id) => id!)
//               .toSet();
          
//           print('Client IDs from carts for livreur: $clientIds');
          
//           if (clientIds.isNotEmpty) {
//             FirebaseFirestore.instance
//                 .collection('locations')
//                 .where('userId', whereIn: clientIds.toList())
//                 .where('role', isEqualTo: 'acheteur')
//                 .snapshots()
//                 .listen((locationSnapshot) {
//                   print('Received ${locationSnapshot.docs.length} client location updates');
//                   _updateMarkers(locationSnapshot.docs, userRole, cartSnapshot.docs);
//                 });
//           }
//         }
//       } else {
//         setState(() {
//           _livreurPosition = null;
//           _acheteurPosition = null;
//           _routeDistance = null;
//           _routeDuration = null;
//           _routePoints.clear();
//         });
//         print('No active orders, cleared map data');
//       }
//     });
//   }

//   void _updateMarkers(List<QueryDocumentSnapshot> otherLocations, String userRole, List<QueryDocumentSnapshot> carts) {
//     final authState = context.read<AuthCubit>().state;
//     if (authState is! AuthSuccess || authState.user == null) return;
    
//     final userId = authState.user!['id'].toString();
//     mapbox.Point? myPosition;

//     print('Updating markers for role: $userRole');

//     final Map<String, QueryDocumentSnapshot> latestPositions = {};
//     for (var doc in otherLocations) {
//       final data = doc.data() as Map<String, dynamic>;
//       final locationUserId = data['userId'] as String;
//       latestPositions[locationUserId] = doc;
//     }

//     if (userRole == 'acheteur') {
//       for (var doc in latestPositions.values) {
//         final data = doc.data() as Map<String, dynamic>;
//         final locationUserId = data['userId'] as String;
//         final phone = data['phone'] as String?;

//         print('Processing livreur location for acheteur - UserId: $locationUserId, Phone: $phone');
        
//         _livreurPhone = phone;
//         print('Updated livreur phone to: $_livreurPhone');
        
//         final livreurPosition = mapbox.Point(coordinates: mapbox.Position(
//           (data['longitude'] as num).toDouble(), 
//           (data['latitude'] as num).toDouble()
//         ));

//         _livreurPosition = livreurPosition;

//         // Ajouter marqueur livreur sur Mapbox
//         _addLivreurMarker(livreurPosition, phone);
//         print('Added livreur marker for acheteur');
//       }

//       // Récupérer position acheteur
//       FirebaseFirestore.instance
//           .collection('locations')
//           .where('userId', isEqualTo: userId)
//           .where('role', isEqualTo: 'acheteur')
//           .limit(1)
//           .get()
//           .then((acheteurSnapshot) {
//             if (acheteurSnapshot.docs.isNotEmpty) {
//               final acheteurData = acheteurSnapshot.docs.first.data();
//               final acheteurPhone = acheteurData['phone'] as String?;
              
//               _acheteurPhone = acheteurPhone;
              
//               final acheteurPosition = mapbox.Point(coordinates: mapbox.Position(
//                 (acheteurData['longitude'] as num).toDouble(), 
//                 (acheteurData['latitude'] as num).toDouble()
//               ));
              
//               _acheteurPosition = acheteurPosition;
              
//               // Ajouter marqueur acheteur
//               _addAcheteurMarker(acheteurPosition, acheteurPhone);
              
//               // Calculer itinéraire si on a les deux positions
//               if (_livreurPosition != null) {
//                 _calculateRoute(_livreurPosition!, _acheteurPosition!);
//               }
//             }
//           });

//     } else if (userRole == 'livreur') {
//       for (var doc in latestPositions.values) {
//         final data = doc.data() as Map<String, dynamic>;
//         final locationUserId = data['userId'] as String;
//         final phone = data['phone'] as String?;

//         print('Processing client location for livreur - UserId: $locationUserId, Phone: $phone');
        
//         _acheteurPhone = phone;
//         print('Updated client phone to: $_acheteurPhone');
        
//         final clientPosition = mapbox.Point(coordinates: mapbox.Position(
//           (data['longitude'] as num).toDouble(), 
//           (data['latitude'] as num).toDouble()
//         ));

//         _acheteurPosition = clientPosition;

//         // Ajouter marqueur client sur Mapbox
//         _addAcheteurMarker(clientPosition, phone);
//         print('Added client marker for livreur');
//       }

//       // Récupérer position livreur
//       FirebaseFirestore.instance
//           .collection('locations')
//           .where('userId', isEqualTo: userId)
//           .where('role', isEqualTo: 'livreur')
//           .limit(1)
//           .get()
//           .then((livreurSnapshot) {
//             if (livreurSnapshot.docs.isNotEmpty) {
//               final livreurData = livreurSnapshot.docs.first.data();
//               final livreurPhone = livreurData['phone'] as String?;
              
//               _livreurPhone = livreurPhone;
              
//               final livreurPosition = mapbox.Point(coordinates: mapbox.Position(
//                 (livreurData['longitude'] as num).toDouble(), 
//                 (livreurData['latitude'] as num).toDouble()
//               ));
              
//               _livreurPosition = livreurPosition;
              
//               // Ajouter marqueur livreur
//               _addLivreurMarker(livreurPosition, livreurPhone);
              
//               // Calculer itinéraire si on a les deux positions
//               if (_acheteurPosition != null) {
//                 _calculateRoute(_livreurPosition!, _acheteurPosition!);
//               }
//             }
//           });
//     }
//   }

//   // Ajouter marqueur livreur sur Mapbox
//   void _addLivreurMarker(mapbox.Point position, String? phone) async {
//     if (_pointAnnotationManager != null) {
//       final options = mapbox.PointAnnotationOptions(
//         geometry: position,
//         iconSize: 1.5,
//         iconImage: "marker-15", // Icône Mapbox par défaut
//         textField: "Livreur",
//         textOffset: [0.0, 1.5],
//         textSize: 12.0,
//       );
      
//       await _pointAnnotationManager!.create(options);
//     }
//   }

//   // Ajouter marqueur acheteur sur Mapbox
//   void _addAcheteurMarker(mapbox.Point position, String? phone) async {
//     if (_pointAnnotationManager != null) {
//       final options = mapbox.PointAnnotationOptions(
//         geometry: position,
//         iconSize: 1.5,
//         iconImage: "marker-15",
//         iconColor: 0xFF0000, // Rouge pour l'acheteur
//         textField: "Acheteur", 
//         textOffset: [0.0, 1.5],
//         textSize: 12.0,
//       );
      
//       await _pointAnnotationManager!.create(options);
//     }
//   }

//   // Calculer itinéraire avec Mapbox Directions API
//   Future<void> _calculateRoute(mapbox.Point origin, mapbox.Point destination) async {
//     try {
//       print("🗺️ Calcul d'itinéraire Mapbox...");
      
//       final url = Uri.parse(
//         'https://api.mapbox.com/directions/v5/mapbox/driving/'
//         '${origin.coordinates.lng},${origin.coordinates.lat};'
//         '${destination.coordinates.lng},${destination.coordinates.lat}'
//         '?access_token=$MAPBOX_ACCESS_TOKEN'
//         '&geometries=geojson'
//         '&steps=true'
//         '&language=fr'
//       );

//       final response = await http.get(url);
      
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         final routes = data['routes'] as List;
        
//         if (routes.isNotEmpty) {
//           final route = routes.first;
//           final geometry = route['geometry'];
//           final coordinates = geometry['coordinates'] as List;
          
//           // Convertir les coordonnées en Point
//           _routePoints = coordinates.map((coord) {
//             return mapbox.Point(coordinates: mapbox.Position(
//               (coord[0] as num).toDouble(), 
//               (coord[1] as num).toDouble()
//             ));
//           }).toList();
          
//           // Extraire distance et durée
//           final distance = route['distance'] as double;
//           final duration = route['duration'] as double;
          
//           setState(() {
//             _routeDistance = '${(distance / 1000).toStringAsFixed(1)} km';
//             _routeDuration = '${(duration / 60).round()} min';
//           });
          
//           // Ajouter l'itinéraire sur la carte
//           _addRouteToMap();
          
//           // Obtenir les instructions de navigation
//           _getNavigationInstructions(route);
          
//           print("✅ Itinéraire calculé: $_routeDistance, $_routeDuration");
//         }
//       } else {
//         print("❌ Erreur API Mapbox: ${response.statusCode}");
//       }
//     } catch (e) {
//       print("❌ Erreur lors du calcul d'itinéraire: $e");
//     }
//   }

//   // Ajouter l'itinéraire sur la carte Mapbox
//   void _addRouteToMap() async {
//     if (_mapboxMap == null || _routePoints.isEmpty) return;

//     try {
//       // Créer la source GeoJSON pour l'itinéraire
//       final routeSource = mapbox.GeoJsonSource(
//         id: "route-source",
//         data: json.encode({
//           "type": "Feature",
//           "properties": {},
//           "geometry": {
//             "type": "LineString",
//             "coordinates": _routePoints.map((point) => [
//               point.coordinates.lng,
//               point.coordinates.lat
//             ]).toList()
//           }
//         })
//       );

//       // Créer le style de ligne pour l'itinéraire
//       final routeLayer = mapbox.LineLayer(
//         id: "route-layer",
//         sourceId: "route-source",
//         lineColor: Colors.blue.value,
//         lineWidth: 4.0,
//         lineCap: mapbox.LineCap.ROUND,
//         lineJoin: mapbox.LineJoin.ROUND,
//       );

//       // Ajouter la source et la couche à la carte
//       await _mapboxMap!.style.addSource(routeSource);
//       await _mapboxMap!.style.addLayer(routeLayer);
      
//       print("✅ Itinéraire ajouté sur la carte");
//     } catch (e) {
//       print("❌ Erreur lors de l'ajout de l'itinéraire: $e");
//     }
//   }

//   // Obtenir les instructions de navigation
//   void _getNavigationInstructions(Map<String, dynamic> route) {
//     try {
//       final legs = route['legs'] as List;
//       if (legs.isNotEmpty) {
//         final steps = legs[0]['steps'] as List;
//         _navigationSteps = steps.map((step) => step as Map<String, dynamic>).toList();
//         print("✅ ${_navigationSteps.length} instructions de navigation obtenues");
//       }
//     } catch (e) {
//       print("❌ Erreur lors de l'obtention des instructions: $e");
//     }
//   }

//   // Centrer la carte sur la position utilisateur
//   Future<void> _centerMapOnUserLocation() async {
//     try {
//       Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );
      
//       setState(() {
//         _currentPosition = position;
//       });
      
//       if (_mapboxMap != null) {
//         await _mapboxMap!.flyTo(
//           mapbox.CameraOptions(
//             center: mapbox.Point(coordinates: mapbox.Position(position.longitude, position.latitude)),
//             zoom: 15.0,
//           ),
//           mapbox.MapAnimationOptions(duration: 1000),
//         );
//       }
//     } catch (e) {
//       print("❌ Erreur lors du centrage de la carte: $e");
//     }
//   }

//   // Démarrer la navigation Mapbox
//   Future<void> _startNavigation() async {
//     if (_acheteurPosition != null) {
//       try {
//         setState(() {
//           _isNavigationActive = true;
//         });
        
//         // Start navigation using the navigation service
//         await _navigationService.startNavigation(
//           destinationLat: _acheteurPosition!.coordinates.lat.toDouble(),
//           destinationLng: _acheteurPosition!.coordinates.lng.toDouble(),
//           destinationName: "Client",
//         );
        
//         print("🚀 Navigation Mapbox démarrée");
        
//         // Update UI based on navigation service status
//         setState(() {
//           _isNavigationActive = _navigationService.isNavigationActive;
//         });
        
//       } catch (e) {
//         print("❌ Erreur lors du démarrage de la navigation: $e");
//         setState(() {
//           _isNavigationActive = false;
//         });
        
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Erreur lors du démarrage de la navigation: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Position du client non disponible'),
//           backgroundColor: Colors.orange,
//         ),
//       );
//     }
//   }

//   // Arrêter la navigation
//   Future<void> _stopNavigation() async {
//     try {
//       await _navigationService.finishNavigation();
//       setState(() {
//         _isNavigationActive = false;
//       });
//       print("🛑 Navigation Mapbox arrêtée");
//     } catch (e) {
//       print("❌ Erreur lors de l'arrêt de la navigation: $e");
//     }
//   }

//   // Afficher les instructions de navigation
//   void _showNavigationInstructions() {
//     if (_navigationSteps.isEmpty) return;
    
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       builder: (context) => Container(
//         height: MediaQuery.of(context).size.height * 0.6,
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text(
//                   'Instructions de navigation',
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//                 IconButton(
//                   onPressed: () => Navigator.pop(context),
//                   icon: const Icon(Icons.close),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             Expanded(
//               child: ListView.builder(
//                 itemCount: _navigationSteps.length,
//                 itemBuilder: (context, index) {
//                   final step = _navigationSteps[index];
//                   final instruction = step['maneuver']?['instruction'] ?? 'Continuez';
//                   final distance = step['distance'] != null 
//                       ? '${(step['distance'] as num).round()}m'
//                       : '';
                  
//                   return Card(
//                     margin: const EdgeInsets.only(bottom: 8),
//                     child: ListTile(
//                       leading: Icon(
//                         _getManeuverIcon(step['maneuver']?['type']),
//                         color: AppColors.primary,
//                       ),
//                       title: Text(instruction),
//                       subtitle: Text(distance),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // Obtenir l'icône pour le type de manœuvre
//   IconData _getManeuverIcon(String? maneuverType) {
//     switch (maneuverType) {
//       case 'turn':
//         return Icons.turn_right;
//       case 'turn_left':
//         return Icons.turn_left;
//       case 'turn_right':
//         return Icons.turn_right;
//       case 'straight':
//         return Icons.straight;
//       case 'arrive':
//         return Icons.location_on;
//       default:
//         return Icons.navigation;
//     }
//   }

//   // Faire un appel téléphonique
//   Future<void> _makePhoneCall(String phoneNumber) async {
//     try {
//       final url = Uri.parse('tel:$phoneNumber');
//       if (await canLaunchUrl(url)) {
//         await launchUrl(url);
//         print("📞 Appel lancé vers: $phoneNumber");
//       } else {
//         print("❌ Impossible de lancer l'appel");
//       }
//     } catch (e) {
//       print("❌ Erreur lors de l'appel: $e");
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Suivi de Livraison - Mapbox'),
//         backgroundColor: AppColors.primary,
//         foregroundColor: Colors.white,
//         elevation: 0,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.my_location),
//             onPressed: _centerMapOnUserLocation,
//             tooltip: 'Ma position',
//           ),
//         ],
//       ),
//       body: _hasActiveOrders
//           ? Stack(
//               children: [
//                 // Carte Mapbox
//                 mapbox.MapWidget(
//                   key: const ValueKey("mapWidget"),
//                   cameraOptions: mapbox.CameraOptions(
//                     center: _currentPosition != null
//                         ? mapbox.Point(coordinates: mapbox.Position(_currentPosition!.longitude, _currentPosition!.latitude))
//                         : mapbox.Point(coordinates: mapbox.Position(18.4241, -33.9249)), // Cape Town par défaut
//                     zoom: 15.0,
//                   ),
//                   styleUri: mapbox.MapboxStyles.MAPBOX_STREETS,
//                   textureView: true,
//                   onMapCreated: (mapbox.MapboxMap mapboxMap) {
//                     print("🗺️ Carte Mapbox créée avec succès");
//                     _mapboxMap = mapboxMap;
                    
//                     // Initialiser le gestionnaire d'annotations
//                     mapboxMap.annotations.createPointAnnotationManager().then((manager) {
//                       _pointAnnotationManager = manager;
//                       print("✅ Gestionnaire d'annotations créé");
//                       setState(() {
//                         _isLoading = false;
//                       });
//                     }).catchError((error) {
//                       print("❌ Erreur lors de la création du gestionnaire d'annotations: $error");
//                       setState(() {
//                         _isLoading = false;
//                       });
//                     });
//                   },
//                 ),
                
//                 // Indicateur de chargement
//                 if (_isLoading)
//                   const Positioned(
//                     top: 100,
//                     left: 0,
//                     right: 0,
//                     child: Center(
//                       child: Card(
//                         child: Padding(
//                           padding: EdgeInsets.all(16),
//                           child: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               SizedBox(
//                                 width: 20,
//                                 height: 20,
//                                 child: CircularProgressIndicator(strokeWidth: 2),
//                               ),
//                               SizedBox(width: 16),
//                               Text('Chargement de la carte...'),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
                
//                 // Contrôles en bas
//                 Positioned(
//                   bottom: 16,
//                   left: 16,
//                   right: 16,
//                   child: Column(
//                     children: [
//                       // Informations d'itinéraire
//                       if (_routeDistance != null && _routeDuration != null)
//                         Card(
//                           elevation: 4,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: Padding(
//                             padding: const EdgeInsets.all(16),
//                             child: Row(
//                               children: [
//                                 Container(
//                                   padding: const EdgeInsets.all(8),
//                                   decoration: BoxDecoration(
//                                     color: Colors.blue.withOpacity(0.1),
//                                     borderRadius: BorderRadius.circular(8),
//                                   ),
//                                   child: const Icon(
//                                     Icons.route,
//                                     color: Colors.blue,
//                                   ),
//                                 ),
//                                 const SizedBox(width: 12),
//                                 Expanded(
//                                   child: Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       Text(
//                                         'Distance: $_routeDistance',
//                                         style: const TextStyle(
//                                           fontWeight: FontWeight.bold,
//                                           fontSize: 14,
//                                         ),
//                                       ),
//                                       const SizedBox(height: 4),
//                                       Text(
//                                         'Durée: $_routeDuration',
//                                         style: const TextStyle(
//                                           color: Colors.grey,
//                                           fontSize: 12,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                                 // Bouton de navigation
//                                 GestureDetector(
//                                   onTap: () {
//                                     if (_isNavigationActive) {
//                                       _stopNavigation();
//                                     } else {
//                                       _startNavigation();
//                                     }
//                                   },
//                                   child: Container(
//                                     padding: const EdgeInsets.all(8),
//                                     decoration: BoxDecoration(
//                                       color: _isNavigationActive 
//                                           ? Colors.red.withOpacity(0.1)
//                                           : Colors.green.withOpacity(0.1),
//                                       borderRadius: BorderRadius.circular(8),
//                                     ),
//                                     child: Column(
//                                       mainAxisSize: MainAxisSize.min,
//                                       children: [
//                                         Icon(
//                                           _isNavigationActive 
//                                               ? Icons.stop
//                                               : Icons.navigation,
//                                           color: _isNavigationActive 
//                                               ? Colors.red
//                                               : Colors.green,
//                                           size: 20,
//                                         ),
//                                         const SizedBox(height: 2),
//                                         Text(
//                                           _isNavigationActive ? 'Arrêter' : 'Naviguer',
//                                           style: TextStyle(
//                                             fontSize: 8,
//                                             color: _isNavigationActive 
//                                                 ? Colors.red
//                                                 : Colors.green,
//                                             fontWeight: FontWeight.bold,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
                      
//                       const SizedBox(height: 8),
                      
//                       // Carte d'appel
//                       Card(
//                         elevation: 4,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Padding(
//                           padding: const EdgeInsets.all(16),
//                           child: Row(
//                             children: [
//                               Container(
//                                 padding: const EdgeInsets.all(8),
//                                 decoration: BoxDecoration(
//                                   color: Colors.green.withOpacity(0.1),
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                                 child: const Icon(
//                                   Icons.phone,
//                                   color: Colors.green,
//                                 ),
//                               ),
//                               const SizedBox(width: 12),
//                               Expanded(
//                                 child: Text(
//                                   'Appeler le livreur',
//                                   style: const TextStyle(fontWeight: FontWeight.bold),
//                                 ),
//                               ),
//                               const SizedBox(width: 20),
//                               Expanded(
//                                 child: GestureDetector(
//                                   onTap: () {
//                                     final phoneToCall = _livreurPhone;
//                                     if (phoneToCall != null && phoneToCall.isNotEmpty) {
//                                       _makePhoneCall(phoneToCall);
//                                     } else {
//                                       ScaffoldMessenger.of(context).showSnackBar(
//                                         const SnackBar(
//                                           content: Text('Numéro de téléphone non disponible'),
//                                         ),
//                                       );
//                                     }
//                                   },
//                                   child: Container(
//                                     padding: const EdgeInsets.all(8),
//                                     decoration: BoxDecoration(
//                                       color: AppColors.primary,
//                                       borderRadius: BorderRadius.circular(8),
//                                     ),
//                                     child: const Text(
//                                       'Appeler',
//                                       textAlign: TextAlign.center,
//                                       style: TextStyle(
//                                         color: Colors.white,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             )
//           : Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(
//                     Icons.delivery_dining,
//                     size: 80,
//                     color: Colors.grey[400],
//                   ),
//                   const SizedBox(height: 16),
//                   Text(
//                     'Aucune livraison en cours',
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.grey[600],
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     'Vous n\'avez pas de commande\n en cours',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: Colors.grey[500],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }

//   @override
//   void dispose() {
//     _mapboxMap?.dispose();
//     _navigationService.dispose();
//     super.dispose();
//   }
// } 
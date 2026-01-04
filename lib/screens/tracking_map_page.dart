import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:immo/constants.dart';
import 'package:immo/widgets/app_logo.dart';
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
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';

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
  
  // Variables pour la navigation vocale
  FlutterTts? _flutterTts;
  bool _isVoiceNavigationActive = false;
  Timer? _voiceNavigationTimer;
  List<String> _navigationInstructions = [];
  int _currentInstructionIndex = 0;
  
  // Variables pour la navigation vocale dynamique en temps réel
  StreamSubscription<Position>? _positionStreamSubscription;
  List<Map<String, dynamic>> _navigationSteps = [];
  int _currentStepIndex = 0;
  Set<int> _alreadySpoken = {};
  bool _isRealTimeNavigationActive = false;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    // Initialiser l'icône du livreur et démarrer immédiatement
    _initializeMarkerIcon();
    // Démarrer immédiatement les mises à jour de localisation
    _setupLocationUpdates();
    // Centrer la carte immédiatement sans délai
    _centerMapOnUserLocation();
    
    // Initialiser la navigation vocale de manière asynchrone
    _initializeVoiceNavigation();
    
    // Initialiser les permissions de géolocalisation
    _initializeLocationPermissions();
    
    // Mettre à jour la position du livreur connecté
    _updateLivreurPosition();
  }

  Future<void> _initializeMarkerIcon() async {
    try {
      print('Loading livreur icon from assets...');

      // Charger l'image depuis les assets
      final ByteData bytes =
          await rootBundle.load('assets/images/pin-livreur.png');
      final Uint8List data = bytes.buffer.asUint8List();

      // Réduire la taille de l'image pour améliorer les performances (plus petit)
      final Uint8List resizedData = await _resizeImage(data, 60, 60);

      // Créer l'icône à partir des données de l'image
      livreurIcon = BitmapDescriptor.fromBytes(resizedData);

      print('Livreur icon loaded successfully with optimized size');

      // Appliquer le style de la carte immédiatement
      if (_mapController != null) {
        _setMapStyle();
      }
    } catch (e) {
      print('Error loading livreur icon: $e');
      // En cas d'erreur, utiliser l'icône bleue par défaut immédiatement
      livreurIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      // Appliquer le style de la carte
      if (_mapController != null) {
        _setMapStyle();
      }
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

  // Initialiser la navigation vocale de manière sécurisée
  Future<void> _initializeVoiceNavigation() async {
    try {
      _flutterTts = FlutterTts();
      
      // Configuration pour iOS
      await _flutterTts!.setSharedInstance(true);
      await _flutterTts!.setIosAudioCategory(
        IosTextToSpeechAudioCategory.ambient,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers
        ],
        IosTextToSpeechAudioMode.voicePrompt
      );
      
      // Configuration par défaut
      await _flutterTts!.setLanguage("fr-FR");
      await _flutterTts!.setSpeechRate(0.5);
      await _flutterTts!.setVolume(1.0);
      await _flutterTts!.setPitch(1.0);
      
      // Configuration spécifique pour Android
      if (Theme.of(context).platform == TargetPlatform.android) {
        await _flutterTts!.setAudioAttributesForNavigation();
        print("🤖 Configuration Android TTS appliquée");
      }
      
      // Test simple de TTS
      await _testSimpleTTS();
      
      print("🔊 Navigation vocale initialisée avec succès");
    } catch (e) {
      print("❌ Erreur lors de l'initialisation de la navigation vocale: $e");
      // Ne pas faire échouer l'application si la navigation vocale échoue
    }
  }

  // Test simple de TTS
  Future<void> _testSimpleTTS() async {
    try {
      print("🔍 Test simple TTS...");
      
      if (Theme.of(context).platform == TargetPlatform.android) {
        print("🤖 Android - Test avec focus");
        await _flutterTts!.speak("Test navigation", focus: true);
      } else {
        print("🍎 iOS - Test normal");
        await _flutterTts!.speak("Test navigation");
      }
      
      print("✅ Test TTS simple terminé");
    } catch (e) {
      print("❌ Erreur test TTS simple: $e");
    }
  }

  // Initialiser les permissions de géolocalisation
  Future<void> _initializeLocationPermissions() async {
    try {
      // Vérifier si les services de localisation sont activés
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print("❌ Les services de localisation sont désactivés");
        return;
      }

      // Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print("❌ Permissions de localisation refusées");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print("❌ Permissions de localisation refusées définitivement");
        return;
      }

      print("✅ Permissions de géolocalisation accordées");
    } catch (e) {
      print("❌ Erreur lors de l'initialisation des permissions: $e");
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

      // Créer le document de position pour le livreur (champs essentiels seulement)
      Map<String, dynamic> positionData = {
        'userId': userId,           // Identifiant unique du livreur
        'role': 'livreur',          // Rôle pour filtrer les positions
        'latitude': position.latitude,    // Position GPS
        'longitude': position.longitude,  // Position GPS
        'phone': userPhone,         // Numéro pour les appels
        'timestamp': FieldValue.serverTimestamp(), // Moment de la mise à jour
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

  void _setupLocationUpdates() {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthSuccess || authState.user == null) return;

    final userRole = authState.user!['role'];
    final userId = authState.user!['id'].toString();

    print('📍 [TrackingMap] User Role: $userRole, User ID: $userId');

    // Écouter directement la collection locations basée sur le rôle
    if (userRole == 'acheteur') {
      // D'abord, écouter ma propre position pour obtenir l'orderId actuel
      FirebaseFirestore.instance
          .collection('locations')
          .where('userId', isEqualTo: userId)
          .where('role', isEqualTo: 'acheteur')
          .snapshots()
          .listen((myLocationSnapshot) {
            print('📍 [TrackingMap] Acheteur location docs: ${myLocationSnapshot.docs.length}');
            
            if (myLocationSnapshot.docs.isNotEmpty) {
              final myData = myLocationSnapshot.docs.first.data();
              final myOrderId = myData['orderId'] as String?;
              
              print('📍 [TrackingMap] Acheteur orderId actuel: $myOrderId');
              
              if (myOrderId != null && myOrderId.isNotEmpty) {
                _currentOrderId = myOrderId;
                
                // Écouter les livreurs avec le même orderId
                FirebaseFirestore.instance
                    .collection('locations')
                    .where('orderId', isEqualTo: myOrderId)
                    .where('role', isEqualTo: 'livreur')
                    .snapshots()
                    .listen((livreurSnapshot) {
                      print('📍 [TrackingMap] Received ${livreurSnapshot.docs.length} livreur locations for orderId: $myOrderId');
                      
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
              print('📍 [TrackingMap] Aucune position trouvée pour acheteur $userId');
              setState(() {
                _isLoading = false;
              });
            }
          });
    } else if (userRole == 'livreur') {
      // Le livreur voit sa propre position et les acheteurs liés à ses commandes
      // D'abord, écouter ma propre position pour obtenir l'orderId actuel
      FirebaseFirestore.instance
          .collection('locations')
          .where('userId', isEqualTo: userId)
          .where('role', isEqualTo: 'livreur')
          .snapshots()
          .listen((myLocationSnapshot) {
            if (myLocationSnapshot.docs.isNotEmpty) {
              final myData = myLocationSnapshot.docs.first.data();
              final myOrderId = myData['orderId'] as String?;
              
              print('📍 [TrackingMap] Livreur orderId actuel: $myOrderId');
              
              if (myOrderId != null && myOrderId.isNotEmpty) {
                _currentOrderId = myOrderId;
                
                // Écouter les acheteurs avec le même orderId
                FirebaseFirestore.instance
                    .collection('locations')
                    .where('orderId', isEqualTo: myOrderId)
                    .where('role', isEqualTo: 'acheteur')
                    .snapshots()
                    .listen((acheteurSnapshot) {
                      print('📍 [TrackingMap] Received ${acheteurSnapshot.docs.length} acheteur locations for orderId: $myOrderId');
                      
                      setState(() {
                        _hasActiveOrders = true;
                        _isLoading = false;
                      });
                      
                      _updateMarkersFromLocations(acheteurSnapshot.docs, userRole, userId);
                    });
              } else {
                setState(() {
                  _hasActiveOrders = false;
                  _isLoading = false;
                });
                _clearMapData();
              }
            } else {
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
    print('📍 [TrackingMap] No active orders, cleared map data');
  }
  
  void _updateMarkersFromLocations(List<QueryDocumentSnapshot> locations, String userRole, String myUserId) {
    final markers = <Marker>{};
    
    print('📍 [TrackingMap] Updating markers for role: $userRole');
    
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
        // Afficher le livreur (icône bleue personnalisée)
        _livreurPosition = position;
        _livreurPhone = phone;
        
        markers.add(
          Marker(
            markerId: MarkerId('livreur_$locationUserId'),
            position: position,
            icon: livreurIcon,
            infoWindow: InfoWindow(
              title: 'Livreur',
              snippet: phone != null ? 'Tél: $phone' : 'En route vers vous',
            ),
            zIndex: 1,
          ),
        );
        print('📍 [TrackingMap] Added livreur marker at $position');
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
            zIndex: 1,
          ),
        );
        print('📍 [TrackingMap] Added acheteur marker at $position');
      }
    }
    
    // Ajouter ma propre position
    _addMyPositionMarker(markers, userRole, myUserId);
    
    setState(() {
      _markers = markers;
    });
    
    // Calculer l'itinéraire si les deux positions sont disponibles
    if (_livreurPosition != null && _acheteurPosition != null) {
      _calculateRoute(_livreurPosition!, _acheteurPosition!);
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) _fitMapToRoute();
      });
    }
    
    print('📍 [TrackingMap] Total markers: ${_markers.length}');
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
                    icon: livreurIcon,
                    infoWindow: const InfoWindow(
                      title: 'Ma position (Livreur)',
                      snippet: 'Position actuelle',
                    ),
                    zIndex: 2,
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
                    zIndex: 2,
                  ),
                );
              }
              
              setState(() {
                _markers = markers;
              });
              
              // Recalculer l'itinéraire
              if (_livreurPosition != null && _acheteurPosition != null) {
                _calculateRoute(_livreurPosition!, _acheteurPosition!);
              }
            }
          }
        });
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
    if (_mapController != null) {
      if (_markers.isNotEmpty) {
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
      } else {
        // Position par défaut si aucun marqueur
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            const CameraPosition(
              target: LatLng(-4.325, 15.308),
              zoom: 12,
              tilt: 0,
              bearing: 0,
            ),
          ),
        );
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    
    // Appliquer le style de la carte immédiatement
    _setMapStyle();
    
    // Centrer la carte immédiatement si des marqueurs sont déjà disponibles
    if (_markers.isNotEmpty) {
      _centerMapOnUserLocation();
    } else {
      // Sinon, centrer sur une position par défaut (Kinshasa)
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          const CameraPosition(
            target: LatLng(-4.325, 15.308),
            zoom: 12,
          ),
        ),
      );
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
        googleApiKey: 'AIzaSyCpJzuEa7jLAcP8ub8AVM8flT2aK5cPdh0',
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
          
          // Obtenir les instructions de navigation de manière asynchrone et sécurisée
          _getNavigationInstructionsAsync(origin, destination);
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

  // Nettoyer les balises HTML des instructions
  String _cleanHtmlInstructions(String htmlInstructions) {
    // Supprimer les balises HTML courantes
    String cleanText = htmlInstructions
        .replaceAll(RegExp(r'<[^>]*>'), '') // Supprimer toutes les balises HTML
        .replaceAll('&nbsp;', ' ') // Remplacer les espaces insécables
        .replaceAll('&amp;', '&') // Remplacer les ampersands
        .replaceAll('&lt;', '<') // Remplacer les <
        .replaceAll('&gt;', '>') // Remplacer les >
        .replaceAll('&quot;', '"') // Remplacer les guillemets
        .trim(); // Supprimer les espaces en début et fin
    
    // Traduction en français des instructions de navigation
    cleanText = cleanText
        .replaceAll(RegExp(r'\bTurn left onto\b', caseSensitive: false), 'Tournez à gauche sur')
        .replaceAll(RegExp(r'\bTurn right onto\b', caseSensitive: false), 'Tournez à droite sur')
        .replaceAll(RegExp(r'\bContinue onto\b', caseSensitive: false), 'Continuez sur')
        .replaceAll(RegExp(r'\bTurn left\b', caseSensitive: false), 'Tournez à gauche')
        .replaceAll(RegExp(r'\bTurn right\b', caseSensitive: false), 'Tournez à droite')
        .replaceAll(RegExp(r'\bTurn\b', caseSensitive: false), 'Tournez')
        .replaceAll(RegExp(r'\bturn\b', caseSensitive: false), 'Tournez')
        .replaceAll(RegExp(r'\bContinue\b', caseSensitive: false), 'Continuez')
        .replaceAll(RegExp(r'\bcontinue\b', caseSensitive: false), 'Continuez')
        .replaceAll(RegExp(r'\bleft\b', caseSensitive: false), 'gauche')
        .replaceAll(RegExp(r'\bright\b', caseSensitive: false), 'droite')
        .replaceAll(RegExp(r'\bonto\b', caseSensitive: false), 'sur')
        .replaceAll(RegExp(r'\bstraight\b', caseSensitive: false), 'tout droit')
        .replaceAll(RegExp(r'\bthe\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\band\b', caseSensitive: false), 'et')
        .replaceAll(RegExp(r'\bat\b', caseSensitive: false), 'à');
    
    return cleanText;
  }

  // Obtenir les instructions de navigation de manière asynchrone et sécurisée
  Future<void> _getNavigationInstructionsAsync(LatLng origin, LatLng destination) async {
    try {
      final String apiKey = 'AIzaSyCpJzuEa7jLAcP8ub8AVM8flT2aK5cPdh0';
      final String url = 'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&language=fr'
          '&region=CD'
          '&key=$apiKey';

      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          final List<dynamic> routes = data['routes'];
          if (routes.isNotEmpty) {
            final List<dynamic> legs = routes[0]['legs'];
            if (legs.isNotEmpty) {
              final List<dynamic> steps = legs[0]['steps'];
              
              // Essayer d'abord la navigation vocale dynamique
              try {
                _startRealTimeNavigation(steps);
              } catch (e) {
                print("❌ Navigation dynamique échouée, utilisation du fallback: $e");
                // Fallback vers la navigation vocale simple
                _startSimpleVoiceNavigation(steps);
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error getting navigation instructions: $e');
      // Ne pas faire échouer le calcul de route à cause des instructions vocales
    }
  }

  // Démarrer la navigation vocale dynamique en temps réel
  void _startRealTimeNavigation(List<dynamic> steps) {
    try {
      // Vérifier le rôle de l'utilisateur
      final authState = context.read<AuthCubit>().state;
      if (authState is! AuthSuccess || authState.user == null) {
        print("❌ Utilisateur non connecté, navigation vocale désactivée");
        return;
      }

      final userRole = authState.user!['role'];
      
      // Désactiver la navigation vocale pour les acheteurs
      if (userRole == 'acheteur') {
        print("ℹ️ Navigation vocale désactivée pour l'acheteur");
        return;
      }

      // Arrêter la navigation précédente si elle est active
      _stopRealTimeNavigation();

      // Convertir les steps en format utilisable
      _navigationSteps = steps.map((step) => {
        'html_instructions': step['html_instructions'],
        'end_location': step['end_location'],
        'distance': step['distance'],
        'duration': step['duration'],
      }).toList();

      print("🗺️ Démarrage de la navigation vocale dynamique avec ${_navigationSteps.length} étapes");

      // Réinitialiser les variables
      _currentStepIndex = 0;
      _alreadySpoken.clear();
      _isRealTimeNavigationActive = true;

      // Lire immédiatement la première instruction
      if (_navigationSteps.isNotEmpty) {
        _speakStepInstruction(0);
      }

      // Démarrer le stream de position
      _startPositionStream();

      if (mounted) {
        setState(() {
          _isVoiceNavigationActive = true;
        });
      }

    } catch (e) {
      print("❌ Erreur lors du démarrage de la navigation dynamique: $e");
    }
  }

  // Démarrer le stream de position pour la navigation en temps réel
  void _startPositionStream() {
    try {
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Mettre à jour tous les 10 mètres
      );

      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          _currentPosition = position;
          _checkProximityToStep();
        },
        onError: (error) {
          print("❌ Erreur du stream de position: $error");
        },
      );

      print("📍 Stream de position démarré");
    } catch (e) {
      print("❌ Erreur lors du démarrage du stream de position: $e");
    }
  }

  // Vérifier la proximité avec l'étape actuelle
  void _checkProximityToStep() {
    if (!_isRealTimeNavigationActive || _currentPosition == null || _navigationSteps.isEmpty) {
      return;
    }

    // Trouver l'étape la plus proche
    double minDistance = double.infinity;
    int closestStepIndex = -1;

    for (int i = 0; i < _navigationSteps.length; i++) {
      if (_alreadySpoken.contains(i)) continue;

      final step = _navigationSteps[i];
      final endLocation = step['end_location'];
      
      double distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        endLocation['lat'].toDouble(),
        endLocation['lng'].toDouble(),
      );

      if (distance < minDistance) {
        minDistance = distance;
        closestStepIndex = i;
      }
    }

    // Si on est proche d'une étape (moins de 30 mètres) et qu'elle n'a pas encore été lue
    if (closestStepIndex != -1 && minDistance <= 30 && !_alreadySpoken.contains(closestStepIndex)) {
      _speakStepInstruction(closestStepIndex);
    }

    // Vérifier si toutes les étapes sont terminées
    if (_alreadySpoken.length == _navigationSteps.length) {
      _stopRealTimeNavigation();
      _speakArrivalMessage();
    }
  }

  // Lire l'instruction d'une étape
  void _speakStepInstruction(int stepIndex) async {
    try {
      if (_flutterTts == null || stepIndex >= _navigationSteps.length) {
        return;
      }

      final step = _navigationSteps[stepIndex];
      String instruction = _cleanHtmlInstructions(step['html_instructions']);
      
      print("🔊 Lecture de l'étape ${stepIndex + 1}: $instruction");
      
      if (Theme.of(context).platform == TargetPlatform.android) {
        await _flutterTts!.speak(instruction, focus: true);
      } else {
        await _flutterTts!.speak(instruction);
      }
      
      _alreadySpoken.add(stepIndex);
      _currentStepIndex = stepIndex;

    } catch (e) {
      print("❌ Erreur lors de la lecture de l'étape: $e");
    }
  }

  // Lire le message d'arrivée
  void _speakArrivalMessage() async {
    try {
      if (_flutterTts == null) return;
      
      print("🎯 Arrivée à destination");
      
      if (Theme.of(context).platform == TargetPlatform.android) {
        await _flutterTts!.speak("Vous êtes arrivé à destination", focus: true);
      } else {
        await _flutterTts!.speak("Vous êtes arrivé à destination");
      }
      
    } catch (e) {
      print("❌ Erreur lors du message d'arrivée: $e");
    }
  }

  // Arrêter la navigation vocale dynamique
  void _stopRealTimeNavigation() {
    try {
      _isRealTimeNavigationActive = false;
      
      if (_positionStreamSubscription != null) {
        _positionStreamSubscription!.cancel();
        _positionStreamSubscription = null;
      }

      // Ne pas vider _navigationSteps pour permettre le redémarrage
      // _navigationSteps.clear();
      _currentStepIndex = 0;
      _alreadySpoken.clear();
      _currentPosition = null;

      if (mounted) {
        setState(() {
          _isVoiceNavigationActive = false;
        });
      }

      print("🛑 Navigation vocale dynamique arrêtée");
    } catch (e) {
      print("❌ Erreur lors de l'arrêt de la navigation dynamique: $e");
    }
  }

  // Redémarrer la navigation vocale dynamique
  void _restartRealTimeNavigation() {
    try {
      // Vérifier le rôle de l'utilisateur
      final authState = context.read<AuthCubit>().state;
      if (authState is! AuthSuccess || authState.user == null) {
        print("❌ Utilisateur non connecté, navigation vocale désactivée");
        return;
      }

      final userRole = authState.user!['role'];
      
      // Désactiver la navigation vocale pour les acheteurs
      if (userRole == 'acheteur') {
        print("ℹ️ Navigation vocale désactivée pour l'acheteur");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Navigation vocale non disponible pour les acheteurs'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      if (_navigationSteps.isNotEmpty) {
        // Réinitialiser les variables pour un nouveau départ
        _currentStepIndex = 0;
        _alreadySpoken.clear();
        _isRealTimeNavigationActive = true;
        
        // Démarrer le stream de position
        _startPositionStream();
        
        if (mounted) {
          setState(() {
            _isVoiceNavigationActive = true;
          });
        }
        
        print("🔄 Navigation vocale dynamique redémarrée avec ${_navigationSteps.length} étapes");
      } else {
        print("❌ Aucune étape de navigation disponible pour redémarrer");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucun itinéraire disponible. Recalculez l\'itinéraire.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print("❌ Erreur lors du redémarrage de la navigation: $e");
      // Essayer la navigation simple en fallback
      if (_navigationSteps.isNotEmpty) {
        _startSimpleVoiceNavigation(_navigationSteps);
      }
    }
  }

  // Obtenir le statut de la navigation vocale
  String _getNavigationStatus() {
    if (!_isRealTimeNavigationActive) {
      return "Navigation inactive";
    }
    
    if (_navigationSteps.isEmpty) {
      return "Aucune étape";
    }
    
    int completedSteps = _alreadySpoken.length;
    int totalSteps = _navigationSteps.length;
    
    if (completedSteps >= totalSteps) {
      return "Arrivée à destination";
    }
    
    return "Étape ${completedSteps + 1} sur $totalSteps";
  }

  // Navigation vocale simple en fallback (sans géolocalisation)
  void _startSimpleVoiceNavigation(List<dynamic> steps) {
    try {
      if (_flutterTts == null) {
        print("❌ FlutterTts n'est pas initialisé");
        return;
      }

      // Arrêter la navigation précédente
      _stopRealTimeNavigation();

      // Extraire et nettoyer les instructions
      List<String> instructions = steps
          .map((step) => _cleanHtmlInstructions(step['html_instructions']))
          .where((instruction) => instruction.isNotEmpty)
          .toList();

      if (instructions.isEmpty) {
        print("❌ Aucune instruction de navigation trouvée");
        return;
      }

      print("🔊 Démarrage de la navigation vocale simple avec ${instructions.length} instructions");

      if (mounted) {
        setState(() {
          _isVoiceNavigationActive = true;
        });
      }

      // Lire la première instruction immédiatement
      if (instructions.isNotEmpty) {
        _flutterTts!.speak(instructions[0]);
        print("🔊 Lecture de la première instruction: ${instructions[0]}");
      }

      // Programmer la lecture des instructions suivantes
      _voiceNavigationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
        int currentIndex = timer.tick;
        if (currentIndex < instructions.length && mounted && _isVoiceNavigationActive) {
          _flutterTts!.speak(instructions[currentIndex]);
          print("🔊 Lecture de l'instruction ${currentIndex + 1}: ${instructions[currentIndex]}");
        } else {
          timer.cancel();
          if (mounted) {
            setState(() {
              _isVoiceNavigationActive = false;
            });
          }
        }
      });

    } catch (e) {
      print("❌ Erreur lors du démarrage de la navigation simple: $e");
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
        title: 'Suivi de livraison',
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
                                // Bouton de navigation vocale - Caché pour les acheteurs
                                Builder(
                                  builder: (context) {
                                    // Vérifier le rôle de l'utilisateur
                                    final authState = context.read<AuthCubit>().state;
                                    final userRole = authState is AuthSuccess && authState.user != null 
                                        ? authState.user!['role'] 
                                        : null;
                                    final isAcheteur = userRole == 'acheteur';
                                    
                                    // Cacher complètement le bouton pour les acheteurs
                                    if (isAcheteur) {
                                      return const SizedBox.shrink();
                                    }
                                    
                                    return GestureDetector(
                                      onTap: () {
                                        if (_isVoiceNavigationActive) {
                                          _stopRealTimeNavigation();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Navigation vocale désactivée'),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        } else {
                                          // Redémarrer la navigation vocale si des instructions sont disponibles
                                          if (_navigationSteps.isNotEmpty) {
                                            _restartRealTimeNavigation();
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Navigation vocale activée'),
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Aucun itinéraire disponible. Recalculez l\'itinéraire.'),
                                                duration: Duration(seconds: 3),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: _isVoiceNavigationActive 
                                              ? Colors.green.withOpacity(0.1)
                                              : Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              _isVoiceNavigationActive 
                                                  ? Icons.volume_off
                                                  : Icons.volume_up,
                                              color: _isVoiceNavigationActive 
                                                  ? Colors.green
                                                  : Colors.red,
                                              size: 20,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _getNavigationStatus(),
                                              style: TextStyle(
                                                fontSize: 8,
                                                color: _isVoiceNavigationActive 
                                                    ? Colors.green
                                                    : Colors.red,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
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
    // Arrêter la navigation vocale
    _stopRealTimeNavigation();
    
    // Nettoyer les ressources
    _mapController?.dispose();
    super.dispose();
  }
}

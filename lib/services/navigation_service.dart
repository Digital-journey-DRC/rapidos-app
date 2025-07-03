import 'package:flutter/material.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  // Navigation state
  bool _isNavigationActive = false;
  bool _isRouteBuilt = false;
  bool _arrived = false;
  String _instruction = "";
  double _distanceRemaining = 0.0;
  double _durationRemaining = 0.0;
  List<WayPoint> _wayPoints = [];

  // Getters
  bool get isNavigationActive => _isNavigationActive;
  bool get isRouteBuilt => _isRouteBuilt;
  bool get arrived => _arrived;
  String get instruction => _instruction;
  double get distanceRemaining => _distanceRemaining;
  double get durationRemaining => _durationRemaining;
  List<WayPoint> get wayPoints => _wayPoints;

  // Initialize navigation options
  Future<void> initializeNavigation() async {
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

      // Register route event listener
      MapBoxNavigation.instance.registerRouteEventListener(_onRouteEvent);
      
      print("✅ Navigation service initialized successfully");
    } catch (e) {
      print("❌ Error initializing navigation service: $e");
    }
  }

  // Route event handler
  Future<void> _onRouteEvent(e) async {
    try {
      switch (e.eventType) {
        case MapBoxEvent.progress_change:
          var progressEvent = e.data as RouteProgressEvent;
          _arrived = progressEvent.arrived ?? false;
          if (progressEvent.currentStepInstruction != null) {
            _instruction = progressEvent.currentStepInstruction ?? "";
          }
          break;
        case MapBoxEvent.route_building:
        case MapBoxEvent.route_built:
          _isRouteBuilt = true;
          break;
        case MapBoxEvent.route_build_failed:
          _isRouteBuilt = false;
          print("❌ Route build failed");
          break;
        case MapBoxEvent.navigation_running:
          _isNavigationActive = true;
          break;
        case MapBoxEvent.on_arrival:
          _arrived = true;
          print("🎯 Arrived at destination");
          break;
        case MapBoxEvent.navigation_finished:
        case MapBoxEvent.navigation_cancelled:
          _isRouteBuilt = false;
          _isNavigationActive = false;
          _arrived = false;
          print("🏁 Navigation finished or cancelled");
          break;
        default:
          break;
      }
    } catch (e) {
      print("❌ Error in route event handler: $e");
    }
  }

  // Start navigation to a destination
  Future<void> startNavigation({
    required double destinationLat,
    required double destinationLng,
    String? destinationName,
    double? originLat,
    double? originLng,
    String? originName,
  }) async {
    try {
      // Get current position if origin not provided
      if (originLat == null || originLng == null) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        originLat = position.latitude;
        originLng = position.longitude;
        originName = "Ma position";
      }

      // Create waypoints
      _wayPoints = [
        WayPoint(
          name: originName ?? "Départ",
          latitude: originLat,
          longitude: originLng,
        ),
        WayPoint(
          name: destinationName ?? "Destination",
          latitude: destinationLat,
          longitude: destinationLng,
        ),
      ];

      print("🗺️ Starting navigation to: ${destinationName ?? 'Destination'}");
      print("📍 From: $originLat, $originLng");
      print("📍 To: $destinationLat, $destinationLng");

      await MapBoxNavigation.instance.startNavigation(wayPoints: _wayPoints);
      
    } catch (e) {
      print("❌ Error starting navigation: $e");
      rethrow;
    }
  }

  // Start navigation with multiple waypoints
  Future<void> startNavigationWithWaypoints(List<WayPoint> wayPoints) async {
    try {
      _wayPoints = wayPoints;
      
      print("🗺️ Starting navigation with ${wayPoints.length} waypoints");
      
      await MapBoxNavigation.instance.startNavigation(wayPoints: wayPoints);
      
    } catch (e) {
      print("❌ Error starting navigation with waypoints: $e");
      rethrow;
    }
  }

  // Finish navigation
  Future<void> finishNavigation() async {
    try {
      await MapBoxNavigation.instance.finishNavigation();
      _isNavigationActive = false;
      _isRouteBuilt = false;
      _arrived = false;
      print("🏁 Navigation finished");
    } catch (e) {
      print("❌ Error finishing navigation: $e");
    }
  }

  // Cancel navigation
  Future<void> cancelNavigation() async {
    try {
      await MapBoxNavigation.instance.finishNavigation();
      _isNavigationActive = false;
      _isRouteBuilt = false;
      _arrived = false;
      print("❌ Navigation cancelled");
    } catch (e) {
      print("❌ Error cancelling navigation: $e");
    }
  }

  // Get current navigation status
  Map<String, dynamic> getNavigationStatus() {
    return {
      'isNavigationActive': _isNavigationActive,
      'isRouteBuilt': _isRouteBuilt,
      'arrived': _arrived,
      'instruction': _instruction,
      'distanceRemaining': _distanceRemaining,
      'durationRemaining': _durationRemaining,
      'wayPoints': _wayPoints.map((wp) => {
        'name': wp.name,
        'latitude': wp.latitude,
        'longitude': wp.longitude,
      }).toList(),
    };
  }

  // Dispose
  void dispose() {
    // Note: flutter_mapbox_navigation doesn't have unregisterRouteEventListener
    // The event listener will be automatically cleaned up when the app is disposed
  }
} 
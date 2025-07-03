import 'package:flutter/material.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:immo/constants.dart';

class NavigationExample extends StatefulWidget {
  const NavigationExample({Key? key}) : super(key: key);

  @override
  State<NavigationExample> createState() => _NavigationExampleState();
}

class _NavigationExampleState extends State<NavigationExample> {
  bool _isNavigationActive = false;
  bool _isRouteBuilt = false;
  bool _arrived = false;
  String _instruction = "";
  double _distanceRemaining = 0.0;
  double _durationRemaining = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeNavigation();
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

  Future<void> _onRouteEvent(e) async {
    switch (e.eventType) {
      case MapBoxEvent.progress_change:
        var progressEvent = e.data as RouteProgressEvent;
        setState(() {
          _arrived = progressEvent.arrived ?? false;
          if (progressEvent.currentStepInstruction != null) {
            _instruction = progressEvent.currentStepInstruction ?? "";
          }
        });
        break;
      case MapBoxEvent.route_building:
      case MapBoxEvent.route_built:
        setState(() {
          _isRouteBuilt = true;
        });
        break;
      case MapBoxEvent.route_build_failed:
        setState(() {
          _isRouteBuilt = false;
        });
        print("❌ Route build failed");
        break;
      case MapBoxEvent.navigation_running:
        setState(() {
          _isNavigationActive = true;
        });
        break;
      case MapBoxEvent.on_arrival:
        setState(() {
          _arrived = true;
        });
        print("🎯 Arrived at destination");
        break;
      case MapBoxEvent.navigation_finished:
      case MapBoxEvent.navigation_cancelled:
        setState(() {
          _isRouteBuilt = false;
          _isNavigationActive = false;
          _arrived = false;
        });
        print("🏁 Navigation finished or cancelled");
        break;
      default:
        break;
    }
  }

  Future<void> _startNavigation() async {
    try {
      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Create waypoints (example: navigate to a nearby location)
      final wayPoints = [
        WayPoint(
          name: "Ma position",
          latitude: position.latitude,
          longitude: position.longitude,
        ),
        WayPoint(
          name: "Destination",
          latitude: position.latitude + 0.01, // 1km south
          longitude: position.longitude + 0.01, // 1km east
        ),
      ];

      await MapBoxNavigation.instance.startNavigation(wayPoints: wayPoints);
      print("🚀 Navigation started");
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
        _isRouteBuilt = false;
        _arrived = false;
      });
      print("🏁 Navigation finished");
    } catch (e) {
      print("❌ Error finishing navigation: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exemple de Navigation'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Statut de Navigation',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    _buildStatusRow('Navigation active', _isNavigationActive),
                    _buildStatusRow('Route construite', _isRouteBuilt),
                    _buildStatusRow('Arrivé à destination', _arrived),
                    if (_instruction.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Instruction: $_instruction',
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Navigation Controls
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Contrôles',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isNavigationActive ? null : _startNavigation,
                            icon: const Icon(Icons.navigation),
                            label: const Text('Démarrer Navigation'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isNavigationActive ? _finishNavigation : null,
                            icon: const Icon(Icons.stop),
                            label: const Text('Arrêter Navigation'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Instructions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instructions',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Appuyez sur "Démarrer Navigation" pour commencer\n'
                      '2. La navigation vous guidera vers la destination\n'
                      '3. Suivez les instructions vocales et visuelles\n'
                      '4. Appuyez sur "Arrêter Navigation" pour terminer',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(
            value ? Icons.check_circle : Icons.cancel,
            color: value ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text('$label: ${value ? "Oui" : "Non"}'),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
} 
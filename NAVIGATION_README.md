# Navigation Integration with flutter_mapbox_navigation

This document explains how the `flutter_mapbox_navigation` package has been integrated into the Rapidos app for turn-by-turn navigation functionality.

## Configuration

### Android Configuration

1. **Mapbox Access Token**: Already configured in `android/app/src/main/res/values/mapbox_access_token.xml`
2. **Permissions**: Location permissions are already set in `AndroidManifest.xml`
3. **MainActivity**: Already extends `FlutterFragmentActivity` as required
4. **Gradle Properties**: Added `MAPBOX_DOWNLOADS_TOKEN` for downloading Mapbox binaries
5. **Kotlin BOM**: Already configured in `build.gradle`

### iOS Configuration

1. **Mapbox Access Token**: Already configured in `Info.plist` with `MBXAccessToken`
2. **Background Modes**: Added `audio` and `location` for background navigation
3. **Embedded Views**: Added `io.flutter.embedded_views_preview` for embedded navigation view
4. **Location Permissions**: Already configured in `Info.plist`

## Files Created/Modified

### New Files
- `lib/services/navigation_service.dart` - Navigation service singleton
- `lib/screens/navigation_example.dart` - Example navigation screen

### Modified Files
- `lib/screens/tracking_map_box.dart` - Integrated navigation service
- `android/gradle.properties` - Added Mapbox downloads token
- `ios/Runner/Info.plist` - Added background modes and embedded views

## Usage

### Basic Navigation

```dart
// Initialize navigation service
final navigationService = NavigationService();
await navigationService.initializeNavigation();

// Start navigation to a destination
await navigationService.startNavigation(
  destinationLat: 40.7128,
  destinationLng: -74.0060,
  destinationName: "New York",
);
```

### Navigation with Multiple Waypoints

```dart
List<WayPoint> wayPoints = [
  WayPoint(name: "Start", latitude: 40.7128, longitude: -74.0060),
  WayPoint(name: "Stop 1", latitude: 40.7589, longitude: -73.9851),
  WayPoint(name: "Destination", latitude: 40.7505, longitude: -73.9934),
];

await navigationService.startNavigationWithWaypoints(wayPoints);
```

### Navigation Events

The navigation service listens to various events:

- `MapBoxEvent.progress_change` - Navigation progress updates
- `MapBoxEvent.route_building` - Route is being calculated
- `MapBoxEvent.route_built` - Route calculation completed
- `MapBoxEvent.navigation_running` - Navigation is active
- `MapBoxEvent.on_arrival` - Arrived at destination
- `MapBoxEvent.navigation_finished` - Navigation completed

### Integration in TrackingMapBox

The `TrackingMapBox` screen now includes:

1. **Navigation Service Integration**: Uses the singleton navigation service
2. **Navigation Controls**: Start/stop navigation buttons
3. **Error Handling**: Proper error messages and state management
4. **Status Updates**: Real-time navigation status updates

## Features

### Voice Instructions
- Turn-by-turn voice guidance in French
- Configurable language and units
- Background audio support

### Visual Instructions
- Banner instructions on screen
- Route visualization
- Distance and duration remaining

### Navigation Modes
- Driving with traffic
- Walking
- Cycling
- Configurable routing options

## Testing

### Navigation Example Screen
Use the `NavigationExample` screen to test basic navigation functionality:

1. Navigate to the example screen
2. Press "Démarrer Navigation" to start navigation
3. Follow voice and visual instructions
4. Press "Arrêter Navigation" to stop

### Integration Testing
The navigation is integrated into the delivery tracking system:

1. When a delivery is active, the navigation button appears
2. Pressing "Naviguer" starts navigation to the client's location
3. The navigation provides turn-by-turn guidance
4. Navigation automatically stops when arriving at destination

## Troubleshooting

### Common Issues

1. **Blue Screen**: Ensure Mapbox access token is correctly configured
2. **No Voice Instructions**: Check device audio settings and permissions
3. **Navigation Not Starting**: Verify location permissions are granted
4. **Route Build Failed**: Check internet connection and Mapbox token validity

### Debug Logs
The navigation service includes comprehensive logging:
- ✅ Success messages
- ❌ Error messages
- 🗺️ Map-related events
- 🚀 Navigation events
- 🎯 Arrival events
- 🏁 Completion events

## Dependencies

- `flutter_mapbox_navigation: ^0.2.2` - Main navigation package
- `geolocator: ^11.0.0` - Location services
- `mapbox_maps_flutter: ^2.9.0` - Mapbox maps integration

## Next Steps

1. **Offline Navigation**: Implement offline route caching
2. **Custom Styling**: Add custom map styles for navigation
3. **Multi-stop Routes**: Enhance support for multiple delivery stops
4. **Real-time Updates**: Integrate with live traffic data
5. **Analytics**: Add navigation analytics and metrics

## Resources

- [flutter_mapbox_navigation Documentation](https://pub.dev/packages/flutter_mapbox_navigation)
- [Mapbox Navigation SDK](https://docs.mapbox.com/android/navigation/overview/)
- [Mapbox Access Tokens](https://docs.mapbox.com/help/glossary/access-token/) 
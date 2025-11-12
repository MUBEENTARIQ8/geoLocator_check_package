# LocationService Usage Guide

## Overview

The `LocationService` class provides a convenient wrapper around the `lapse_geo_guard` package to check user location against multiple geofence sites. It now correctly checks **ALL sites** (not just the first one) and uses the following thresholds:

- **Within 30m of ANY site** → Shows "Go near window" message
- **More than 300m from ALL sites** → Shows "Too far" message  
- **Between 30m-300m** → Shows "Go near window" message

## Installation

Add the required dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  lapse_geo_guard:
    git:
      url: https://github.com/MUBEENTARIQ8/geoLocator_check_package.git
      ref: main
  flutter_secure_storage: ^9.0.0
  geolocator: ^10.1.0
```

## Basic Usage

### 1. Import the LocationService

```dart
import 'package:your_app/services/location_service.dart';
```

### 2. Create an instance

```dart
final locationService = LocationService();
```

### 3. Check user location against all sites

```dart
final decision = await locationService.evaluateUserLocation(
  context: context,
  onWithinThirtyMeters: (siteIndex, site) {
    // This callback is called when user is within 30m of any site
    print('User is within 30m of site $siteIndex');
    print('Site coordinates: lat=${site.lat}, lon=${site.lon}');
  },
);

// Check the result
if (decision.message.isEmpty) {
  // User is within 30m - no message needed
  print('User is very close!');
} else {
  // Show the message to user
  print('Message: ${decision.message}');
}
```

### 4. Simple boolean check (inside/outside)

```dart
final isInside = await locationService.isUserInsideGeofence();

if (isInside) {
  print('User is inside geofence');
} else {
  print('User is outside geofence');
}
```

## Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:your_app/services/location_service.dart';

class MyLocationCheckWidget extends StatefulWidget {
  @override
  _MyLocationCheckWidgetState createState() => _MyLocationCheckWidgetState();
}

class _MyLocationCheckWidgetState extends State<MyLocationCheckWidget> {
  final LocationService _locationService = LocationService();
  String _statusMessage = 'Ready to check location';

  Future<void> _checkLocation() async {
    setState(() {
      _statusMessage = 'Checking location...';
    });

    try {
      final decision = await _locationService.evaluateUserLocation(
        context: context,
        onWithinThirtyMeters: (siteIndex, site) {
          // Handle when user is within 30m
          print('Within 30m of site $siteIndex');
        },
      );

      setState(() {
        _statusMessage = decision.message.isEmpty 
            ? 'Location OK (within 30m)' 
            : decision.message;
      });

      // Show detailed info
      _showDetails(decision);
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
    }
  }

  void _showDetails(MultiGeofenceDecision decision) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Location Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Message: ${decision.message}'),
            Text('Inside any: ${decision.insideAny}'),
            Text('Closest distance: ${decision.closestDistanceM.toStringAsFixed(1)}m'),
            Text('Closest site: ${decision.closestSiteIndex}'),
            SizedBox(height: 8),
            Text('All distances:'),
            ...decision.distancesM.asMap().entries.map(
              (e) => Text('  Site ${e.key}: ${e.value.toStringAsFixed(1)}m'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Location Check')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_statusMessage),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _checkLocation,
              child: Text('Check Location'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## How It Works

1. **Loads Sites**: The service first tries to load sites from secure storage (saved during enrollment). If none are found, it uses default hardcoded sites.

2. **Checks ALL Sites**: The function calculates distances to **ALL** sites in the list, not just the first one.

3. **Finds Closest**: It determines which site is closest to the user.

4. **Applies Thresholds**:
   - If closest distance ≤ 30m → Shows inside message
   - If closest distance > 300m → Shows outside message
   - Otherwise (30m < distance ≤ 300m) → Shows inside message

5. **Returns Decision**: Returns a `MultiGeofenceDecision` object with:
   - `message`: The message to show to user
   - `insideAny`: Whether user is inside any site's radius
   - `closestDistanceM`: Distance to closest site
   - `closestSiteIndex`: Index of closest site
   - `distancesM`: List of distances to all sites
   - `insideFlags`: List of booleans indicating which sites user is inside

## Storing Sites in Secure Storage

To save sites during enrollment:

```dart
final storage = FlutterSecureStorage();

// Save site 1
await storage.write(key: 'lat_1', value: '24.711667019762736');
await storage.write(key: 'lon_1', value: '46.62244234390605');

// Save site 2
await storage.write(key: 'lat_2', value: '24.711255236977546');
await storage.write(key: 'lon_2', value: '46.622431615070255');

// ... and so on
```

The `LocationService` will automatically load these when `evaluateUserLocation()` is called.

## Important Notes

- The function now checks **ALL sites**, not just the first one
- Thresholds are: **30m** for "go near window" and **300m** for "too far"
- The callback `onWithinThirtyMeters` is called when user is within 30m of any site
- Make sure location permissions are granted before calling these methods
- The service handles errors gracefully and returns appropriate failure messages

## API Reference

### `evaluateUserLocation()`

Evaluates user location against all sites and returns a decision.

**Parameters:**
- `context` (required): BuildContext for localization
- `onWithinThirtyMeters` (optional): Callback when user is within 30m of any site

**Returns:** `Future<MultiGeofenceDecision>`

### `isUserInsideGeofence()`

Simple boolean check if user is inside any geofence.

**Returns:** `Future<bool>`

### `sites` (getter)

Gets the list of sites (from storage or defaults).

**Returns:** `Future<List<GeoPoint>>`


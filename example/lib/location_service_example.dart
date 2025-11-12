import 'package:flutter/material.dart';
import 'location_service.dart';

/// Example usage of LocationService
/// 
/// This demonstrates how to use the LocationService class to:
/// 1. Check user location against multiple geofence sites
/// 2. Handle different distance thresholds (30m and 300m)
/// 3. Show appropriate messages based on proximity
class LocationServiceExample extends StatefulWidget {
  const LocationServiceExample({super.key});

  @override
  State<LocationServiceExample> createState() => _LocationServiceExampleState();
}

class _LocationServiceExampleState extends State<LocationServiceExample> {
  final LocationService _locationService = LocationService();
  String _statusMessage = 'Tap button to check location';
  bool _isChecking = false;

  /// Example 1: Basic location evaluation
  Future<void> _checkUserLocation() async {
    setState(() {
      _isChecking = true;
      _statusMessage = 'Checking location...';
    });

    try {
      final decision = await _locationService.evaluateUserLocation(
        context: context,
        onWithinThirtyMeters: (siteIndex, site) {
          // This callback is called when user is within 30m of any site
          print('User is within 30m of site $siteIndex: lat=${site.lat}, lon=${site.lon}');
        },
      );

      setState(() {
        _statusMessage = decision.message.isEmpty
            ? 'Location check successful (within 30m)'
            : decision.message;
      });

      // Show detailed information
      _showDecisionDetails(decision);
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isChecking = false;
      });
    }
  }

  /// Example 2: Check if user is inside geofence (boolean check)
  Future<void> _checkInsideGeofence() async {
    setState(() {
      _isChecking = true;
      _statusMessage = 'Checking if inside geofence...';
    });

    try {
      final isInside = await _locationService.isUserInsideGeofence();

      setState(() {
        _statusMessage = isInside
            ? 'User is inside geofence ✓'
            : 'User is outside geofence ✗';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isChecking = false;
      });
    }
  }

  /// Show detailed decision information in a dialog
  void _showDecisionDetails(MultiGeofenceDecision decision) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Check Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Message: ${decision.message.isEmpty ? "None (within 30m)" : decision.message}'),
              const SizedBox(height: 8),
              Text('Inside any site: ${decision.insideAny}'),
              Text('Closest distance: ${decision.closestDistanceM.toStringAsFixed(1)}m'),
              Text('Closest site index: ${decision.closestSiteIndex}'),
              const SizedBox(height: 8),
              const Text('Distances to all sites:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...decision.distancesM.asMap().entries.map(
                    (entry) => Text('  Site ${entry.key}: ${entry.value.toStringAsFixed(1)}m'),
                  ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LocationService Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'How it works:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('• Checks ALL sites (not just the first one)'),
                    const Text('• Within 30m of ANY site → "Go near window" message'),
                    const Text('• More than 300m from ALL sites → "Too far" message'),
                    const Text('• Between 30m-300m → "Go near window" message'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _statusMessage,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isChecking ? null : _checkUserLocation,
              icon: _isChecking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.location_on),
              label: const Text('Check User Location'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isChecking ? null : _checkInsideGeofence,
              icon: _isChecking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle),
              label: const Text('Check Inside Geofence (Boolean)'),
            ),
          ],
        ),
      ),
    );
  }
}


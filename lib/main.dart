import 'package:flutter/material.dart';
import 'dart:async';
import 'lapse_geo_guard/lapse_geo_guard.dart';

void main() => runApp(const LapesGeofencingApp());

class LapesGeofencingApp extends StatelessWidget {
  const LapesGeofencingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lapes Geofencing',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const GeofencingHomePage(),
    );
  }
}

class GeofencingHomePage extends StatefulWidget {
  const GeofencingHomePage({super.key});

  @override
  State<GeofencingHomePage> createState() => _GeofencingHomePageState();
}

class _GeofencingHomePageState extends State<GeofencingHomePage> {
  String _statusText = 'Ready to check location';
  bool _isChecking = false;
  bool _isLiveTracking = false;
  GeoGuardResult? _lastResult;
  Timer? _locationTimer;
  int _checkCount = 0;
  DateTime? _lastCheckTime;

  // Entry point geofence (e.g., office gate)
  final double _entryLat = 31.432016;
  final double _entryLon = 74.287923;
  final double _entryRadiusM = 50.0; // adjust as needed

  // Inside-office geofence (e.g., center of office)
  final double _insideLat = 31.432500; // TODO: replace with actual
  final double _insideLon = 74.288300; // TODO: replace with actual
  final double _insideRadiusM = 200.0;

  // Computed dual geofence state
  bool? _isInsideEntry;
  bool? _isInsideOffice;
  double? _distanceToEntryM;
  double? _distanceToOfficeM;

  // Live tracking configuration
  final Duration _trackingInterval = const Duration(seconds: 10); // Check every 10 seconds

  Future<void> _checkGeofence() async {
    if (_isChecking) return; // Prevent multiple simultaneous checks

    setState(() {
      _isChecking = true;
      _statusText = _isLiveTracking ? 'Live tracking... (Check #${_checkCount + 1})' : 'Checking location...';
    });

    try {
      await GeoGuard.ensurePermissions();

      // Take one high-quality fix using entry config as baseline (single fix)
      final fix = await GeoGuard.quickCheck(
        siteLat: _entryLat,
        siteLon: _entryLon,
        radiusM: _entryRadiusM,
        cfg: const GeoGuardConfig(
          timeBudgetMs: 8000,
          attemptTimeoutMs: 4000,
          desiredAccuracyM: 50,
          useAccuracyCushion: true,
          androidGnssSnapshot: true,
        ),
      );

      // Compute distances to both geofences using the same fix
      final pos = fix.position;
      final distEntry = GeoGuard.distanceMeters(pos.latitude, pos.longitude, _entryLat, _entryLon);
      final distOffice = GeoGuard.distanceMeters(pos.latitude, pos.longitude, _insideLat, _insideLon);

      // Apply accuracy cushion if enabled in above config
      final effectiveEntry = distEntry - fix.accuracyM;
      final effectiveOffice = distOffice - fix.accuracyM;

      final insideEntry = effectiveEntry <= _entryRadiusM && fix.fixAgeMs <= 15000;
      final insideOffice = effectiveOffice <= _insideRadiusM && fix.fixAgeMs <= 15000;

      // Update state
      setState(() {
        _lastResult = fix;
        _distanceToEntryM = distEntry;
        _distanceToOfficeM = distOffice;
        _isInsideEntry = insideEntry;
        _isInsideOffice = insideOffice;
        _checkCount++;
        _lastCheckTime = DateTime.now();

        final bothOutside = !(insideEntry || insideOffice);
        if (_isLiveTracking) {
          _statusText = bothOutside
              ? '🔴 LIVE: Outside all geofences (Check #$_checkCount)'
              : (insideOffice ? '🟢 LIVE: Inside office (Check #$_checkCount)' : '🟡 LIVE: At entry (Check #$_checkCount)');
        } else {
          _statusText = bothOutside ? '❌ Outside all geofences' : (insideOffice ? '✅ Inside office' : '✅ At entry');
        }
        _isChecking = false;
      });

      // If outside both radii, surface an error message
      if (!insideEntry && !insideOffice) {
        if (mounted) {
          // Show non-blocking SnackBar
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You are outside the allowed radius.')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _statusText = _isLiveTracking ? '⚠️ LIVE: Error - ${e.toString()}' : 'Error: ${e.toString()}';
        _isChecking = false;
      });
    }
  }

  void _startLiveTracking() async {
    if (_isLiveTracking) return;

    try {
      await GeoGuard.ensurePermissions();

      setState(() {
        _isLiveTracking = true;
        _checkCount = 0;
        _statusText = 'Starting live tracking...';
      });

      await _checkGeofence();

      _locationTimer = Timer.periodic(_trackingInterval, (timer) {
        if (_isLiveTracking) {
          _checkGeofence();
        }
      });
    } catch (e) {
      setState(() {
        _isLiveTracking = false;
        _statusText = 'Failed to start tracking: ${e.toString()}';
      });
    }
  }

  void _stopLiveTracking() {
    _locationTimer?.cancel();
    _locationTimer = null;

    setState(() {
      _isLiveTracking = false;
      _statusText = 'Live tracking stopped. Total checks: $_checkCount';
    });
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  Widget _buildResultCard() {
    if (_lastResult == null) return const SizedBox.shrink();

    final result = _lastResult!;
    final timeSinceCheck = _lastCheckTime != null ? DateTime.now().difference(_lastCheckTime!).inSeconds : 0;

    final insideEntry = _isInsideEntry ?? false;
    final insideOffice = _isInsideOffice ?? false;

    return Card(
      margin: const EdgeInsets.all(16),
      color: _isLiveTracking ? ((insideEntry || insideOffice) ? Colors.green.shade50 : Colors.red.shade50) : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _isLiveTracking ? 'Live Location Result' : 'Location Check Result',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (_isLiveTracking) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'LIVE',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            if (_isLiveTracking) ...[
              _buildResultRow('Check Count', '#$_checkCount'),
              _buildResultRow('Last Update', '${timeSinceCheck}s ago'),
              _buildResultRow('Update Interval', '${_trackingInterval.inSeconds}s'),
              const Divider(),
            ],

            // Dual geofence summary
            Text('Entry Geofence', style: Theme.of(context).textTheme.titleMedium),
            _buildResultRow('Status', insideEntry ? 'Inside' : 'Outside'),
            _buildResultRow('Distance', _distanceToEntryM != null ? '${_distanceToEntryM!.toStringAsFixed(1)} m' : '-'),
            _buildResultRow('Radius', '${_entryRadiusM.toStringAsFixed(0)} m'),
            const SizedBox(height: 8),
            Text('Office Geofence', style: Theme.of(context).textTheme.titleMedium),
            _buildResultRow('Status', insideOffice ? 'Inside' : 'Outside'),
            _buildResultRow('Distance', _distanceToOfficeM != null ? '${_distanceToOfficeM!.toStringAsFixed(1)} m' : '-'),
            _buildResultRow('Radius', '${_insideRadiusM.toStringAsFixed(0)} m'),
            const Divider(),

            // Raw fix diagnostics
            _buildResultRow('Accuracy', '${result.accuracyM.toStringAsFixed(1)} m'),
            _buildResultRow('Fix Age', '${result.fixAgeMs} ms'),
            _buildResultRow('Latitude', result.position.latitude.toStringAsFixed(6)),
            _buildResultRow('Longitude', result.position.longitude.toStringAsFixed(6)),
            _buildResultRow('Quality Score', result.qualityScore.toStringAsFixed(3)),

            if (result.androidGnss != null && result.androidGnss!['supported'] == true) ...[
              const Divider(),
              Text(
                'GNSS Info (Android)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              _buildResultRow('Satellites Used', '${result.androidGnss!['satsUsed']}'),
              _buildResultRow('Avg CN0', '${result.androidGnss!['avgCn0']?.toStringAsFixed(1)} dB-Hz'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Lapes Geofencing'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Geofence Configuration',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    // Entry config
                    Text('Entry', style: Theme.of(context).textTheme.titleMedium),
                    _buildResultRow('Latitude', _entryLat.toStringAsFixed(6)),
                    _buildResultRow('Longitude', _entryLon.toStringAsFixed(6)),
                    _buildResultRow('Radius', '${_entryRadiusM.toStringAsFixed(0)} meters'),
                    const SizedBox(height: 8),
                    // Office config
                    Text('Office', style: Theme.of(context).textTheme.titleMedium),
                    _buildResultRow('Latitude', _insideLat.toStringAsFixed(6)),
                    _buildResultRow('Longitude', _insideLon.toStringAsFixed(6)),
                    _buildResultRow('Radius', '${_insideRadiusM.toStringAsFixed(0)} meters'),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    _statusText,
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Single Check Button
                  ElevatedButton.icon(
                    onPressed: (_isChecking || _isLiveTracking) ? null : _checkGeofence,
                    icon: _isChecking
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                    label: Text(_isChecking ? 'Checking...' : 'Check Location Once'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Live Tracking Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: (_isLiveTracking || _isChecking) ? null : _startLiveTracking,
                          icon:
                              _isLiveTracking ? const Icon(Icons.radio_button_checked, color: Colors.green) : const Icon(Icons.play_arrow),
                          label: const Text('Start Live Tracking'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isLiveTracking ? Colors.green.shade100 : null,
                            foregroundColor: _isLiveTracking ? Colors.green.shade800 : null,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLiveTracking ? _stopLiveTracking : null,
                          icon: const Icon(Icons.stop),
                          label: const Text('Stop Tracking'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isLiveTracking ? Colors.red.shade100 : null,
                            foregroundColor: _isLiveTracking ? Colors.red.shade800 : null,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (_isLiveTracking) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Live tracking active - Updates every ${_trackingInterval.inSeconds} seconds',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.blue.shade800,
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
            _buildResultCard(),
          ],
        ),
      ),
    );
  }
}

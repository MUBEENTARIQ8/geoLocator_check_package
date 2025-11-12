import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lapse_geo_guard/lapse_geo_guard.dart';

typedef SiteProximityCallback = void Function(int siteIndex, GeoPoint site);

class LocationService {
  // Default/fallback coordinates (used if storage doesn't have coordinates)
  static const _defaultSites = <GeoPoint>[
    GeoPoint(lat: 24.711667019762736, lon: 46.62244234390605, radiusM: 200),
    GeoPoint(lat: 24.711255236977546, lon: 46.622431615070255, radiusM: 200),
    GeoPoint(lat: 24.71021237270764, lon: 46.62318799799376, radiusM: 200),
    GeoPoint(lat: 24.711091985437186, lon: 46.62334356611278, radiusM: 200),
    GeoPoint(lat: 24.710909609854664, lon: 46.62255984436264, radiusM: 200),
  ];

  final _storage = const FlutterSecureStorage();

  /// Loads geofence sites from storage (saved during enrollment).
  /// Falls back to default hardcoded sites if storage is empty.
  Future<List<GeoPoint>> _loadSitesFromStorage() async {
    try {
      final List<GeoPoint> sites = [];

      // Try to read coordinates from storage
      // Coordinates are saved as lat_1, lon_1, lat_2, lon_2, etc.
      int index = 1;
      while (true) {
        final latKey = 'lat_$index';
        final lonKey = 'lon_$index';
        final latStr = await _storage.read(key: latKey);
        final lonStr = await _storage.read(key: lonKey);

        if (latStr == null || lonStr == null) {
          // No more coordinates found
          break;
        }

        final lat = double.tryParse(latStr);
        final lon = double.tryParse(lonStr);

        if (lat != null && lon != null && lat != 0.0 && lon != 0.0) {
          sites.add(GeoPoint(lat: lat, lon: lon, radiusM: 200));
          print('LocationService: Loaded site $index from storage: lat=$lat, lon=$lon');
        }

        index++;
      }

      // If we found coordinates in storage, use them
      if (sites.isNotEmpty) {
        print('LocationService: Using ${sites.length} sites from storage');
        return sites;
      }

      // Fallback to default hardcoded sites
      print('LocationService: No coordinates in storage, using default sites');
      return _defaultSites;
    } catch (e) {
      print('LocationService: Error loading sites from storage: $e');
      // On error, return default sites
      return _defaultSites;
    }
  }

  /// Gets the sites list (from storage or default)
  Future<List<GeoPoint>> get sites async => await _loadSitesFromStorage();

  Future<bool> ensureServiceEnabled() async {
    return Geolocator.isLocationServiceEnabled();
  }

  Future<bool> ensurePermissionGranted() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      return false;
    }
    return perm == LocationPermission.whileInUse || perm == LocationPermission.always;
  }

  Future<Position?> _getPositionSafe({Duration timeout = const Duration(seconds: 8)}) async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      ).timeout(timeout);
    } catch (_) {
      return Geolocator.getLastKnownPosition();
    }
  }

  /// Returns final decision + metadata for the caller.
  /// 
  /// IMPORTANT: Checks ALL sites (1 site ho ya 5 sites, sab ko check karega)
  /// 
  /// Logic:
  /// - If location matches (within 5m of ANY site): empty message (no alert)
  /// - If within 30m of ANY site (but not matched): "Go near window" message
  /// - If more than 300m from ALL sites: "Too far" message
  /// - If between 30m-300m: "Go near window" message
  /// 
  /// If the user is within 30m of any site, [onWithinThirtyMeters] callback is invoked.
  Future<MultiGeofenceDecision> evaluateUserLocation({
    required BuildContext context,
    SiteProximityCallback? onWithinThirtyMeters,
  }) async {
    if (!await ensureServiceEnabled()) {
      return _failureDecision('Please enable Location Services to continue.', []);
    }

    if (!await ensurePermissionGranted()) {
      return _failureDecision('Location permission is required. Please grant it in Settings.', []);
    }

    final pos = await _getPositionSafe();
    if (pos == null) {
      return _failureDecision('Unable to obtain your current location. Try again.', []);
    }

    // Load sites from storage (or use defaults)
    final sitesList = await sites;

    // Evaluate position against ALL sites
    // The package checks ALL sites and returns result based on closest site
    final decision = GeoGuard.evaluatePositionAgainstSites(
      userLat: pos.latitude,
      userLon: pos.longitude,
      sites: sitesList, // Sab sites pass ki (1 ho ya 5, sab check hongi)
      matchToleranceM: 5.0, // 5m ke andar match ho to empty message
      withinRadiusM: 200.0, // Used for checking if inside any site's radius
      silenceRadiusM: 30.0, // 30m threshold (not used in new logic, but kept for compatibility)
      insideMessage: Localizations.localeOf(context).languageCode == 'ar'
          ? "اذهب بالقرب من النافذة وما إلى ذلك"
          : 'Go near window and so on',
      outsideMessage: Localizations.localeOf(context).languageCode == 'ar'
          ? "أنت على بُعد أكثر من ٣٠٠ متر. يُرجى الاقتراب."
          : 'You are more than 300 meters away. Please move closer.',
    );

    print(
      'LocationService: userLat=${pos.latitude}, userLon=${pos.longitude}, '
      'distances=${decision.distancesM.map((d) => d.toStringAsFixed(1)).toList()}, '
      'closest=${decision.closestSiteIndex} '
      'insideAny=${decision.insideAny} message="${decision.message}"',
    );

    // Callback when user is within 30m of any site
    // Check if closest distance is <= 30m and callback is provided
    if (decision.closestDistanceM <= 30.0 && 
        onWithinThirtyMeters != null && 
        decision.closestSiteIndex < sitesList.length) {
      onWithinThirtyMeters(decision.closestSiteIndex, sitesList[decision.closestSiteIndex]);
    }

    return decision;
  }

  MultiGeofenceDecision _failureDecision(String message, List<GeoPoint> sitesList) {
    return MultiGeofenceDecision(
      insideAny: false,
      message: message,
      closestDistanceM: double.infinity,
      closestSiteIndex: 0,
      distances: List<double>.filled(sitesList.length, double.infinity),
      insideFlags: List<bool>.filled(sitesList.length, false),
      matchedSiteIndex: null,
      matchedSite: null,
      raw: null,
    );
  }

  /// Simple method to check if user is inside geofence.
  /// Uses coordinates from storage (saved during enrollment) or falls back to defaults.
  /// Checks ALL sites (1 site ho ya 5 sites, sab ko check karega).
  Future<bool> isUserInsideGeofence() async {
    if (!await ensureServiceEnabled()) return false;
    if (!await ensurePermissionGranted()) return false;

    // Optional warm-up to speed up the subsequent high-quality fix.
    await _getPositionSafe(timeout: const Duration(seconds: 4));

    // Configure stricter accuracy and a slightly longer time budget for reliability.
    const cfg = GeoGuardConfig(
      timeBudgetMs: 16000, // allow more time to get a good fix
      attemptTimeoutMs: 6000, // first attempt bestForNavigation, then high
      desiredAccuracyM: 25.0, // tighten desired accuracy
      maxFixAgeMs: 12000, // fix must be recent
      useAccuracyCushion: true, // conservative inside check
      androidGnssSnapshot: true, // better scoring on Android
    );

    // Load sites from storage (or use defaults)
    final sitesList = await sites;

    // Perform a single high-quality fix and evaluate ALL sites at once.
    // This checks ALL sites, not just the first one.
    final result = await GeoGuard.checkMultiple(sites: sitesList, cfg: cfg);

    // Logging for diagnostics; adjust or remove as needed.
    print('LocationService: fixAcc=${result.accuracyM} ageMs=${result.fixAgeMs} '
        'score=${result.qualityScore} insideAny=${result.insideAny} '
        'distances=${result.distancesM.map((d) => d.toStringAsFixed(1)).toList()} '
        'insideList=${result.insideList}');

    // Example decision policy:
    // - Require being inside ANY of the geofences (sab sites check ki)
    // - And prefer higher trust fixes (low score means better). Tune threshold if needed.
    if (result.insideAny && result.qualityScore <= 0.6) {
      return true;
    }

    return false;
  }
}

import 'dart:async';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'gnss_channel.dart';

/// Tuning knobs for geofencing reliability behavior.
class GeoGuardConfig {
  /// Max total time budget for collecting a good fix.
  final int timeBudgetMs;

  /// Single attempt timeout.
  final int attemptTimeoutMs;

  /// Desired accuracy.
  final double desiredAccuracyM;

  /// Max acceptable fix age.
  final int maxFixAgeMs;

  /// Accept if (distance - accuracy) <= radius.
  final bool useAccuracyCushion;

  /// Android-only: include GNSS snapshot for quality scoring.
  final bool androidGnssSnapshot;

  const GeoGuardConfig({
    this.timeBudgetMs = 12000,
    this.attemptTimeoutMs = 6000,
    this.desiredAccuracyM = 50.0,
    this.maxFixAgeMs = 15000,
    this.useAccuracyCushion = true,
    this.androidGnssSnapshot = true,
  });
}

/// Result of a quick check-in computation.
class GeoGuardResult {
  final bool inside;
  final double distanceM;
  final double accuracyM;
  final int fixAgeMs;
  final Position position;
  final double qualityScore; // 0..1, higher = lower trust
  final Map<String, dynamic>? androidGnss;

  const GeoGuardResult({
    required this.inside,
    required this.distanceM,
    required this.accuracyM,
    required this.fixAgeMs,
    required this.position,
    required this.qualityScore,
    this.androidGnss,
  });
}

/// Result for dual geofence check (entry + office).
class DualGeofenceResult {
  final Position position;
  final bool insideEntry;
  final bool insideOffice;
  final double distanceToEntryM;
  final double distanceToOfficeM;
  final double accuracyM;
  final int fixAgeMs;
  final double qualityScore;
  final Map<String, dynamic>? androidGnss;

  const DualGeofenceResult({
    required this.position,
    required this.insideEntry,
    required this.insideOffice,
    required this.distanceToEntryM,
    required this.distanceToOfficeM,
    required this.accuracyM,
    required this.fixAgeMs,
    required this.qualityScore,
    this.androidGnss,
  });
}

/// Result for office proximity checks.
class OfficeProximityResult {
  final double radiusM;
  final double? distanceToIndoorOfficeM;
  final double? distanceToEntryOfficeM;
  final bool insideIndoorOffice;
  final bool insideEntryOffice;
  /// True if inside either indoor or entry office radius
  final bool insideAnyOffice;

  const OfficeProximityResult({
    required this.radiusM,
    this.distanceToIndoorOfficeM,
    this.distanceToEntryOfficeM,
    required this.insideIndoorOffice,
    required this.insideEntryOffice,
    required this.insideAnyOffice,
  });
}

/// Distances between provided coordinate sets (in meters). Any null means that
/// the corresponding pair was not computable due to missing inputs.
class GeoDistances {
  final double? entryToOfficeM;
  final double? userToOfficeM;
  final double? userToEntryM;

  const GeoDistances({
    this.entryToOfficeM,
    this.userToOfficeM,
    this.userToEntryM,
  });

  /// True if at least one distance could be computed.
  bool get hasAnyDistance => entryToOfficeM != null || userToOfficeM != null || userToEntryM != null;
}

class GeoGuard {
  /// Ask for location permission and confirm services are enabled.
  static Future<void> ensurePermissions() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw StateError('Location services disabled');
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      throw StateError('Location permission denied');
    }
  }

  static Future<Position> _tryGetFix(Duration timeout, {bool bestNav = true}) {
    final accuracy = bestNav ? LocationAccuracy.bestForNavigation : LocationAccuracy.high;
    return Geolocator.getCurrentPosition(desiredAccuracy: accuracy).timeout(timeout);
  }

  static Future<Position> _getFixWithRetries(GeoGuardConfig cfg) async {
    final start = DateTime.now();
    Position? best;
    double bestAcc = double.infinity;

    while (DateTime.now().difference(start).inMilliseconds < cfg.timeBudgetMs) {
      try {
        final pos = await _tryGetFix(Duration(milliseconds: cfg.attemptTimeoutMs), bestNav: (best == null));
        final acc = pos.accuracy;
        if (acc < bestAcc) {
          best = pos;
          bestAcc = acc;
        }
        if (acc <= cfg.desiredAccuracyM) return pos;
      } catch (_) {
        // timeout or error → keep looping until time budget exceeded
      }
    }
    if (best != null) return best;
    throw TimeoutException('Unable to obtain location within time budget');
  }

  static double _toRad(double deg) => deg * math.pi / 180.0;

  /// Haversine distance in meters.
  static double distanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) + math.cos(_toRad(lat1)) * math.cos(_toRad(lat2)) * math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  /// Compute distances (in meters) between the provided coordinate sets.
  /// - entry ↔ office
  /// - user ↔ office
  /// - user ↔ entry
  ///
  /// Any missing lat/lon pair yields a null for that specific distance.
  static GeoDistances computeDistances({
    double? entryLat,
    double? entryLon,
    double? officeLat,
    double? officeLon,
    double? userLat,
    double? userLon,
  }) {
    final bool hasEntry = entryLat != null && entryLon != null;
    final bool hasOffice = officeLat != null && officeLon != null;
    final bool hasUser = userLat != null && userLon != null;

    double? entryToOfficeM;
    double? userToOfficeM;
    double? userToEntryM;

    if (hasEntry && hasOffice) {
      entryToOfficeM = distanceMeters(entryLat, entryLon, officeLat, officeLon);
    }
    if (hasUser && hasOffice) {
      userToOfficeM = distanceMeters(userLat, userLon, officeLat, officeLon);
    }
    if (hasUser && hasEntry) {
      userToEntryM = distanceMeters(userLat, userLon, entryLat, entryLon);
    }

    return GeoDistances(
      entryToOfficeM: entryToOfficeM,
      userToOfficeM: userToOfficeM,
      userToEntryM: userToEntryM,
    );
  }

  /// Determine if user is inside office radii for indoor and entry points.
  /// Returns per-point distances and booleans, plus overall insideAnyOffice.
  static OfficeProximityResult officeProximity({
    double? indoorOfficeLat,
    double? indoorOfficeLon,
    double? entryOfficeLat,
    double? entryOfficeLon,
    double? userLat,
    double? userLon,
    double radiusM = 300.0,
  }) {
    final bool hasUser = userLat != null && userLon != null;
    final bool hasIndoor = indoorOfficeLat != null && indoorOfficeLon != null;
    final bool hasEntry = entryOfficeLat != null && entryOfficeLon != null;

    double? dIndoor;
    double? dEntry;

    if (hasUser && hasIndoor) {
      dIndoor = distanceMeters(userLat, userLon, indoorOfficeLat, indoorOfficeLon);
    }
    if (hasUser && hasEntry) {
      dEntry = distanceMeters(userLat, userLon, entryOfficeLat, entryOfficeLon);
    }

    final bool insideIndoor = dIndoor != null && dIndoor <= radiusM;
    final bool insideEntry = dEntry != null && dEntry <= radiusM;
    final bool insideAny = insideIndoor || insideEntry;

    return OfficeProximityResult(
      radiusM: radiusM,
      distanceToIndoorOfficeM: dIndoor,
      distanceToEntryOfficeM: dEntry,
      insideIndoorOffice: insideIndoor,
      insideEntryOffice: insideEntry,
      insideAnyOffice: insideAny,
    );
  }

  /// 0..1 quality score (higher = lower trust).
  static double _qualityScore({
    required double accuracyM,
    required int fixAgeMs,
    Map<String, dynamic>? gnss,
  }) {
    double s = 0;
    if (accuracyM > 50) s += 0.4;
    if (accuracyM > 100) s += 0.2;
    if (fixAgeMs > 15000) s += 0.2;
    if (gnss != null && gnss['supported'] == true) {
      final sats = (gnss['satsUsed'] ?? 0) as int;
      final cn0 = (gnss['avgCn0'] ?? 99.0) as double;
      if (sats < 4) s += 0.2;
      if (cn0 < 20) s += 0.2;
    }
    if (s < 0) s = 0;
    if (s > 1) s = 1;
    return s;
  }

  /// Main API: get a fresh fix, compute distance, apply cushion, and return summary.
  static Future<GeoGuardResult> quickCheck({
    required double siteLat,
    required double siteLon,
    required double radiusM,
    GeoGuardConfig cfg = const GeoGuardConfig(),
  }) async {
    await ensurePermissions();
    final pos = await _getFixWithRetries(cfg);
    final now = DateTime.now();
    final ts = pos.timestamp;
    final ageMs = now.difference(ts).inMilliseconds;

    final dist = distanceMeters(pos.latitude, pos.longitude, siteLat, siteLon);

    Map<String, dynamic>? gnss;
    if (cfg.androidGnssSnapshot) {
      try {
        gnss = await GnssChannel.snapshot();
      } catch (_) {}
    }

    final score = _qualityScore(accuracyM: pos.accuracy, fixAgeMs: ageMs, gnss: gnss);
    final effective = cfg.useAccuracyCushion ? (dist - pos.accuracy) : dist;
    final inside = effective <= radiusM && ageMs <= cfg.maxFixAgeMs;

    return GeoGuardResult(
      inside: inside,
      distanceM: dist,
      accuracyM: pos.accuracy,
      fixAgeMs: ageMs,
      position: pos,
      qualityScore: score,
      androidGnss: gnss,
    );
  }

  /// Convenience API: Only pass lat/lon/radius, returns inside? + details.
  static Future<GeoGuardResult> checkSingle({
    required double lat,
    required double lon,
    required double radiusM,
    GeoGuardConfig cfg = const GeoGuardConfig(),
  }) {
    return quickCheck(siteLat: lat, siteLon: lon, radiusM: radiusM, cfg: cfg);
  }

  /// Convenience API: Pass entry and office points. Returns dual geofence result.
  static Future<DualGeofenceResult> checkDual({
    required double entryLat,
    required double entryLon,
    required double entryRadiusM,
    required double officeLat,
    required double officeLon,
    required double officeRadiusM,
    GeoGuardConfig cfg = const GeoGuardConfig(),
  }) async {
    await ensurePermissions();
    final pos = await _getFixWithRetries(cfg);
    final now = DateTime.now();
    final ts = pos.timestamp;
    final ageMs = now.difference(ts).inMilliseconds;

    final dEntry = distanceMeters(pos.latitude, pos.longitude, entryLat, entryLon);
    final dOffice = distanceMeters(pos.latitude, pos.longitude, officeLat, officeLon);

    Map<String, dynamic>? gnss;
    if (cfg.androidGnssSnapshot) {
      try {
        gnss = await GnssChannel.snapshot();
      } catch (_) {}
    }

    final score = _qualityScore(accuracyM: pos.accuracy, fixAgeMs: ageMs, gnss: gnss);

    final effEntry = cfg.useAccuracyCushion ? (dEntry - pos.accuracy) : dEntry;
    final effOffice = cfg.useAccuracyCushion ? (dOffice - pos.accuracy) : dOffice;

    final insideEntry = effEntry <= entryRadiusM && ageMs <= cfg.maxFixAgeMs;
    final insideOffice = effOffice <= officeRadiusM && ageMs <= cfg.maxFixAgeMs;

    return DualGeofenceResult(
      position: pos,
      insideEntry: insideEntry,
      insideOffice: insideOffice,
      distanceToEntryM: dEntry,
      distanceToOfficeM: dOffice,
      accuracyM: pos.accuracy,
      fixAgeMs: ageMs,
      qualityScore: score,
      androidGnss: gnss,
    );
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:lapse_geo_guard/lapse_geo_guard.dart';

void main() {
  test('types are available', () {
    const cfg = GeoGuardConfig();
    expect(cfg.desiredAccuracyM, greaterThan(0));
  });

  test('evaluatePositionAgainstSites detects inside and match', () {
    const sites = [
      GeoPoint(lat: 24.711667019762736, lon: 46.62244234390605, radiusM: 500),
      GeoPoint(lat: 24.71021237270764, lon: 46.62318799799376, radiusM: 500),
    ];

    final res = GeoGuard.evaluatePositionAgainstSites(
      userLat: 24.711667019762736,
      userLon: 46.62244234390605,
      sites: sites,
    );

    expect(res.insideAny, isTrue);
    expect(res.matchedSiteIndex, 0);
    expect(res.matchedSite, sites.first);
    expect(res.message, 'You are within 500 m of a configured location.');
  });

  test('evaluatePositionAgainstSites detects outside', () {
    const sites = [
      GeoPoint(lat: 24.711667019762736, lon: 46.62244234390605, radiusM: 500),
      GeoPoint(lat: 24.71021237270764, lon: 46.62318799799376, radiusM: 500),
    ];

    final res = GeoGuard.evaluatePositionAgainstSites(
      userLat: 24.0,
      userLon: 46.0,
      sites: sites,
    );

    expect(res.insideAny, isFalse);
    expect(res.matchedSiteIndex, isNull);
    expect(res.message, 'You are outside the 500 m radius for all locations.');
    expect(res.closestDistanceM, greaterThan(500));
  });
}

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
    expect(res.message, isEmpty);
    expect(res.closestSiteIndex, 0);
    expect(res.closestDistanceM, closeTo(0, 0.01));
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
    expect(res.message, 'You are more than 500 meters away. Please move closer.');
    expect(res.closestDistanceM, greaterThan(500));
  });

  test('evaluatePositionAgainstSites shows inside message between 20m and 500m', () {
    const sites = [
      GeoPoint(lat: 24.711667019762736, lon: 46.62244234390605, radiusM: 500),
    ];

    final res = GeoGuard.evaluatePositionAgainstSites(
      userLat: 24.711667019762736 + 0.0003,
      userLon: 46.62244234390605,
      sites: sites,
    );

    expect(res.insideAny, isTrue);
    expect(res.message, 'Please move closer to the window.');
    expect(res.closestSiteIndex, 0);
    expect(res.closestDistanceM, greaterThan(20));
    expect(res.closestDistanceM, lessThan(500));
  });
}

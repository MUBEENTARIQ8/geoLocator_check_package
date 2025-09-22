import 'package:flutter_test/flutter_test.dart';
import 'package:lapse_geo_guard/lapse_geo_guard.dart';

void main() {
  test('types are available', () {
    const cfg = GeoGuardConfig();
    expect(cfg.desiredAccuracyM, greaterThan(0));
  });
}

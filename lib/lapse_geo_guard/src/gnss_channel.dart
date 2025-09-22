import 'package:flutter/services.dart';

class GnssChannel {
  static const _ch = MethodChannel('lapse_geo_guard/gnss');

  /// Android returns: { supported: true, satsUsed: int, avgCn0: double }
  /// iOS returns: { supported: false }
  static Future<Map<String, dynamic>> snapshot() async {
    try {
      final res = await _ch.invokeMethod<Map<dynamic, dynamic>>('snapshot');
      return Map<String, dynamic>.from(res ?? const {'supported': false});
    } catch (e) {
      // Handle missing plugin gracefully
      return const {'supported': false};
    }
  }
}
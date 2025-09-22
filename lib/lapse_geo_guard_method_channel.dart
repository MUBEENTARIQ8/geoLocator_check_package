import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'lapse_geo_guard_platform_interface.dart';

/// An implementation of [LapseGeoGuardPlatform] that uses method channels.
class MethodChannelLapseGeoGuard extends LapseGeoGuardPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('lapse_geo_guard');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}

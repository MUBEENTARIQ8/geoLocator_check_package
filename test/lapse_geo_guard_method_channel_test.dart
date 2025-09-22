import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse_geo_guard/lapse_geo_guard_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelLapseGeoGuard platform = MethodChannelLapseGeoGuard();
  const MethodChannel channel = MethodChannel('lapse_geo_guard');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}

import 'package:flutter/material.dart';
import 'package:lapse_geo_guard/lapse_geo_guard.dart';

void main() => runApp(const DemoApp());

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('lapse_geo_guard demo')),
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              try {
                await GeoGuard.ensurePermissions();
                final res = await GeoGuard.quickCheck(
                  siteLat: 24.7136,
                  siteLon: 46.6753,
                  radiusM: 200,
                );
                // ignore: use_build_context_synchronously
                showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                        content: Text('inside=${res.inside}\n'
                            'dist=${res.distanceM.toStringAsFixed(1)}m\n'
                            'acc=${res.accuracyM}m\n'
                            'age=${res.fixAgeMs}ms\n'
                            'score=${res.qualityScore}')));
              } catch (e) {
                // ignore: use_build_context_synchronously
                showDialog(context: context, builder: (_) => AlertDialog(content: Text('Error: $e')));
              }
            },
            child: const Text('Check site'),
          ),
        ),
      ),
    );
  }
}

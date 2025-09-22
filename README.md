
# lapse_geo_guard

Reliable geofencing helper for Flutter — on-demand high-accuracy fixes with retries, accuracy cushion, and optional Android GNSS snapshot.

## Install

```yaml
dependencies:
  lapse_geo_guard:
    git:
      url: https://github.com/MUBEENTARIQ8/geoLocator_check_package.git
      ref: main
```

Ensure you configure platform permissions per geolocator docs.

## APIs

### 1) Single geofence check
```dart
import 'package:lapse_geo_guard/lapse_geo_guard.dart';

final single = await GeoGuard.checkSingle(
  lat: 31.432016,
  lon: 74.287923,
  radiusM: 200,
);
print('inside=' + single.inside.toString());
```

### 2) Dual geofence check (entry + office)
```dart
final dual = await GeoGuard.checkDual(
  entryLat: 31.432016, entryLon: 74.287923, entryRadiusM: 50,
  officeLat: 31.432500, officeLon: 74.288300, officeRadiusM: 200,
);
print('insideEntry=' + dual.insideEntry.toString() + ' insideOffice=' + dual.insideOffice.toString());
```

### Config (optional)
```dart
const cfg = GeoGuardConfig(
  timeBudgetMs: 12000,
  attemptTimeoutMs: 6000,
  desiredAccuracyM: 50,
  maxFixAgeMs: 15000,
  useAccuracyCushion: true,
  androidGnssSnapshot: true,
);
```

## Platform channel
- Android/iOS method channel: `lapse_geo_guard/gnss`
  - Android `snapshot` → `{ supported: true, satsUsed: int, avgCn0: double }`
  - iOS `snapshot` → `{ supported: false }`

## Permissions
This package relies on geolocator. Add platform-specific location permissions.

## Example
See `example/` for a runnable demo.

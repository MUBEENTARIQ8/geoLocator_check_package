# LocationService Kaise Use Karein (How to Use)

## Summary (خلاصہ)

Ab `LocationService` class **sabhi sites ko check karti hai** (pehle sirf pehli site check hoti thi). Ab yeh sahi se kaam karega:

- **30 meter ke andar** koi bhi site ho → "Go near window" message dikhega
- **300 meter se zyada door** sabhi sites se → "Too far" message dikhega
- **30-300 meter ke beech** → "Go near window" message dikhega

## Step 1: LocationService Class Copy Karein

Apni app mein `lib/services/` folder mein `location_service.dart` file banaein aur `example/lib/location_service.dart` se code copy karein.

## Step 2: Dependencies Add Karein

Apni `pubspec.yaml` mein yeh add karein:

```yaml
dependencies:
  flutter_secure_storage: ^9.0.0
  geolocator: ^10.1.0
  lapse_geo_guard:
    git:
      url: https://github.com/MUBEENTARIQ8/geoLocator_check_package.git
      ref: main
```

Phir run karein:
```bash
flutter pub get
```

## Step 3: Use Karein Apni App Mein

### Basic Usage:

```dart
import 'package:your_app/services/location_service.dart';

// Class mein instance banaein
final locationService = LocationService();

// Location check karein
final decision = await locationService.evaluateUserLocation(
  context: context,
  onWithinThirtyMeters: (siteIndex, site) {
    // Jab user 30m ke andar ho, yeh callback call hoga
    print('User site $siteIndex ke 30m ke andar hai');
  },
);

// Message check karein
if (decision.message.isNotEmpty) {
  // User ko message dikhayein
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(decision.message)),
  );
}
```

### Complete Example:

```dart
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final LocationService _locationService = LocationService();

  Future<void> checkLocation() async {
    try {
      final decision = await _locationService.evaluateUserLocation(
        context: context,
        onWithinThirtyMeters: (siteIndex, site) {
          print('Within 30m of site $siteIndex');
        },
      );

      // Message show karein
      if (decision.message.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(decision.message)),
        );
      }

      // Details print karein
      print('Closest distance: ${decision.closestDistanceM}m');
      print('All distances: ${decision.distancesM}');
      print('Inside any: ${decision.insideAny}');
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: checkLocation,
      child: Text('Check Location'),
    );
  }
}
```

## Important Points (اہم نکات)

1. ✅ **Sabhi sites check hoti hain** - ab sirf pehli site nahi, sabhi 5 sites check hongi
2. ✅ **30m threshold** - agar user kisi bhi site se 30m ke andar hai to "go near window" message
3. ✅ **300m threshold** - agar user sabhi sites se 300m se zyada door hai to "too far" message
4. ✅ **Automatic site loading** - pehle storage se sites load karega, agar nahi mili to default sites use karega

## Sites Ko Storage Mein Save Karna

Agar aap enrollment ke time sites save karna chahte hain:

```dart
final storage = FlutterSecureStorage();

// Site 1 save karein
await storage.write(key: 'lat_1', value: '24.711667019762736');
await storage.write(key: 'lon_1', value: '46.62244234390605');

// Site 2 save karein
await storage.write(key: 'lat_2', value: '24.711255236977546');
await storage.write(key: 'lon_2', value: '46.622431615070255');

// ... aur bhi sites
```

`LocationService` automatically in sites ko load kar lega jab `evaluateUserLocation()` call hoga.

## Testing

1. App run karein
2. Location permission allow karein
3. "Check Location" button press karein
4. Console mein sabhi sites ki distances dikhengi
5. Appropriate message show hoga based on distance

## Files

- `example/lib/location_service.dart` - Complete LocationService class
- `example/lib/location_service_example.dart` - Full working example
- `LOCATION_SERVICE_USAGE.md` - Detailed English documentation


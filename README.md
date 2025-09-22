# Lapes Geofencing Flutter App

A comprehensive Flutter application for reliable geofencing with high-accuracy location tracking, GNSS satellite data integration, and modern Material 3 UI.

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Architecture](#architecture)
- [Platform Support](#platform-support)
- [API Reference](#api-reference)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## 🎯 Overview

This Flutter application integrates the Lapse Geo Guard plugin to provide robust geofencing capabilities with:
- High-accuracy location fixes with retry mechanisms
- GNSS satellite data for enhanced location quality (Android)
- Accuracy cushioning for more reliable geofence detection
- Modern Material 3 UI with comprehensive result display
- Cross-platform support (Android/iOS)

## ✨ Features

### Core Geofencing
- **Real-time location checking** against configurable geofence boundaries
- **Live location tracking** with automatic periodic updates (every 10 seconds)
- **High-accuracy GPS fixes** with configurable timeout and retry logic
- **Distance calculation** using Haversine formula for precise measurements
- **Accuracy cushioning** - considers GPS accuracy in geofence calculations
- **Quality scoring system** (0-1 scale) for location reliability assessment

### GNSS Integration (Android Only)
- **Satellite tracking** - real-time GNSS status monitoring
- **Signal strength measurement** - CN0 (Carrier-to-Noise ratio) averaging
- **Active satellite count** - tracks satellites used in position fix
- **Enhanced quality metrics** based on satellite data

### User Interface
- **Modern Material 3 design** with dynamic theming
- **Live tracking controls** with start/stop functionality
- **Real-time status updates** with loading animations and live indicators
- **Visual feedback** - green/red cards for inside/outside status during live tracking
- **Comprehensive result display** showing all location metrics
- **Check counter** and timing information for live tracking sessions
- **Error handling** with user-friendly messages
- **Responsive layout** optimized for mobile devices

## 🚀 Installation

### Prerequisites
- Flutter SDK 3.0.0 or higher
- Android SDK 21+ (for Android builds)
- iOS 11.0+ (for iOS builds)
- Xcode 12+ (for iOS development)

### Setup Steps

1. **Clone or download the project**
   ```bash
   cd /path/to/lapesgeofencing
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Platform-specific setup**

   **Android:**
   - Location permissions are automatically configured in `AndroidManifest.xml`
   - GNSS plugin is integrated for satellite data

   **iOS:**
   - Location permissions are configured in `Info.plist`
   - GNSS features gracefully fallback (not supported on iOS)

4. **Run the application**
   ```bash
   flutter run
   ```

## ⚙️ Configuration

### Geofence Parameters

The app is configured with the following default settings in `main.dart`:

```dart
// Target location (currently set to Lahore, Pakistan)
final double _siteLat = 31.467077633293147;
final double _siteLon = 74.30481719475854;
final double _radiusM = 200.0; // 200 meter radius

// GeoGuard configuration
const GeoGuardConfig(
  timeBudgetMs: 12000,        // Total time budget for location fix
  attemptTimeoutMs: 6000,     // Timeout per attempt
  desiredAccuracyM: 50,       // Target accuracy in meters
  maxFixAgeMs: 15000,         // Maximum acceptable fix age
  useAccuracyCushion: true,   // Enable accuracy-based distance calculation
  androidGnssSnapshot: true,  // Include GNSS data (Android only)
)
```

### Customizing Location

To change the target geofence location, modify these values in `_GeofencingHomePageState`:

```dart
final double _siteLat = YOUR_LATITUDE;
final double _siteLon = YOUR_LONGITUDE;
final double _radiusM = YOUR_RADIUS_IN_METERS;
```

## 📱 Usage

### Basic Operation

1. **Launch the app** - The main screen displays the current geofence configuration
2. **Grant permissions** - Allow location access when prompted
3. **Choose your tracking mode**:
   - **Single Check**: Tap "Check Location Once" for a one-time geofence check
   - **Live Tracking**: Tap "Start Live Tracking" for continuous monitoring
4. **View results** - Comprehensive location data is displayed in the results card

### Live Tracking Mode

- **Start Live Tracking** - Begins continuous location monitoring every 10 seconds
- **Real-time updates** - Status and results update automatically
- **Visual indicators** - Green card for inside geofence, red for outside
- **Check counter** - Shows total number of location checks performed
- **Stop anytime** - Tap "Stop Tracking" to end live monitoring

### Understanding Results

The app displays the following information after each location check:

- **Status**: Inside/Outside geofence indication
- **Distance**: Precise distance to target location in meters
- **Accuracy**: GPS accuracy of the current fix
- **Fix Age**: How old the location fix is in milliseconds
- **Quality Score**: Reliability score (0 = high quality, 1 = low quality)
- **Coordinates**: Exact latitude and longitude
- **GNSS Info** (Android only): Satellite count and signal strength

### Live Tracking Additional Info

During live tracking mode, additional information is displayed:

- **Check Count**: Total number of location checks performed
- **Last Update**: Time since the last location update
- **Update Interval**: Frequency of location checks (10 seconds)
- **Live Status**: Real-time inside/outside status with visual indicators

### Quality Score Interpretation

The quality score (0-1 scale) considers:
- **GPS Accuracy**: Higher penalty for accuracy > 50m or > 100m
- **Fix Age**: Penalty for fixes older than 15 seconds
- **Satellite Data** (Android): Penalties for < 4 satellites or weak signals

## 🏗️ Architecture

### Project Structure

```
lib/
├── main.dart                          # Main application entry point
└── lapse_geo_guard/                   # Geofencing plugin
    ├── lapse_geo_guard.dart          # Plugin exports
    └── src/
        ├── core.dart                  # Core geofencing logic
        └── gnss_channel.dart          # Platform communication

android/
└── app/src/main/kotlin/com/example/lapes/lapesgeofencing/
    ├── MainActivity.kt                # Main Android activity
    └── GeoGuardPlugin.kt             # Android GNSS plugin

ios/
└── Runner/
    ├── AppDelegate.swift             # iOS app delegate
    └── Info.plist                    # iOS permissions
```

### Core Components

#### GeoGuard Class
The main class providing geofencing functionality:

```dart
class GeoGuard {
  static Future<void> ensurePermissions()     // Request location permissions
  static Future<GeoGuardResult> quickCheck()  // Perform geofence check
  static double distanceMeters()              // Calculate distance
}
```

#### GeoGuardResult Class
Contains the results of a geofencing operation:

```dart
class GeoGuardResult {
  final bool inside;                    // Inside geofence?
  final double distanceM;              // Distance to target
  final double accuracyM;              // GPS accuracy
  final int fixAgeMs;                  // Age of location fix
  final Position position;             // Full position data
  final double qualityScore;           // Quality assessment
  final Map<String, dynamic>? androidGnss; // GNSS data (Android)
}
```

## 🔧 Platform Support

### Android Features
- ✅ Full geofencing functionality
- ✅ GNSS satellite data integration
- ✅ High-accuracy location fixes
- ✅ Background location permission support
- ✅ API level 21+ compatibility

### iOS Features
- ✅ Core geofencing functionality
- ✅ High-accuracy location fixes
- ❌ GNSS satellite data (not available)
- ✅ iOS 11.0+ compatibility

### Permissions

#### Android (automatically configured)
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
```

#### iOS (automatically configured)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to check if you are within the specified geofence area.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs location access to check if you are within the specified geofence area.</string>
```

## 📚 API Reference

### GeoGuardConfig Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `timeBudgetMs` | int | 12000 | Total time budget for obtaining a location fix |
| `attemptTimeoutMs` | int | 6000 | Timeout for each individual location attempt |
| `desiredAccuracyM` | double | 50.0 | Target accuracy in meters |
| `maxFixAgeMs` | int | 15000 | Maximum acceptable age for location fixes |
| `useAccuracyCushion` | bool | true | Apply accuracy cushioning to distance calculation |
| `androidGnssSnapshot` | bool | true | Include GNSS satellite data (Android only) |

### Error Handling

The app handles various error scenarios:

- **Permission Denied**: Shows error message and guidance
- **Location Services Disabled**: Prompts user to enable services
- **Timeout**: Falls back to best available fix within time budget
- **Platform Errors**: Graceful degradation with informative messages

## 🔍 Troubleshooting

### Common Issues

#### "Location services disabled"
- **Solution**: Enable location services in device settings
- **Android**: Settings > Location > Turn on
- **iOS**: Settings > Privacy & Security > Location Services > Turn on

#### "Location permission denied"
- **Solution**: Grant location permissions to the app
- **Android**: Settings > Apps > Lapes Geofencing > Permissions > Location
- **iOS**: Settings > Privacy & Security > Location Services > Lapes Geofencing

#### Poor accuracy or quality scores
- **Causes**: Indoor usage, poor satellite visibility, device limitations
- **Solutions**: Use outdoors, wait for better satellite lock, check device GPS capabilities

#### Build failures
- **Android**: Ensure NDK version 27.0.12077973+ is installed
- **iOS**: Verify Xcode version and iOS deployment target compatibility

### Debug Information

Enable Flutter debugging for detailed logs:
```bash
flutter run --verbose
```

Monitor location services:
```bash
# Android
adb logcat | grep -i location

# iOS (via Xcode console)
```

## 🤝 Contributing

### Development Setup

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes
4. Run tests: `flutter test`
5. Commit changes: `git commit -m 'Add amazing feature'`
6. Push to branch: `git push origin feature/amazing-feature`
7. Open a Pull Request

### Code Style

- Follow [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Use `flutter analyze` to check for issues
- Format code with `dart format`
- Add tests for new functionality

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Lapse Geo Guard Plugin** - Core geofencing functionality
- **Geolocator Package** - Cross-platform location services
- **Flutter Team** - Framework and tooling
- **Material Design** - UI/UX guidelines

## 📞 Support

For support and questions:
- Create an issue on GitHub
- Check the troubleshooting section above
- Review Flutter and Geolocator documentation

---

**Built with ❤️ using Flutter**

*Last updated: September 19, 2025*# geoLocator_check_package
# geoLocator_check_package

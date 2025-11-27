import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static Position? _currentPosition;

  static Future<bool> checkPermissions() async {
    // Check location permission
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  static Future<Map<String, dynamic>?> getCurrentLocation() async {
    try {
      if (!await checkPermissions()) {
        return null;
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // Get current position
      LocationSettings locationSettings;

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        locationSettings = AppleSettings(
          accuracy: LocationAccuracy.high,
          activityType: ActivityType.fitness,
          distanceFilter: 0,
          pauseLocationUpdatesAutomatically: true,
          showBackgroundLocationIndicator: false,
          timeLimit: const Duration(seconds: 10),
        );
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        locationSettings = AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
          forceLocationManager: true,
          intervalDuration: const Duration(seconds: 10),
        );
      } else {
        locationSettings = const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        );
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );

      return {
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
        'accuracy': _currentPosition!.accuracy,
        'altitude': _currentPosition!.altitude,
        'speed': _currentPosition!.speed,
        'heading': _currentPosition!.heading,
        'timestamp': _currentPosition!.timestamp.toIso8601String(),
        'provider': 'GPS',
      };
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  static double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  static bool isWithinRadius(
    double userLat,
    double userLon,
    double targetLat,
    double targetLon,
    double radiusInMeters,
  ) {
    final distance = calculateDistance(userLat, userLon, targetLat, targetLon);
    return distance <= radiusInMeters;
  }

  static Position? get currentPosition => _currentPosition;
}
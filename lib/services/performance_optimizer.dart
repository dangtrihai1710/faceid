import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class PerformanceOptimizer {
  static final PerformanceOptimizer _instance = PerformanceOptimizer._internal();
  factory PerformanceOptimizer() => _instance;
  PerformanceOptimizer._internal();

  SharedPreferences? _prefs;
  bool _isInitialized = false;

  // Performance settings
  static const String _enableAnimationsKey = 'enable_animations';
  static const String _enableTransitionsKey = 'enable_transitions';
  static const String _cacheSizeKey = 'cache_size';
  static const String _imageQualityKey = 'image_quality';
  static const String _enableBackgroundSyncKey = 'enable_background_sync';

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      await _setDefaultPerformanceSettings();
      _isInitialized = true;

      if (!kReleaseMode) {
        _logPerformanceInfo();
      }
    } catch (e) {
      print('Error initializing PerformanceOptimizer: $e');
    }
  }

  Future<void> _setDefaultPerformanceSettings() async {
    final prefs = _prefs!;

    // Set default settings only if not already set
    await prefs.setBool(_enableAnimationsKey, prefs.getBool(_enableAnimationsKey) ?? true);
    await prefs.setBool(_enableTransitionsKey, prefs.getBool(_enableTransitionsKey) ?? true);
    await prefs.setInt(_cacheSizeKey, prefs.getInt(_cacheSizeKey) ?? 50); // MB
    await prefs.setString(_imageQualityKey, prefs.getString(_imageQualityKey) ?? 'medium');
    await prefs.setBool(_enableBackgroundSyncKey, prefs.getBool(_enableBackgroundSyncKey) ?? true);
  }

  Future<void> _logPerformanceInfo() async {
    try {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      final packageInfo = await PackageInfo.fromPlatform();

      print('=== PERFORMANCE OPTIMIZER INFO ===');
      print('Device: ${deviceInfo.model}');
      print('Android Version: ${deviceInfo.version.release}');
      print('App Version: ${packageInfo.version}');

      final prefs = _prefs!;
      print('Animations Enabled: ${prefs.getBool(_enableAnimationsKey)}');
      print('Transitions Enabled: ${prefs.getBool(_enableTransitionsKey)}');
      print('Cache Size: ${prefs.getInt(_cacheSizeKey)} MB');
      print('Image Quality: ${prefs.getString(_imageQualityKey)}');
      print('Background Sync: ${prefs.getBool(_enableBackgroundSyncKey)}');
      print('================================');
    } catch (e) {
      print('Error logging performance info: $e');
    }
  }

  // Getters for performance settings
  bool get enableAnimations => _prefs?.getBool(_enableAnimationsKey) ?? true;
  bool get enableTransitions => _prefs?.getBool(_enableTransitionsKey) ?? true;
  int get cacheSize => _prefs?.getInt(_cacheSizeKey) ?? 50;
  String get imageQuality => _prefs?.getString(_imageQualityKey) ?? 'medium';
  bool get enableBackgroundSync => _prefs?.getBool(_enableBackgroundSyncKey) ?? true;

  // Setters for performance settings
  Future<void> setAnimations(bool value) async {
    await _prefs?.setBool(_enableAnimationsKey, value);
  }

  Future<void> setTransitions(bool value) async {
    await _prefs?.setBool(_enableTransitionsKey, value);
  }

  Future<void> setCacheSize(int sizeInMB) async {
    await _prefs?.setInt(_cacheSizeKey, sizeInMB);
  }

  Future<void> setImageQuality(String quality) async {
    await _prefs?.setString(_imageQualityKey, quality);
  }

  Future<void> setBackgroundSync(bool enabled) async {
    await _prefs?.setBool(_enableBackgroundSyncKey, enabled);
  }

  // Performance monitoring
  static void logPerformance(String operation, Duration duration) {
    if (!kReleaseMode) {
      print('Performance: $operation took ${duration.inMilliseconds}ms');
    }

    // Log slow operations
    if (duration.inMilliseconds > 1000) {
      print('WARNING: Slow operation detected - $operation: ${duration.inMilliseconds}ms');
    }
  }

  // Memory optimization
  static Future<void> clearCache() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${appDir.path}/cache');

      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        print('Cache cleared successfully');
      }
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  static Future<int> getCacheSize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${appDir.path}/cache');

      if (!await cacheDir.exists()) return 0;

      int totalSize = 0;
      await for (final entity in cacheDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }

      return (totalSize / (1024 * 1024)).round(); // Return in MB
    } catch (e) {
      print('Error calculating cache size: $e');
      return 0;
    }
  }

  // Device-specific optimizations
  static Future<bool> isLowEndDevice() async {
    try {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      // For demonstration, we'll consider devices with less than 2GB RAM as low-end
      // This is an approximation - actual implementation would need memory info
      return false; // Default to false for now
    } catch (e) {
      return false;
    }
  }

  static Future<void> optimizeForDevice() async {
    final isLowEnd = await isLowEndDevice();

    if (isLowEnd) {
      print('Optimizing for low-end device...');

      // Disable heavy animations
      // Reduce cache size
      // Lower image quality
      // Disable background processing

      // This can be implemented based on your specific needs
    }
  }

  // Frame rate optimization
  static void setFrameRate(double fps) {
    // This would typically be done at the app level
    // but we can store the preference
    print('Setting target frame rate: ${fps}fps');
  }

  // Battery optimization
  static Future<bool> isBatteryOptimized() async {
    try {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      // Check if battery saver is on
      return false; // Implement actual battery check
    } catch (e) {
      return false;
    }
  }

  // App lifecycle management
  static void handleAppLifecycle() {
    // Implement app lifecycle optimizations
    // such as pausing background tasks
    print('Handling app lifecycle for performance optimization');
  }

  // Image quality presets
  static double getImageQualityMultiplier() {
    final quality = _instance.imageQuality;
    switch (quality) {
      case 'low':
        return 0.5;
      case 'medium':
        return 0.75;
      case 'high':
        return 1.0;
      default:
        return 0.75;
    }
  }

  // Performance presets
  static Future<void> setPerformancePreset(String preset) async {
    switch (preset.toLowerCase()) {
      case 'high_performance':
        await _instance.setAnimations(true);
        await _instance.setTransitions(true);
        await _instance.setCacheSize(100);
        await _instance.setImageQuality('high');
        break;
      case 'balanced':
        await _instance.setAnimations(true);
        await _instance.setTransitions(true);
        await _instance.setCacheSize(50);
        await _instance.setImageQuality('medium');
        break;
      case 'battery_saver':
        await _instance.setAnimations(false);
        await _instance.setTransitions(false);
        await _instance.setCacheSize(20);
        await _instance.setImageQuality('low');
        break;
    }
  }

  // Get available memory
  static Future<int> getAvailableMemory() async {
    try {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      // For Android, we can't directly access totalMemory, so we'll estimate based on device info
      // This is an approximation - actual implementation would use deviceinfo_plus's extended info
      return 1024; // Default to 1GB estimate for demonstration
    } catch (e) {
      return 0;
    }
  }
}

// Performance decorator for timing function execution
class PerformanceMonitor {
  static T measure<T>(String name, T Function() function) {
    if (!kReleaseMode) {
      final stopwatch = Stopwatch()..start();
      try {
        return function();
      } finally {
        stopwatch.stop();
        PerformanceOptimizer.logPerformance(name, stopwatch.elapsed);
      }
    } else {
      return function();
    }
  }

  static Future<T> measureAsync<T>(String name, Future<T> Function() function) async {
    if (!kReleaseMode) {
      final stopwatch = Stopwatch()..start();
      try {
        return await function();
      } finally {
        stopwatch.stop();
        PerformanceOptimizer.logPerformance(name, stopwatch.elapsed);
      }
    } else {
      return await function();
    }
  }
}
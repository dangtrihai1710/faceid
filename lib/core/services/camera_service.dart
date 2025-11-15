import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';

class CameraService {
  static CameraController? _controller;
  static List<CameraDescription>? _cameras;

  static Future<void> initialize() async {
    try {
      // Get available cameras
      _cameras = await availableCameras();

      if (_cameras != null && _cameras!.isNotEmpty) {
        // Use front camera for face recognition
        final frontCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras!.first,
        );

        _controller = CameraController(
          frontCamera,
          ResolutionPreset.high,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );

        await _controller!.initialize();
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      rethrow;
    }
  }

  static CameraController? get controller => _controller;

  static bool get isInitialized => _controller?.value.isInitialized ?? false;

  static Future<String?> captureImage() async {
    try {
      if (!isInitialized) {
        debugPrint('Camera not initialized');
        return null;
      }

      final XFile picture = await _controller!.takePicture();
      return picture.path;
    } catch (e) {
      debugPrint('Error capturing image: $e');
      return null;
    }
  }

  static void dispose() {
    _controller?.dispose();
    _controller = null;
  }

  static Future<void> switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    try {
      final currentIndex = _cameras!.indexOf(_controller!.description);
      final nextIndex = (currentIndex + 1) % _cameras!.length;

      await _controller?.dispose();

      _controller = CameraController(
        _cameras![nextIndex],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
    } catch (e) {
      debugPrint('Error switching camera: $e');
    }
  }
}
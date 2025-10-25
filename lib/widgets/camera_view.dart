import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraView extends StatefulWidget {
  final List<CameraDescription>? cameras;
  final Function(CameraController) onControllerReady;

  const CameraView({
    super.key,
    required this.cameras,
    required this.onControllerReady,
  });

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  CameraController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (widget.cameras == null || widget.cameras!.isEmpty) return;

    final frontCamera = widget.cameras!.firstWhere(
          (cam) => cam.lensDirection == CameraLensDirection.front,
      orElse: () => widget.cameras!.first,
    );

    _controller = CameraController(frontCamera, ResolutionPreset.medium);
    await _controller!.initialize();
    widget.onControllerReady(_controller!); // gửi controller ra ngoài
    if (mounted) setState(() => _isInitialized = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return CameraPreview(_controller!);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/camera_service.dart';

class RealCameraPreview extends StatefulWidget {
  final double? width;
  final double? height;
  final bool isScanning;
  final Function(String)? onImageCaptured;

  const RealCameraPreview({
    super.key,
    this.width,
    this.height,
    this.isScanning = false,
    this.onImageCaptured,
  });

  @override
  State<RealCameraPreview> createState() => _RealCameraPreviewState();
}

class _RealCameraPreviewState extends State<RealCameraPreview>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scanController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeCamera();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _scanController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _scanAnimation = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scanController,
      curve: Curves.easeInOut,
    ));

    if (widget.isScanning) {
      _pulseController.repeat(reverse: true);
      _scanController.repeat();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      await CameraService.initialize();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Failed to initialize camera: $e');
    }
  }

  @override
  void didUpdateWidget(RealCameraPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning != oldWidget.isScanning) {
      if (widget.isScanning) {
        _pulseController.repeat(reverse: true);
        _scanController.repeat();
      } else {
        _pulseController.stop();
        _scanController.stop();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scanController.dispose();
    CameraService.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    try {
      final imagePath = await CameraService.captureImage();
      if (imagePath != null && widget.onImageCaptured != null) {
        widget.onImageCaptured!(imagePath);
      }
    } catch (e) {
      debugPrint('Error capturing photo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = CameraService.controller;

    if (controller == null || !controller.value.isInitialized) {
      return Container(
        width: widget.width ?? double.infinity,
        height: widget.height ?? 300,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              SizedBox(height: 16),
              Text(
                'Đang khởi tạo camera...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Camera preview
            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller.value.previewSize!.height,
                  height: controller.value.previewSize!.width,
                  child: CameraPreview(controller),
                ),
              ),
            ),

            // Face overlay guide
            Center(
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.8),
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.face,
                            size: 80,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Đặt khuôn mặt vào khung',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Processing line animation
            if (widget.isScanning)
              AnimatedBuilder(
                animation: _scanAnimation,
                builder: (context, child) {
                  return Positioned(
                    left: 0,
                    right: 0,
                    top: MediaQuery.of(context).size.height * 0.3,
                    child: Transform.translate(
                      offset: Offset(0, _scanAnimation.value * 60),
                      child: Container(
                        height: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 50),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.white.withValues(alpha: 0.8),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

            // Corner brackets
            _buildCorner(Alignment.topLeft),
            _buildCorner(Alignment.topRight),
            _buildCorner(Alignment.bottomLeft),
            _buildCorner(Alignment.bottomRight),

            // Capture button
            if (widget.onImageCaptured != null)
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: _capturePhoto,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.3),
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorner(Alignment alignment) {
    return Positioned(
      top: alignment == Alignment.topLeft || alignment == Alignment.topRight ? 40 : null,
      bottom: alignment == Alignment.bottomLeft || alignment == Alignment.bottomRight ? 40 : null,
      left: alignment == Alignment.topLeft || alignment == Alignment.bottomLeft ? 40 : null,
      right: alignment == Alignment.topRight || alignment == Alignment.bottomRight ? 40 : null,
      child: Transform.rotate(
        angle: alignment == Alignment.topLeft
            ? 0
            : alignment == Alignment.topRight
                ? 1.5708
                : alignment == Alignment.bottomRight
                    ? 3.14159
                    : -1.5708,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.8),
                width: 3,
              ),
              left: BorderSide(
                color: Colors.white.withValues(alpha: 0.8),
                width: 3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
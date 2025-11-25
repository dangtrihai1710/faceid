import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class CameraView extends StatefulWidget {
  final List<CameraDescription>? cameras;
  final Function(CameraController?) onControllerReady;

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
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (!kIsWeb) {
      // Mobile platform initialization
      if (widget.cameras == null || widget.cameras!.isEmpty) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Không tìm thấy camera';
        });
        widget.onControllerReady(null);
        return;
      }

      try {
        final frontCamera = widget.cameras!.firstWhere(
          (cam) => cam.lensDirection == CameraLensDirection.front,
          orElse: () => widget.cameras!.first,
        );

        _controller = CameraController(frontCamera, ResolutionPreset.medium);
        await _controller!.initialize();
        if (mounted) {
          widget.onControllerReady(_controller);
        }
        if (mounted) setState(() => _isInitialized = true);
      } catch (e) {
        debugPrint('Mobile camera initialization failed: $e');
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = 'Không thể khởi tạo camera: $e';
          });
        }
        widget.onControllerReady(null);
      }
    } else {
      // Web platform - camera needs HTTPS and user permission
      try {
        await Future.delayed(const Duration(milliseconds: 500));

        if (widget.cameras != null && widget.cameras!.isNotEmpty) {
          final frontCamera = widget.cameras!.firstWhere(
            (cam) => cam.lensDirection == CameraLensDirection.front,
            orElse: () => widget.cameras!.first,
          );

          _controller = CameraController(frontCamera, ResolutionPreset.medium);
          await _controller!.initialize().timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Camera initialization timeout');
            },
          );
          if (mounted) {
            widget.onControllerReady(_controller);
          }
          if (mounted) setState(() => _isInitialized = true);
        } else {
          if (mounted) {
            setState(() {
              _hasError = true;
              _errorMessage = 'Không tìm thấy camera trên trình duyệt';
            });
          }
          widget.onControllerReady(null);
        }
      } catch (e) {
        debugPrint('Web camera initialization failed: $e');
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = 'Camera web không khả dụng. Vui lòng:\n'
                          '• Sử dụng HTTPS\n'
                          '• Cấp quyền truy cập camera\n'
                          '• Kiểm tra camera có đang hoạt động không';
          });
        }
        widget.onControllerReady(null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        color: Colors.grey[100],
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.camera_alt_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Camera không khả dụng',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Đang khởi tạo camera...'),
          ],
        ),
      );
    }

    if (_controller != null) {
      return CameraPreview(_controller!);
    } else {
      return Container(
        color: Colors.grey[100],
        child: const Center(
          child: Text('Camera không khả dụng'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
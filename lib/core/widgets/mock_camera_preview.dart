import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class MockCameraPreview extends StatefulWidget {
  final double? width;
  final double? height;
  final bool isScanning;

  const MockCameraPreview({
    super.key,
    this.width,
    this.height,
    this.isScanning = false,
  });

  @override
  State<MockCameraPreview> createState() => _MockCameraPreviewState();
}

class _MockCameraPreviewState extends State<MockCameraPreview>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scanController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
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

  @override
  void didUpdateWidget(MockCameraPreview oldWidget) {
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            // Mock camera background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.8),
                    AppColors.primaryVariant.withValues(alpha: 0.9),
                  ],
                ),
              ),
            ),
            // Mock face outline
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
            // Scanning line animation
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
            Positioned(
              top: 40,
              left: 40,
              child: _buildCorner(),
            ),
            Positioned(
              top: 40,
              right: 40,
              child: Transform.rotate(angle: 1.5708, child: _buildCorner()),
            ),
            Positioned(
              bottom: 40,
              left: 40,
              child: Transform.rotate(angle: -1.5708, child: _buildCorner()),
            ),
            Positioned(
              bottom: 40,
              right: 40,
              child: Transform.rotate(angle: 3.14159, child: _buildCorner()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorner() {
    return Container(
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
    );
  }
}
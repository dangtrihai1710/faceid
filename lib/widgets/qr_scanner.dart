import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../core/theme/app_colors.dart';

class QRScanner extends StatefulWidget {
  final Function(String) onScan;
  final bool continuous;

  const QRScanner({
    super.key,
    required this.onScan,
    this.continuous = false,
  });

  @override
  State<QRScanner> createState() => _QRScannerState();
}

class _QRScannerState extends State<QRScanner> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _controller.start();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing || !widget.continuous) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        _isProcessing = true;
        widget.onScan(barcode.rawValue!);

        if (!widget.continuous) {
          // Stop scanning after first detection if not continuous
          _controller.stop();
        }

        // Reset processing flag after a delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _isProcessing = false;
            });
            if (widget.continuous) {
              _controller.start();
            }
          }
        });
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: _onDetect,
        ),

        // QR Scanner overlay
        CustomPaint(
          size: Size.infinite,
          painter: QRScannerOverlay(),
        ),

        // Instructions
        Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    size: 32,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hạ camera xuống mã QR để điểm danh',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class QRScannerOverlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    final Paint borderPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Create transparent rectangle in the center
    final transparentRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 250,
      height: 250,
    );

    // Draw dark overlay outside the transparent rectangle
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(transparentRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Draw border around the transparent rectangle
    canvas.drawRRect(
      RRect.fromRectAndRadius(transparentRect, const Radius.circular(12)),
      borderPaint,
    );

    // Draw corner markers
    final cornerPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final cornerSize = 20.0;
    final cornerLength = 30.0;

    // Top-left corner
    canvas.drawLine(
      Offset(transparentRect.left - cornerSize, transparentRect.top),
      Offset(transparentRect.left + cornerLength, transparentRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(transparentRect.left, transparentRect.top - cornerSize),
      Offset(transparentRect.left, transparentRect.top + cornerLength),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(transparentRect.right - cornerLength, transparentRect.top),
      Offset(transparentRect.right + cornerSize, transparentRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(transparentRect.right, transparentRect.top - cornerSize),
      Offset(transparentRect.right, transparentRect.top + cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(transparentRect.left - cornerSize, transparentRect.bottom),
      Offset(transparentRect.left + cornerLength, transparentRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(transparentRect.left, transparentRect.bottom - cornerLength),
      Offset(transparentRect.left, transparentRect.bottom + cornerSize),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(transparentRect.right - cornerLength, transparentRect.bottom),
      Offset(transparentRect.right + cornerSize, transparentRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(transparentRect.right, transparentRect.bottom - cornerLength),
      Offset(transparentRect.right, transparentRect.bottom + cornerSize),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
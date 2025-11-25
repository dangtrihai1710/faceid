import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';
import '../../models/user.dart';
import '../../services/api_service.dart';

class QRAttendanceScreen extends StatefulWidget {
  final User currentUser;

  const QRAttendanceScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<QRAttendanceScreen> createState() => _QRAttendanceScreenState();
}

class _QRAttendanceScreenState extends State<QRAttendanceScreen> {
  late MobileScannerController _scannerController;
  bool _isScanning = true;
  bool _isLoading = false;
  String _pinCode = '';
  bool _usePinMode = false;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning || _isLoading) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null) {
        setState(() {
          _isLoading = true;
          _isScanning = false;
        });
        _processQRCode(code);
        break;
      }
    }
  }

  Future<void> _processQRCode(String qrData) async {
    try {
      Map<String, dynamic> sessionData;

      try {
        sessionData = jsonDecode(qrData);
      } catch (e) {
        sessionData = {
          'sessionCode': qrData,
          'timestamp': DateTime.now().toIso8601String(),
        };
      }

      final response = await ApiService.makeAuthenticatedRequest(
        'POST',
        '/api/v1/attendance/qr',
        body: {
          'qr_code': jsonEncode(sessionData),
          'user_id': widget.currentUser.userId,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (response['success'] == true) {
        _showSuccessDialog();
      } else {
        throw Exception(response['message'] ?? 'Failed to mark attendance');
      }
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submitWithPin() async {
    if (_pinCode.length != 6) {
      _showErrorDialog('Mã PIN phải có 6 ký tự');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.makeAuthenticatedRequest(
        'POST',
        '/api/v1/attendance/code',
        body: {
          'code': _pinCode.toUpperCase(),
          'user_id': widget.currentUser.userId,
          'timestamp': DateTime.now().toIso8601String(),
          'class_id': '',
        },
      );

      if (response['success'] == true) {
        _showSuccessDialog();
      } else {
        throw Exception(response['message'] ?? 'Invalid PIN code');
      }
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
        _pinCode = '';
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Điểm danh thành công!'),
          ],
        ),
        content: const Text('Bạn đã điểm danh thành công.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Điểm danh thất bại'),
          ],
        ),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _isScanning = true;
              });
            },
            child: const Text('Thử lại'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_usePinMode ? 'Điểm danh PIN' : 'Điểm danh QR'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _usePinMode = !_usePinMode;
                _isScanning = !_usePinMode;
              });
            },
            icon: Icon(_usePinMode ? Icons.qr_code_scanner : Icons.keyboard),
            tooltip: _usePinMode ? 'Chuyển sang QR' : 'Chuyển sang PIN',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang xử lý...'),
                ],
              ),
            )
          : _usePinMode
              ? _buildPinMode()
              : _buildQRMode(),
    );
  }

  Widget _buildQRMode() {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: MobileScanner(
                controller: _scannerController,
                onDetect: _onDetect,
              ),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Đưa mã QR vào vùng quét',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPinMode() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.keyboard,
            size: 80,
            color: Colors.green[600],
          ),
          const SizedBox(height: 24),
          const Text(
            'Nhập mã PIN điểm danh',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(6, (index) {
              return Container(
                width: 50,
                height: 60,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    index < _pinCode.length ? _pinCode[index].toUpperCase() : '',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                ...List.generate(9, (index) {
                  final number = (index + 1).toString();
                  return _buildKeypadButton(
                    text: number,
                    onPressed: () {
                      if (_pinCode.length < 6) {
                        setState(() => _pinCode += number);
                      }
                    },
                  );
                }),
                _buildKeypadButton(
                  text: 'Xóa',
                  onPressed: () {
                    if (_pinCode.isNotEmpty) {
                      setState(() => _pinCode = _pinCode.substring(0, _pinCode.length - 1));
                    }
                  },
                  color: Colors.orange,
                ),
                _buildKeypadButton(
                  text: '0',
                  onPressed: () {
                    if (_pinCode.length < 6) {
                      setState(() => _pinCode += '0');
                    }
                  },
                ),
                _buildKeypadButton(
                  text: 'Điểm danh',
                  onPressed: _submitWithPin,
                  color: Colors.green,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadButton({
    required String text,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? Colors.grey[200],
        foregroundColor: color != null ? Colors.white : Colors.black,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
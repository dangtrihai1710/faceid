import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';
import '../services/qr_service.dart';
import '../services/class_service.dart';
import '../models/class_model.dart';
import '../models/user.dart';
import '../screens/class_detail_screen.dart';

class QRGeneratorEnhancedScreen extends StatefulWidget {
  final ClassModel classModel;
  final User currentUser;

  const QRGeneratorEnhancedScreen({
    super.key,
    required this.classModel,
    required this.currentUser,
  });

  @override
  State<QRGeneratorEnhancedScreen> createState() => _QRGeneratorEnhancedScreenState();
}

class _QRGeneratorEnhancedScreenState extends State<QRGeneratorEnhancedScreen> {
  String? _qrData;
  Timer? _countdownTimer;
  int _remainingSeconds = 0;
  bool _isGenerating = false;
  final List<String> _generatedQRs = [];
  int _checkInCount = 0;

  // OTP Fallback properties
  bool _showOTP = false;
  String? _otpCode;
  String? _otpSessionId;
  Timer? _otpCountdownTimer;
  int _otpRemainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _loadAttendanceCount();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _otpCountdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAttendanceCount() async {
    try {
      final attendanceRecords = await ClassService.getAttendanceRecordsByClass(widget.classModel.id);
      setState(() {
        _checkInCount = attendanceRecords.length;
      });
    } catch (e) {
      print('Error loading attendance count: $e');
    }
  }

  Future<void> _generateQRCode() async {
    if (!widget.classModel.isAttendanceOpen) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng mở điểm danh trước khi tạo QR Code'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      // Generate QR Code data with embedded OTP
      final qrData = QRService.generateQRCodeData(widget.classModel, widget.currentUser.id);

      // Extract OTP from QR data
      final data = await QRService.validateQRCodeData(qrData);
      if (data != null && !data.containsKey('error')) {
        await QRService.saveQRSession(data['sessionId'], widget.classModel.id);

        setState(() {
          _qrData = qrData;
          _otpCode = data['otpCode'] as String?;
          _otpSessionId = data['sessionId'] as String?;
          _remainingSeconds = 900; // 15 minutes
          _otpRemainingSeconds = 600; // 10 minutes for OTP
          _isGenerating = false;
          _generatedQRs.add(qrData);
        });

        // Start both countdowns
        _startCountdown();
        _startOTPCountdown();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã tạo QR Code và mã OTP dự phòng'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error generating QR code: $e');
      setState(() {
        _isGenerating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tạo QR Code: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _generateOTPFallback() async {
    if (!widget.classModel.isAttendanceOpen) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng mở điểm danh trước khi tạo OTP'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final otpData = QRService.generateFallbackOTP(widget.classModel, widget.currentUser.id);

      setState(() {
        _otpCode = otpData['otpCode'];
        _otpSessionId = otpData['sessionId'];
        _otpRemainingSeconds = 600; // 10 minutes
        _showOTP = true;
        _isGenerating = false;
      });

      _startOTPCountdown();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã tạo mã OTP dự phòng'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error generating OTP: $e');
      setState(() {
        _isGenerating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tạo OTP: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) {
          timer.cancel();
          _qrData = null;
        }
      });
    });
  }

  void _startOTPCountdown() {
    _otpCountdownTimer?.cancel();
    _otpCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _otpRemainingSeconds--;
        if (_otpRemainingSeconds <= 0) {
          timer.cancel();
          _otpCode = null;
          _showOTP = false;
        }
      });
    });
  }

  void _stopQRCode() {
    _countdownTimer?.cancel();
    setState(() {
      _qrData = null;
      _remainingSeconds = 0;
    });
  }

  void _toggleOTPView() {
    setState(() {
      _showOTP = !_showOTP;
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _refreshAttendanceCount() async {
    await _loadAttendanceCount();
  }

  void _showQRHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lịch sử QR Code'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: _generatedQRs.isEmpty
              ? const Center(child: Text('Chưa có QR Code nào được tạo'))
              : ListView.builder(
                  itemCount: _generatedQRs.length,
                  itemBuilder: (context, index) {
                    final qrData = _generatedQRs[index];
                    return ListTile(
                      leading: const Icon(Icons.qr_code),
                      title: Text('QR Code #${index + 1}'),
                      subtitle: Text('Tạo lúc: ${DateTime.now().subtract(Duration(minutes: _generatedQRs.length - index)).toString().substring(0, 19)}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.visibility),
                        onPressed: () {
                          Navigator.of(context).pop();
                          setState(() {
                            _qrData = qrData;
                            _remainingSeconds = 60; // Show for 1 minute
                          });
                          _startCountdown();
                        },
                      ),
                    );
                  },
                ),
        ),
        actions: [
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
      appBar: AppBar(
        title: Text('QR Code - ${widget.classModel.name}'),
        backgroundColor: Colors.purple[700],
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showQRHistory,
            tooltip: 'Lịch sử QR Code',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAttendanceCount,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: Column(
        children: [
          // Class Info Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.classModel.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      widget.classModel.timeRange,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      widget.classModel.room,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.people, size: 16, color: Colors.blue[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Đã điểm danh: $_checkInCount sinh viên',
                      style: TextStyle(color: Colors.blue[600], fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // QR Code Display Section
          Expanded(
            flex: 3,
            child: _qrData != null
                ? Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.purple[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: QrImageView(
                            data: _qrData!,
                            version: QrVersions.auto,
                            size: 200,
                            backgroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (_remainingSeconds > 0) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _remainingSeconds < 60
                                  ? Colors.red[100]
                                  : Colors.orange[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Thời gian còn lại: ${_formatTime(_remainingSeconds)}',
                              style: TextStyle(
                                color: _remainingSeconds < 60
                                    ? Colors.red[700]
                                    : Colors.orange[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        ElevatedButton.icon(
                          onPressed: _stopQRCode,
                          icon: const Icon(Icons.stop),
                          label: const Text('Dừng QR Code'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_scanner, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Chưa có QR Code nào',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Nhấn "Tạo QR Code" để bắt đầu',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
          ),

          // OTP Fallback Section
          if (_otpCode != null) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.backup, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Mã OTP dự phòng',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _toggleOTPView,
                        icon: Icon(
                          _showOTP ? Icons.visibility_off : Icons.visibility,
                          color: Colors.orange[700],
                        ),
                        label: Text(
                          _showOTP ? 'Ẩn' : 'Hiện',
                          style: TextStyle(color: Colors.orange[700]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_showOTP) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[300]!),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _otpCode!,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 8,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Mã có hiệu lực trong ${_formatTime(_otpRemainingSeconds)}',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange[700], size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Sinh viên có thể sử dụng mã này khi không thể quét QR Code',
                              style: TextStyle(
                                color: Colors.orange[700],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock, color: Colors.orange[400]),
                          const SizedBox(width: 8),
                          Text(
                            'Mã OTP đã được tạo',
                            style: TextStyle(
                              color: Colors.orange[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // Action Buttons
          Container(
            margin: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isGenerating ? null : _generateQRCode,
                        icon: _isGenerating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.qr_code),
                        label: Text(_isGenerating ? 'Đang tạo...' : 'Tạo QR Code'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _otpCode == null && !_isGenerating ? _generateOTPFallback : null,
                      icon: const Icon(Icons.backup),
                      label: const Text('Tạo OTP'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => ClassDetailScreen(
                                classModel: widget.classModel,
                                currentUser: widget.currentUser,
                                cameras: const [],
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Quay lại'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
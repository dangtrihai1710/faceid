import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/class_model.dart';
import '../models/user.dart';

class QRService {
  static const String _qrSessionsKey = 'qr_sessions';

  // Generate QR Code data for a class session
  static String generateQRCodeData(ClassModel classModel, String instructorId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final otpCode = _generateOTPCode(classModel.id, timestamp);
    final data = {
      'type': 'class_session',
      'classId': classModel.id,
      'className': classModel.name,
      'instructorId': instructorId,
      'timestamp': timestamp,
      'expiresAt': timestamp + (15 * 60 * 1000), // 15 minutes expiry
      'sessionId': _generateSessionId(classModel.id, timestamp),
      'otpCode': otpCode,
      'checksum': _generateChecksum(classModel.id, otpCode, timestamp),
    };

    final jsonString = jsonEncode(data);
    return base64Encode(utf8.encode(jsonString));
  }

  // Generate 6-digit OTP code
  static String _generateOTPCode(String classId, int timestamp) {
    final input = '$classId-$timestamp-${DateTime.now().millisecond}';
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    final otpValue = int.parse(digest.toString().substring(0, 8), radix: 16);
    return (otpValue % 1000000).toString().padLeft(6, '0');
  }

  // Generate fallback OTP when camera is not available
  static Map<String, String> generateFallbackOTP(ClassModel classModel, String instructorId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final otpCode = _generateOTPCode(classModel.id, timestamp);
    final sessionId = _generateSessionId(classModel.id, timestamp);

    return {
      'otpCode': otpCode,
      'sessionId': sessionId,
      'expiresAt': (timestamp + (10 * 60 * 1000)).toString(), // 10 minutes for OTP
      'timestamp': timestamp.toString(),
      'classId': classModel.id,
      'className': classModel.name,
    };
  }

  // Validate OTP code
  static Future<Map<String, dynamic>?> validateOTPCode(String otpCode, String classId) async {
    try {
      // For demo purposes, generate and validate OTP
      // In real app, this would check against stored OTP codes
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final expectedOTP = _generateOTPCode(classId, timestamp - 60000); // Allow 1 minute drift

      if (otpCode.length == 6 && int.tryParse(otpCode) != null) {
        return {
          'valid': true,
          'classId': classId,
          'timestamp': timestamp,
          'type': 'otp_fallback',
        };
      }

      return {'valid': false, 'error': 'Mã OTP không hợp lệ'};
    } catch (e) {
      print('Error validating OTP: $e');
      return {'valid': false, 'error': 'Lỗi xác thực OTP'};
    }
  }

  // Generate unique session ID
  static String _generateSessionId(String classId, int timestamp) {
    final input = '$classId-$timestamp-${DateTime.now().millisecondsSinceEpoch}';
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  // Validate QR Code data
  static Future<Map<String, dynamic>?> validateQRCodeData(String qrData) async {
    try {
      final decodedBytes = base64.decode(qrData);
      final jsonString = utf8.decode(decodedBytes);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // Check if QR Code has expired
      final expiresAt = data['expiresAt'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;

      if (now > expiresAt) {
        return {'error': 'QR Code đã hết hạn'};
      }

      // Check if session is still valid
      final sessionId = data['sessionId'] as String;
      final isValidSession = await _validateSession(sessionId);

      if (!isValidSession) {
        return {'error': 'Phiên điểm danh không hợp lệ'};
      }

      return data;
    } catch (e) {
      print('Error validating QR code: $e');
      return {'error': 'QR Code không hợp lệ'};
    }
  }

  // Save QR session
  static Future<void> saveQRSession(String sessionId, String classId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final qrSessionsJson = prefs.getString(_qrSessionsKey) ?? '{}';
      final qrSessions = jsonDecode(qrSessionsJson) as Map<String, dynamic>;

      qrSessions[sessionId] = {
        'classId': classId,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };

      await prefs.setString(_qrSessionsKey, jsonEncode(qrSessions));
    } catch (e) {
      print('Error saving QR session: $e');
    }
  }

  // Validate QR session
  static Future<bool> _validateSession(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final qrSessionsJson = prefs.getString(_qrSessionsKey) ?? '{}';
      final qrSessions = jsonDecode(qrSessionsJson) as Map<String, dynamic>;

      if (!qrSessions.containsKey(sessionId)) {
        return false;
      }

      final session = qrSessions[sessionId] as Map<String, dynamic>;
      final createdAt = session['createdAt'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Session valid for 30 minutes
      return (now - createdAt) < (30 * 60 * 1000);
    } catch (e) {
      print('Error validating session: $e');
      return false;
    }
  }

  // Clean up expired sessions
  static Future<void> cleanupExpiredSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final qrSessionsJson = prefs.getString(_qrSessionsKey) ?? '{}';
      final qrSessions = jsonDecode(qrSessionsJson) as Map<String, dynamic>;

      final now = DateTime.now().millisecondsSinceEpoch;
      final validSessions = <String, dynamic>{};

      qrSessions.forEach((sessionId, sessionData) {
        final session = sessionData as Map<String, dynamic>;
        final createdAt = session['createdAt'] as int;

        // Keep sessions less than 1 hour old
        if ((now - createdAt) < (60 * 60 * 1000)) {
          validSessions[sessionId] = session;
        }
      });

      await prefs.setString(_qrSessionsKey, jsonEncode(validSessions));
    } catch (e) {
      print('Error cleaning up sessions: $e');
    }
  }

  // Get active QR sessions for a class
  static Future<List<String>> getActiveSessionsForClass(String classId) async {
    try {
      await cleanupExpiredSessions();

      final prefs = await SharedPreferences.getInstance();
      final qrSessionsJson = prefs.getString(_qrSessionsKey) ?? '{}';
      final qrSessions = jsonDecode(qrSessionsJson) as Map<String, dynamic>;

      final activeSessions = <String>[];

      qrSessions.forEach((sessionId, sessionData) {
        final session = sessionData as Map<String, dynamic>;
        if (session['classId'] == classId) {
          activeSessions.add(sessionId);
        }
      });

      return activeSessions;
    } catch (e) {
      print('Error getting active sessions: $e');
      return [];
    }
  }

  // Generate attendance QR Code text for student
  static String generateStudentAttendanceQR(User student, String classId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final data = {
      'type': 'student_attendance',
      'studentId': student.id,
      'studentName': student.fullName,
      'classId': classId,
      'timestamp': timestamp,
      'checksum': _generateChecksum(student.id, classId, timestamp),
    };

    final jsonString = jsonEncode(data);
    return base64Encode(utf8.encode(jsonString));
  }

  // Validate student attendance QR Code
  static bool validateStudentAttendanceQR(String qrData, String expectedClassId) {
    try {
      final decodedBytes = base64.decode(qrData);
      final jsonString = utf8.decode(decodedBytes);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      if (data['type'] != 'student_attendance') {
        return false;
      }

      if (data['classId'] != expectedClassId) {
        return false;
      }

      final timestamp = data['timestamp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;

      // QR Code valid for 5 minutes
      if ((now - timestamp) > (5 * 60 * 1000)) {
        return false;
      }

      final expectedChecksum = _generateChecksum(
        data['studentId'],
        data['classId'],
        timestamp,
      );

      return data['checksum'] == expectedChecksum;
    } catch (e) {
      print('Error validating student QR: $e');
      return false;
    }
  }

  // Generate checksum for data integrity
  static String _generateChecksum(String studentId, String classId, int timestamp) {
    final input = '$studentId-$classId-$timestamp';
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 8);
  }
}
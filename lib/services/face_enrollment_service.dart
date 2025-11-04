import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/face_model.dart';
import '../models/user.dart';

class FaceEnrollmentService {
  static const String _facesKey = 'enrolled_faces';

  // Get enrolled faces for a user
  static Future<List<FaceModel>> getEnrolledFaces(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final facesJson = prefs.getString(_facesKey) ?? '[]';
      final List<dynamic> facesList = jsonDecode(facesJson);

      return facesList
          .map((json) => FaceModel.fromJson(json))
          .where((face) => face.userId == userId)
          .toList()
        ..sort((a, b) => b.enrolledAt.compareTo(a.enrolledAt));
    } catch (e) {
      print('Error getting enrolled faces: $e');
      return [];
    }
  }

  // Save enrolled face
  static Future<void> saveEnrolledFace(FaceModel face) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final facesJson = prefs.getString(_facesKey) ?? '[]';
      final List<dynamic> facesList = jsonDecode(facesJson);

      facesList.add(face.toJson());

      await prefs.setString(_facesKey, jsonEncode(facesList));
      print('Face enrolled successfully');
    } catch (e) {
      print('Error saving enrolled face: $e');
      throw Exception('Lỗi khi lưu khuôn mặt đã đăng ký');
    }
  }

  // Update enrolled face
  static Future<void> updateEnrolledFace(FaceModel face) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final facesJson = prefs.getString(_facesKey) ?? '[]';
      final List<dynamic> facesList = jsonDecode(facesJson);

      final index = facesList.indexWhere(
        (faceJson) => faceJson['id'] == face.id,
      );

      if (index != -1) {
        facesList[index] = face.toJson();
        await prefs.setString(_facesKey, jsonEncode(facesList));
        print('Face updated successfully');
      }
    } catch (e) {
      print('Error updating enrolled face: $e');
      throw Exception('Lỗi khi cập nhật khuôn mặt đã đăng ký');
    }
  }

  // Delete enrolled face
  static Future<void> deleteEnrolledFace(String faceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final facesJson = prefs.getString(_facesKey) ?? '[]';
      final List<dynamic> facesList = jsonDecode(facesJson);

      facesList.removeWhere((faceJson) => faceJson['id'] == faceId);

      await prefs.setString(_facesKey, jsonEncode(facesList));
      print('Face deleted successfully');
    } catch (e) {
      print('Error deleting enrolled face: $e');
      throw Exception('Lỗi khi xóa khuôn mặt đã đăng ký');
    }
  }

  // Check if user has enrolled faces
  static Future<bool> hasEnrolledFaces(String userId) async {
    try {
      final faces = await getEnrolledFaces(userId);
      return faces.any((face) => face.isActive);
    } catch (e) {
      print('Error checking enrolled faces: $e');
      return false;
    }
  }

  // Get enrollment statistics
  static Future<Map<String, int>> getEnrollmentStats(String userId) async {
    try {
      final faces = await getEnrolledFaces(userId);
      return {
        'total': faces.length,
        'active': faces.where((face) => face.isActive).length,
        'inactive': faces.where((face) => !face.isActive).length,
      };
    } catch (e) {
      print('Error getting enrollment stats: $e');
      return {
        'total': 0,
        'active': 0,
        'inactive': 0,
      };
    }
  }

  // Simulate face enrollment process
  static Future<FaceModel> enrollFace(
    String userId,
    String photoPath,
    {String? description}
  ) async {
    try {
      // Simulate processing time
      await Future.delayed(const Duration(seconds: 2));

      // Create face model
      final face = FaceModel(
        id: 'face_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        photoPath: photoPath,
        enrolledAt: DateTime.now(),
        isActive: true,
        description: description,
        faceFeatures: {
          // Simulated face features (in real app, this would be extracted from face recognition)
          'confidence': 0.95,
          'quality': 'high',
          'faceId': 'face_${DateTime.now().millisecondsSinceEpoch}',
          'capturedAt': DateTime.now().toIso8601String(),
        },
      );

      // Save face
      await saveEnrolledFace(face);

      return face;
    } catch (e) {
      print('Error in face enrollment process: $e');
      throw Exception('Lỗi trong quá trình đăng ký khuôn mặt: $e');
    }
  }

  // Simulate face recognition check
  static Future<bool> recognizeFace(String userId, String photoPath) async {
    try {
      await Future.delayed(const Duration(seconds: 1));

      // Simulate face recognition process
      final faces = await getEnrolledFaces(userId);
      final activeFaces = faces.where((face) => face.isActive);

      // In demo mode, randomly return true for testing
      return activeFaces.isNotEmpty && DateTime.now().millisecondsSinceEpoch % 2 == 0;
    } catch (e) {
      print('Error in face recognition: $e');
      return false;
    }
  }

  // Get face enrollment guidelines
  static List<String> getEnrollmentGuidelines() {
    return [
      'Đảm bảo đủ ánh sáng, tránh quá tối hoặc quá sáng',
      'Nhìn thẳng vào camera, giữ khuôn mặt trong khung hình',
      'Giữ biểu cảm tự nhiên, không đeo kính hoặc khẩu trang',
      'Chụp từ 3-5 ảnh ở các góc độ khác nhau để tốt nhất',
      'Loại bỏ các vật cản trở như khẩu trang, tóc che mắt',
      'Giữ khoảng cách phù hợp với camera (khoảng 30-50cm)',
      'Đảm bảo toàn bộ khuôn mặt hiển thị rõ ràng',
    ];
  }
}
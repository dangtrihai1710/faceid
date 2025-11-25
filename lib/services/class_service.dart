import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/class_model.dart';
import '../models/attendance_model.dart';
import '../utils/constants.dart';

class ClassService {
  static String _getToken() {
    return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiMzYiLCJlbWFpbCI6InJhdW1hQGdtYWlsLmNvbSIsImZ1bGxfbmFtZSI6IlJhdSBNXHUwMGUxIiwicm9sZSI6InN0dWRlbnQiLCJleHAiOjE3NjQxMjkzMDF9.4yyE127-ylZ2U8dkAlV8f5x6V_cVit6cRRUjACL8Fgg';
  }

  static Future<List<ClassModel>> getStudentClasses() async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.BASE_URL}/api/v1/classes/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_getToken()',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final classes = data['data'] as List;
          return classes.map((classJson) => ClassModel.fromJson(classJson)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching student classes: $e');
      return [];
    }
  }

  static Future<List<AttendanceModel>> getAttendanceHistory(String classId) async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.BASE_URL}/api/v1/attendance/student/36'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_getToken()',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final attendances = data['data']['records'] as List;
          return attendances.map((attJson) => AttendanceModel.fromJson(attJson)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching attendance history: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> getAttendanceStats() async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.BASE_URL}/api/v1/attendance/student/36'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_getToken()',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'success': false, 'data': {}};
    } catch (e) {
      print('Error fetching attendance stats: $e');
      return {'success': false, 'data': {}};
    }
  }

  static Future<Map<String, dynamic>> getSchedule() async {
    try {
      final classes = await getStudentClasses();

      // Lấy lịch học từ các lớp học
      List<Map<String, dynamic>> schedule = [];
      for (var classModel in classes) {
        if (classModel.schedule != null) {
          schedule.add({
            'classId': classModel.id,
            'className': classModel.name,
            'instructor': classModel.instructorName,
            'room': classModel.room ?? 'TBA',
            'dayOfWeek': classModel.schedule!['day_of_week'],
            'startTime': classModel.schedule!['start_time'],
            'endTime': classModel.schedule!['end_time'],
            'type': classModel.classType.toString().split('.').last,
          });
        }
      }

      return {
        'success': true,
        'data': schedule,
      };
    } catch (e) {
      print('Error fetching schedule: $e');
      return {'success': false, 'data': []};
    }
  }
}
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../models/class_model.dart';
import '../models/attendance_model.dart';
import '../core/config/api_config.dart';

class ClassService {
  static String _getToken() {
    return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiMzYiLCJlbWFpbCI6InJhdW1hQGdtYWlsLmNvbSIsImZ1bGxfbmFtZSI6IlJhdSBNXHUwMGUxIiwicm9sZSI6InN0dWRlbnQiLCJleHAiOjE3NjQxMjkzMDF9.4yyE127-ylZ2U8dkAlV8f5x6V_cVit6cRRUjACL8Fgg';
  }

  static Future<List<ClassModel>> getStudentClasses() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/classes/'),
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
      developer.log('Error fetching student classes: $e', name: 'ClassService.getStudentClasses', level: 1000);
      return [];
    }
  }

  static Future<List<AttendanceModel>> getAttendanceHistory(String classId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/attendance/student/36'),
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
      developer.log('Error fetching attendance history: $e', name: 'ClassService.getAttendanceHistory', level: 1000);
      return [];
    }
  }

  static Future<Map<String, dynamic>> getAttendanceStats() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/attendance/student/36'),
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
      developer.log('Error fetching attendance stats: $e', name: 'ClassService.getAttendanceStats', level: 1000);
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
            'room': classModel.room,
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
      developer.log('Error fetching schedule: $e', name: 'ClassService.getSchedule', level: 1000);
      return {'success': false, 'data': []};
    }
  }

  // Admin methods for class management
  static Future<List<dynamic>> getAttendanceRecordsByClass(String classId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/attendance/class/$classId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_getToken()',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'] as List;
        }
      }
      return [];
    } catch (e) {
      developer.log('Error fetching attendance records: $e', name: 'ClassService.getAttendanceRecordsByClass', level: 1000);
      return [];
    }
  }

  static Future<Map<String, dynamic>> updateClass(String classId, Map<String, dynamic> updateData) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/classes/$classId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_getToken()',
        },
        body: json.encode(updateData),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'success': false, 'message': 'Failed to update class'};
    } catch (e) {
      developer.log('Error updating class: $e', name: 'ClassService.updateClass', level: 1000);
      return {'success': false, 'message': 'Error updating class'};
    }
  }

  static Future<Map<String, dynamic>> saveAttendanceRecord(Map<String, dynamic> attendanceData) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/v1/attendance'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_getToken()',
        },
        body: json.encode(attendanceData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'success': false, 'message': 'Failed to save attendance'};
    } catch (e) {
      developer.log('Error saving attendance: $e', name: 'ClassService.saveAttendanceRecord', level: 1000);
      return {'success': false, 'message': 'Error saving attendance'};
    }
  }
}
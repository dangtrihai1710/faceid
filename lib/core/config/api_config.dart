class ApiConfig {
  // Server configuration
  // Use your actual IP address when running on mobile device/emulator
  static const String baseUrl = 'http://192.168.100.142:8000'; // For Android emulator
  // static const String baseUrl = 'http://127.0.0.1:8000'; // For same machine testing
  static const String apiVersion = 'api/v1';

  // API endpoints
  static const String _auth = '/auth';
  static const String _users = '/users';
  static const String _classes = '/classes';
  static const String _attendance = '/attendance';
  static const String _admin = '/admin';

  // Full endpoint URLs
  static String get authEndpoint => '$baseUrl/$apiVersion$_auth';
  static String get usersEndpoint => '$baseUrl/$apiVersion$_users';
  static String get classesEndpoint => '$baseUrl/$apiVersion$_classes';
  static String get attendanceEndpoint => '$baseUrl/$apiVersion$_attendance';
  static String get adminEndpoint => '$baseUrl/$apiVersion$_admin';

  // Specific endpoints
  static String get loginEndpoint => '$authEndpoint/login';
  static String get logoutEndpoint => '$authEndpoint/logout';
  static String get refreshTokenEndpoint => '$authEndpoint/refresh';
  static String get meEndpoint => '$authEndpoint/me';
  static String get changePasswordEndpoint => '$authEndpoint/change-password';
  static String get demoAccountsEndpoint => '$authEndpoint/demo-accounts';

  static String get recognizeFaceEndpoint => '$attendanceEndpoint/recognize-face';
  static String get qrAttendanceEndpoint => '$attendanceEndpoint/qr';
  static String get codeAttendanceEndpoint => '$attendanceEndpoint/code';
  static String get attendanceHistoryEndpoint => '$attendanceEndpoint/history';

  static String get healthEndpoint => '$baseUrl/health';
  static String get adminHealthEndpoint => '$adminEndpoint/health';

  // Timeout configurations
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Cache configuration
  static const Duration cacheTimeout = Duration(minutes: 5);

  // Retry configuration
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 1);
}

class ApiConstants {
  // HTTP Status Codes
  static const int ok = 200;
  static const int created = 201;
  static const int badRequest = 400;
  static const int unauthorized = 401;
  static const int forbidden = 403;
  static const int notFound = 404;
  static const int serverError = 500;

  // Cache keys
  static const String userTokenKey = 'user_token';
  static const String userInfoKey = 'user_info';
  static const String rememberMeKey = 'remember_me';

  // File upload limits
  static const int maxFileSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageTypes = [
    'image/jpeg',
    'image/png',
    'image/webp',
  ];

  // Face recognition settings
  static const double faceConfidenceThreshold = 0.85;
  static const int maxImageDimension = 800;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
}
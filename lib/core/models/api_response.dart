/// Base API Response
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final int? statusCode;
  final String? message;
  final DateTime timestamp;

  ApiResponse({
    required this.success,
    this.data,
    this.error,
    this.statusCode,
    this.message,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ApiResponse.success(T data, {String? message, int? statusCode}) {
    return ApiResponse<T>(
      success: true,
      data: data,
      message: message,
      statusCode: statusCode,
    );
  }

  factory ApiResponse.error(String error, {int? statusCode, String? message}) {
    return ApiResponse<T>(
      success: false,
      error: error,
      statusCode: statusCode,
      message: message,
    );
  }

  factory ApiResponse.fromJson(Map<String, dynamic> json, {T? data}) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      data: data ?? json['data'],
      error: json['error'],
      statusCode: json['status_code'],
      message: json['message'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data,
      'error': error,
      'status_code': statusCode,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Paginated Response
class PaginatedResponse<T> {
  final List<T> items;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int pageSize;
  final bool hasNext;
  final bool hasPrevious;

  PaginatedResponse({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.pageSize,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemFromJson,
  ) {
    final itemsData = json['items'] as List? ?? [];
    final items = itemsData
        .map((item) => itemFromJson(item as Map<String, dynamic>))
        .toList();

    return PaginatedResponse<T>(
      items: items,
      currentPage: json['current_page'] ?? 1,
      totalPages: json['total_pages'] ?? 1,
      totalItems: json['total_items'] ?? 0,
      pageSize: json['page_size'] ?? 20,
      hasNext: json['has_next'] ?? false,
      hasPrevious: json['has_previous'] ?? false,
    );
  }
}

/// API Error Model
class ApiError {
  final String code;
  final String message;
  final String? details;
  final int? statusCode;
  final DateTime timestamp;

  ApiError({
    required this.code,
    required this.message,
    this.details,
    this.statusCode,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      code: json['code'] ?? 'UNKNOWN_ERROR',
      message: json['message'] ?? json['error'] ?? 'Unknown error occurred',
      details: json['details'],
      statusCode: json['status_code'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'ApiError{code: $code, message: $message, statusCode: $statusCode}';
  }
}

/// Network Exception Types
enum NetworkExceptionType {
  noInternet,
  timeout,
  serverError,
  unauthorized,
  forbidden,
  notFound,
  badRequest,
  unknown,
}

class NetworkException implements Exception {
  final NetworkExceptionType type;
  final String message;
  final String? details;
  final int? statusCode;

  NetworkException({
    required this.type,
    required this.message,
    this.details,
    this.statusCode,
  });

  @override
  String toString() {
    return 'NetworkException{type: $type, message: $message}';
  }
}
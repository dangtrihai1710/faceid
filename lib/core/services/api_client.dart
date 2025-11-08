import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/api_response.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  late Dio _dio;
  String? _accessToken;

  void initialize() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      sendTimeout: ApiConfig.sendTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptors
    _dio.interceptors.add(LogInterceptor(
      requestBody: kDebugMode,
      responseBody: kDebugMode,
      requestHeader: kDebugMode,
      responseHeader: kDebugMode,
      error: kDebugMode,
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add authentication token if available
        if (_accessToken != null) {
          options.headers['Authorization'] = 'Bearer $_accessToken';
        }

        debugPrint('API Request: ${options.method} ${options.uri}');
        if (options.data != null) {
          debugPrint('Request Data: ${options.data}');
        }

        handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint('API Response: ${response.statusCode} ${response.requestOptions.uri}');
        handler.next(response);
      },
      onError: (error, handler) async {
        debugPrint('API Error: ${error.message}');

        // Handle token refresh
        if (error.response?.statusCode == 401 && _accessToken != null) {
          try {
            final newToken = await _refreshToken();
            if (newToken != null) {
              _accessToken = newToken;
              // Retry the original request with new token
              error.requestOptions.headers['Authorization'] = 'Bearer $_accessToken';
              final response = await _dio.fetch(error.requestOptions);
              handler.resolve(response);
              return;
            }
          } catch (e) {
            // Refresh failed, clear token
            _accessToken = null;
            await _clearStoredToken();
          }
        }

        handler.next(error);
      },
    ));
  }

  void setAuthToken(String token) {
    _accessToken = token;
  }

  void clearAuth() {
    _accessToken = null;
  }

  Future<String?> _refreshToken() async {
    try {
      final response = await _dio.post(
        '${ApiConfig.authEndpoint}/refresh',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_accessToken',
          },
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data']['access_token'];
      }
    } catch (e) {
      debugPrint('Token refresh failed: $e');
    }
    return null;
  }

  Future<void> _clearStoredToken() async {
    // This would integrate with SharedPreferences or flutter_secure_storage
    debugPrint('Clearing stored authentication tokens');
  }

  // Generic GET request
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return _handleResponse<T>(response, fromJson: fromJson);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Generic POST request
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return _handleResponse<T>(response, fromJson: fromJson);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Generic PUT request
  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return _handleResponse<T>(response, fromJson: fromJson);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Generic DELETE request
  Future<ApiResponse<T>> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.delete(path, queryParameters: queryParameters);
      return _handleResponse<T>(response, fromJson: fromJson);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // File upload
  Future<ApiResponse<T>> upload<T>(
    String path, {
    required File file,
    Map<String, dynamic>? data,
    T Function(dynamic)? fromJson,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final fileName = file.path.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
        ...?data,
      });

      final response = await _dio.post(
        path,
        data: formData,
        onSendProgress: onSendProgress,
      );

      return _handleResponse<T>(response, fromJson: fromJson);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Handle successful response
  ApiResponse<T> _handleResponse<T>(
    Response response, {
    T Function(dynamic)? fromJson,
  }) {
    if (response.statusCode! >= 200 && response.statusCode! < 300) {
      final data = response.data;

      if (data is Map<String, dynamic>) {
        // Check if this is a standard API response format
        if (data.containsKey('success') && data.containsKey('data')) {
          // Convert nested data if fromJson function is provided
          if (fromJson != null && data['data'] != null) {
            try {
              final convertedData = fromJson(data['data']);
              return ApiResponse<T>.success(
                convertedData,
                message: data['message'],
                statusCode: response.statusCode,
              );
            } catch (e) {
              // If conversion fails, fall back to raw data
              debugPrint('Data conversion error: $e');
            }
          }

          // Return API response without converting nested data
          return ApiResponse<T>(
            success: data['success'] ?? false,
            data: null, // Don't assign raw Map to generic type T
            message: data['message'],
            statusCode: response.statusCode,
          );
        }

        // Handle direct data response (not wrapped in API format)
        if (fromJson != null) {
          try {
            final convertedData = fromJson(data);
            return ApiResponse<T>.success(
              convertedData,
              statusCode: response.statusCode,
            );
          } catch (e) {
            debugPrint('Direct data conversion error: $e');
          }
        }

        return ApiResponse<T>.success(
          data as T,
          statusCode: response.statusCode,
        );
      }

      // Handle direct data response
      if (fromJson != null && data != null) {
        return ApiResponse<T>.success(
          fromJson(data),
          statusCode: response.statusCode,
        );
      }

      return ApiResponse<T>.success(
        data as T,
        statusCode: response.statusCode,
      );
    }

    throw NetworkException(
      type: NetworkExceptionType.serverError,
      message: 'Server returned status code: ${response.statusCode}',
      statusCode: response.statusCode,
    );
  }

  // Handle Dio errors
  NetworkException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException(
          type: NetworkExceptionType.timeout,
          message: 'Request timeout. Please check your internet connection.',
        );

      case DioExceptionType.connectionError:
        return NetworkException(
          type: NetworkExceptionType.noInternet,
          message: 'No internet connection. Please check your network settings.',
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = _extractErrorMessage(error.response);

        switch (statusCode) {
          case 400:
            return NetworkException(
              type: NetworkExceptionType.badRequest,
              message: message,
              statusCode: statusCode,
            );
          case 401:
            return NetworkException(
              type: NetworkExceptionType.unauthorized,
              message: message,
              statusCode: statusCode,
            );
          case 403:
            return NetworkException(
              type: NetworkExceptionType.forbidden,
              message: message,
              statusCode: statusCode,
            );
          case 404:
            return NetworkException(
              type: NetworkExceptionType.notFound,
              message: message,
              statusCode: statusCode,
            );
          default:
            return NetworkException(
              type: NetworkExceptionType.serverError,
              message: message,
              statusCode: statusCode,
            );
        }

      default:
        return NetworkException(
          type: NetworkExceptionType.unknown,
          message: error.message ?? 'Unknown error occurred',
        );
    }
  }

  // Extract error message from response
  String _extractErrorMessage(Response? response) {
    if (response?.data is Map<String, dynamic>) {
      final data = response!.data as Map<String, dynamic>;
      return data['error'] ?? data['message'] ?? 'Request failed';
    }
    return 'Request failed';
  }
}
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/api_response.dart';
import '../models/user_models.dart';
import '../config/api_config.dart';
import 'api_client.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiClient _apiClient = ApiClient();
  User? _currentUser;
  String? _accessToken;

  // Initialize service
  Future<void> initialize() async {
    _apiClient.initialize();
    await _loadStoredAuthData();
  }

  // Get current user
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null && _accessToken != null;

  // Login
  Future<ApiResponse<LoginResponse>> login({
    required String userCode,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      final loginRequest = LoginRequest(userCode: userCode, password: password);

      final response = await _apiClient.post<LoginResponse>(
        ApiConfig.loginEndpoint,
        data: loginRequest.toJson(),
        fromJson: (data) => LoginResponse.fromJson(data),
      );

      if (response.success && response.data != null) {
        final loginResponse = response.data!;
        _currentUser = loginResponse.user;
        _accessToken = loginResponse.accessToken;

        await _storeAuthData(
          loginResponse.accessToken,
          loginResponse.refreshToken,
          loginResponse.expiresAt,
          loginResponse.user,
          rememberMe,
        );

        // Update API client with token
        _apiClient.setAuthToken(_accessToken!);

        debugPrint('Login successful for user: ${_currentUser?.fullName}');
      }

      return response;
    } catch (e) {
      debugPrint('Login failed: $e');
      return ApiResponse.error(e.toString());
    }
  }

  // Logout
  Future<ApiResponse<String>> logout() async {
    try {
      // Call logout API first
      final response = await _apiClient.post<String>(
        ApiConfig.logoutEndpoint,
      );

      // Clear local data regardless of API response
      _currentUser = null;
      _accessToken = null;
      _apiClient.clearAuth();
      await _clearStoredAuthData();

      if (response.success) {
        debugPrint('Logout successful');
      } else {
        debugPrint('Logout API failed but local data cleared');
      }

      return response.success
          ? ApiResponse.success('Logout successful', message: 'Logout successful')
          : ApiResponse.error('Logout completed locally');
    } catch (e) {
      debugPrint('Logout error: $e');
      // Still clear local data on error
      _currentUser = null;
      _accessToken = null;
      _apiClient.clearAuth();
      await _clearStoredAuthData();
      return ApiResponse.error('Logout completed with errors: $e');
    }
  }

  // Get current user profile
  Future<ApiResponse<User>> getCurrentUser() async {
    try {
      final response = await _apiClient.get<User>(
        ApiConfig.meEndpoint,
        fromJson: (data) => User.fromJson(data),
      );

      if (response.success && response.data != null) {
        _currentUser = response.data!;
        await _storeUserData(_currentUser!);
      }

      return response;
    } catch (e) {
      debugPrint('Get current user failed: $e');
      return ApiResponse.error(e.toString());
    }
  }

  // Change password
  Future<ApiResponse<String>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final request = ChangePasswordRequest(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      final response = await _apiClient.post<String>(
        ApiConfig.changePasswordEndpoint,
        data: request.toJson(),
      );

      if (response.success) {
        debugPrint('Password changed successfully');
      }

      return response;
    } catch (e) {
      debugPrint('Change password failed: $e');
      return ApiResponse.error(e.toString());
    }
  }

  // Get demo accounts
  Future<ApiResponse<List<DemoAccount>>> getDemoAccounts() async {
    try {
      final response = await _apiClient.get<List<DemoAccount>>(
        ApiConfig.demoAccountsEndpoint,
        fromJson: (data) {
          if (data is List) {
            return data.map((item) => DemoAccount.fromJson(item)).toList();
          }
          return <DemoAccount>[];
        },
      );

      return response;
    } catch (e) {
      debugPrint('Get demo accounts failed: $e');
      return ApiResponse.error(e.toString());
    }
  }

  // Refresh token
  Future<bool> refreshAuthToken() async {
    try {
      final refreshToken = await _getStoredRefreshToken();
      if (refreshToken == null) {
        return false;
      }

      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConfig.refreshTokenEndpoint,
        data: {'refresh_token': refreshToken},
      );

      if (response.success && response.data != null) {
        final data = response.data!;
        final newAccessToken = data['access_token'];
        final newRefreshToken = data['refresh_token'];
        final expiresAt = data['expires_at'];

        if (newAccessToken != null) {
          _accessToken = newAccessToken;
          await _storeTokenData(newAccessToken, newRefreshToken ?? refreshToken, expiresAt);
          _apiClient.setAuthToken(_accessToken!);
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('Token refresh failed: $e');
      return false;
    }
  }

  // Update current user
  void updateUser(User user) {
    _currentUser = user;
    _storeUserData(user);
  }

  // Private methods for storage
  Future<void> _storeAuthData(
    String accessToken,
    String refreshToken,
    DateTime expiresAt,
    User user,
    bool rememberMe,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('access_token', accessToken);
      await prefs.setString('refresh_token', refreshToken);
      await prefs.setString('expires_at', expiresAt.toIso8601String());
      await prefs.setBool('remember_me', rememberMe);

      if (rememberMe) {
        await _storeUserData(user);
      }

      debugPrint('Auth data stored successfully');
    } catch (e) {
      debugPrint('Error storing auth data: $e');
    }
  }

  Future<void> _storeUserData(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = jsonEncode(user.toJson());
      await prefs.setString('user_data', userJson);
      debugPrint('User data stored successfully');
    } catch (e) {
      debugPrint('Error storing user data: $e');
    }
  }

  Future<void> _storeTokenData(String accessToken, String refreshToken, String? expiresAt) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', accessToken);
      if (refreshToken.isNotEmpty) {
        await prefs.setString('refresh_token', refreshToken);
      }
      if (expiresAt != null) {
        await prefs.setString('expires_at', expiresAt);
      }
    } catch (e) {
      debugPrint('Error storing token data: $e');
    }
  }

  Future<void> _loadStoredAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if user wants to be remembered
      final rememberMe = prefs.getBool('remember_me') ?? false;
      if (!rememberMe) {
        debugPrint('Remember me is disabled');
        return;
      }

      // Load token
      _accessToken = prefs.getString('access_token');
      final expiresAtStr = prefs.getString('expires_at');

      if (_accessToken == null) {
        debugPrint('No access token found');
        return;
      }

      // Check if token is expired
      if (expiresAtStr != null) {
        final expiresAt = DateTime.parse(expiresAtStr);
        if (DateTime.now().isAfter(expiresAt)) {
          debugPrint('Token expired, attempting refresh');
          final refreshed = await refreshAuthToken();
          if (!refreshed) {
            await _clearStoredAuthData();
            return;
          }
        }
      }

      // Load user data
      final userJson = prefs.getString('user_data');
      if (userJson != null) {
        final userData = jsonDecode(userJson) as Map<String, dynamic>;
        _currentUser = User.fromJson(userData);
      }

      // Set API client token
      if (_accessToken != null) {
        _apiClient.setAuthToken(_accessToken!);
      }

      debugPrint('Auth data loaded successfully');
    } catch (e) {
      debugPrint('Error loading auth data: $e');
      await _clearStoredAuthData();
    }
  }

  Future<void> _clearStoredAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      await prefs.remove('expires_at');
      await prefs.remove('user_data');
      await prefs.remove('remember_me');
      debugPrint('Auth data cleared successfully');
    } catch (e) {
      debugPrint('Error clearing auth data: $e');
    }
  }

  Future<String?> _getStoredRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('refresh_token');
    } catch (e) {
      debugPrint('Error getting refresh token: $e');
      return null;
    }
  }

  // Check if user has specific role
  bool hasRole(String role) {
    return _currentUser?.role.toLowerCase() == role.toLowerCase();
  }

  // Check if user has any of the specified roles
  bool hasAnyRole(List<String> roles) {
    final userRole = _currentUser?.role.toLowerCase();
    return roles.any((role) => role.toLowerCase() == userRole);
  }
}
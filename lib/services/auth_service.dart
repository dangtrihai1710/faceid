import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _usersKey = 'registered_users';

  // Demo accounts for testing (matching backend passwords)
  static final Map<String, String> _demoAccounts = {
    'AD001': 'admin123',        // Admin
    'GV001': 'instructor123',   // Instructor A
    'GV002': 'instructor123',   // Instructor B
    'SV001': 'student123',      // Student 1
    'SV002': 'student123',      // Student 2
    '1': 'student123',          // Legacy Student 1
    '2': 'student123',          // Legacy Student 2
    '3': 'student123',          // Legacy Student 3
    '4': 'student123',          // Legacy Student 4
    '5': 'student123',          // Legacy Student 5
  };

  // Simple password encoding (temporary fix)
  static String _hashPassword(String password) {
    // Simple encoding without crypto dependency
    return 'encoded_${password.hashCode}_$password';
  }

  // Save authentication state
  static Future<void> _saveAuthState(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, user.token);
      await prefs.setString(_userKey, jsonEncode(user.toJson()));
      print('✅ Authentication state saved for user: ${user.userId}');
    } catch (e) {
      print('❌ Error saving auth state: $e');
      throw Exception('Lỗi khi lưu trạng thái đăng nhập');
    }
  }

  // Public method to save auth state (for external use)
  static Future<void> saveAuthState(User user) async {
    await _saveAuthState(user);
  }

  // Clear authentication state
  static Future<void> _clearAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
      print('✅ Authentication state cleared');
    } catch (e) {
      print('❌ Error clearing auth state: $e');
      throw Exception('Lỗi khi xóa trạng thái đăng nhập');
    }
  }

  // Get registered users from local storage
  static Future<List<Map<String, dynamic>>> _getRegisteredUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_usersKey) ?? '[]';
      final List<dynamic> usersList = jsonDecode(usersJson);
      return usersList.cast<Map<String, dynamic>>();
    } catch (e) {
      print('❌ Error getting registered users: $e');
      return [];
    }
  }

  // Save user to local storage
  static Future<void> _saveUserToStorage(Map<String, dynamic> userData) async {
    try {
      final users = await _getRegisteredUsers();
      users.add(userData);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_usersKey, jsonEncode(users));
      print('✅ User saved to local storage: ${userData['userId']}');
    } catch (e) {
      print('❌ Error saving user to storage: $e');
      throw Exception('Lỗi khi lưu thông tin người dùng');
    }
  }

  // Register new user
  Future<User> register(String userId, String email, String password, String fullName, {String role = 'student'}) async {
    try {
      print('🔄 Starting registration for: $userId');

      // Check if userId already exists
      final users = await _getRegisteredUsers();
      final existingUser = users.firstWhere(
        (user) => user['userId'] == userId,
        orElse: () => {},
      );

      if (existingUser.isNotEmpty) {
        throw Exception('Tên đăng nhập đã tồn tại');
      }

      // Check if email already exists
      final existingEmail = users.firstWhere(
        (user) => user['email'] == email,
        orElse: () => {},
      );

      if (existingEmail.isNotEmpty) {
        throw Exception('Email đã được sử dụng');
      }

      // Hash password
      final hashedPassword = _hashPassword(password);

      // Create user data
      final userData = {
        'id': 'user_${DateTime.now().millisecondsSinceEpoch}',
        'userId': userId,
        'email': email,
        'password': hashedPassword,
        'fullName': fullName,
        'role': role,
        'createdAt': DateTime.now().toIso8601String(),
      };

      // Save to local storage
      await _saveUserToStorage(userData);

      // Create User object
      final user = User(
        id: userData['id']?.toString() ?? '',
        userId: userId,
        email: email,
        fullName: fullName,
        token: 'token_${DateTime.now().millisecondsSinceEpoch}',
        role: role,
        createdAt: DateTime.now(),
      );

      // Save authentication state
      await _saveAuthState(user);

      // Also set token in ApiService for CRUD operations
      ApiService.setToken(user.token);

      print('✅ Registration successful for: $userId');
      return user;
    } catch (e) {
      print('❌ Registration error: $e');
      throw e;
    }
  }

  // Login user
  Future<User> login(String userId, String password, {String role = 'student'}) async {
    try {
      print('🔄 Starting login for: $userId');

      // Check demo accounts first
      if (_demoAccounts.containsKey(userId) && _demoAccounts[userId] == password) {
        print('✅ Demo account login successful: $userId');

        final user = User(
          id: 'demo_${userId}_id',
          userId: userId,
          email: '${userId}@demo.com',
          fullName: userId == 'AD001' || userId == 'admin' ? 'Admin Demo' : 'User Demo',
          token: 'demo_token_${DateTime.now().millisecondsSinceEpoch}',
          role: userId == 'AD001' || userId == 'admin' ? 'admin' : role,
          createdAt: DateTime.now(),
        );

        await _saveAuthState(user);

        // Also set token in ApiService for CRUD operations
        ApiService.setToken(user.token);

        return user;
      }

      // Check registered users
      final users = await _getRegisteredUsers();
      final userData = users.firstWhere(
        (user) => user['userId'] == userId,
        orElse: () => {},
      );

      if (userData.isEmpty) {
        throw Exception('Tên đăng nhập không tồn tại');
      }

      // Verify password
      final hashedPassword = _hashPassword(password);
      if (userData['password'] != hashedPassword) {
        throw Exception('Mật khẩu không đúng');
      }

      // Create User object
      final user = User(
        id: userData['id'],
        userId: userData['userId'],
        email: userData['email'],
        fullName: userData['fullName'],
        token: 'token_${DateTime.now().millisecondsSinceEpoch}',
        createdAt: userData['createdAt'] != null
            ? DateTime.tryParse(userData['createdAt'])
            : DateTime.now(),
      );

      // Save authentication state
      await _saveAuthState(user);

      // Also set token in ApiService for CRUD operations
      ApiService.setToken(user.token);

      print('✅ Login successful for: $userId');
      return user;
    } catch (e) {
      print('❌ Login error: $e');
      throw e;
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
      await _clearAuthState();

      // Clear token from ApiService
      ApiService.setToken('');

      print('✅ Logout successful');
    } catch (e) {
      print('❌ Logout error: $e');
      throw Exception('Lỗi khi đăng xuất: $e');
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          throw Exception('SharedPreferences timeout');
        },
      );

      final token = prefs.getString(_tokenKey);
      final isLoggedIn = token != null && token.isNotEmpty;

      // Set token in ApiService if logged in
      if (isLoggedIn && token != null) {
        ApiService.setToken(token);
      }

      print('Login status check: $isLoggedIn');
      return isLoggedIn;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  // Get current user
  Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);

      if (userJson == null || userJson.isEmpty) {
        return null;
      }

      final userData = jsonDecode(userJson) as Map<String, dynamic>;
      return User.fromJson(userData);
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Get demo accounts info
  static Map<String, String> getDemoAccounts() {
    return _demoAccounts;
  }

  // Create demo users for mobile testing
  static Future<void> createDemoUsers() async {
    try {
      print('🔄 Creating demo users for mobile testing...');

      await saveUserCredentials('AD001', 'admin123', 'admin');
      await saveUserCredentials('SV001', 'student123', 'student');
      await saveUserCredentials('SV002', 'student123', 'student');
      await saveUserCredentials('GV001', 'instructor123', 'instructor');
      await saveUserCredentials('GV002', 'instructor123', 'instructor');

      print('✅ Demo users created successfully');
    } catch (e) {
      print('❌ Error creating demo users: $e');
    }
  }

  // Save user credentials for admin functionality
  static Future<void> saveUserCredentials(String userId, String password, String role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_usersKey) ?? '[]';
      final users = jsonDecode(usersJson) as List;

      // Check if user already exists
      final existingUserIndex = users.indexWhere(
        (user) => user['userId'] == userId,
      );

      final userData = {
        'id': existingUserIndex >= 0 ? users[existingUserIndex]['id'] : DateTime.now().millisecondsSinceEpoch.toString(),
        'userId': userId,
        'password': _hashPassword(password),
        'role': role,
        'createdAt': existingUserIndex >= 0
            ? users[existingUserIndex]['createdAt']
            : DateTime.now().toIso8601String(),
        'email': '$userId@demo.com',
        'fullName': userId == 'admin' ? 'Admin User' : '${userId}_user',
      };

      if (existingUserIndex >= 0) {
        users[existingUserIndex] = userData;
      } else {
        users.add(userData);
      }

      await prefs.setString(_usersKey, jsonEncode(users));
      print('✅ User credentials saved for: $userId');
    } catch (e) {
      print('❌ Error saving user credentials: $e');
    }
  }
}
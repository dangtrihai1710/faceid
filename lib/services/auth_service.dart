import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _usersKey = 'registered_users';

  // Demo accounts for testing
  static final Map<String, String> _demoAccounts = {
    'admin': 'admin123',
    'user': 'user123',
    'test': 'test123',
  };

  // Hash password using SHA-256
  static String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Save authentication state
  static Future<void> _saveAuthState(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, user.token);
      await prefs.setString(_userKey, jsonEncode(user.toJson()));
      print('✅ Authentication state saved for user: ${user.username}');
    } catch (e) {
      print('❌ Error saving auth state: $e');
      throw Exception('Lỗi khi lưu trạng thái đăng nhập');
    }
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
      print('✅ User saved to local storage: ${userData['username']}');
    } catch (e) {
      print('❌ Error saving user to storage: $e');
      throw Exception('Lỗi khi lưu thông tin người dùng');
    }
  }

  // Register new user
  Future<User> register(String username, String email, String password, String fullName, {String role = 'student'}) async {
    try {
      print('🔄 Starting registration for: $username');

      // Check if username already exists
      final users = await _getRegisteredUsers();
      final existingUser = users.firstWhere(
        (user) => user['username'] == username,
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
        'username': username,
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
        username: username,
        email: email,
        fullName: fullName,
        token: 'token_${DateTime.now().millisecondsSinceEpoch}',
        role: role,
        createdAt: DateTime.now(),
      );

      // Save authentication state
      await _saveAuthState(user);

      print('✅ Registration successful for: $username');
      return user;
    } catch (e) {
      print('❌ Registration error: $e');
      throw e;
    }
  }

  // Login user
  Future<User> login(String username, String password, {String role = 'student'}) async {
    try {
      print('🔄 Starting login for: $username');

      // Check demo accounts first
      if (_demoAccounts.containsKey(username) && _demoAccounts[username] == password) {
        print('✅ Demo account login successful: $username');

        final user = User(
          id: 'demo_${username}_id',
          username: username,
          email: '${username}@demo.com',
          fullName: username == 'admin' ? 'Admin Demo' : 'User Demo',
          token: 'demo_token_${DateTime.now().millisecondsSinceEpoch}',
          role: role,
          createdAt: DateTime.now(),
        );

        await _saveAuthState(user);
        return user;
      }

      // Check registered users
      final users = await _getRegisteredUsers();
      final userData = users.firstWhere(
        (user) => user['username'] == username,
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
        username: userData['username'],
        email: userData['email'],
        fullName: userData['fullName'],
        token: 'token_${DateTime.now().millisecondsSinceEpoch}',
        createdAt: userData['createdAt'] != null
            ? DateTime.tryParse(userData['createdAt'])
            : DateTime.now(),
      );

      // Save authentication state
      await _saveAuthState(user);

      print('✅ Login successful for: $username');
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
}
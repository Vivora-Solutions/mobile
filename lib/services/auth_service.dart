import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'http://10.0.2.2:3000/api';
  static AuthService? _instance;
  late Dio _dio;
  late CookieJar _cookieJar;
  Dio get dio => _dio;
  // Singleton pattern
  factory AuthService() {
    _instance ??= AuthService._internal();
    return _instance!;
  }

  AuthService._internal() {
    _cookieJar = CookieJar();
    _dio = Dio();
    _dio.interceptors.add(CookieManager(_cookieJar));
  }

  // Login with email and password
  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    try {
      final response = await _dio.post(
        '$baseUrl/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        // Store tokens in SharedPreferences
        if (data != null && data['access_token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', data['access_token']);
          await prefs.setString('user_role', data['customRole']);
        } else {
          throw Exception('Invalid response format: access_token is null');
        }
        
        return data;
      } else {
        throw Exception(response.data['error'] ?? 'Login failed');
      }
    } catch (e) {
      if (e is DioException) {
        throw Exception('Login error: ${e.response?.data['error'] ?? e.message}');
      }
      throw Exception('Login error: $e');
    }
  }

  // Register with email, password and additional data
  Future<Map<String, dynamic>> registerUser({
    required String email,
    required String password,
    required String role,
    String? firstName,
    String? lastName,
    String? salonName,
    String? salonAddress,
    String? dateOfBirth,
    Map<String, double>? location,
    String? contactNumber,
    String? salonDescription,
    String? salonLogoLink,
  }) async {
    try {
      final body = {
        'email': email,
        'password': password,
        'role': role,
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (salonName != null) 'salon_name': salonName,
        if (salonAddress != null) 'salon_address': salonAddress,
        if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
        if (location != null) 'location': location,
        if (contactNumber != null) 'contact_number': contactNumber,
        if (salonDescription != null) 'salon_description': salonDescription,
        if (salonLogoLink != null) 'salon_logo_link': salonLogoLink,
      };

      final response = await _dio.post(
        '$baseUrl/auth/register',
        data: body,
      );

      if (response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception(response.data['error'] ?? 'Registration failed');
      }
    } catch (e) {
      if (e is DioException) {
        throw Exception('Registration error: ${e.response?.data['error'] ?? e.message}');
      }
      throw Exception('Registration error: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      final token = await getAccessToken();
      
      await _dio.post(
        '$baseUrl/auth/logout',
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );

      // Clear stored tokens and cookies
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('user_role');
      _cookieJar.deleteAll(); // Clear all cookies
    } catch (e) {
      // Still clear local tokens even if backend call fails
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('user_role');
      _cookieJar.deleteAll();
      throw Exception('Logout error: $e');
    }
  }

  // Get current user token
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // Get user role
  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role');
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null;
  }

  // Refresh access token (now uses cookies automatically)
  Future<Map<String, dynamic>> refreshAccessToken() async {
    try {
      // The refresh token cookie is automatically sent by dio
      final response = await _dio.post('$baseUrl/auth/refresh-token');

      if (response.statusCode == 200) {
        final data = response.data;
        
        // Update stored access token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', data['session']['access_token']);
        
        return data;
      } else {
        throw Exception(response.data['error'] ?? 'Token refresh failed');
      }
    } catch (e) {
      if (e is DioException) {
        throw Exception('Token refresh error: ${e.response?.data['error'] ?? e.message}');
      }
      throw Exception('Token refresh error: $e');
    }
  }

  // Get current user info
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final token = await getAccessToken();
      if (token == null) return null;

      final response = await _dio.get(
        '$baseUrl/auth/user',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else if (response.statusCode == 401) {
        // Token might be expired, try to refresh
        try {
          await refreshAccessToken();
          return getCurrentUser(); // Retry with new token
        } catch (e) {
          await signOut(); // Clear invalid tokens
          return null;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
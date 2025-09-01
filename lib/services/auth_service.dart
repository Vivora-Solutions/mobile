import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salonDora/config/api_constants.dart';
import 'package:salonDora/services/google_auth_service.dart'; // Add this import

class AuthService {
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
        '${ApiConstants.baseUrl}/auth/login',
        data: {'email': email, 'password': password},
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
        throw Exception(
          'Login error: ${e.response?.data['error'] ?? e.message}',
        );
      }
      throw Exception('Login error: $e');
    }
  }

  // Register with email, password and additional data
  Future<Map<String, dynamic>> registerUser({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? dateOfBirth,
    Map<String, double>? location,
    String? contactNumber,
  }) async {
    try {
      final body = {
        'email': email,
        'password': password,
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
        if (location != null)
          'location': {
            'latitude': location['latitude'],
            'longitude': location['longitude'],
          },
        if (contactNumber != null) 'contact_number': contactNumber,
      };

      final response = await _dio.post(
        '${ApiConstants.baseUrl}/auth/register-customer',
        data: body,
      );

      print("Response code = ${response.statusCode}");
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(response.data['error'] ?? 'Registration failed');
      }
    } catch (e) {
      if (e is DioException) {
        throw Exception(
          'Registration error: ${e.response?.data['error'] ?? e.message}',
        );
      }
      throw Exception('Registration error: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Get the token BEFORE clearing local storage
      final token = await getAccessToken();

      // Clear local storage first (this always succeeds)
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      await prefs.remove('user_role');

      // Clear cookies
      try {
        _cookieJar.deleteAll();
      } catch (e) {
        print('Failed to clear cookies: $e');
      }

      // Sign out from Google
      try {
        await GoogleAuthService().signOut();
      } catch (e) {
        print('Google sign out failed (ignored): $e');
      }

      // Optional: Call backend logout (don't wait for it if it fails)
      try {
        if (token != null) {
          await _dio
              .post(
                '${ApiConstants.baseUrl}/auth/logout',
                options: Options(
                  headers: {'Authorization': 'Bearer $token'},
                  sendTimeout: Duration(seconds: 5),
                  receiveTimeout: Duration(seconds: 5),
                ),
              )
              .timeout(Duration(seconds: 5));
        }
      } catch (e) {
        // Ignore backend logout errors - local logout is more important
        print('Backend logout failed (ignored): $e');
      }
    } catch (e) {
      // Even if something fails, we've cleared what we can
      print('Logout error: $e');
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
    try {
      final token = await getAccessToken();
      if (token == null) return false;

      final response = await _dio.get(
        '${ApiConstants.baseUrl}/auth/me',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          sendTimeout: Duration(seconds: 10),
          receiveTimeout: Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200) {
        // User is authenticated and token is valid
        return true;
      } else if (response.statusCode == 401) {
        // Token is invalid or expired, try to refresh
        try {
          await refreshAccessToken();
          // If refresh succeeds, user is still logged in
          return true;
        } catch (e) {
          // Refresh failed, clear invalid tokens and return false
          await signOut();
          return false;
        }
      } else {
        // Other error codes mean user is not authenticated
        return false;
      }
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          // Unauthorized - try to refresh token
          try {
            await refreshAccessToken();
            return true;
          } catch (refreshError) {
            // Refresh failed, clear tokens
            await signOut();
            return false;
          }
        } else if (e.response?.statusCode == 404) {
          // User not found - clear tokens
          await signOut();
          return false;
        }
      }

      // Network error or other issues - assume not logged in for safety
      // but don't clear tokens in case it's just a temporary network issue
      return false;
    }
  }

  // Refresh access token (now uses cookies automatically)
  Future<Map<String, dynamic>> refreshAccessToken() async {
    try {
      // The refresh token cookie is automatically sent by dio
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/auth/refresh-token',
      );

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
        throw Exception(
          'Token refresh error: ${e.response?.data['error'] ?? e.message}',
        );
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
        '${ApiConstants.baseUrl}/auth/user',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
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

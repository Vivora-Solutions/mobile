import 'package:google_sign_in/google_sign_in.dart';
import 'package:salonDora/services/auth_service.dart';
import 'package:salonDora/config/api_constants.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoogleAuthService {
  static GoogleAuthService? _instance;
  late GoogleSignIn _googleSignIn;
  late Dio _dio;

  factory GoogleAuthService() {
    _instance ??= GoogleAuthService._internal();
    return _instance!;
  }

  GoogleAuthService._internal() {
    // Initialize Google Sign-In with your web client ID
    _googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
      serverClientId: "1096507026173-npf89k1uq77u9dnasifh9nd2nib88ovq.apps.googleusercontent.com", 
    );
    _dio = Dio();
  }

  // Sign in with Google
  Future<Map<String, dynamic>> signInWithGoogle({bool fromBooking = false}) async {
    try {
      // Start Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw Exception('Google sign-in was cancelled');
      }

      // Get authentication tokens
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      if (googleAuth.accessToken == null) {
        throw Exception('Failed to get Google access token');
      }

      // Try to login first
      try {
        final loginResult = await _attemptLogin(googleAuth.accessToken!);
        return {
          'success': true,
          'isNewUser': false,
          'data': loginResult,
          'fromBooking': fromBooking,
        };
      } catch (loginError) {
        // If login fails, try registration
        if (loginError.toString().contains('not found in system')) {
          final registerResult = await _attemptRegistration(googleUser, googleAuth.accessToken!);
          
          // After successful registration, login
          final loginResult = await _attemptLogin(googleAuth.accessToken!);
          
          return {
            'success': true,
            'isNewUser': true,
            'data': loginResult,
            'fromBooking': fromBooking,
          };
        } else {
          throw loginError;
        }
      }
    } catch (e) {
      throw Exception('Google OAuth failed: $e');
    }
  }

  // Attempt login with Google access token
  Future<Map<String, dynamic>> _attemptLogin(String accessToken) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/auth/google-oauth-login',
        data: {'access_token': accessToken},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        // Store tokens using AuthService pattern
        final authService = AuthService();
        await authService._storeAuthData(data['access_token'], data['customRole']);
        
        return data;
      } else {
        throw Exception(response.data['error'] ?? 'Google login failed');
      }
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['error'] ?? e.message);
      }
      throw Exception('Google login error: $e');
    }
  }

  // Attempt registration with Google user data
  Future<Map<String, dynamic>> _attemptRegistration(
    GoogleSignInAccount googleUser, 
    String accessToken
  ) async {
    try {
      // Extract user data from Google account
      final nameParts = googleUser.displayName?.split(' ') ?? [];
      final firstName = nameParts.isNotEmpty ? nameParts.first : null;
      final lastName = nameParts.length > 1 ? nameParts.skip(1).join(' ') : null;

      final payload = {
        'uid': googleUser.id,
        'email': googleUser.email,
        'first_name': firstName,
        'last_name': lastName,
        'date_of_birth': null,
        'location': null,
        'contact_number': null,
      };

      final response = await _dio.post(
        '${ApiConstants.baseUrl}/auth/register-customer-google',
        data: payload,
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(response.data['error'] ?? 'Google registration failed');
      }
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['error'] ?? e.message);
      }
      throw Exception('Google registration error: $e');
    }
  }

  // Sign out from Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      // Ignore errors, just try to sign out
      print('Google sign out error: $e');
    }
  }

  // Check if user is signed in to Google
  Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }
}

// Extension to add private method access to AuthService
extension AuthServicePrivate on AuthService {
  Future<void> _storeAuthData(String accessToken, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('user_role', role);
  }
}
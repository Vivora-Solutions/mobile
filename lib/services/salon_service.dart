import 'package:dio/dio.dart';
import 'package:salonDora/services/auth_service.dart';
import 'dart:typed_data';
import 'package:salonDora/config/api_constants.dart';

class SalonService {
  static SalonService? _instance;
  late Dio _dio;

  // Singleton pattern
  factory SalonService() {
    _instance ??= SalonService._internal();
    return _instance!;
  }

  SalonService._internal() {
    // Use the same Dio instance from AuthService to share cookies
    _dio = AuthService().dio;
  }

  // Get all salons with automatic token refresh
  Future<List<Map<String, dynamic>>> getAllSalons() async {
    try {
      final token = await AuthService().getAccessToken();

      final response = await _dio.get(
        '${ApiConstants.baseUrl}/salons',
        options: Options(
          headers: {if (token != null) 'Authorization': 'Bearer $token'},
        ),
      );

      final List<dynamic> data = response.data;
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 401) {
        // Token expired, try to refresh
        try {
          await AuthService().refreshAccessToken();
          return getAllSalons(); // Retry with new token
        } catch (refreshError) {
          throw Exception('Authentication failed: Please login again');
        }
      }
      throw Exception('Error fetching salons: $e');
    }
  }

  // Search salons by name with automatic token refresh
  Future<List<Map<String, dynamic>>> searchSalonsByName(String name) async {
    try {
      final token = await AuthService().getAccessToken();

      final response = await _dio.get(
        '${ApiConstants.baseUrl}/salons/name/${Uri.encodeComponent(name)}',
        options: Options(
          headers: {if (token != null) 'Authorization': 'Bearer $token'},
        ),
      );

      final List<dynamic> data = response.data;
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 401) {
        // Token expired, try to refresh
        try {
          await AuthService().refreshAccessToken();
          return searchSalonsByName(name); // Retry with new token
        } catch (refreshError) {
          throw Exception('Authentication failed: Please login again');
        }
      }
      throw Exception('Error searching salons: $e');
    }
  }

  // Get salon by ID with banner images
  Future<Map<String, dynamic>> getSalonById(String salonId) async {
    try {
      final token = await AuthService().getAccessToken();

      final response = await _dio.get(
        '${ApiConstants.baseUrl}/salons/by-id/$salonId',
        options: Options(
          headers: {if (token != null) 'Authorization': 'Bearer $token'},
        ),
      );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 401) {
        // Token expired, try to refresh
        try {
          await AuthService().refreshAccessToken();
          return getSalonById(salonId); // Retry with new token
        } catch (refreshError) {
          throw Exception('Authentication failed: Please login again');
        }
      }
      if (e is DioException && e.response?.statusCode == 404) {
        throw Exception('Salon not found or not approved');
      }
      throw Exception('Error fetching salon details: $e');
    }
  }

  // Get salon services by salon ID
  Future<List<Map<String, dynamic>>> getSalonServices(String salonId) async {
    try {
      final token = await AuthService().getAccessToken();

      final response = await _dio.get(
        '${ApiConstants.baseUrl}/salons/$salonId/services',
        options: Options(
          headers: {if (token != null) 'Authorization': 'Bearer $token'},
        ),
      );

      if (response.data['success'] == true) {
        final List<dynamic> services = response.data['data'];
        return services.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to fetch services');
      }
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 401) {
        // Token expired, try to refresh
        try {
          await AuthService().refreshAccessToken();
          return getSalonServices(salonId); // Retry with new token
        } catch (refreshError) {
          throw Exception('Authentication failed: Please login again');
        }
      }
      if (e is DioException && e.response?.statusCode == 400) {
        throw Exception('Invalid salon ID');
      }
      throw Exception('Error fetching salon services: $e');
    }
  }

  // Get salons by location
  Future<List<Map<String, dynamic>>> getSalonsByLocation({
    required double latitude,
    required double longitude,
    double radiusMeters = 5000,
  }) async {
    try {
      final token = await AuthService().getAccessToken();

      final response = await _dio.post(
        '${ApiConstants.baseUrl}/salons/location',
        data: {
          'location': {'latitude': latitude, 'longitude': longitude},
          'radius': radiusMeters,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );

      final List<dynamic> data = response.data;
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 401) {
        // Token expired, try to refresh
        try {
          await AuthService().refreshAccessToken();
          return getSalonsByLocation(
            latitude: latitude,
            longitude: longitude,
            radiusMeters: radiusMeters,
          );
        } catch (refreshError) {
          throw Exception('Authentication failed: Please login again');
        }
      }
      if (e is DioException && e.response?.statusCode == 400) {
        throw Exception(
          'Invalid location data: ${e.response?.data['error'] ?? 'Bad request'}',
        );
      }
      throw Exception('Error fetching salons by location: $e');
    }
  }

  // Parse location from PostgreSQL geography format
  Map<String, double>? parseLocationFromGeography(String? locationString) {
    if (locationString == null || locationString.isEmpty) return null;

    try {
      // Convert hex string to bytes
      final bytes = Uint8List.fromList(
        List.generate(
          locationString.length ~/ 2,
          (i) =>
              int.parse(locationString.substring(i * 2, i * 2 + 2), radix: 16),
        ),
      );

      final byteData = ByteData.sublistView(bytes);

      // Read float64 values from byte offset 9 and 17 (little endian)
      final lng = byteData.getFloat64(9, Endian.little);
      final lat = byteData.getFloat64(17, Endian.little);

      return {'lat': lat, 'lng': lng};
    } catch (e) {
      print('Error parsing location: $e');
      return null;
    }
  }
}

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:book_my_salon/services/auth_service.dart';

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

  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api'; // Android emulator
    } else if (Platform.isIOS) {
      return 'http://localhost:3000/api'; // iOS simulator
    } else {
      return 'http://localhost:3000/api'; // Web/Desktop
    }
  }

  // Get all salons with automatic token refresh
  Future<List<Map<String, dynamic>>> getAllSalons() async {
    try {
      final token = await AuthService().getAccessToken();

      final response = await _dio.get(
        '$baseUrl/salons',
        options: Options(
          headers: {
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
        '$baseUrl/salons/name/${Uri.encodeComponent(name)}',
        options: Options(
          headers: {
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
        '$baseUrl/salons/by-id/$salonId',
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
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
        '$baseUrl/salons/$salonId/services',
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
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

  // Get eligible stylists for selected services
  Future<List<Map<String, dynamic>>> getEligibleStylists(
    String salonId, 
    List<String> serviceIds
  ) async {
    try {
      final token = await AuthService().getAccessToken();

      final response = await _dio.post(
        '$baseUrl/bookings/eligible-stylists',
        data: {
          'salonId': salonId,
          'serviceIds': serviceIds,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.data['success'] == true) {
        final List<dynamic> stylists = response.data['data'];
        return stylists.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to fetch eligible stylists');
      }
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 401) {
        // Token expired, try to refresh
        try {
          await AuthService().refreshAccessToken();
          return getEligibleStylists(salonId, serviceIds); // Retry with new token
        } catch (refreshError) {
          throw Exception('Authentication failed: Please login again');
        }
      }
      if (e is DioException && e.response?.statusCode == 400) {
        throw Exception('Invalid salon ID or service IDs');
      }
      throw Exception('Error fetching eligible stylists: $e');
    }
  }

  // Get available time slots for selected services, stylist, salon and date
  Future<List<Map<String, dynamic>>> getAvailableTimeSlots({
    required List<String> serviceIds,
    required String stylistId,
    required String salonId,
    required String date, // Format: YYYY-MM-DD
  }) async {
    try {
      final token = await AuthService().getAccessToken();

      final response = await _dio.post(
        '$baseUrl/salons/available-time-slots',
        data: {
          'service_ids': serviceIds,
          'stylist_id': stylistId,
          'salon_id': salonId,
          'date': date,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.data['success'] == true) {
        final List<dynamic> timeSlots = response.data['data'];
        return timeSlots.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to fetch available time slots');
      }
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 401) {
        // Token expired, try to refresh
        try {
          await AuthService().refreshAccessToken();
          return getAvailableTimeSlots(
            serviceIds: serviceIds,
            stylistId: stylistId,
            salonId: salonId,
            date: date,
          ); // Retry with new token
        } catch (refreshError) {
          throw Exception('Authentication failed: Please login again');
        }
      }
      if (e is DioException && e.response?.statusCode == 400) {
        throw Exception('Invalid input parameters for time slots');
      }
      throw Exception('Error fetching available time slots: $e');
    }
  }

  Future<Map<String, dynamic>> createBooking({
    required String stylistId,
    required List<String> serviceIds,
    required String bookingStartDateTime, // ISO format: "2025-07-31T10:00:00Z"
    String? notes,
  }) async {
    try {
      final token = await AuthService().getAccessToken();

      final response = await _dio.post(
        '$baseUrl/bookings',
        data: {
          'stylist_id': stylistId,
          'service_ids': serviceIds,
          'booking_start_datetime': bookingStartDateTime,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 401) {
        // Token expired, try to refresh
        try {
          await AuthService().refreshAccessToken();
          return createBooking(
            stylistId: stylistId,
            serviceIds: serviceIds,
            bookingStartDateTime: bookingStartDateTime,
            notes: notes,
          ); // Retry with new token
        } catch (refreshError) {
          throw Exception('Authentication failed: Please login again');
        }
      }
      if (e is DioException && e.response?.statusCode == 400) {
        throw Exception('Invalid booking data: ${e.response?.data['error'] ?? 'Bad request'}');
      }
      if (e is DioException && e.response?.statusCode == 500) {
        throw Exception('Server error: ${e.response?.data['error'] ?? 'Internal server error'}');
      }
      throw Exception('Error creating booking: $e');
    }
  }

  // Get current user bookings
  Future<List<Map<String, dynamic>>> getUserBookings() async {
    try {
      final token = await AuthService().getAccessToken();

      final response = await _dio.get(
        '$baseUrl/bookings',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 401) {
        // Token expired, try to refresh
        try {
          await AuthService().refreshAccessToken();
          return getUserBookings(); // Retry with new token
        } catch (refreshError) {
          throw Exception('Authentication failed: Please login again');
        }
      }
      if (e is DioException && e.response?.statusCode == 400) {
        throw Exception('Bad request: ${e.response?.data['error'] ?? 'Invalid request'}');
      }
      if (e is DioException && e.response?.statusCode == 500) {
        throw Exception('Server error: ${e.response?.data['error'] ?? 'Internal server error'}');
      }
      throw Exception('Error fetching bookings: $e');
    }
  }

  // Cancel a booking
  Future<Map<String, dynamic>> cancelBooking(String bookingId) async {
    try {
      final token = await AuthService().getAccessToken();

      final response = await _dio.put(  
        '$baseUrl/bookings/$bookingId/cancel',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 401) {
        // Token expired, try to refresh
        try {
          await AuthService().refreshAccessToken();
          return cancelBooking(bookingId); // Retry with new token
        } catch (refreshError) {
          throw Exception('Authentication failed: Please login again');
        }
      }
      if (e is DioException && e.response?.statusCode == 400) {
        throw Exception('${e.response?.data['error'] ?? 'Cannot cancel booking'}');
      }
      if (e is DioException && e.response?.statusCode == 404) {
        throw Exception('Booking not found or cannot be cancelled');
      }
      if (e is DioException && e.response?.statusCode == 500) {
        throw Exception('Server error: ${e.response?.data['error'] ?? 'Internal server error'}');
      }
      throw Exception('Error cancelling booking: $e');
    }
  }

  Future<Map<String, dynamic>> getBookingHistory({int page = 1, int limit = 10}) async {
    try {
      final token = await AuthService().getAccessToken();

      final response = await _dio.get(
        '$baseUrl/bookings/history',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 401) {
        // Token expired, try to refresh
        try {
          await AuthService().refreshAccessToken();
          return getBookingHistory(page: page, limit: limit); // Retry with new token
        } catch (refreshError) {
          throw Exception('Authentication failed: Please login again');
        }
      }
      if (e is DioException && e.response?.statusCode == 400) {
        throw Exception('Bad request: ${e.response?.data['error'] ?? 'Invalid request'}');
      }
      if (e is DioException && e.response?.statusCode == 500) {
        throw Exception('Server error: ${e.response?.data['error'] ?? 'Internal server error'}');
      }
      throw Exception('Error fetching booking history: $e');
    }
  }
}
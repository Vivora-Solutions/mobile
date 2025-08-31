import 'package:dio/dio.dart';
import 'package:salonDora/services/auth_service.dart';
import 'package:salonDora/config/api_constants.dart';

class BookingService {
  static BookingService? _instance;
  late Dio _dio;

  // Singleton pattern
  factory BookingService() {
    _instance ??= BookingService._internal();
    return _instance!;
  }

  BookingService._internal() {
    // Use the same Dio instance from AuthService to share cookies
    _dio = AuthService().dio;
  }

  // Get eligible stylists for selected services
  Future<List<Map<String, dynamic>>> getEligibleStylists(
    String salonId,
    List<String> serviceIds,
  ) async {
    try {
      final token = await AuthService().getAccessToken();

      final response = await _dio.post(
        '${ApiConstants.baseUrl}/bookings/eligible-stylists',
        data: {'salonId': salonId, 'serviceIds': serviceIds},
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
          return getEligibleStylists(
            salonId,
            serviceIds,
          ); // Retry with new token
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
        '${ApiConstants.baseUrl}/salons/available-time-slots-sithum',
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

  // Create a new booking
  Future<Map<String, dynamic>> createBooking({
    required String stylistId,
    required List<String> serviceIds,
    required String bookingStartDateTime, // ISO format: "2025-07-31T10:00:00Z"
    String? notes,
  }) async {
    try {
      final token = await AuthService().getAccessToken();

      final response = await _dio.post(
        '${ApiConstants.baseUrl}/bookings',
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
        throw Exception(
          'Invalid booking data: ${e.response?.data['error'] ?? 'Bad request'}',
        );
      }
      if (e is DioException && e.response?.statusCode == 500) {
        throw Exception(
          'Server error: ${e.response?.data['error'] ?? 'Internal server error'}',
        );
      }
      throw Exception('Error creating booking: $e');
    }
  }

  // Get current user bookings
  Future<List<Map<String, dynamic>>> getUserBookings() async {
    try {
      final token = await AuthService().getAccessToken();

      final response = await _dio.get(
        '${ApiConstants.baseUrl}/bookings',
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
        throw Exception(
          'Bad request: ${e.response?.data['error'] ?? 'Invalid request'}',
        );
      }
      if (e is DioException && e.response?.statusCode == 500) {
        throw Exception(
          'Server error: ${e.response?.data['error'] ?? 'Internal server error'}',
        );
      }
      throw Exception('Error fetching bookings: $e');
    }
  }

  // Cancel a booking
  Future<Map<String, dynamic>> cancelBooking(String bookingId) async {
    try {
      final token = await AuthService().getAccessToken();

      final response = await _dio.put(
        '${ApiConstants.baseUrl}/bookings/$bookingId',
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
        throw Exception(
          '${e.response?.data['error'] ?? 'Cannot cancel booking'}',
        );
      }
      if (e is DioException && e.response?.statusCode == 404) {
        throw Exception('Booking not found or cannot be cancelled');
      }
      if (e is DioException && e.response?.statusCode == 500) {
        throw Exception(
          'Server error: ${e.response?.data['error'] ?? 'Internal server error'}',
        );
      }
      throw Exception('Error cancelling booking: $e');
    }
  }

  // Get booking history with pagination
  Future<Map<String, dynamic>> getBookingHistory({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final token = await AuthService().getAccessToken();

      final response = await _dio.get(
        '${ApiConstants.baseUrl}/bookings/history',
        queryParameters: {'page': page, 'limit': limit},
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
          return getBookingHistory(
            page: page,
            limit: limit,
          ); // Retry with new token
        } catch (refreshError) {
          throw Exception('Authentication failed: Please login again');
        }
      }
      if (e is DioException && e.response?.statusCode == 400) {
        throw Exception(
          'Bad request: ${e.response?.data['error'] ?? 'Invalid request'}',
        );
      }
      if (e is DioException && e.response?.statusCode == 500) {
        throw Exception(
          'Server error: ${e.response?.data['error'] ?? 'Internal server error'}',
        );
      }
      throw Exception('Error fetching booking history: $e');
    }
  }

  // Update phone number
  Future<Map<String, dynamic>> updatePhone(String phoneNumber) async {
    try {
      final token = await AuthService().getAccessToken();

      final response = await _dio.put(
        '${ApiConstants.baseUrl}/auth/update-phone',
        data: {'phone_number': phoneNumber},
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
          return updatePhone(phoneNumber); // Retry with new token
        } catch (refreshError) {
          throw Exception('Authentication failed: Please login again');
        }
      }
      if (e is DioException && e.response?.statusCode == 400) {
        throw Exception(
          '${e.response?.data['error'] ?? 'Invalid phone number'}',
        );
      }
      if (e is DioException && e.response?.statusCode == 500) {
        throw Exception(
          'Server error: ${e.response?.data['error'] ?? 'Internal server error'}',
        );
      }
      throw Exception('Error updating phone number: $e');
    }
  }
}

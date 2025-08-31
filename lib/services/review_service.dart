import 'package:dio/dio.dart';
import 'package:salonDora/services/auth_service.dart';
import 'package:salonDora/config/api_constants.dart';

class ReviewService {
  static ReviewService? _instance;
  late Dio _dio;

  // Singleton pattern
  factory ReviewService() {
    _instance ??= ReviewService._internal();
    return _instance!;
  }

  ReviewService._internal() {
    _dio = Dio();
  }

  // Create a review
  Future<Map<String, dynamic>> createReview({
    required String bookingId,
    required String salonId,
    required double starRating,
    String? reviewText,
  }) async {
    try {
      final token = await AuthService().getAccessToken();

      final response = await _dio.post(
        "${ApiConstants.baseUrl}/review",
        data: {
          'booking_id': bookingId,
          'salon_id': salonId,
          'star_rating': starRating,
          if (reviewText != null && reviewText.isNotEmpty)
            'review_text': reviewText,
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
          return createReview(
            bookingId: bookingId,
            salonId: salonId,
            starRating: starRating,
            reviewText: reviewText,
          );
        } catch (refreshError) {
          throw Exception('Authentication failed: Please login again');
        }
      }
      if (e is DioException && e.response?.statusCode == 400) {
        throw Exception(
          '${e.response?.data['error'] ?? 'Invalid review data'}',
        );
      }
      if (e is DioException && e.response?.statusCode == 500) {
        throw Exception(
          'Server error: ${e.response?.data['error'] ?? 'Internal server error'}',
        );
      }
      throw Exception('Error creating review: $e');
    }
  }

  // Update a review
  Future<Map<String, dynamic>> updateReview({
    required String reviewId,
    double? starRating,
    String? reviewText,
  }) async {
    try {
      final token = await AuthService().getAccessToken();

      final Map<String, dynamic> data = {};
      if (starRating != null) data['star_rating'] = starRating;
      if (reviewText != null) data['review_text'] = reviewText;

      if (data.isEmpty) {
        throw Exception('No data to update');
      }

      final response = await _dio.put(
        '${ApiConstants.baseUrl}/review/$reviewId',
        data: data,
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
          return updateReview(
            reviewId: reviewId,
            starRating: starRating,
            reviewText: reviewText,
          );
        } catch (refreshError) {
          throw Exception('Authentication failed: Please login again');
        }
      }
      if (e is DioException && e.response?.statusCode == 400) {
        throw Exception(
          '${e.response?.data['error'] ?? 'Invalid review data'}',
        );
      }
      if (e is DioException && e.response?.statusCode == 404) {
        throw Exception('Review not found or cannot be updated');
      }
      if (e is DioException && e.response?.statusCode == 500) {
        throw Exception(
          'Server error: ${e.response?.data['error'] ?? 'Internal server error'}',
        );
      }
      throw Exception('Error updating review: $e');
    }
  }
}

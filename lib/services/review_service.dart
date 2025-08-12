import 'dart:io';
import 'package:dio/dio.dart';
import 'package:book_my_salon/services/auth_service.dart';

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

  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api/review';
    } else {
      return 'http://localhost:3000/api/review';
    }
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
        baseUrl,
        data: {
          'booking_id': bookingId,
          'salon_id': salonId,
          'star_rating': starRating,
          if (reviewText != null && reviewText.isNotEmpty) 'review_text': reviewText,
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
        throw Exception('${e.response?.data['error'] ?? 'Invalid review data'}');
      }
      if (e is DioException && e.response?.statusCode == 500) {
        throw Exception('Server error: ${e.response?.data['error'] ?? 'Internal server error'}');
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
        '$baseUrl/$reviewId',
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
        throw Exception('${e.response?.data['error'] ?? 'Invalid review data'}');
      }
      if (e is DioException && e.response?.statusCode == 404) {
        throw Exception('Review not found or cannot be updated');
      }
      if (e is DioException && e.response?.statusCode == 500) {
        throw Exception('Server error: ${e.response?.data['error'] ?? 'Internal server error'}');
      }
      throw Exception('Error updating review: $e');
    }
  }
}
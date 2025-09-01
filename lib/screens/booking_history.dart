import 'package:flutter/material.dart';
import 'package:salonDora/services/auth_service.dart';
import 'package:salonDora/services/review_service.dart';
import 'package:salonDora/screens/auth/login_screen.dart';
import 'package:intl/intl.dart';
import 'package:salonDora/services/booking_service.dart';

class BookingHistory extends StatefulWidget {
  const BookingHistory({Key? key}) : super(key: key);

  @override
  _BookingHistoryState createState() => _BookingHistoryState();
}

class _BookingHistoryState extends State<BookingHistory> {
  List<Map<String, dynamic>> bookings = [];
  List<Map<String, dynamic>> filteredBookings = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  String? errorMessage;
  bool isLoggedIn = false;
  String selectedFilter = 'All';

  int currentPage = 1;
  int totalPages = 1;
  bool hasMorePages = false;
  final int itemsPerPage = 10;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadHistory();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthAndLoadHistory() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final authStatus = await AuthService().isLoggedIn();

      if (!authStatus) {
        setState(() {
          isLoggedIn = false;
          isLoading = false;
        });
        return;
      }

      setState(() {
        isLoggedIn = true;
      });

      await _loadBookingHistory(reset: true);
    } catch (e) {
      setState(() {
        isLoggedIn = false;
        isLoading = false;
      });
    }
  }

  Future<void> _loadBookingHistory({bool reset = false}) async {
    try {
      if (reset) {
        setState(() {
          isLoading = true;
          currentPage = 1;
          bookings.clear();
          filteredBookings.clear();
        });
      } else {
        setState(() {
          isLoadingMore = true;
        });
      }

      final response = await BookingService().getBookingHistory(
        page: reset ? 1 : currentPage,
        limit: itemsPerPage,
      );

      final fetchedBookings = List<Map<String, dynamic>>.from(
        response['data'] ?? [],
      );

      final processedBookings = fetchedBookings.map((booking) {
        final reviews = booking['customer_reviews'] as List<dynamic>?;

        if (reviews != null && reviews.isNotEmpty) {
          final review = reviews.first as Map<String, dynamic>;
          booking['review_id'] = review['review_id'];
          booking['user_rating'] = review['star_rating'];
          booking['user_review'] = review['review_text'];
          booking['review_created_at'] = review['created_at'];
          booking['review_updated_at'] = review['updated_at'];
        }

        booking.remove('customer_reviews');

        return booking;
      }).toList();

      final pagination = response['pagination'] as Map<String, dynamic>?;

      setState(() {
        if (reset) {
          bookings = processedBookings;
          currentPage = 1;
        } else {
          bookings.addAll(processedBookings);
        }

        if (pagination != null) {
          totalPages = pagination['totalPages'] ?? 1;
          hasMorePages = currentPage < totalPages;
        }

        isLoading = false;
        isLoadingMore = false;
      });

      _applyFilter(selectedFilter);

      if (reset) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showUnratedBookingsPopup();
        });
      }
    } catch (e) {
      if (e.toString().contains('Authentication failed') ||
          e.toString().contains('Please login again')) {
        setState(() {
          isLoggedIn = false;
          isLoading = false;
          isLoadingMore = false;
        });
      } else {
        setState(() {
          errorMessage = e.toString().replaceAll('Exception: ', '');
          isLoading = false;
          isLoadingMore = false;
        });
      }
    }
  }

  void _applyFilter(String filter) {
    setState(() {
      selectedFilter = filter;

      switch (filter) {
        case 'Completed':
          filteredBookings = bookings.where((booking) {
            final status = booking['status']?.toString().toLowerCase() ?? '';
            return status == 'completed';
          }).toList();
          break;
        case 'Cancelled':
          filteredBookings = bookings.where((booking) {
            final status = booking['status']?.toString().toLowerCase() ?? '';
            return status == 'cancelled' || status == 'no_show';
          }).toList();
          break;
        default:
          filteredBookings = List.from(bookings);
          break;
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (hasMorePages && !isLoadingMore) {
        currentPage++;
        _loadBookingHistory();
      }
    }
  }

  Future<void> _refreshHistory() async {
    await _checkAuthAndLoadHistory();
  }

  void _navigateToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen(fromBooking: false)),
    ).then((_) {
      _checkAuthAndLoadHistory();
    });
  }

  void _showUnratedBookingsPopup() {
    final unratedBookings = filteredBookings
        .where(
          (booking) =>
              booking['status']?.toString().toLowerCase() == 'completed' &&
              (booking['user_rating'] == null || booking['user_rating'] == 0),
        )
        .toList();

    if (unratedBookings.isNotEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 24),
                SizedBox(width: 8),
                Text(
                  'Rate Your Experience',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You have ${unratedBookings.length} completed booking${unratedBookings.length > 1 ? 's' : ''} waiting for your review.',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'Your feedback helps us improve our services!',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Later'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _applyFilter('Completed');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.white,
                ),
                child: Text('Rate Now'),
              ),
            ],
          );
        },
      );
    }
  }

  bool _canRateBooking(Map<String, dynamic> booking) {
    final status = booking['status']?.toString().toLowerCase();
    final userRating = booking['user_rating'];
    return status == 'completed' && (userRating == null || userRating == 0);
  }

  bool _hasReview(Map<String, dynamic> booking) {
    final userRating = booking['user_rating'];
    return userRating != null && userRating > 0;
  }

  void _showRatingDialog(Map<String, dynamic> booking, {bool isEdit = false}) {
    final salon = booking['salon'] as Map<String, dynamic>?;
    double rating = isEdit ? (booking['user_rating']?.toDouble() ?? 0.0) : 0.0;
    String reviewText = isEdit ? (booking['user_review']?.toString() ?? '') : '';
    final reviewController = TextEditingController(text: reviewText);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEdit ? 'Edit Your Review' : 'Rate Your Experience',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    salon?['salon_name'] ?? 'Salon',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDate(
                              booking['booking_start_datetime'] ?? '',
                            ),
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _formatTimeSlot(
                              booking['booking_start_datetime'] ?? '',
                              booking['booking_end_datetime'],
                            ),
                            style: TextStyle(fontSize: 14),
                          ),
                          Text(
                            'Rs ${booking['total_price'] ?? 0}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Rate your experience:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              rating = (index + 1).toDouble();
                            });
                          },
                          child: Icon(
                            Icons.star,
                            size: 40,
                            color: index < rating
                                ? Colors.amber
                                : Colors.grey[300],
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Write a review (optional):',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: reviewController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Share your experience...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: EdgeInsets.all(12),
                      ),
                      onChanged: (value) {
                        reviewText = value;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: rating > 0
                      ? () {
                          Navigator.of(context).pop();
                          if (isEdit) {
                            _updateRating(booking, rating, reviewText);
                          } else {
                            _submitRating(booking, rating, reviewText);
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isEdit ? 'Update Review' : 'Submit Rating'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitRating(
    Map<String, dynamic> booking,
    double rating,
    String reviewText,
  ) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              ),
              SizedBox(height: 16),
              Text(
                'Submitting your review...',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
      );

      final result = await ReviewService().createReview(
        bookingId: booking['booking_id'].toString(),
        salonId: booking['salon_id'].toString(),
        starRating: rating,
        reviewText: reviewText.isNotEmpty ? reviewText : null,
      );

      Navigator.of(context).pop();

      setState(() {
        final index = bookings.indexWhere(
          (b) => b['booking_id'] == booking['booking_id'],
        );
        if (index != -1) {
          bookings[index]['user_rating'] = rating;
          bookings[index]['user_review'] = reviewText;
          if (result['data'] != null && result['data']['review_id'] != null) {
            bookings[index]['review_id'] = result['data']['review_id'];
          }
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Thank you for your review!'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to submit review: ${e.toString().replaceAll('Exception: ', '')}',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _updateRating(
    Map<String, dynamic> booking,
    double rating,
    String reviewText,
  ) async {
    try {
      final reviewId = booking['review_id']?.toString();

      if (reviewId == null) {
        throw Exception('Review ID not found');
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              ),
              SizedBox(height: 16),
              Text(
                'Updating your review...',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
      );

      await ReviewService().updateReview(
        reviewId: reviewId,
        starRating: rating,
        reviewText: reviewText.isNotEmpty ? reviewText : null,
      );

      Navigator.of(context).pop();

      setState(() {
        final index = bookings.indexWhere(
          (b) => b['booking_id'] == booking['booking_id'],
        );
        if (index != -1) {
          bookings[index]['user_rating'] = rating;
          bookings[index]['user_review'] = reviewText;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Review updated successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update review: ${e.toString().replaceAll('Exception: ', '')}',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  String _formatDate(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat('d MMMM yyyy').format(dateTime);
    } catch (e) {
      return 'Invalid Date';
    }
  }

  String _formatTimeSlot(String startDateTime, String? endDateTime) {
    try {
      final startTime = DateTime.parse(startDateTime);
      final startTimeStr = DateFormat('h:mm a').format(startTime);

      if (endDateTime != null) {
        final endTime = DateTime.parse(endDateTime);
        final endTimeStr = DateFormat('h:mm a').format(endTime);
        return '$startTimeStr - $endTimeStr';
      } else {
        return startTimeStr;
      }
    } catch (e) {
      return 'Invalid Time';
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'no_show':
        return 'No Show';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'no_show':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Booking History',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (isLoggedIn)
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.black),
              onPressed: _refreshHistory,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isLoggedIn && bookings.isNotEmpty)
              Container(
                margin: EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filter by Status',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          '${filteredBookings.length} booking${filteredBookings.length != 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['All', 'Completed', 'Cancelled'].map((
                          filter,
                        ) {
                          final isSelected = selectedFilter == filter;

                          int count = 0;
                          switch (filter) {
                            case 'Completed':
                              count = bookings
                                  .where(
                                    (b) =>
                                        b['status']?.toString().toLowerCase() ==
                                        'completed',
                                  )
                                  .length;
                              break;
                            case 'Cancelled':
                              count = bookings.where((b) {
                                final status =
                                    b['status']?.toString().toLowerCase() ?? '';
                                return status == 'cancelled' ||
                                    status == 'no_show';
                              }).length;
                              break;
                            default:
                              count = bookings.length;
                              break;
                          }

                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: Text(
                                '$filter ($count)',
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                _applyFilter(filter);
                              },
                              backgroundColor: Colors.grey[200],
                              selectedColor: Colors.black,
                              checkmarkColor: Colors.white,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : !isLoggedIn
                      ? _buildLoginRequiredWidget()
                      : errorMessage != null
                          ? _buildErrorWidget()
                          : filteredBookings.isEmpty
                              ? _buildEmptyWidget()
                              : _buildHistoryList(),
            ),
            if (isLoggedIn)
              Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Back to Bookings',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginRequiredWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.login, size: 64, color: Colors.blue),
          SizedBox(height: 16),
          Text(
            'Login Required',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Please login to view your booking history',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: Icon(Icons.login),
            label: Text(
              'Login',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(
            'Error loading history',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _loadBookingHistory(reset: true),
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    String message;
    String description;

    switch (selectedFilter) {
      case 'Completed':
        message = 'No Completed Bookings';
        description = 'You don\'t have any completed bookings in your history';
        break;
      case 'Cancelled':
        message = 'No Cancelled Bookings';
        description = 'You don\'t have any cancelled bookings in your history';
        break;
      default:
        message = 'No Booking History';
        description = 'You haven\'t completed any bookings yet';
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          if (selectedFilter != 'All')
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton(
                onPressed: () => _applyFilter('All'),
                child: Text('View All Bookings'),
              ),
            ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            child: Text('Go Back', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      controller: _scrollController,
      itemCount: filteredBookings.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == filteredBookings.length) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              ),
            ),
          );
        }

        final booking = filteredBookings[index];
        final salon = booking['salon'] as Map<String, dynamic>?;
        final stylist = booking['stylist'] as Map<String, dynamic>?;
        final canRate = _canRateBooking(booking);
        final hasReview = _hasReview(booking);
        final userRating = booking['user_rating']?.toDouble() ?? 0.0;

        return Card(
          color: Colors.grey[200],
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.store, color: Colors.grey[600]),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${salon?['salon_name'] ?? 'Unknown Salon'}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                if (salon?['salon_address'] != null)
                                  Text(
                                    salon!['salon_address'],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                Text(
                                  'Stylist: ${stylist?['stylist_name'] ?? 'Not assigned'}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Rs ${booking['total_price'] ?? 0}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              booking['status'] ?? 'completed',
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getStatusText(booking['status'] ?? 'completed'),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _formatDate(booking['booking_start_datetime'] ?? ''),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTimeSlot(
                    booking['booking_start_datetime'] ?? '',
                    booking['booking_end_datetime'],
                  ),
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                ),
                if (booking['total_duration_minutes'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Duration: ${booking['total_duration_minutes']} minutes',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                if (booking['notes'] != null &&
                    booking['notes'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.note, size: 16, color: Colors.blue),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              booking['notes'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (hasReview) ...[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Rating:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Row(
                              children: [
                                Row(
                                  children: List.generate(5, (starIndex) {
                                    return Icon(
                                      Icons.star,
                                      size: 16,
                                      color: starIndex < userRating
                                          ? Colors.amber
                                          : Colors.grey[300],
                                    );
                                  }),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '${userRating.toStringAsFixed(1)}/5',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                            if (booking['user_review'] != null &&
                                booking['user_review'].toString().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '"${booking['user_review']}"',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () =>
                            _showRatingDialog(booking, isEdit: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: Icon(Icons.edit, size: 16),
                        label: Text('Edit', style: TextStyle(fontSize: 12)),
                      ),
                    ] else if (canRate) ...[
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.star_border,
                              color: Colors.amber,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Rate your experience',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showRatingDialog(booking),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: Icon(Icons.star, size: 16),
                        label: Text('Rate Now', style: TextStyle(fontSize: 12)),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.grey,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            booking['status']?.toString().toLowerCase() ==
                                    'cancelled'
                                ? 'Booking was cancelled'
                                : booking['status']?.toString().toLowerCase() ==
                                        'no_show'
                                    ? 'Marked as no-show'
                                    : 'Rating not available',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
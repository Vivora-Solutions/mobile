import 'package:flutter/material.dart';
import 'package:salonDora/screens/booking_history.dart';
import 'package:salonDora/screens/home_screen.dart';
import 'package:salonDora/screens/user_profile.dart';
import 'package:salonDora/screens/auth/login_screen.dart';
import 'package:salonDora/services/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:salonDora/services/booking_service.dart';

class CurrentBooking extends StatefulWidget {
  const CurrentBooking({Key? key}) : super(key: key);

  @override
  _CurrentBookingState createState() => _CurrentBookingState();
}

class _CurrentBookingState extends State<CurrentBooking> {
  List<Map<String, dynamic>> bookings = [];
  List<Map<String, dynamic>> filteredBookings = [];
  bool isLoading = true;
  String? errorMessage;
  bool isLoggedIn = false;
  String selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadBookings();
  }

  Future<void> _checkAuthAndLoadBookings() async {
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

      await _loadBookings();
    } catch (e) {
      setState(() {
        isLoggedIn = false;
        isLoading = false;
      });
    }
  }

  Future<void> _loadBookings() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final fetchedBookings = await BookingService().getUserBookings();

      final now = DateTime.now();
      final currentBookings = fetchedBookings.where((booking) {
        try {
          final bookingDate = DateTime.parse(booking['booking_start_datetime']);
          return bookingDate.isAfter(now.subtract(Duration(hours: 1)));
        } catch (e) {
          return false;
        }
      }).toList();

      currentBookings.sort((a, b) {
        try {
          final dateA = DateTime.parse(a['booking_start_datetime']);
          final dateB = DateTime.parse(b['booking_start_datetime']);
          return dateA.compareTo(dateB);
        } catch (e) {
          return 0;
        }
      });

      setState(() {
        bookings = currentBookings;
        filteredBookings = currentBookings;
        isLoading = false;
      });

      _applyFilter(selectedFilter);
    } catch (e) {
      if (e.toString().contains('Authentication failed') ||
          e.toString().contains('Please login again')) {
        setState(() {
          isLoggedIn = false;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = e.toString().replaceAll('Exception: ', '');
          isLoading = false;
        });
      }
    }
  }

  void _applyFilter(String filter) {
    setState(() {
      selectedFilter = filter;

      switch (filter) {
        case 'Pending':
          filteredBookings = bookings.where((booking) {
            final status = booking['status']?.toString().toLowerCase() ?? '';
            return status == 'pending';
          }).toList();
          break;
        case 'Confirmed':
          filteredBookings = bookings.where((booking) {
            final status = booking['status']?.toString().toLowerCase() ?? '';
            return status == 'confirmed';
          }).toList();
          break;
        default:
          filteredBookings = List.from(bookings);
          break;
      }
    });
  }

  Future<void> _refreshBookings() async {
    await _checkAuthAndLoadBookings();
  }

  void _navigateToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen(fromBooking: false)),
    ).then((_) {
      _checkAuthAndLoadBookings();
    });
  }

  bool _canCancelBooking(Map<String, dynamic> booking) {
    try {
      final status = booking['status']?.toString().toLowerCase() ?? '';
      final startDateTime = booking['booking_start_datetime'];

      if (!['pending', 'confirmed'].contains(status)) {
        return false;
      }

      if (startDateTime != null) {
        final startTime = DateTime.parse(startDateTime);
        final now = DateTime.now();
        final hoursUntilBooking = startTime.difference(now).inHours;
        return hoursUntilBooking >= 2;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  String _getCancellationMessage(Map<String, dynamic> booking) {
    try {
      final status = booking['status']?.toString().toLowerCase() ?? '';
      final startDateTime = booking['booking_start_datetime'];

      if (!['pending', 'confirmed'].contains(status)) {
        return 'This booking cannot be cancelled due to its current status.';
      }

      if (startDateTime != null) {
        final startTime = DateTime.parse(startDateTime);
        final now = DateTime.now();
        final hoursUntilBooking = startTime.difference(now).inHours;

        if (hoursUntilBooking < 2) {
          return 'Bookings can only be cancelled at least 2 hours before the scheduled time.';
        }
      }

      return 'Cancelling this booking will delete all data regarding your booking and this process is irreversible.';
    } catch (e) {
      return 'Unable to determine cancellation eligibility.';
    }
  }

  Future<void> _cancelBooking(String bookingId, int index) async {
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
                'Cancelling booking...',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
      );

      final result = await BookingService().cancelBooking(bookingId);

      Navigator.of(context).pop();

      final bookingToRemove = filteredBookings[index];
      setState(() {
        bookings.removeWhere((booking) => booking['booking_id'] == bookingId);
        filteredBookings.removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Booking cancelled successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      Navigator.of(context).pop();

      String errorMessage = e.toString().replaceAll('Exception: ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => _cancelBooking(bookingId, index),
          ),
        ),
      );
    }
  }

  void _showCancelConfirmation(String bookingId, int index) {
    final booking = filteredBookings[index];
    final canCancel = _canCancelBooking(booking);
    final message = _getCancellationMessage(booking);
    final salon = booking['salon'] as Map<String, dynamic>?;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            canCancel ? 'Cancel Booking' : 'Cannot Cancel Booking',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: canCancel ? Colors.black : Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
          content: Container(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                        '${salon?['salon_name'] ?? 'Salon'}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _formatDate(booking['booking_start_datetime'] ?? ''),
                        style: TextStyle(fontSize: 14),
                      ),
                      Text(
                        _formatTimeSlot(
                          booking['booking_start_datetime'] ?? '',
                          booking['booking_end_datetime'],
                        ),
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: canCancel ? Colors.black : Colors.red[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                if (canCancel && _getTimeUntilBooking(booking) != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Time until booking: ${_getTimeUntilBooking(booking)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 12.0,
                  horizontal: 24.0,
                ),
                backgroundColor: Colors.grey[200],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                canCancel ? 'KEEP BOOKING' : 'CLOSE',
                style: TextStyle(color: Colors.black),
              ),
            ),
            if (canCancel)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _cancelBooking(bookingId, index);
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 24.0,
                  ),
                  backgroundColor: Colors.red[400],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'CANCEL BOOKING',
                  style: TextStyle(color: Colors.white),
                ),
              ),
          ],
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          backgroundColor: Colors.white,
        );
      },
    );
  }

  String? _getTimeUntilBooking(Map<String, dynamic> booking) {
    try {
      final startDateTime = booking['booking_start_datetime'];
      if (startDateTime != null) {
        final startTime = DateTime.parse(startDateTime);
        final now = DateTime.now();
        final difference = startTime.difference(now);

        if (difference.inDays > 0) {
          return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''}';
        } else if (difference.inHours > 0) {
          return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''}';
        } else if (difference.inMinutes > 0) {
          return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
        }
      }
      return null;
    } catch (e) {
      return null;
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
      case 'pending':
        return 'Pending Confirmation';
      case 'confirmed':
        return 'Confirmed';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Current Bookings',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.black),
            onPressed: _refreshBookings,
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
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['All', 'Pending', 'Confirmed'].map((filter) {
                          final isSelected = selectedFilter == filter;

                          int count = 0;
                          switch (filter) {
                            case 'Pending':
                              count = bookings
                                  .where(
                                    (b) =>
                                        b['status']?.toString().toLowerCase() ==
                                        'pending',
                                  )
                                  .length;
                              break;
                            case 'Confirmed':
                              count = bookings
                                  .where(
                                    (b) =>
                                        b['status']?.toString().toLowerCase() ==
                                        'confirmed',
                                  )
                                  .length;
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
                              : _buildBookingsList(),
            ),
            if (isLoggedIn)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookingHistory(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'View Booking History',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: Colors.black),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book, color: Colors.black),
            label: 'My Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, color: Colors.black),
            label: 'Profile',
          ),
        ],
        currentIndex: 1,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey[500],
        backgroundColor: Colors.white,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
              );
              break;
            case 1:
              break;
            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => UserProfile()),
              );
              break;
          }
        },
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
            'Please login to view your ongoing bookings',
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
          SizedBox(height: 16),
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
              );
            },
            child: Text(
              'Browse Salons',
              style: TextStyle(color: Colors.grey[600]),
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
            'Error loading bookings',
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
            onPressed: _loadBookings,
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
      case 'Pending':
        message = 'No Pending Bookings';
        description = 'You don\'t have any pending bookings at the moment';
        break;
      case 'Confirmed':
        message = 'No Confirmed Bookings';
        description = 'You don\'t have any confirmed bookings at the moment';
        break;
      default:
        message = 'No Current Bookings';
        description = 'You don\'t have any upcoming bookings at the moment';
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, size: 64, color: Colors.grey),
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
                style: TextButton.styleFrom(
                  backgroundColor: Colors.blue[100], // Light blue background
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'View All Bookings',
                  style: TextStyle(color: Colors.blue[800]),
                ),
              ),
            ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            child: Text('Book Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsList() {
    return ListView.builder(
      itemCount: filteredBookings.length,
      itemBuilder: (context, index) {
        final booking = filteredBookings[index];
        final salon = booking['salon'] as Map<String, dynamic>?;
        final stylist = booking['stylist'] as Map<String, dynamic>?;
        final canCancel = _canCancelBooking(booking);

        return Card(
          color: const Color.fromARGB(255, 221, 220, 220),
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
                      crossAxisAlignment: CrossAxisAlignment.end,
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
                              booking['status'] ?? 'pending',
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getStatusText(booking['status'] ?? 'pending'),
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
                if (_getTimeUntilBooking(booking) != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: canCancel ? Colors.green[50] : Colors.orange[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'In ${_getTimeUntilBooking(booking)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: canCancel
                              ? Colors.green[700]
                              : Colors.orange[700],
                          fontWeight: FontWeight.bold,
                        ),
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
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Visibility(
                      visible: false,
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Reschedule feature coming soon!'),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Reschedule',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        _showCancelConfirmation(
                          booking['booking_id'].toString(),
                          index,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canCancel
                            ? Colors.red
                            : Colors.grey[400],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        canCancel ? 'Cancel' : 'Cannot Cancel',
                        style: TextStyle(
                          color: canCancel ? Colors.white : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ),
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
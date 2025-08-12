import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:book_my_salon/screens/home_screen.dart';
import 'package:book_my_salon/services/salon_service.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final String salonId;
  final String salonName;
  final String stylistId;
  final String stylistName;
  final List<Map<String, dynamic>> selectedServices;
  final String service; // This should be a comma-separated string for display
  final DateTime date;
  final TimeOfDay time;
  final int totalDuration; // Total duration in minutes
  final int totalPrice; // Total price in Rs
  final String selectedEmployee; // Display name
  final List<String> selectedTimeSlots; // Time slots for display

  const BookingConfirmationScreen({
    super.key,
    required this.salonId,
    required this.salonName,
    required this.stylistId,
    required this.stylistName,
    required this.selectedServices,
    required this.service,
    required this.date,
    required this.time,
    required this.totalDuration,
    required this.totalPrice,
    required this.selectedEmployee,
    required this.selectedTimeSlots,
  });

  @override
  _BookingConfirmationScreenState createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  final TextEditingController _notesController = TextEditingController();
  bool _isBooking = false;
  String? _bookingError;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _confirmBooking() async {
    try {
      setState(() {
        _isBooking = true;
        _bookingError = null;
      });

      // Extract service IDs
      final serviceIds = widget.selectedServices
          .map((service) => service['service_id'].toString())
          .toList();

      // Format the booking start datetime
      final bookingDateTime = DateTime(
        widget.date.year,
        widget.date.month,
        widget.date.day,
        widget.time.hour,
        widget.time.minute,
      );
      final bookingStartDateTime = bookingDateTime.toUtc().toIso8601String();

      // Create the booking
      final result = await SalonService().createBooking(
        stylistId: widget.stylistId,
        serviceIds: serviceIds,
        bookingStartDateTime: bookingStartDateTime,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      // Show success and navigate to home
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking confirmed successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() {
        _bookingError = e.toString().replaceAll('Exception: ', '');
        _isBooking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Parse selected services for display
    final List<String> selectedServices = widget.service.split(', ');

    // Format date and time
    final formattedDate = DateFormat('EEEE, MMMM d, y').format(widget.date);
    final startTime = '${widget.time.hour}:${widget.time.minute.toString().padLeft(2, '0')}';
    final endDateTime = DateTime(
      widget.date.year,
      widget.date.month,
      widget.date.day,
      widget.time.hour,
      widget.time.minute,
    ).add(Duration(minutes: widget.totalDuration));
    final endTime = '${endDateTime.hour}:${endDateTime.minute.toString().padLeft(2, '0')}';

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Confirm Booking'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Text(
                  'VIVORA',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Confirmation Icon
              Center(
                child: Icon(Icons.calendar_today, color: Colors.blue, size: 64),
              ),
              SizedBox(height: 16),

              // Confirmation Text
              Center(
                child: Text(
                  'Review Your Booking',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 24),

              // Salon Info Card
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.store, color: Colors.grey[600]),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.salonName,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Colombo',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      // Services Section
                      Text(
                        'Services Booked:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      ...widget.selectedServices.map(
                        (service) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  service['service_name'],
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                              Text(
                                'Rs ${service['price']}',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Booking Details Card
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Booking Details',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 16),

                      // Stylist
                      _buildDetailRow('Stylist', widget.selectedEmployee),
                      SizedBox(height: 8),

                      // Date
                      _buildDetailRow('Date', formattedDate),
                      SizedBox(height: 8),

                      // Time Slot
                      _buildDetailRow(
                        'Time',
                        '$startTime - $endTime (${widget.totalDuration} mins)',
                      ),
                      SizedBox(height: 8),

                      // Payment Method
                      _buildDetailRow('Payment Method', 'Pay at Salon'),
                      SizedBox(height: 16),

                      // Total Price
                      Divider(),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Amount',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Rs ${widget.totalPrice}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Notes Section
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Special Notes (Optional)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 12),
                      TextField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Add any special requests or notes for your booking...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Error message
              if (_bookingError != null)
                Container(
                  margin: EdgeInsets.only(top: 16),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _bookingError!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(height: 24),

              // Action Buttons
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isBooking ? null : _confirmBooking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isBooking
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('CONFIRMING BOOKING...'),
                              ],
                            )
                          : Text(
                              'CONFIRM BOOKING',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _isBooking ? null : () => Navigator.pop(context),
                      child: Text(
                        'Go Back to Edit',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey[600]),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
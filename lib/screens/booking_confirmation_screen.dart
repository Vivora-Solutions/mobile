import 'package:salonDora/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:salonDora/services/booking_service.dart';
import 'package:salonDora/services/profile_service.dart';
import 'package:salonDora/screens/current_booking.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final String salonId;
  final String salonName;
  final String stylistId;
  final String stylistName;
  final List<Map<String, dynamic>> selectedServices;
  final String service;
  final DateTime date;
  final TimeOfDay time;
  final int totalDuration;
  final int totalPrice;
  final String selectedEmployee;
  final List<String> selectedTimeSlots;

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
  _BookingConfirmationScreenState createState() =>
      _BookingConfirmationScreenState();
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

      final profile = await ProfileService().getUserProfile();
      final customerData = profile['customer'] as Map<String, dynamic>?;
      final contactNumber = customerData?['contact_number'];

      if (contactNumber == null || contactNumber.toString().trim().isEmpty) {
        final phoneNumber = await _showPhoneNumberDialog();
        if (phoneNumber == null) {
          setState(() {
            _isBooking = false;
          });
          return;
        }
        await BookingService().updatePhone(phoneNumber);
      }

      final serviceIds = widget.selectedServices
          .map((service) => service['service_id'].toString())
          .toList();

      final bookingDateTime = DateTime(
        widget.date.year,
        widget.date.month,
        widget.date.day,
        widget.time.hour,
        widget.time.minute,
      );

      final bookingStartDateTime = bookingDateTime.toIso8601String();

      final result = await BookingService().createBooking(
        stylistId: widget.stylistId,
        serviceIds: serviceIds,
        bookingStartDateTime: bookingStartDateTime,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking confirmed successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => CurrentBooking()),
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

  Future<String?> _showPhoneNumberDialog() async {
    final TextEditingController phoneController = TextEditingController();
    String? phoneError;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Phone Number Required'),
              backgroundColor: Colors.grey[200], // Ash background for dialog
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'We need your phone number to confirm your booking. This will be used for booking confirmations and updates.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      hintText: 'Enter your phone number',
                      border: OutlineInputBorder(),
                      errorText: phoneError,
                      prefixText: '+94 ',
                      labelStyle: TextStyle(color: Colors.grey[700]),
                      hintStyle: TextStyle(color: Colors.grey[500]),
                    ),
                    onChanged: (value) {
                      if (phoneError != null) {
                        setState(() {
                          phoneError = null;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(null);
                  },
                  child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final phoneNumber = phoneController.text.trim();
                    if (phoneNumber.isEmpty) {
                      setState(() {
                        phoneError = 'Phone number is required';
                      });
                      return;
                    }
                    Navigator.of(context).pop(phoneNumber);
                  },
                  child: Text('Submit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> selectedServices = widget.service.split(', ');
    final formattedDate = DateFormat('EEEE, MMMM d, y').format(widget.date);
    final startTime =
        '${widget.time.hour}:${widget.time.minute.toString().padLeft(2, '0')}';
    final endDateTime = DateTime(
      widget.date.year,
      widget.date.month,
      widget.date.day,
      widget.time.hour,
      widget.time.minute,
    ).add(Duration(minutes: widget.totalDuration));
    final endTime =
        '${endDateTime.hour}:${endDateTime.minute.toString().padLeft(2, '0')}';

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Confirm Booking'),
          backgroundColor: Colors.grey[200], // Ash background for AppBar
          foregroundColor: Colors.grey[800],
          elevation: 1,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Icon(Icons.calendar_today, color: Colors.grey[700], size: 64),
              ),
              SizedBox(height: 16),
              Center(
                child: Text(
                  'Review Your Booking',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              SizedBox(height: 24),
              Card(
                elevation: 3,
                color: Colors.grey[200], // Ash background for Card
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
                                    color: Colors.grey[800],
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Colombo',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Services Booked:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.grey[800],
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
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                              Text(
                                'Rs ${service['price']}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
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
              Card(
                elevation: 3,
                color: Colors.grey[200], // Ash background for Card
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
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 16),
                      _buildDetailRow('Stylist', widget.selectedEmployee),
                      SizedBox(height: 8),
                      _buildDetailRow('Date', formattedDate),
                      SizedBox(height: 8),
                      _buildDetailRow(
                        'Time',
                        '$startTime - $endTime (${widget.totalDuration} mins)',
                      ),
                      SizedBox(height: 8),
                      _buildDetailRow('Payment Method', 'Pay at Salon'),
                      SizedBox(height: 16),
                      Divider(color: Colors.grey[400]),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Amount',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.grey[800],
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
              Card(
                elevation: 3,
                color: Colors.grey[200], // Ash background for Card
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
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 12),
                      TextField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText:
                              'Add any special requests or notes for your booking...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: EdgeInsets.all(12),
                          hintStyle: TextStyle(color: Colors.grey[500]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_bookingError != null)
                Container(
                  margin: EdgeInsets.only(top: 16),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300], // Ash background for error
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.grey[700]),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _bookingError!,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 24),
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isBooking ? null : _confirmBooking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[700], // Ash button color
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
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
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
                      onPressed: _isBooking
                          ? null
                          : () => Navigator.pop(context),
                      child: Text(
                        'Go Back to Edit',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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
        Text(label, style: TextStyle(color: Colors.grey[600])),
        SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:book_my_salon/screens/auth/login_screen.dart';
import 'package:book_my_salon/services/auth_service.dart';
import 'package:book_my_salon/screens/booking_confirmation_screen.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:book_my_salon/services/booking_storage_service.dart';
import 'package:book_my_salon/services/booking_service.dart';

class BookingScreen extends StatefulWidget {
  final String salonId;
  final String salonName;
  final List<Map<String, dynamic>> selectedServices;
  final int totalCost;
  final int totalDuration;
  final Map<String, dynamic>? salonData;

  const BookingScreen({
    required this.salonId,
    required this.salonName,
    required this.selectedServices,
    required this.totalCost,
    required this.totalDuration,
    this.salonData,
    super.key,
  });

  @override
  _BookingScreenState createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  String? selectedStylistId;
  String selectedStylistName = 'None Selected';
  DateTime? selectedDate;
  Map<String, dynamic>? selectedTimeSlot;
  bool isConfirmed = false;
  bool isLoadingStylists = true;
  bool isLoadingTimeSlots = false;
  String? stylistError;
  String? timeSlotsError;

  List<Map<String, dynamic>> availableStylists = [];
  List<Map<String, dynamic>> availableTimeSlots = [];

  // Calendar configuration
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadStylists();
  }

  Future<void> _loadStylists() async {
    try {
      setState(() {
        isLoadingStylists = true;
        stylistError = null;
      });

      // Extract service IDs from selected services
      final serviceIds = widget.selectedServices
          .map((service) => service['service_id'].toString())
          .toList();

      final stylists = await BookingService().getEligibleStylists(
        widget.salonId,
        serviceIds,
      );

      setState(() {
        availableStylists = stylists;
        isLoadingStylists = false;
      });
    } catch (e) {
      setState(() {
        stylistError = e.toString().replaceAll('Exception: ', '');
        isLoadingStylists = false;
      });
    }
  }

  Future<void> _loadTimeSlots() async {
    // Only load time slots if both stylist and date are selected
    if (selectedStylistId == null || selectedDate == null) return;

    try {
      setState(() {
        isLoadingTimeSlots = true;
        timeSlotsError = null;
        availableTimeSlots = [];
        // Clear selected time slot when loading new slots
        selectedTimeSlot = null;
      });

      // Extract service IDs from selected services
      final serviceIds = widget.selectedServices
          .map((service) => service['service_id'].toString())
          .toList();

      // Format date as YYYY-MM-DD
      final formattedDate =
          '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}';

      final timeSlots = await BookingService().getAvailableTimeSlots(
        serviceIds: serviceIds,
        stylistId: selectedStylistId!,
        salonId: widget.salonId,
        date: formattedDate,
      );

      setState(() {
        availableTimeSlots = timeSlots;
        isLoadingTimeSlots = false;
      });
    } catch (e) {
      setState(() {
        timeSlotsError = e.toString().replaceAll('Exception: ', '');
        isLoadingTimeSlots = false;
      });
    }
  }

  String _formatTimeSlot(Map<String, dynamic> slot) {
    try {
      // Parse start and end times
      final startTime = DateTime.parse(slot['start']);
      final endTime = DateTime.parse(slot['end']);

      // Format times as HH:MM
      final startFormatted =
          '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
      final endFormatted =
          '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

      return '$startFormatted - $endFormatted';
    } catch (e) {
      // Fallback if parsing fails
      return '${slot['start']?.toString() ?? 'Start'} - ${slot['end']?.toString() ?? 'End'}';
    }
  }

  bool _canSelectDate(DateTime date) {
    // Only allow dates from today onwards
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final dateStart = DateTime(date.year, date.month, date.day);
    return dateStart.isAfter(todayStart) ||
        dateStart.isAtSameMomentAs(todayStart);
  }

  bool _canLoadTimeSlots() {
    return selectedStylistId != null && selectedDate != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book Appointment'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // VIVORA Logo
              // Center(
              //   child: Text(
              //     'VIVORA',
              //     style: TextStyle(
              //       fontSize: 32,
              //       fontWeight: FontWeight.bold,
              //       color: Colors.black,
              //       fontFamily: 'Roboto',
              //     ),
              //   ),
              // ),
              SizedBox(height: 20),

              // Salon Name
              Center(
                child: Text(
                  widget.salonName,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 20),

              // Selected Services Summary
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected Services:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    ...widget.selectedServices.map(
                      (service) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '• ${service['service_name']} (Rs ${service['price']})',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Text(
                        'Total: Rs ${widget.totalCost} • ${widget.totalDuration >= 60 ? '${widget.totalDuration ~/ 60} ${widget.totalDuration ~/ 60 == 1 ? 'hour' : 'hours'}${widget.totalDuration % 60 > 0 ? ' ${widget.totalDuration % 60} min' : ''}' : '${widget.totalDuration} min'}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Step 1: Stylist Selection
              Text(
                'Step 1: Select Stylist',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),

              if (isLoadingStylists)
                Center(child: CircularProgressIndicator())
              else if (stylistError != null)
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Column(
                    children: [
                      Text('Error loading stylists: $stylistError'),
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadStylists,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: availableStylists.length,
                    itemBuilder: (context, index) {
                      final stylist = availableStylists[index];
                      return _buildStylistButton(
                        stylist['stylist_id'],
                        stylist['stylist_name'],
                        stylist['profile_pic_link'],
                      );
                    },
                  ),
                ),

              SizedBox(height: 24),

              // Step 2: Date Selection
              Text(
                'Step 2: Select Date',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TableCalendar<dynamic>(
                  firstDay: DateTime.now(),
                  lastDay: DateTime.now().add(Duration(days: 30)),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  headerVisible: true,
                  selectedDayPredicate: (day) {
                    return selectedDate != null &&
                        isSameDay(selectedDate!, day);
                  },
                  enabledDayPredicate: _canSelectDate,
                  onDaySelected: (selectedDay, focusedDay) {
                    if (_canSelectDate(selectedDay)) {
                      setState(() {
                        selectedDate = selectedDay;
                        _focusedDay = focusedDay;
                        if (selectedTimeSlot != null) {
                          selectedTimeSlot?.clear();
                        }
                      });

                      // Load time slots if both stylist and date are selected
                      if (_canLoadTimeSlots()) {
                        _loadTimeSlots();
                      }
                    }
                  },
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    selectedDecoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Colors.grey[400],
                      shape: BoxShape.circle,
                    ),
                    disabledDecoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: true,
                    formatButtonShowsNext: false,
                    titleCentered: true,
                    formatButtonDecoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Step 3: Time Slots (only show if both stylist and date are selected)
              Text(
                'Step 3: Select Time Slot',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),

              if (!_canLoadTimeSlots())
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Text(
                    'Please select both a stylist and date to view available time slots',
                    style: TextStyle(color: Colors.blue[700]),
                  ),
                )
              else if (isLoadingTimeSlots)
                Center(child: CircularProgressIndicator())
              else if (timeSlotsError != null)
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Column(
                    children: [
                      Text('Error loading time slots'),
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadTimeSlots,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              else if (availableTimeSlots.isEmpty)
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Text(
                    'No available time slots for selected date and stylist',
                    style: TextStyle(color: Colors.orange[700]),
                  ),
                )
              else
                // Changed from GridView to Column with single column layout
                Container(
                  constraints: BoxConstraints(
                    maxHeight: 330, // Limit height to make it scrollable
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: availableTimeSlots.asMap().entries.map((entry) {
                        final index = entry.key;
                        final timeSlot = entry.value;
                        final timeDisplay = _formatTimeSlot(timeSlot);
                        final isSelected = selectedTimeSlot == timeSlot;

                        return Container(
                          margin: EdgeInsets.only(bottom: 8),
                          child: SizedBox(
                            width: double.infinity,
                            height:
                                45, // Increased height to accommodate both times
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  // Toggle selection - if same slot clicked, deselect it
                                  if (isSelected) {
                                    selectedTimeSlot = null;
                                  } else {
                                    // Select this slot (replacing any previous selection)
                                    selectedTimeSlot = timeSlot;
                                  }
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSelected
                                    ? Colors.green[100]
                                    : Colors.grey[200],
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: isSelected
                                    ? BorderSide(color: Colors.green, width: 2)
                                    : BorderSide(
                                        color: Colors.grey[300]!,
                                        width: 1,
                                      ),
                                elevation: isSelected ? 3 : 1,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 20,
                                    color: isSelected
                                        ? Colors.green[700]
                                        : Colors.grey[600],
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    timeDisplay,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? Colors.green[700]
                                          : Colors.black87,
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    SizedBox(width: 12),
                                    Icon(
                                      Icons.check_circle,
                                      size: 20,
                                      color: Colors.green[700],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

              SizedBox(height: 20),

              // Confirm Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedTimeSlot != null && !isConfirmed
                      ? () async {
                          setState(() {
                            isConfirmed = true;
                          });

                          final authService = Provider.of<AuthService>(
                            context,
                            listen: false,
                          );
                          final isLoggedIn = await authService.isLoggedIn();

                          if (isLoggedIn) {
                            // User is logged in, proceed directly to confirmation
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookingConfirmationScreen(
                                  salonId: widget.salonId,
                                  salonName: widget.salonName,
                                  stylistId: selectedStylistId!,
                                  stylistName: selectedStylistName,
                                  selectedServices: widget.selectedServices,
                                  service: widget.selectedServices
                                      .map((s) => s['service_name'])
                                      .join(', '),
                                  date: selectedDate!,
                                  time: TimeOfDay(
                                    hour: DateTime.parse(
                                      selectedTimeSlot!['start'],
                                    ).hour,
                                    minute: DateTime.parse(
                                      selectedTimeSlot!['start'],
                                    ).minute,
                                  ),
                                  selectedEmployee: selectedStylistName,
                                  // Pass single time slot as list for compatibility
                                  selectedTimeSlots: [
                                    _formatTimeSlot(selectedTimeSlot!),
                                  ],
                                  totalDuration: widget.totalDuration,
                                  totalPrice: widget.totalCost,
                                ),
                              ),
                            );
                          } else {
                            // User is not logged in, store booking data and redirect to login
                            try {
                              await BookingStorageService.storePendingBooking(
                                salonId: widget.salonId,
                                salonName: widget.salonName,
                                stylistId: selectedStylistId!,
                                stylistName: selectedStylistName,
                                selectedServices: widget.selectedServices,
                                date: selectedDate!,
                                timeSlot: selectedTimeSlot!,
                                totalDuration: widget.totalDuration,
                                totalPrice: widget.totalCost,
                              );

                              // Show message to user
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Please login to complete your booking',
                                  ),
                                  backgroundColor: Colors.blue,
                                ),
                              );

                              // Navigate to login screen
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      LoginScreen(fromBooking: true),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error storing booking data'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }

                          // Reset the confirmation state
                          setState(() {
                            isConfirmed = false;
                          });
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    selectedTimeSlot == null
                        ? 'Select Time Slot to Continue'
                        : 'Proceed to Confirmation',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 24),

              // // Note about booking confirmation
              // Text(
              //   'Note: You can change your booking details later in the app.',
              //   style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStylistButton(
    String stylistId,
    String name,
    String? profilePicLink,
  ) {
    final isSelected = selectedStylistId == stylistId;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedStylistId = stylistId;
          selectedStylistName = name;
          // Clear selected time slot when changing stylist
          selectedTimeSlot = null;
        });

        // Load time slots if both stylist and date are selected
        if (_canLoadTimeSlots()) {
          _loadTimeSlots();
        }
      },
      child: Container(
        margin: EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Colors.black : Colors.grey[300]!,
                  width: isSelected ? 3 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: profilePicLink != null && profilePicLink.isNotEmpty
                    ? Image.network(
                        profilePicLink,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: Icon(
                              Icons.person,
                              color: Colors.grey[600],
                              size: 40,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.person,
                          color: Colors.grey[600],
                          size: 40,
                        ),
                      ),
              ),
            ),
            SizedBox(height: 8),
            Container(
              width: 80,
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
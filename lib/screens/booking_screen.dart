import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salonDora/screens/auth/login_screen.dart';
import 'package:salonDora/services/auth_service.dart';
import 'package:salonDora/screens/booking_confirmation_screen.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:salonDora/services/booking_storage_service.dart';
import 'package:salonDora/services/booking_service.dart';

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
    if (selectedStylistId == null || selectedDate == null) return;

    try {
      setState(() {
        isLoadingTimeSlots = true;
        timeSlotsError = null;
        availableTimeSlots = [];
        selectedTimeSlot = null;
      });

      final serviceIds = widget.selectedServices
          .map((service) => service['service_id'].toString())
          .toList();

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
      final startTime = DateTime.parse(slot['start']);
      final endTime = DateTime.parse(slot['end']);

      final startFormatted =
          '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
      final endFormatted =
          '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

      return '$startFormatted - $endFormatted';
    } catch (e) {
      return '${slot['start']?.toString() ?? 'Start'} - ${slot['end']?.toString() ?? 'End'}';
    }
  }

  bool _canSelectDate(DateTime date) {
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey[100]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Salon Name
                Center(
                  child: Text(
                    widget.salonName,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Selected Services Summary
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected Services:',
                        style: GoogleFonts.playfairDisplay(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      ...widget.selectedServices.map(
                        (service) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '• ${service['service_name']} (Rs ${service['price']})',
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.green[100]!, Colors.green[50]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Text(
                          'Total: Rs ${widget.totalCost} • ${widget.totalDuration >= 60 ? '${widget.totalDuration ~/ 60} ${widget.totalDuration ~/ 60 == 1 ? 'hour' : 'hours'}${widget.totalDuration % 60 > 0 ? ' ${widget.totalDuration % 60} min' : ''}' : '${widget.totalDuration} min'}',
                          style: GoogleFonts.roboto(
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
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 12),

                if (isLoadingStylists)
                  Center(child: CircularProgressIndicator(color: Colors.black))
                else if (stylistError != null)
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Error loading stylists: $stylistError',
                          style: GoogleFonts.roboto(
                            color: Colors.red[700],
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _loadStylists,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                            elevation: 3,
                          ),
                          child: Text(
                            'Retry',
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    height: 140,
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
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 12),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
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
                        gradient: LinearGradient(
                          colors: [Colors.black, Colors.grey[700]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
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
                      defaultTextStyle: GoogleFonts.roboto(fontSize: 16),
                      selectedTextStyle: GoogleFonts.roboto(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: true,
                      formatButtonShowsNext: false,
                      titleCentered: true,
                      titleTextStyle: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      formatButtonDecoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      formatButtonTextStyle: GoogleFonts.roboto(fontSize: 14),
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // Step 3: Time Slots
                Text(
                  'Step 3: Select Time Slot',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 12),

                if (!_canLoadTimeSlots())
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      'Please select both a stylist and date to view available time slots',
                      style: GoogleFonts.roboto(
                        color: Colors.blue[700],
                        fontSize: 16,
                      ),
                    ),
                  )
                else if (isLoadingTimeSlots)
                  Center(child: CircularProgressIndicator(color: Colors.black))
                else if (timeSlotsError != null)
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Error loading time slots',
                          style: GoogleFonts.roboto(
                            color: Colors.red[700],
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _loadTimeSlots,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                            elevation: 3,
                          ),
                          child: Text(
                            'Retry',
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      'No available time slots for selected date and stylist',
                      style: GoogleFonts.roboto(
                        color: Colors.orange[700],
                        fontSize: 16,
                      ),
                    ),
                  )
                else
                  Container(
                    constraints: BoxConstraints(maxHeight: 330),
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
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    if (isSelected) {
                                      selectedTimeSlot = null;
                                    } else {
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
                                      ? BorderSide(color: Colors.green[700]!, width: 2)
                                      : BorderSide(color: Colors.grey[300]!, width: 1),
                                  elevation: isSelected ? 5 : 2,
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 22,
                                      color: isSelected ? Colors.green[700] : Colors.grey[600],
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      timeDisplay,
                                      style: GoogleFonts.roboto(
                                        fontSize: 16,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        color: isSelected ? Colors.green[700] : Colors.black87,
                                      ),
                                    ),
                                    if (isSelected) ...[
                                      SizedBox(width: 12),
                                      Icon(
                                        Icons.check_circle,
                                        size: 22,
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

                SizedBox(height: 24),

                // Confirm Button
                Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        spreadRadius: 3,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SizedBox(
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
                                      selectedTimeSlots: [
                                        _formatTimeSlot(selectedTimeSlot!),
                                      ],
                                      totalDuration: widget.totalDuration,
                                      totalPrice: widget.totalCost,
                                    ),
                                  ),
                                );
                              } else {
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

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Please login to complete your booking',
                                        style: GoogleFonts.roboto(fontSize: 16),
                                      ),
                                      backgroundColor: Colors.blue,
                                    ),
                                  );

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
                                      content: Text(
                                        'Error storing booking data',
                                        style: GoogleFonts.roboto(fontSize: 16),
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }

                              setState(() {
                                isConfirmed = false;
                              });
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0, // Shadow handled by Container
                      ),
                      child: Text(
                        selectedTimeSlot == null
                            ? 'Select Time Slot to Continue'
                            : 'Proceed to Confirmation',
                        style: GoogleFonts.roboto(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 24),
              ],
            ),
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
          selectedTimeSlot = null;
        });

        if (_canLoadTimeSlots()) {
          _loadTimeSlots();
        }
      },
      child: Container(
        margin: EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Colors.black : Colors.grey[300]!,
                  width: isSelected ? 3 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
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
                              size: 50,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.person,
                          color: Colors.grey[600],
                          size: 50,
                        ),
                      ),
              ),
            ),
            SizedBox(height: 8),
            Container(
              width: 100,
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.black : Colors.black54,
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
import 'package:flutter/material.dart';
import 'package:book_my_salon/services/auth_service.dart';
import 'package:book_my_salon/services/booking_storage_service.dart';
import 'package:book_my_salon/screens/home_screen.dart';
import 'package:book_my_salon/screens/auth/signup_screen.dart';
import 'package:book_my_salon/screens/booking_confirmation_screen.dart';
import 'package:book_my_salon/widgets/custom_button.dart';
import 'package:book_my_salon/widgets/custom_textfield.dart';
import 'package:book_my_salon/utils/colors.dart';
import 'package:book_my_salon/utils/styles.dart';

class LoginScreen extends StatefulWidget {
  final bool fromBooking; // Flag to indicate if coming from booking flow
  
  const LoginScreen({super.key, this.fromBooking = false});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final result = await AuthService().loginUser(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login successful!'),
            backgroundColor: Colors.green,
          ),
        );

        // Check if we need to redirect to booking confirmation
        if (widget.fromBooking) {
          await _handleBookingRedirect();
        } else {
          // Normal login flow - go to home screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleBookingRedirect() async {
    try {
      final bookingData = await BookingStorageService.getPendingBooking();
      
      if (bookingData != null) {
        // Clear the stored data since we're using it now
        await BookingStorageService.clearPendingBooking();
        
        // Navigate to booking confirmation screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BookingConfirmationScreen(
              salonId: bookingData['salonId'],
              salonName: bookingData['salonName'],
              stylistId: bookingData['stylistId'],
              stylistName: bookingData['stylistName'],
              selectedServices: List<Map<String, dynamic>>.from(bookingData['selectedServices']),
              service: (bookingData['selectedServices'] as List)
                  .map((s) => s['service_name'])
                  .join(', '),
              date: DateTime.parse(bookingData['date']),
              time: TimeOfDay(
                hour: DateTime.parse(bookingData['timeSlot']['start']).hour,
                minute: DateTime.parse(bookingData['timeSlot']['start']).minute,
              ),
              selectedEmployee: bookingData['stylistName'],
              selectedTimeSlots: [_formatTimeSlot(bookingData['timeSlot'])],
              totalDuration: bookingData['totalDuration'],
              totalPrice: bookingData['totalPrice'],
            ),
          ),
        );
      } else {
        // No booking data found, go to home screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      // If there's an error, just go to home screen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error retrieving booking data. Please try booking again.'),
          backgroundColor: Colors.orange,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  String _formatTimeSlot(Map<String, dynamic> slot) {
    try {
      final startTime = DateTime.parse(slot['start']);
      final hour = startTime.hour.toString().padLeft(2, '0');
      final minute = startTime.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (e) {
      return slot['start']?.toString() ?? 'Time';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 80),
                  
                  // Show booking context message if coming from booking
                  if (widget.fromBooking)
                    Container(
                      padding: EdgeInsets.all(12),
                      margin: EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Please login to complete your booking',
                              style: TextStyle(color: Colors.blue[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // App Logo/Title
                  Text(
                    'Book My Salon',
                    style: AppStyles.headingStyle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.fromBooking ? 'Login to continue booking' : 'Welcome back!',
                    style: AppStyles.subHeadingStyle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 50),

                  // Social Login Button (Optional)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Google login not implemented yet'),
                          ),
                        );
                      },
                      icon: Image.network(
                        'https://www.google.com/favicon.ico',
                        width: 24,
                        height: 24,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.login, size: 24);
                        },
                      ),
                      label: const Text('Continue with Google'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black,
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // OR Divider
                  Row(
                    children: [
                      const Expanded(child: Divider(color: Colors.white)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('OR', style: AppStyles.subHeadingStyle),
                      ),
                      const Expanded(child: Divider(color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Email Field
                  CustomTextField(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'Enter your email',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Password Field
                  CustomTextField(
                    controller: _passwordController,
                    label: 'Password',
                    hint: 'Enter your password',
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),

                  // Login Button
                  CustomButton(
                    text: widget.fromBooking ? 'Login & Continue Booking' : 'Login',
                    onPressed: _login,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 20),

                  // Sign up link
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SignupScreen(
                            fromBooking: widget.fromBooking, // Pass the flag
                          ),
                        ),
                      );
                    },
                    child: Text(
                      "Don't have an account? Sign up",
                      style: AppStyles.linkStyle,
                    ),
                  ),
                  
                  // Back to booking button (optional)
                  if (widget.fromBooking)
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Back to Booking',
                        style: AppStyles.linkStyle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
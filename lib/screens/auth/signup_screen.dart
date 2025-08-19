import 'package:flutter/material.dart';
import 'package:book_my_salon/services/auth_service.dart';
import 'package:book_my_salon/services/booking_storage_service.dart';
import 'package:book_my_salon/screens/home_screen.dart';
import 'package:book_my_salon/screens/auth/login_screen.dart';
import 'package:book_my_salon/screens/booking_confirmation_screen.dart';
import 'package:book_my_salon/widgets/custom_button.dart';
import 'package:book_my_salon/widgets/custom_textfield.dart';
import 'package:book_my_salon/utils/colors.dart';
import 'package:book_my_salon/utils/styles.dart';

class SignupScreen extends StatefulWidget {
  final bool fromBooking; // Flag to indicate if coming from booking flow
  
  const SignupScreen({super.key, this.fromBooking = false});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _selectedRole = 'customer'; // Default role for customers
  bool _isLoading = false;

  Future<void> _signup() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passwords do not match'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // Register user with proper named parameters
        await AuthService().registerUser(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          role: _selectedRole,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
        );

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Check if we need to redirect to booking confirmation
        if (widget.fromBooking) {
          await _handleBookingRedirect();
        } else {
          // Normal signup flow - go to home screen
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
        const SnackBar(
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
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
                  const SizedBox(height: 40),
                  
                  // Show booking context message if coming from booking
                  if (widget.fromBooking)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Create an account to complete your booking',
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
                    widget.fromBooking ? 'Create account to continue' : 'Create a new account',
                    style: AppStyles.subHeadingStyle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // First Name Field
                  CustomTextField(
                    controller: _firstNameController,
                    label: 'First Name',
                    hint: 'Enter your first name',
                    keyboardType: TextInputType.name,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your first name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Last Name Field
                  CustomTextField(
                    controller: _lastNameController,
                    label: 'Last Name',
                    hint: 'Enter your last name',
                    keyboardType: TextInputType.name,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your last name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

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
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Confirm Password Field
                  CustomTextField(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
                    hint: 'Confirm your password',
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),

                  // Signup Button
                  CustomButton(
                    text: widget.fromBooking ? 'Create Account & Continue Booking' : 'Sign Up',
                    onPressed: _signup,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 20),

                  // Login link
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoginScreen(
                            fromBooking: widget.fromBooking, // Pass the flag
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'Already have an account? Login',
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
}
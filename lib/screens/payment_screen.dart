import 'package:flutter/material.dart';
import 'package:book_my_salon/screens/booking_confirmation_screen.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const Text(
                'SalonDora',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 0, 0, 0),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                'This Salon requests for an advance payment to reserve the booking',
                style: TextStyle(
                  fontSize: 16,
                  color: Color.fromARGB(255, 0, 0, 0),
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 52, 52, 52),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color.fromARGB(255, 66, 66, 66)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPaymentOption(
                      context,
                      title: 'Payhere',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Payhere payment not implemented yet'),
                            backgroundColor: Color.fromARGB(255, 255, 255, 255),
                          ),
                        );
                      },
                    ),
                    Divider(color: const Color.fromARGB(255, 66, 66, 66)),
                    _buildPaymentOption(
                      context,
                      title: 'Direct Banking Transaction',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Direct Banking Transaction not implemented yet'),
                            backgroundColor: Color.fromARGB(255, 255, 255, 255),
                          ),
                        );
                      },
                    ),
                    Divider(color: const Color.fromARGB(255, 66, 66, 66)),
                    _buildPaymentOption(
                      context,
                      title: 'Credit Card Payment',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Credit Card Payment not implemented yet'),
                            backgroundColor: Color.fromARGB(255, 255, 255, 255),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookingConfirmationScreen(
                        salonId: '',
                        salonName: '',
                        stylistId: '',
                        stylistName: '',
                        selectedServices: [],
                        service: '',
                        date: DateTime(2025, 8, 15),
                        time: const TimeOfDay(hour: 10, minute: 0),
                        selectedEmployee: '',
                        selectedTimeSlots: [],
                        totalDuration: 0,
                        totalPrice: 0,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 52, 52, 52),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption(BuildContext context, {required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
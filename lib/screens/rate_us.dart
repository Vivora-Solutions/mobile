import 'package:flutter/material.dart';
import 'package:book_my_salon/screens/home_screen.dart';

class RateUs extends StatefulWidget {
  const RateUs({Key? key}) : super(key: key);

  @override
  _RateUsState createState() => _RateUsState();
}

class _RateUsState extends State<RateUs> {
  double _rating = 0.0;
  final TextEditingController _commentController = TextEditingController();

  void _submitRating() {
    // Navigate to home screen after submission
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            // VIVORA Header
            const Text(
              'VIVORA',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            // Rate your service text
            const Text(
              'Rate your service',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 30),
            // Five-star rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _rating = (index + 1).toDouble();
                    });
                  },
                  child: Icon(
                    Icons.star,
                    size: 40, // Larger stars as per image inference
                    color: index < _rating ? Colors.amber : Colors.grey[400],
                  ),
                );
              }),
            ),
            const SizedBox(height: 30),
            // Comment field
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Add your comments here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 30),
            // Submit button
            ElevatedButton(
              onPressed: _rating > 0 ? _submitRating : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 216, 216, 216),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 24,
                ),
              ),
              child: const Text(
                'SUBMIT',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}

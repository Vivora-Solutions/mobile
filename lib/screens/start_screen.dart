import 'package:flutter/material.dart';
import 'package:salonDora/screens/home_screen.dart';
import 'dart:async';

class StartScreen extends StatefulWidget {
  const StartScreen({Key? key}) : super(key: key);

  @override
  _StartScreenState createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Fade animation: fade in first half, fade out second half
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.addListener(() {
      setState(() {});
    });

    // Start the animation and navigation
    _startAnimation();
  }

  void _startAnimation() async {
    if (_isNavigating) return;
    setState(() {
      _isNavigating = true;
    });

    // Fade in for 1 second
    await _controller.animateTo(1.0, duration: const Duration(seconds: 1));

    // Hold for a brief moment
    await Future.delayed(const Duration(milliseconds: 200));

    // Fade out for 0.8 seconds
    await _controller.animateBack(
      0.0,
      duration: const Duration(milliseconds: 800),
    );

    // Navigate to home screen
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          if (_isNavigating) return;
          _controller.stop();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color.fromARGB(255, 255, 255, 255), Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Image.asset(
                'images/icon.jpg',
                height: 200,
                width: 200,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback if image doesn't load
                  return Container(
                    height: 200,
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.content_cut,
                      size: 80,
                      color: Colors.black54,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

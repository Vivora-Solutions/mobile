import 'package:flutter/material.dart';
import 'package:book_my_salon/screens/home_screen.dart';
import 'package:book_my_salon/screens/auth/login_screen.dart';
import 'package:book_my_salon/services/auth_service.dart';
import 'dart:async';

class StartScreen extends StatefulWidget {
  const StartScreen({Key? key}) : super(key: key);

  @override
  _StartScreenState createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _iconFadeAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _creatorFadeAnimation;
  bool? _isLoggedIn;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Fade-in animation for icon
    _iconFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeInOut),
      ),
    );

    // Fade-in animation for "Book My Salon"
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.7, curve: Curves.easeInOut),
      ),
    );

    // Fade-in animation for "Created by VIVORA Solutions"
    _creatorFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.addListener(() {
      setState(() {});
    });

    _controller.forward();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    if (_isNavigating) return;

    // Check authentication in background
    final authResult = await AuthService().isLoggedIn();
    _isLoggedIn = authResult;

    // Wait for animation to complete unless interrupted
    await Future.delayed(const Duration(seconds: 2));

    if (mounted && !_isNavigating) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => _isLoggedIn! ? const HomeScreen() : const LoginScreen(),
        ),
      );
    }
  }

  void _navigateToHomeScreen() {
    if (_isNavigating) return;
    setState(() {
      _isNavigating = true;
    });
    _controller.stop();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
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
        onTap: _navigateToHomeScreen,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 192, 191, 191),
                Colors.white,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              // Icon at top center
              Positioned(
                top: MediaQuery.of(context).size.height * 0.3,
                child: FadeTransition(
                  opacity: _iconFadeAnimation,
                  child: const Icon(
                    Icons.content_cut, // Scissors icon for salon theme
                    size: 80,
                    color: Colors.black,
                  ),
                ),
              ),
              // "Book My Salon" in center
              Center(
                child: FadeTransition(
                  opacity: _textFadeAnimation,
                  child: Text(
                    'Book My Salon',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: const Offset(2.0, 2.0),
                          blurRadius: 4.0,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // "Created by VIVORA Solutions" at bottom right
              Positioned(
                right: 16,
                bottom: 16,
                child: FadeTransition(
                  opacity: _creatorFadeAnimation,
                  child: Text(
                    'Created by VIVORA Solutions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
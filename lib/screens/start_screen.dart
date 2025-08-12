import 'package:flutter/material.dart';
import 'package:book_my_salon/screens/home_screen.dart';
import 'package:book_my_salon/screens/auth/login_screen.dart';
import 'package:book_my_salon/services/auth_service.dart';
import 'dart:async';
import 'dart:math' as math;

class StartScreen extends StatefulWidget {
  const StartScreen({Key? key}) : super(key: key);

  @override
  _StartScreenState createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bladeAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _textScaleAnimation;
  late Animation<Offset> _creatorSlideAnimation;
  
  bool? _isLoggedIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // Reduced to 2 seconds
    );

    // Blade animation (realistic cutting motion)
    _bladeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.7, curve: Curves.easeInOutCubic),
      ),
    );

    // Fade-in animation for text
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.9, curve: Curves.easeInOut),
      ),
    );

    // Slide animation for "Book My Salon"
    _textSlideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 1.0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.6, 0.9, curve: Curves.easeOutBack),
          ),
        );

    // Scale animation for "Book My Salon"
    _textScaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 0.9, curve: Curves.easeOut),
      ),
    );

    // Slide animation for "Created by VIVORA Solutions"
    _creatorSlideAnimation =
        Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
          ),
        );

    _controller.addListener(() {
      setState(() {});
    });

    _controller.forward();
    // _checkAuthAndNavigate();

    Timer(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    });
  }

  Future<void> _checkAuthAndNavigate() async {
    // Check authentication in background
    final authResult = await AuthService().isLoggedIn();
    _isLoggedIn = authResult;

    // Wait for animation to complete (2 seconds)
    await _controller.forward();
    
    // Navigate based on auth result
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => _isLoggedIn! ? const HomeScreen() : const LoginScreen(),
        ),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 192, 191, 191),
              Colors.white,
            ], // Ash to white gradient
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Blade animation (stylized cutting effect)
                  CustomPaint(
                    painter: BladePainter(progress: _bladeAnimation.value),
                    child: const SizedBox(width: 200, height: 200),
                  ),
                  // "Book My Salon" with fade, slide, and scale animations
                  SlideTransition(
                    position: _textSlideAnimation,
                    child: ScaleTransition(
                      scale: _textScaleAnimation,
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
                  ),
                  // "Created by VIVORA Solutions" at bottom right
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: SlideTransition(
                      position: _creatorSlideAnimation,
                      child: FadeTransition(
                        opacity: _textFadeAnimation,
                        child: Text(
                          'Created by VIVORA Solutions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Colors.black54, // Ash variant
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// Custom painter for blade-like animation
class BladePainter extends CustomPainter {
  final double progress;

  BladePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0;

    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);

    // Realistic blade motion with a slight curve
    final angle =
        math.pi * progress * 0.5; // Controlled angle for smoother motion
    final bladeLength = size.width * 0.35;
    final curveOffset = size.width * 0.1 * math.sin(progress * math.pi);

    // Left blade
    path.moveTo(
      center.dx - bladeLength * math.cos(angle),
      center.dy - bladeLength * math.sin(angle),
    );
    path.quadraticBezierTo(
      center.dx - curveOffset,
      center.dy - curveOffset,
      center.dx,
      center.dy,
    );

    // Right blade
    path.moveTo(
      center.dx + bladeLength * math.cos(angle),
      center.dy + bladeLength * math.sin(angle),
    );
    path.quadraticBezierTo(
      center.dx + curveOffset,
      center.dy + curveOffset,
      center.dx,
      center.dy,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

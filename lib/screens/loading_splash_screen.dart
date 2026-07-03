// lib/screens/loading_splash_screen.dart
import 'package:flutter/material.dart';

class LoadingSplashScreen extends StatefulWidget {
  final VoidCallback onDone;

  const LoadingSplashScreen({super.key, required this.onDone});

  @override
  State<LoadingSplashScreen> createState() => _LoadingSplashScreenState();
}

class _LoadingSplashScreenState extends State<LoadingSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fadeIn = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
    );

    _fadeController.forward().then((_) {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Image.asset(
            'assets/studio_logo.png',
            width: 260,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const SizedBox(width: 260, height: 260),
          ),
        ),
      ),
    );
  }
}

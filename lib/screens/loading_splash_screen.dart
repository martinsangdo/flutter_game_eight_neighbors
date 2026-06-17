// lib/screens/loading_splash_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../widgets/shape_painter.dart';

class LoadingSplashScreen extends StatefulWidget {
  final VoidCallback onDone;

  const LoadingSplashScreen({super.key, required this.onDone});

  @override
  State<LoadingSplashScreen> createState() => _LoadingSplashScreenState();
}

class _LoadingSplashScreenState extends State<LoadingSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _fadeController;
  late Animation<double> _fadeIn;
  late Animation<double> _fadeOut;

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fadeIn = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
    );
    _fadeOut = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
    );

    _fadeController.forward().then((_) {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_bgController, _fadeController]),
        builder: (_, __) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // Animated gradient background
              Container(
                decoration: BoxDecoration(
                  gradient: SweepGradient(
                    center: Alignment.center,
                    startAngle: _bgController.value * 2 * pi,
                    colors: const [
                      Color(0xFF6B46C1),
                      Color(0xFF3B82F6),
                      Color(0xFF6B46C1),
                      Color(0xFF3B82F6),
                      Color(0xFF6B46C1),
                    ],
                  ),
                ),
              ),
              // Fade out overlay
              Opacity(
                opacity: _fadeOut.value,
                child: Container(color: Colors.black),
              ),
              // Logo fades in
              Opacity(
                opacity: _fadeIn.value * (1 - _fadeOut.value),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildShapeRow(),
                      const SizedBox(height: 24),
                      const Text(
                        'EIGHT\nNEIGHBORS',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 0.9,
                          letterSpacing: 2,
                          shadows: [
                            Shadow(color: Colors.black, offset: Offset(3, 3)),
                            Shadow(color: Colors.black, offset: Offset(-3, -3)),
                            Shadow(color: Colors.black, offset: Offset(3, -3)),
                            Shadow(color: Colors.black, offset: Offset(-3, 3)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Fireworks Edition',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white70,
                          shadows: [
                            Shadow(color: Colors.black54, offset: Offset(1, 2), blurRadius: 4),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildShapeRow() {
    final types = [
      ShapeType.sphere,
      ShapeType.cube,
      ShapeType.octa,
      ShapeType.icosa,
      ShapeType.tetra,
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: types.map((t) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: CustomPaint(
          size: const Size(36, 36),
          painter: ShapePainter(type: t, color: shapeColor(t)),
        ),
      )).toList(),
    );
  }
}

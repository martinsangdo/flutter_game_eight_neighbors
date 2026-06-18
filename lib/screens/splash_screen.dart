// lib/screens/splash_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../widgets/shape_painter.dart';
import '../widgets/banner_ad_widget.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onStartGame;
  final VoidCallback onSettings;

  const SplashScreen({
    super.key,
    required this.onStartGame,
    required this.onSettings,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotController;
  late AnimationController _floatController;
  late Animation<double> _titleScale;
  late AnimationController _titleController;

  final _shapes = <_FloatingShape>[];
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _rotController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _titleScale = CurvedAnimation(parent: _titleController, curve: Curves.elasticOut);
    _titleController.forward();

    _generateShapes();
  }

  void _generateShapes() {
    final types = ShapeType.values;
    for (int i = 0; i < 14; i++) {
      _shapes.add(_FloatingShape(
        type: types[_rng.nextInt(types.length)],
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        size: 28 + _rng.nextDouble() * 24,
        speed: 0.6 + _rng.nextDouble() * 0.8,
        offset: _rng.nextDouble() * 2 * pi,
      ));
    }
  }

  @override
  void dispose() {
    _rotController.dispose();
    _floatController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      bottomNavigationBar: const BannerAdWidget(),
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedBuilder(
            animation: _rotController,
            builder: (_, __) {
              return Container(
                decoration: BoxDecoration(
                  gradient: SweepGradient(
                    center: Alignment.center,
                    startAngle: _rotController.value * 2 * pi,
                    colors: const [
                      Color(0xFF6B46C1),
                      Color(0xFF3B82F6),
                      Color(0xFF6B46C1),
                      Color(0xFF3B82F6),
                      Color(0xFF6B46C1),
                    ],
                  ),
                ),
              );
            },
          ),

          // Floating shapes
          AnimatedBuilder(
            animation: _floatController,
            builder: (_, __) {
              return Stack(
                children: _shapes.map((s) {
                  final floatY = sin(_floatController.value * pi * s.speed + s.offset) * 0.04;
                  return Positioned(
                    left: s.x * size.width - s.size / 2,
                    top: (s.y + floatY) * size.height - s.size / 2,
                    child: Opacity(
                      opacity: 0.55,
                      child: CustomPaint(
                        size: Size(s.size, s.size),
                        painter: ShapePainter(
                          type: s.type,
                          color: shapeColor(s.type),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),

          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _titleScale,
                  child: Column(
                    children: [
                      Text(
                        'EIGHT\nNEIGHBORS',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: _clampFont(context, 48, 72),
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 0.9,
                          letterSpacing: 2,
                          shadows: const [
                            Shadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0),
                            Shadow(color: Colors.black, offset: Offset(-3, -3), blurRadius: 0),
                            Shadow(color: Colors.black, offset: Offset(3, -3), blurRadius: 0),
                            Shadow(color: Colors.black, offset: Offset(-3, 3), blurRadius: 0),
                            Shadow(color: Colors.black, offset: Offset(0, 0), blurRadius: 12),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Fireworks Edition',
                        style: TextStyle(
                          fontSize: _clampFont(context, 16, 22),
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          shadows: const [
                            Shadow(color: Colors.black54, offset: Offset(1, 2), blurRadius: 4),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // Buttons
                SizedBox(
                  width: 260,
                  child: Column(
                    children: [
                      _MenuButton(
                        label: 'START GAME',
                        color: const Color(0xFFFBBF24),
                        shadowColor: const Color(0xFF92400E),
                        onTap: widget.onStartGame,
                      ),
                      const SizedBox(height: 16),
                      _MenuButton(
                        label: 'SETTINGS',
                        color: const Color(0xFF3B82F6),
                        shadowColor: const Color(0xFF1E3A8A),
                        onTap: widget.onSettings,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _clampFont(BuildContext ctx, double min, double max) {
    final w = MediaQuery.of(ctx).size.width;
    return (w * 0.11).clamp(min, max);
  }
}

class _FloatingShape {
  final ShapeType type;
  final double x, y, size, speed, offset;
  _FloatingShape({
    required this.type,
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.offset,
  });
}

class _MenuButton extends StatefulWidget {
  final String label;
  final Color color;
  final Color shadowColor;
  final VoidCallback onTap;

  const _MenuButton({
    required this.label,
    required this.color,
    required this.shadowColor,
    required this.onTap,
  });

  @override
  State<_MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<_MenuButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.translationValues(0, _pressed ? 4 : 0, 0),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black, width: 3),
          boxShadow: [
            BoxShadow(
              color: widget.shadowColor,
              offset: Offset(0, _pressed ? 2 : 6),
              blurRadius: 0,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        child: Center(
          child: Text(
            widget.label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
              letterSpacing: 2,
              shadows: [
                Shadow(color: Colors.black54, offset: Offset(1, 2), blurRadius: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

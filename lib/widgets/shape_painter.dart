// lib/widgets/shape_painter.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_models.dart';

/// Color for each shape type
Color shapeColor(ShapeType type) {
  switch (type) {
    case ShapeType.sphere:  return const Color(0xFFEF4444); // red
    case ShapeType.cube:    return const Color(0xFF22C55E); // green
    case ShapeType.tetra:   return const Color(0xFF3B82F6); // blue
    case ShapeType.octa:    return const Color(0xFFFBBF24); // yellow
    case ShapeType.icosa:   return const Color(0xFFD946EF); // fuchsia
    case ShapeType.dodeca:  return const Color(0xFFFFFFFF); // white
  }
}

/// Label for each shape type (for legend/accessibility)
String shapeLabel(ShapeType type) {
  switch (type) {
    case ShapeType.sphere:  return '●';
    case ShapeType.cube:    return '■';
    case ShapeType.tetra:   return '▲';
    case ShapeType.octa:    return '◆';
    case ShapeType.icosa:   return '✦';
    case ShapeType.dodeca:  return '⬡';
  }
}

class ShapePainter extends CustomPainter {
  final ShapeType type;
  final Color color;
  final bool highlighted;
  final bool isPrize;
  final bool prizeCollected;
  final double animScale;

  ShapePainter({
    required this.type,
    required this.color,
    this.highlighted = false,
    this.isPrize = false,
    this.prizeCollected = false,
    this.animScale = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = min(cx, cy) * 0.78 * animScale;

    final basePaint = Paint()
      ..color = highlighted ? color.withOpacity(0.95) : color.withOpacity(0.88)
      ..style = PaintingStyle.fill;

    final glowPaint = highlighted
        ? (Paint()
          ..color = color.withOpacity(0.5)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8))
        : null;

    final strokePaint = Paint()
      ..color = Colors.white.withOpacity(highlighted ? 0.9 : 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = highlighted ? 2.5 : 1.5;

    // Glow behind shape
    if (glowPaint != null) {
      _drawShape(canvas, cx, cy, r * 1.25, glowPaint, null);
    }

    _drawShape(canvas, cx, cy, r, basePaint, strokePaint);

    // Prize star overlay
    if (isPrize && !prizeCollected) {
      _drawPrizeStar(canvas, cx, cy, r * 0.38);
    }
  }

  void _drawShape(Canvas canvas, double cx, double cy, double r,
      Paint fill, Paint? stroke) {
    switch (type) {
      case ShapeType.sphere:
        canvas.drawCircle(Offset(cx, cy), r, fill);
        if (stroke != null) canvas.drawCircle(Offset(cx, cy), r, stroke);
        _drawHighlight(canvas, cx, cy, r, fill);
        break;
      case ShapeType.cube:
        _drawCube(canvas, cx, cy, r, fill, stroke);
        break;
      case ShapeType.tetra:
        _drawPolygon(canvas, cx, cy, r, 3, -pi / 2, fill, stroke);
        break;
      case ShapeType.octa:
        _drawPolygon(canvas, cx, cy, r, 4, -pi / 4, fill, stroke);
        break;
      case ShapeType.icosa:
        _drawPolygon(canvas, cx, cy, r, 5, -pi / 2, fill, stroke);
        break;
      case ShapeType.dodeca:
        _drawPolygon(canvas, cx, cy, r, 6, 0, fill, stroke);
        break;
    }
  }

  void _drawPolygon(Canvas canvas, double cx, double cy, double r,
      int sides, double startAngle, Paint fill, Paint? stroke) {
    final path = Path();
    for (int i = 0; i < sides; i++) {
      final angle = startAngle + 2 * pi * i / sides;
      final x = cx + r * cos(angle);
      final y = cy + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, fill);
    if (stroke != null) canvas.drawPath(path, stroke);
    _drawHighlight(canvas, cx, cy, r * 0.6, fill);
  }

  void _drawCube(Canvas canvas, double cx, double cy, double r,
      Paint fill, Paint? stroke) {
    final half = r * 0.75;
    final rect = Rect.fromCenter(center: Offset(cx, cy), width: half * 2, height: half * 2);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(r * 0.15));
    canvas.drawRRect(rrect, fill);
    if (stroke != null) canvas.drawRRect(rrect, stroke);
    _drawHighlight(canvas, cx, cy - half * 0.15, r * 0.5, fill);

    // 3D top face
    final topPaint = Paint()
      ..color = fill.color.withOpacity(0.45)
      ..style = PaintingStyle.fill;
    final topPath = Path()
      ..moveTo(cx - half, cy - half)
      ..lineTo(cx - half + r * 0.35, cy - half - r * 0.35)
      ..lineTo(cx + half + r * 0.35, cy - half - r * 0.35)
      ..lineTo(cx + half, cy - half)
      ..close();
    canvas.drawPath(topPath, topPaint);
    // right face
    final rightPath = Path()
      ..moveTo(cx + half, cy - half)
      ..lineTo(cx + half + r * 0.35, cy - half - r * 0.35)
      ..lineTo(cx + half + r * 0.35, cy + half - r * 0.35)
      ..lineTo(cx + half, cy + half)
      ..close();
    canvas.drawPath(rightPath, topPaint);
  }

  void _drawHighlight(Canvas canvas, double cx, double cy, double r, Paint fill) {
    final highlightPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.45),
        radius: 0.7,
        colors: [
          Colors.white.withOpacity(0.55),
          Colors.white.withOpacity(0.0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx - r * 0.2, cy - r * 0.3), radius: r));
    canvas.drawCircle(Offset(cx - r * 0.2, cy - r * 0.3), r * 0.55, highlightPaint);
  }

  void _drawPrizeStar(Canvas canvas, double cx, double cy, double r) {
    final paint = Paint()
      ..color = const Color(0xFFFBBF24).withOpacity(0.95)
      ..style = PaintingStyle.fill;
    final path = Path();
    const points = 5;
    for (int i = 0; i < points * 2; i++) {
      final angle = -pi / 2 + i * pi / points;
      final radius = i.isEven ? r : r * 0.4;
      final x = cx + radius * cos(angle);
      final y = cy + radius * sin(angle);
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
    final strokeP = Paint()
      ..color = const Color(0xFF92400E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(path, strokeP);
  }

  @override
  bool shouldRepaint(ShapePainter old) =>
      old.type != type ||
      old.highlighted != highlighted ||
      old.isPrize != isPrize ||
      old.prizeCollected != prizeCollected ||
      old.animScale != animScale;
}

class ShapeWidget extends StatefulWidget {
  final ShapeType type;
  final bool highlighted;
  final bool isPrize;
  final bool prizeCollected;
  final VoidCallback? onTap;
  final double size;
  final bool animateIn;

  const ShapeWidget({
    super.key,
    required this.type,
    this.highlighted = false,
    this.isPrize = false,
    this.prizeCollected = false,
    this.onTap,
    this.size = 44,
    this.animateIn = false,
  });

  @override
  State<ShapeWidget> createState() => _ShapeWidgetState();
}

class _ShapeWidgetState extends State<ShapeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    if (widget.animateIn) {
      _ctrl.forward();
    } else {
      _ctrl.value = 1.0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, __) => CustomPaint(
          size: Size(widget.size, widget.size),
          painter: ShapePainter(
            type: widget.type,
            color: shapeColor(widget.type),
            highlighted: widget.highlighted,
            isPrize: widget.isPrize,
            prizeCollected: widget.prizeCollected,
            animScale: _scale.value,
          ),
        ),
      ),
    );
  }
}

// lib/widgets/game_board.dart
import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../game/game_engine.dart';
import 'shape_painter.dart';

class GameBoard extends StatefulWidget {
  final GameEngine engine;
  final Function(int row, int col) onCellTap;
  final Set<String> highlightedCells;
  final Set<String> poppingCells;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;

  const GameBoard({
    super.key,
    required this.engine,
    required this.onCellTap,
    required this.highlightedCells,
    required this.poppingCells,
    required this.onSwipeLeft,
    required this.onSwipeRight,
  });

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  double? _swipeStartX;
  double? _swipeStartY;

  @override
  Widget build(BuildContext context) {
    final engine = widget.engine;
    if (engine.board.isEmpty) return const SizedBox();

    return GestureDetector(
      onHorizontalDragStart: (d) {
        _swipeStartX = d.localPosition.dx;
        _swipeStartY = d.localPosition.dy;
      },
      onHorizontalDragEnd: (d) {
        if (_swipeStartX == null) return;
        final dx = (d.localPosition.dx) - _swipeStartX!;
        if (dx.abs() > 60) {
          if (dx > 0) {
            widget.onSwipeRight();
          } else {
            widget.onSwipeLeft();
          }
        }
        _swipeStartX = null;
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellSize = _computeCellSize(
              constraints, engine.rows, engine.cols);
          return Center(
            child: SizedBox(
              width: cellSize * engine.cols,
              height: cellSize * engine.rows,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(engine.rows, (row) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(engine.cols, (col) {
                      return _buildCell(row, col, cellSize, engine);
                    }),
                  );
                }),
              ),
            ),
          );
        },
      ),
    );
  }

  double _computeCellSize(BoxConstraints c, int rows, int cols) {
    final maxW = c.maxWidth / cols;
    final maxH = c.maxHeight / rows;
    return min(maxW, maxH).clamp(24.0, 64.0);
  }

  double min(double a, double b) => a < b ? a : b;

  Widget _buildCell(int row, int col, double size, GameEngine engine) {
    final cell = engine.board[row][col];
    final key = '$row,$col';
    final isHighlighted = widget.highlightedCells.contains(key);
    final isPopping = widget.poppingCells.contains(key);

    if (!cell.isActive) {
      return SizedBox(width: size, height: size);
    }

    return SizedBox(
      width: size,
      height: size,
      child: Padding(
        padding: const EdgeInsets.all(1.5),
        child: cell.hasShape
            ? _AnimatedCell(
                key: ValueKey('${row}_${col}_${cell.shapeType}'),
                cell: cell,
                isHighlighted: isHighlighted,
                isPopping: isPopping,
                cellSize: size - 3,
                onTap: () => widget.onCellTap(row, col),
              )
            : Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
      ),
    );
  }
}

class _AnimatedCell extends StatefulWidget {
  final BoardCell cell;
  final bool isHighlighted;
  final bool isPopping;
  final double cellSize;
  final VoidCallback onTap;

  const _AnimatedCell({
    super.key,
    required this.cell,
    required this.isHighlighted,
    required this.isPopping,
    required this.cellSize,
    required this.onTap,
  });

  @override
  State<_AnimatedCell> createState() => _AnimatedCellState();
}

class _AnimatedCellState extends State<_AnimatedCell>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward(from: 0);
  }

  @override
  void didUpdateWidget(_AnimatedCell old) {
    super.didUpdateWidget(old);
    if (widget.isPopping && !old.isPopping) {
      _ctrl.reverse();
    }
    if (!widget.isPopping && old.isPopping) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (_, __) => Transform.scale(
        scale: _scale.value,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.cellSize * 0.15),
              boxShadow: widget.isHighlighted
                  ? [
                      BoxShadow(
                        color: shapeColor(widget.cell.shapeType!)
                            .withOpacity(0.6),
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ]
                  : [],
            ),
            child: CustomPaint(
              size: Size(widget.cellSize, widget.cellSize),
              painter: ShapePainter(
                type: widget.cell.shapeType!,
                color: shapeColor(widget.cell.shapeType!),
                highlighted: widget.isHighlighted,
                isPrize: widget.cell.isPrize,
                prizeCollected: widget.cell.prizeCollected,
                animScale: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// lib/screens/game_screen.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_models.dart';
import '../game/game_engine.dart';
import '../widgets/game_board.dart';
import '../widgets/shape_painter.dart';

class GameScreen extends StatefulWidget {
  final GameSettings settings;
  final VoidCallback onExitToMenu;
  final Function(GameSettings) onUpdateSettings;

  const GameScreen({
    super.key,
    required this.settings,
    required this.onExitToMenu,
    required this.onUpdateSettings,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  final GameEngine _engine = GameEngine();

  Set<String> _highlighted = {};
  Set<String> _popping = {};
  bool _animating = false;

  // Toast
  String? _toastText;
  Timer? _toastTimer;

  // Overlay state
  bool _showGameOver = false;
  bool _showGameWin = false;
  bool _showAbandon = false;

  ProgressionChoice? _progression;

  // Rotate animation
  late AnimationController _rotCtrl;
  late Animation<double> _rotAnim;
  bool _rotating = false;
  String _rotDir = 'right';

  // Score bump animation
  late AnimationController _scoreCtrl;
  late Animation<double> _scoreAnim;

  // Fireworks particles for win
  List<_Particle> _particles = [];
  Timer? _fireworksTimer;

  @override
  void initState() {
    super.initState();
    _rotCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _rotAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _rotCtrl, curve: Curves.easeInOut),
    );
    _rotCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        setState(() => _rotating = false);
        _animating = false;
      }
    });

    _scoreCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _scoreAnim = Tween<double>(begin: 1, end: 1.5).animate(
      CurvedAnimation(parent: _scoreCtrl, curve: Curves.elasticOut),
    );

    _startNewGame();
  }

  @override
  void dispose() {
    _rotCtrl.dispose();
    _scoreCtrl.dispose();
    _toastTimer?.cancel();
    _fireworksTimer?.cancel();
    super.dispose();
  }

  void _startNewGame() {
    final s = widget.settings;
    _engine.newBoard(
      rows: s.rows,
      cols: s.cols,
      template: s.template,
      minGroupSize: s.minGroupSize,
    );
    setState(() {
      _highlighted = {};
      _popping = {};
      _showGameOver = false;
      _showGameWin = false;
      _showAbandon = false;
      _progression = null;
    });
  }

  void _onCellTap(int row, int col) {
    if (_animating) return;
    final cell = _engine.board[row][col];
    if (!cell.hasShape) return;

    final connected = _engine.findConnectedShapes(row, col, cell.shapeType!);
    if (connected.length < _engine.minGroupSize) {
      // Flash briefly to indicate invalid
      setState(() {
        _highlighted = {for (final p in connected) '${p[0]},${p[1]}'};
      });
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted) setState(() => _highlighted = {});
      });
      return;
    }

    // Show highlight first
    setState(() {
      _highlighted = {for (final p in connected) '${p[0]},${p[1]}'};
    });

    Future.delayed(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      // Pop animation
      setState(() {
        _popping = {for (final p in connected) '${p[0]},${p[1]}'};
        _highlighted = {};
      });

      Future.delayed(const Duration(milliseconds: 320), () {
        if (!mounted) return;
        final result = _engine.tapCell(row, col);
        setState(() {
          _popping = {};
          _highlighted = {};
        });

        _scoreCtrl.forward(from: 0);

        if (result.prizes > 0) {
          _showToast('⭐ Prize! +${result.prizes * 50} bonus');
        }

        // Check win / lose
        Future.delayed(const Duration(milliseconds: 100), () {
          if (!mounted) return;
          if (_engine.isBoardEmpty || _engine.allPrizesCollected) {
            _triggerWin();
          } else if (!_engine.hasValidMoves()) {
            _triggerGameOver();
          }
          setState(() {});
        });
      });
    });
  }

  void _rotateBoard(String dir) {
    if (_animating || _rotating) return;
    _rotating = true;
    _animating = true;
    _rotDir = dir;
    setState(() => _highlighted = {});

    _rotCtrl.forward(from: 0).then((_) {
      _engine.rotateBoard(dir);
      _rotCtrl.reset();
      setState(() {
        _rotating = false;
        _animating = false;
      });
      if (!_engine.hasValidMoves() && !_engine.isBoardEmpty) {
        _triggerGameOver();
      }
    });
  }

  void _triggerWin() {
    final bumped = _engine.bumpSize(_engine.rows, _engine.cols, 'larger');
    setState(() {
      _showGameWin = true;
      _progression = ProgressionChoice(
        rows: bumped['rows']!,
        cols: bumped['cols']!,
        template: widget.settings.template,
        startRows: _engine.rows,
        startCols: _engine.cols,
        which: 'win',
      );
    });
    _startFireworks();
  }

  void _triggerGameOver() {
    final bumped = _engine.bumpSize(_engine.rows, _engine.cols, 'smaller');
    setState(() {
      _showGameOver = true;
      _progression = ProgressionChoice(
        rows: bumped['rows']!,
        cols: bumped['cols']!,
        template: widget.settings.template,
        startRows: _engine.rows,
        startCols: _engine.cols,
        which: 'over',
      );
    });
  }

  void _startFireworks() {
    final rng = Random();
    final particles = <_Particle>[];
    for (int i = 0; i < 60; i++) {
      particles.add(_Particle(
        x: rng.nextDouble(),
        y: rng.nextDouble() * 0.6,
        vx: (rng.nextDouble() - 0.5) * 0.012,
        vy: -rng.nextDouble() * 0.018 - 0.005,
        color: HSVColor.fromAHSV(1, rng.nextDouble() * 360, 1, 1).toColor(),
        size: 4 + rng.nextDouble() * 5,
      ));
    }
    setState(() => _particles = particles);

    _fireworksTimer = Timer.periodic(const Duration(milliseconds: 40), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        for (final p in _particles) {
          p.x += p.vx;
          p.y += p.vy;
          p.vy += 0.001; // gravity
          p.life -= 0.02;
        }
        _particles.removeWhere((p) => p.life <= 0);
      });
      if (_particles.isEmpty) t.cancel();
    });
  }

  void _nextLevel() {
    if (_progression == null) return;
    final newSettings = widget.settings.copyWith(
      rows: _progression!.rows,
      cols: _progression!.cols,
      template: _progression!.template,
    );
    widget.onUpdateSettings(newSettings);
    _engine.newBoard(
      rows: newSettings.rows,
      cols: newSettings.cols,
      template: newSettings.template,
      minGroupSize: newSettings.minGroupSize,
    );
    _fireworksTimer?.cancel();
    setState(() {
      _showGameWin = false;
      _showGameOver = false;
      _progression = null;
      _particles = [];
      _highlighted = {};
      _popping = {};
    });
  }

  void _showToast(String msg) {
    _toastTimer?.cancel();
    setState(() => _toastText = msg);
    _toastTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _toastText = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF000033),
      body: Stack(
        children: [
          // Board + rotation
          SafeArea(
            child: Column(
              children: [
                _buildHUD(),
                Expanded(
                  child: AnimatedBuilder(
                    animation: _rotAnim,
                    builder: (_, child) {
                      final angle = _rotating
                          ? (_rotDir == 'right' ? _rotAnim.value : -_rotAnim.value) * pi / 2
                          : 0.0;
                      return Transform.rotate(
                        angle: angle,
                        child: child,
                      );
                    },
                    child: GameBoard(
                      engine: _engine,
                      onCellTap: _onCellTap,
                      highlightedCells: _highlighted,
                      poppingCells: _popping,
                      onSwipeLeft: () => _rotateBoard('left'),
                      onSwipeRight: () => _rotateBoard('right'),
                    ),
                  ),
                ),
                _buildRotationControls(),
              ],
            ),
          ),

          // Fireworks
          if (_particles.isNotEmpty)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _FireworksPainter(_particles),
                ),
              ),
            ),

          // Toast
          if (_toastText != null)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedOpacity(
                  opacity: _toastText != null ? 1 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xF00F0F1E),
                      border: Border.all(color: const Color(0xFFFBBF24)),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFBBF24).withOpacity(0.4),
                          blurRadius: 20,
                        )
                      ],
                    ),
                    child: Text(
                      _toastText!,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ),

          // Abandon confirm
          if (_showAbandon) _buildAbandonOverlay(),

          // Game Over
          if (_showGameOver) _buildGameOverOverlay(),

          // Game Win
          if (_showGameWin) _buildGameWinOverlay(),
        ],
      ),
    );
  }

  Widget _buildHUD() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Menu button
          GestureDetector(
            onTap: () {
              if (_engine.hasMadeMove) {
                setState(() => _showAbandon = true);
              } else {
                widget.onExitToMenu();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('☰',
                  style: TextStyle(color: Colors.white, fontSize: 22)),
            ),
          ),

          // Score
          ScaleTransition(
            scale: _scoreAnim,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_engine.score}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRotationControls() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _RotateButton(
            label: '↺',
            onTap: () => _rotateBoard('left'),
            enabled: !_animating,
          ),
          const SizedBox(width: 24),
          _RotateButton(
            label: '↻',
            onTap: () => _rotateBoard('right'),
            enabled: !_animating,
          ),
        ],
      ),
    );
  }

  Widget _buildAbandonOverlay() {
    return _Overlay(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Leave game?', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          const Text('Your progress will be lost.', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _OverlayButton(
                label: 'CANCEL',
                color: const Color(0xFF3B82F6),
                onTap: () => setState(() => _showAbandon = false),
              ),
              _OverlayButton(
                label: 'LEAVE',
                color: const Color(0xFFEF4444),
                onTap: widget.onExitToMenu,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    return _Overlay(
      child: _ProgressionContent(
        title: '💀 GAME OVER',
        titleColor: const Color(0xFFEF4444),
        score: _engine.score,
        progression: _progression,
        actionLabel: 'TRY AGAIN',
        engine: _engine,
        onSizeChanged: (r, c) => setState(() => _progression = _progression?.withSize(r, c)),
        onTemplateChanged: (t) => setState(() => _progression = _progression?.withTemplate(t)),
        onAction: _nextLevel,
      ),
    );
  }

  Widget _buildGameWinOverlay() {
    return _Overlay(
      color: const Color(0xE614641400),
      child: _ProgressionContent(
        title: '🎉 YOU WIN!',
        titleColor: const Color(0xFFFBBF24),
        score: _engine.score,
        progression: _progression,
        actionLabel: 'NEXT LEVEL',
        engine: _engine,
        onSizeChanged: (r, c) => setState(() => _progression = _progression?.withSize(r, c)),
        onTemplateChanged: (t) => setState(() => _progression = _progression?.withTemplate(t)),
        onAction: _nextLevel,
      ),
    );
  }
}

// ── Overlay widget ────────────────────────────────────────────────────────────

class _Overlay extends StatelessWidget {
  final Widget child;
  final Color? color;

  const _Overlay({required this.child, this.color});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 360),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: color ?? const Color(0xE6000020),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 30)],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _OverlayButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OverlayButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
      ),
    );
  }
}

class _ProgressionContent extends StatelessWidget {
  final String title;
  final Color titleColor;
  final int score;
  final ProgressionChoice? progression;
  final String actionLabel;
  final GameEngine engine;
  final void Function(int rows, int cols) onSizeChanged;
  final void Function(BoardTemplate) onTemplateChanged;
  final VoidCallback onAction;

  const _ProgressionContent({
    required this.title,
    required this.titleColor,
    required this.score,
    required this.progression,
    required this.actionLabel,
    required this.engine,
    required this.onSizeChanged,
    required this.onTemplateChanged,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final p = progression;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: TextStyle(color: titleColor, fontSize: 28, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text('Score: $score',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        if (p != null) ...[
          const SizedBox(height: 20),
          const Text('Next Board', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StepBtn(
                label: '−',
                enabled: engine.canBump(p.rows, p.cols, 'smaller'),
                onTap: () {
                  final b = engine.bumpSize(p.rows, p.cols, 'smaller');
                  onSizeChanged(b['rows']!, b['cols']!);
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '${p.rows} × ${p.cols}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                ),
              ),
              _StepBtn(
                label: '+',
                enabled: engine.canBump(p.rows, p.cols, 'larger'),
                onTap: () {
                  final b = engine.bumpSize(p.rows, p.cols, 'larger');
                  onSizeChanged(b['rows']!, b['cols']!);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButton<BoardTemplate>(
              value: p.template,
              underline: const SizedBox(),
              isDense: true,
              items: BoardTemplate.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(_tLabel(t))))
                  .toList(),
              onChanged: (v) { if (v != null) onTemplateChanged(v); },
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
            ),
          ),
          if (p.rows != p.startRows || p.cols != p.startCols)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                  children: [
                    TextSpan(text: '${p.startRows}×${p.startCols} → '),
                    TextSpan(
                      text: '${p.rows}×${p.cols}',
                      style: const TextStyle(color: Color(0xFFFBBF24), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap: onAction,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFBBF24),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black, width: 2),
                boxShadow: const [BoxShadow(color: Color(0xFF92400E), offset: Offset(0, 4))],
              ),
              child: Center(
                child: Text(actionLabel,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 1)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _tLabel(BoardTemplate t) {
    switch (t) {
      case BoardTemplate.rectangle: return 'Rectangle';
      case BoardTemplate.diamond:   return 'Diamond';
      case BoardTemplate.cross:     return 'Cross';
      case BoardTemplate.circle:    return 'Circle';
      case BoardTemplate.staircase: return 'Staircase';
      case BoardTemplate.corners:   return 'Corners';
      case BoardTemplate.triangle:  return 'Triangle';
      case BoardTemplate.random:    return 'Random';
    }
  }
}

class _StepBtn extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  const _StepBtn({required this.label, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: enabled ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(enabled ? 0.5 : 0.15)),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(enabled ? 1 : 0.3),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _RotateButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool enabled;

  const _RotateButton({required this.label, required this.onTap, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.7),
          border: Border.all(color: Colors.white.withOpacity(0.35), width: 2),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: enabled ? Colors.white : Colors.white38,
              fontSize: 26,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Fireworks painter ─────────────────────────────────────────────────────────

class _Particle {
  double x, y, vx, vy, life, size;
  Color color;
  _Particle({
    required this.x, required this.y,
    required this.vx, required this.vy,
    required this.color, required this.size,
    this.life = 1.0,
  });
}

class _FireworksPainter extends CustomPainter {
  final List<_Particle> particles;
  _FireworksPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()
        ..color = p.color.withOpacity(p.life.clamp(0, 1))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(p.x * size.width, p.y * size.height), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(_FireworksPainter old) => true;
}

// ── Extension helpers on ProgressionChoice ────────────────────────────────────

extension _ProgressionExt on ProgressionChoice {
  ProgressionChoice withSize(int r, int c) => ProgressionChoice(
    rows: r, cols: c, template: template,
    startRows: startRows, startCols: startCols, which: which,
  );
  ProgressionChoice withTemplate(BoardTemplate t) => ProgressionChoice(
    rows: rows, cols: cols, template: t,
    startRows: startRows, startCols: startCols, which: which,
  );
}

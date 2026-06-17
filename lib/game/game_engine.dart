// lib/game/game_engine.dart
import 'dart:math';
import '../models/game_models.dart';

class GameEngine {
  List<List<BoardCell>> board = [];
  int rows = 9;
  int cols = 9;
  int minGroupSize = 2;
  BoardTemplate template = BoardTemplate.rectangle;
  int score = 0;
  bool hasMadeMove = false;
  Random _rng = Random();

  // ── Board Generation ─────────────────────────────────────────────────────

  void newBoard({
    required int rows,
    required int cols,
    required BoardTemplate template,
    required int minGroupSize,
  }) {
    this.rows = rows;
    this.cols = cols;
    this.template = template;
    this.minGroupSize = minGroupSize;
    score = 0;
    hasMadeMove = false;

    int attempts = 0;
    do {
      _generateBoard();
      attempts++;
    } while (!hasValidMoves() && attempts < 50);
  }

  void _generateBoard() {
    final layout = _buildLayout(template, rows, cols);
    board = List.generate(rows, (r) => List.generate(cols, (c) {
      if (!layout[r][c]) return BoardCell(isActive: false);
      final st = ShapeType.values[_rng.nextInt(ShapeType.values.length)];
      return BoardCell(shapeType: st, isActive: true);
    }));
    _assignPrizes();
  }

  void _assignPrizes() {
    final active = <List<int>>[];
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (board[r][c].hasShape) active.add([r, c]);
      }
    }
    active.shuffle(_rng);
    final count = min(active.length ~/ 5, 10);
    for (int i = 0; i < count; i++) {
      final pos = active[i];
      board[pos[0]][pos[1]].isPrize = true;
    }
  }

  List<List<bool>> _buildLayout(BoardTemplate t, int r, int c) {
    switch (t) {
      case BoardTemplate.rectangle:
        return List.generate(r, (_) => List.filled(c, true));
      case BoardTemplate.diamond:
        return _diamond(r, c);
      case BoardTemplate.cross:
        return _cross(r, c);
      case BoardTemplate.circle:
        return _circle(r, c);
      case BoardTemplate.staircase:
        return _staircase(r, c);
      case BoardTemplate.corners:
        return _corners(r, c);
      case BoardTemplate.triangle:
        return _triangle(r, c);
      case BoardTemplate.random:
        return List.generate(r, (_) => List.generate(c, (_) => _rng.nextDouble() > 0.4));
    }
  }

  List<List<bool>> _diamond(int r, int c) {
    final layout = List.generate(r, (_) => List.filled(c, false));
    final midR = r ~/ 2, midC = c ~/ 2;
    final maxDist = min(midR, midC);
    for (int i = 0; i < r; i++) {
      for (int j = 0; j < c; j++) {
        if ((i - midR).abs() + (j - midC).abs() <= maxDist) layout[i][j] = true;
      }
    }
    return layout;
  }

  List<List<bool>> _cross(int r, int c) {
    final layout = List.generate(r, (_) => List.filled(c, false));
    final midR = r ~/ 2, midC = c ~/ 2;
    final arm = max(1, min(r, c) ~/ 5);
    for (int i = 0; i < r; i++) {
      for (int j = 0; j < c; j++) {
        if ((i - midR).abs() <= arm || (j - midC).abs() <= arm) layout[i][j] = true;
      }
    }
    return layout;
  }

  List<List<bool>> _circle(int r, int c) {
    final layout = List.generate(r, (_) => List.filled(c, false));
    final cR = (r - 1) / 2, cC = (c - 1) / 2;
    final radius = min(r, c) / 2 - 0.5;
    for (int i = 0; i < r; i++) {
      for (int j = 0; j < c; j++) {
        if (sqrt(pow(i - cR, 2) + pow(j - cC, 2)) <= radius) layout[i][j] = true;
      }
    }
    return layout;
  }

  List<List<bool>> _staircase(int r, int c) {
    final layout = List.generate(r, (_) => List.filled(c, false));
    final nSteps = max(2, min(4, min(r, c) ~/ 4));
    final stepRows = (r / nSteps).ceil();
    final stepCols = (c / nSteps).ceil();
    for (int k = 0; k < nSteps; k++) {
      final rowStart = max(0, r - (k + 1) * stepRows);
      final rowEnd = r - k * stepRows - 1;
      if (rowEnd < 0) continue;
      final colStart = k * stepCols;
      if (colStart >= c) continue;
      for (int i = rowStart; i <= rowEnd; i++) {
        for (int j = colStart; j < c; j++) layout[i][j] = true;
      }
    }
    return layout;
  }

  List<List<bool>> _corners(int r, int c) {
    final layout = List.generate(r, (_) => List.filled(c, false));
    final M = min((r - 1) ~/ 2, (c - 1) ~/ 2);
    if (M < 1) return layout;
    final corners = [[0, 0], [0, c - M], [r - M, 0], [r - M, c - M]];
    for (final corner in corners) {
      for (int i = 0; i < M; i++) {
        for (int j = 0; j < M; j++) layout[corner[0] + i][corner[1] + j] = true;
      }
    }
    return layout;
  }

  List<List<bool>> _triangle(int r, int c) {
    return List.generate(r, (i) => List.generate(c, (j) => j * (r - 1) <= i * (c - 1)));
  }

  // ── Match Logic ───────────────────────────────────────────────────────────

  List<List<int>> findConnectedShapes(int startRow, int startCol, ShapeType type) {
    final visited = <String>{};
    final result = <List<int>>[];
    final queue = [[startRow, startCol]];
    while (queue.isNotEmpty) {
      final pos = queue.removeAt(0);
      final key = '${pos[0]},${pos[1]}';
      if (visited.contains(key)) continue;
      visited.add(key);
      final r = pos[0], c = pos[1];
      if (r < 0 || r >= rows || c < 0 || c >= cols) continue;
      final cell = board[r][c];
      if (!cell.hasShape || cell.shapeType != type) continue;
      result.add([r, c]);
      // 8 neighbors
      for (int dr = -1; dr <= 1; dr++) {
        for (int dc = -1; dc <= 1; dc++) {
          if (dr == 0 && dc == 0) continue;
          final nr = r + dr, nc = c + dc;
          final nk = '$nr,$nc';
          if (!visited.contains(nk)) queue.add([nr, nc]);
        }
      }
    }
    return result;
  }

  bool hasValidMoves() {
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final cell = board[r][c];
        if (cell.hasShape) {
          if (findConnectedShapes(r, c, cell.shapeType!).length >= minGroupSize) return true;
        }
      }
    }
    return false;
  }

  /// Returns (points, prizesCollected) - empty list means invalid tap
  ({int points, int prizes, List<List<int>> cells}) tapCell(int row, int col) {
    final cell = board[row][col];
    if (!cell.hasShape) return (points: 0, prizes: 0, cells: []);

    final connected = findConnectedShapes(row, col, cell.shapeType!);
    if (connected.length < minGroupSize) return (points: 0, prizes: 0, cells: []);

    hasMadeMove = true;
    int prizesCollected = 0;

    for (final pos in connected) {
      final c = board[pos[0]][pos[1]];
      if (c.isPrize && !c.prizeCollected) {
        prizesCollected++;
        c.prizeCollected = true;
      }
      board[pos[0]][pos[1]].shapeType = null;
    }

    final basePoints = connected.length * connected.length;
    final bonus = prizesCollected * 50;
    final gained = basePoints + bonus;
    score += gained;

    applyGravity();
    return (points: gained, prizes: prizesCollected, cells: connected);
  }

  void applyGravity() {
    for (int c = 0; c < cols; c++) {
      // collect non-null shapes from bottom up
      final shapes = <ShapeType?>[];
      final prizes = <bool>[];
      final prizeCollected = <bool>[];
      final active = <bool>[];
      for (int r = rows - 1; r >= 0; r--) {
        final cell = board[r][c];
        if (cell.isActive) {
          active.add(true);
          if (cell.hasShape) {
            shapes.add(cell.shapeType);
            prizes.add(cell.isPrize);
            prizeCollected.add(cell.prizeCollected);
          }
        }
      }
      int shapeIdx = 0;
      for (int r = rows - 1; r >= 0; r--) {
        if (board[r][c].isActive) {
          if (shapeIdx < shapes.length) {
            board[r][c].shapeType = shapes[shapeIdx];
            board[r][c].isPrize = prizes[shapeIdx];
            board[r][c].prizeCollected = prizeCollected[shapeIdx];
            shapeIdx++;
          } else {
            board[r][c].shapeType = null;
            board[r][c].isPrize = false;
            board[r][c].prizeCollected = false;
          }
        }
      }
    }
  }

  // ── Board Rotation ────────────────────────────────────────────────────────

  void rotateBoard(String direction) {
    // direction: 'left' = 90° counter-clockwise, 'right' = 90° clockwise
    final newRows = cols;
    final newCols = rows;
    final newBoard = List.generate(newRows, (_) => List.generate(newCols, (_) => BoardCell()));

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final cell = board[r][c];
        int nr, nc;
        if (direction == 'right') {
          nr = c;
          nc = rows - 1 - r;
        } else {
          nr = newRows - 1 - c;
          nc = r;
        }
        newBoard[nr][nc] = BoardCell(
          shapeType: cell.shapeType,
          isActive: cell.isActive,
          isPrize: cell.isPrize,
          prizeCollected: cell.prizeCollected,
        );
      }
    }

    rows = newRows;
    cols = newCols;
    board = newBoard;
    applyGravity();
  }

  // ── Win/Lose Checks ───────────────────────────────────────────────────────

  bool get isBoardEmpty {
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (board[r][c].hasShape) return false;
      }
    }
    return true;
  }

  bool get allPrizesCollected {
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (board[r][c].isPrize && !board[r][c].prizeCollected) return false;
      }
    }
    return true;
  }

  // ── Level Progression ─────────────────────────────────────────────────────

  static const int minSize = 7;
  static const int maxSize = 15;

  Map<String, int> bumpSize(int r, int c, String direction) {
    if (direction == 'larger') {
      if (r >= maxSize && c >= maxSize) return {'rows': r, 'cols': c};
      if (c < r) return {'rows': r, 'cols': c + 2};
      if (r < c) return {'rows': r + 2, 'cols': c};
      return c < maxSize ? {'rows': r, 'cols': c + 2} : {'rows': r + 2, 'cols': c};
    } else {
      if (r <= minSize && c <= minSize) return {'rows': r, 'cols': c};
      if (c > r) return {'rows': r, 'cols': c - 2};
      if (r > c) return {'rows': r - 2, 'cols': c};
      return r > minSize ? {'rows': r - 2, 'cols': c} : {'rows': r, 'cols': c - 2};
    }
  }

  bool canBump(int r, int c, String direction) {
    final after = bumpSize(r, c, direction);
    return after['rows'] != r || after['cols'] != c;
  }
}

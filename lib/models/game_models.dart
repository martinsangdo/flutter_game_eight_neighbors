// lib/models/game_models.dart

enum ShapeType { sphere, cube, tetra, octa, icosa, dodeca }

enum BoardTemplate { rectangle, diamond, cross, circle, staircase, corners, triangle, random }

enum AppScreen { splash, settings, playing }

class BoardCell {
  ShapeType? shapeType;
  bool isActive; // part of layout
  bool isPrize;
  bool prizeCollected;

  BoardCell({
    this.shapeType,
    this.isActive = false,
    this.isPrize = false,
    this.prizeCollected = false,
  });

  BoardCell copyWith({
    ShapeType? shapeType,
    bool? isActive,
    bool? isPrize,
    bool? prizeCollected,
    bool clearShape = false,
  }) {
    return BoardCell(
      shapeType: clearShape ? null : (shapeType ?? this.shapeType),
      isActive: isActive ?? this.isActive,
      isPrize: isPrize ?? this.isPrize,
      prizeCollected: prizeCollected ?? this.prizeCollected,
    );
  }

  bool get hasShape => shapeType != null;
}

class GameSettings {
  int rows;
  int cols;
  BoardTemplate template;
  int minGroupSize;
  bool soundEnabled;

  GameSettings({
    this.rows = 9,
    this.cols = 9,
    this.template = BoardTemplate.rectangle,
    this.minGroupSize = 2,
    this.soundEnabled = true,
  });

  GameSettings copyWith({
    int? rows,
    int? cols,
    BoardTemplate? template,
    int? minGroupSize,
    bool? soundEnabled,
  }) {
    return GameSettings(
      rows: rows ?? this.rows,
      cols: cols ?? this.cols,
      template: template ?? this.template,
      minGroupSize: minGroupSize ?? this.minGroupSize,
      soundEnabled: soundEnabled ?? this.soundEnabled,
    );
  }
}

class ProgressionChoice {
  int rows;
  int cols;
  BoardTemplate template;
  int startRows;
  int startCols;
  String which; // 'win' or 'over'

  ProgressionChoice({
    required this.rows,
    required this.cols,
    required this.template,
    required this.startRows,
    required this.startCols,
    required this.which,
  });
}

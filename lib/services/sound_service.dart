// lib/services/sound_service.dart
import 'package:audioplayers/audioplayers.dart';

enum Sfx { pop, invalid, prize, rotate, win, gameOver }

class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  /// Mirrors GameSettings.soundEnabled; updated whenever settings change.
  bool enabled = true;

  // Small pool so rapid taps don't cut each other off.
  final List<AudioPlayer> _pool = [];
  int _next = 0;
  static const int _poolSize = 4;
  bool _initialized = false;

  static const Map<Sfx, String> _files = {
    Sfx.pop: 'audio/pop.wav',
    Sfx.invalid: 'audio/invalid.wav',
    Sfx.prize: 'audio/prize.wav',
    Sfx.rotate: 'audio/rotate.wav',
    Sfx.win: 'audio/win.wav',
    Sfx.gameOver: 'audio/game_over.wav',
  };

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    for (int i = 0; i < _poolSize; i++) {
      final p = AudioPlayer();
      await p.setPlayerMode(PlayerMode.lowLatency);
      await p.setReleaseMode(ReleaseMode.stop);
      _pool.add(p);
    }
  }

  Future<void> play(Sfx sfx) async {
    if (!enabled) return;
    if (!_initialized) await initialize();
    final player = _pool[_next];
    _next = (_next + 1) % _pool.length;
    try {
      await player.stop();
      await player.play(AssetSource(_files[sfx]!));
    } catch (_) {
      // Never let audio failures break gameplay.
    }
  }

  void dispose() {
    for (final p in _pool) {
      p.dispose();
    }
    _pool.clear();
    _initialized = false;
  }
}

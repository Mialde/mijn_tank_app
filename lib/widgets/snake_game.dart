import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SnakeGame extends StatefulWidget {
  final Color themeColor;
  const SnakeGame({super.key, required this.themeColor});

  @override
  State<SnakeGame> createState() => _SnakeGameState();
}

enum Direction { up, down, left, right }
enum GameState { idle, playing, paused, gameOver }

class _SnakeGameState extends State<SnakeGame> with TickerProviderStateMixin {
  static const int cols = 20;
  static const int rows = 28;
  static const int highScoreKey = 0;

  List<Point<int>> _snake = [];
  Point<int> _fuel = const Point(10, 10);
  Direction _dir = Direction.right;
  Direction _nextDir = Direction.right;
  GameState _state = GameState.idle;
  int _score = 0;
  int _highScore = 0;
  Timer? _timer;
  Duration _speed = const Duration(milliseconds: 280);

  late AnimationController _fuelPulse;
  late Animation<double> _fuelAnim;

  // Powerups
  Point<int>? _heart;
  bool _heartIsPlus = true;
  Timer? _heartTimer;
  double _speedMultiplier = 1.0;

  // Swipe detection
  Offset? _swipeStart;

  @override
  void initState() {
    super.initState();
    _fuelPulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _fuelAnim = Tween(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _fuelPulse, curve: Curves.easeInOut));
    _initGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _heartTimer?.cancel();
    _fuelPulse.dispose();
    super.dispose();
  }

  void _initGame() {
    _snake = [
      const Point(10, 14),
      const Point(9, 14),
      const Point(8, 14),
    ];
    _dir = Direction.right;
    _nextDir = Direction.right;
    _score = 0;
    _speed = const Duration(milliseconds: 280);
    _placeFuel();
    _scheduleNextHeart();
  }

  void _placeFuel() {
    final rng = Random();
    Point<int> pos;
    do {
      pos = Point(rng.nextInt(cols), rng.nextInt(rows));
    } while (_snake.contains(pos));
    _fuel = pos;
  }

  void _scheduleNextHeart() {
    _heartTimer?.cancel();
    _heart = null;
    // Verschijn na 5-15 seconden
    final delay = Duration(seconds: 5 + Random().nextInt(11));
    _heartTimer = Timer(delay, () {
      if (_state != GameState.playing) return;
      setState(() {
        _heartIsPlus = Random().nextBool();
        final rng = Random();
        Point<int> pos;
        do {
          pos = Point(rng.nextInt(cols), rng.nextInt(rows));
        } while (_snake.contains(pos) || pos == _fuel);
        _heart = pos;
      });
      // Verdwijnt na 6 seconden als niet opgepakt
      _heartTimer = Timer(const Duration(seconds: 6), () {
        setState(() => _heart = null);
        _scheduleNextHeart();
      });
    });
  }

  void _startGame() {
    _initGame();
    setState(() => _state = GameState.playing);
    _scheduleNextHeart();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_speed, (_) => _tick());
  }

  void _tick() {
    if (_state != GameState.playing) return;
    setState(() {
      _dir = _nextDir;
      final head = _snake.first;
      Point<int> newHead;
      switch (_dir) {
        case Direction.up:    newHead = Point(head.x, head.y - 1); break;
        case Direction.down:  newHead = Point(head.x, head.y + 1); break;
        case Direction.left:  newHead = Point(head.x - 1, head.y); break;
        case Direction.right: newHead = Point(head.x + 1, head.y); break;
      }

      // Wrap-around: door muren heen
      newHead = Point(
        (newHead.x + cols) % cols,
        (newHead.y + rows) % rows,
      );
      // Self collision
      if (_snake.contains(newHead)) {
        _gameOver(); return;
      }

      _snake.insert(0, newHead);

      if (newHead == _fuel) {
        _score++;
        if (_score > _highScore) _highScore = _score;
        // Sneller na elke 5 brandstof
        if (_score % 5 == 0 && _speed.inMilliseconds > 80) {
          _speed = Duration(milliseconds: (_speed.inMilliseconds * 0.9).round().clamp(60, 9999));
          _startTimer();
        }
        _placeFuel();
        HapticFeedback.lightImpact();
      } else if (newHead == _heart) {
        // Heart powerup
        if (_heartIsPlus) {
          _speedMultiplier = (_speedMultiplier * 1.05);
          final newMs = (_speed.inMilliseconds / 1.05).round().clamp(60, 9999);
          _speed = Duration(milliseconds: newMs);
        } else {
          _speedMultiplier = (_speedMultiplier / 1.05);
          final newMs = (_speed.inMilliseconds * 1.05).round().clamp(60, 9999);
          _speed = Duration(milliseconds: newMs);
        }
        _heart = null;
        _startTimer();
        _scheduleNextHeart();
        HapticFeedback.mediumImpact();
        _snake.removeLast();
      } else {
        _snake.removeLast();
      }
    });
  }

  void _gameOver() {
    _timer?.cancel();
    HapticFeedback.heavyImpact();
    setState(() => _state = GameState.gameOver);
  }

  void _setDir(Direction d) {
    // Geen 180 graden draaien
    if (_dir == Direction.up && d == Direction.down) return;
    if (_dir == Direction.down && d == Direction.up) return;
    if (_dir == Direction.left && d == Direction.right) return;
    if (_dir == Direction.right && d == Direction.left) return;
    _nextDir = d;
  }

  void _handleSwipe(Offset delta) {
    if (delta.dx.abs() > delta.dy.abs()) {
      _setDir(delta.dx > 0 ? Direction.right : Direction.left);
    } else {
      _setDir(delta.dy > 0 ? Direction.down : Direction.up);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.themeColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF0F4F0);
    final gridBg = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFE8F0E8);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('SNAKE',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                color: color, letterSpacing: 2)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text('BEST: $_highScore',
                  style: TextStyle(fontSize: 11, color: color.withOpacity(0.6),
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Score
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_gas_station, color: color, size: 18),
                const SizedBox(width: 6),
                Text('$_score',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),

          // Game grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onPanStart: (d) => _swipeStart = d.localPosition,
                onPanEnd: (d) {
                  if (_swipeStart != null) {
                    _handleSwipe(d.velocity.pixelsPerSecond);
                    _swipeStart = null;
                  }
                },
                onTap: () {
                  if (_state == GameState.idle || _state == GameState.gameOver) _startGame();
                },
                child: LayoutBuilder(builder: (ctx, constraints) {
                    final cellW = constraints.maxWidth / cols;
                    final cellH = constraints.maxHeight / rows;
                    return Stack(children: [
                      // Grid achtergrond
                      Container(
                        decoration: BoxDecoration(
                          color: gridBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
                        ),
                      ),
                      // Grid lijnen
                      CustomPaint(
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                        painter: _GridPainter(cols, rows, isDark),
                      ),
                      // Heart powerup
                      if (_heart != null)
                        Positioned(
                          left: _heart!.x * (constraints.maxWidth / cols),
                          top: _heart!.y * (constraints.maxHeight / rows),
                          width: constraints.maxWidth / cols,
                          height: constraints.maxHeight / rows,
                          child: _buildHeart(constraints.maxWidth / cols, constraints.maxHeight / rows),
                        ),
                      // Brandstof druppel
                      AnimatedBuilder(
                        animation: _fuelAnim,
                        builder: (_, __) => Positioned(
                          left: _fuel.x * cellW,
                          top: _fuel.y * cellH,
                          width: cellW,
                          height: cellH,
                          child: Transform.scale(
                            scale: _fuelAnim.value,
                            child: _buildFuelDrop(cellW, cellH, color),
                          ),
                        ),
                      ),
                      // Snake (auto's)
                      ..._snake.asMap().entries.map((e) {
                        final i = e.key;
                        final p = e.value;
                        return Positioned(
                          left: p.x * cellW + 1,
                          top: p.y * cellH + 1,
                          width: cellW - 2,
                          height: cellH - 2,
                          child: i == 0
                              ? _buildCarHead(cellW - 2, cellH - 2, color)
                              : _buildCarBody(cellW - 2, cellH - 2, color, i),
                        );
                      }),
                      // Overlay: idle / game over
                      if (_state != GameState.playing)
                        _buildOverlay(color, isDark),
                    ]);
                }),
              ),
            ),
          ),

          // Swipe hint
          Padding(
            padding: const EdgeInsets.only(bottom: 16, top: 8),
            child: Text('Swipe om te sturen',
                style: TextStyle(fontSize: 11, color: color.withOpacity(0.4))),
          ),
        ],
      ),
    );
  }

  Widget _buildFuelDrop(double w, double h, Color color) {
    return Center(
      child: Icon(
        Icons.water_drop,
        color: const Color(0xFF10B981),
        size: w * 0.65,
        shadows: [Shadow(color: const Color(0xFF10B981).withOpacity(0.7), blurRadius: 8)],
      ),
    );
  }

  Widget _buildHeart(double w, double h) {
    final isPlus = _heartIsPlus;
    final color = isPlus ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final icon = isPlus ? Icons.favorite : Icons.heart_broken;
    return Center(
      child: Icon(
        icon,
        color: color,
        size: w * 0.7,
        shadows: [Shadow(color: color.withOpacity(0.6), blurRadius: 8)],
      ),
    );
  }

  Widget _buildCarHead(double w, double h, Color color) {
    double rotation = 0;
    switch (_dir) {
      case Direction.up:    rotation = 0;        break;
      case Direction.down:  rotation = pi;       break;
      case Direction.left:  rotation = -pi / 2;  break;
      case Direction.right: rotation = pi / 2;   break;
    }
    return Transform.rotate(
      angle: rotation,
      child: Center(
        child: Icon(
          Icons.drive_eta,
          color: color,
          size: w * 0.85,
          shadows: [Shadow(color: color.withOpacity(0.8), blurRadius: 10)],
        ),
      ),
    );
  }

  Widget _buildCarBody(double w, double h, Color color, int index) {
    final opacity = (1.0 - index * 0.04).clamp(0.3, 0.85);
    return Center(
      child: Container(
        width: w * 0.55,
        height: h * 0.55,
        decoration: BoxDecoration(
          color: color.withOpacity(opacity),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildOverlay(Color color, bool isDark) {
    final isGameOver = _state == GameState.gameOver;
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isGameOver) ...[
              const Text('💥', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 8),
              Text('GAME OVER',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                      color: color, letterSpacing: 2)),
              const SizedBox(height: 4),
              Text('Score: $_score',
                  style: const TextStyle(fontSize: 16, color: Colors.white70)),
              if (_score == _highScore && _score > 0) ...[
                const SizedBox(height: 4),
                Text('🏆 Nieuw record!',
                    style: TextStyle(fontSize: 13, color: color)),
              ],
            ] else ...[
              Icon(Icons.directions_car, color: color, size: 48),
              const SizedBox(height: 12),
              Text('SNAKE',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold,
                      color: color, letterSpacing: 3)),
              const SizedBox(height: 4),
              const Text('Tik om te starten',
                  style: TextStyle(fontSize: 13, color: Colors.white60)),
            ],
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _startGame,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(isGameOver ? 'OPNIEUW' : 'START',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }


}

// ── Grid painter ──────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  final int cols, rows;
  final bool isDark;
  const _GridPainter(this.cols, this.rows, this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.04)
      ..strokeWidth = 0.5;
    final cw = size.width / cols;
    final rh = size.height / rows;
    for (int x = 1; x < cols; x++) canvas.drawLine(Offset(x * cw, 0), Offset(x * cw, size.height), paint);
    for (int y = 1; y < rows; y++) canvas.drawLine(Offset(0, y * rh), Offset(size.width, y * rh), paint);
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}
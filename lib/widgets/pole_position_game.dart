import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PolePositionGame extends StatefulWidget {
  final Color themeColor;
  
  const PolePositionGame({super.key, required this.themeColor});

  @override
  State<PolePositionGame> createState() => _PolePositionGameState();
}

class _PolePositionGameState extends State<PolePositionGame> {
  // Game state
  bool _isPlaying = false;
  bool _gameOver = false;
  int _score = 0;
  int _highScore = 0;
  double _speed = 2.0;
  
  // Player position (0.0 = links, 1.0 = rechts)
  double _playerPosition = 0.5;
  
  // Road scroll offset
  double _roadOffset = 0.0;
  
  // Other cars
  final List<_Car> _cars = [];
  
  // Timer
  Timer? _gameTimer;
  
  // Fuel system
  double _fuel = 100.0;
  final double _maxFuel = 100.0;
  final double _fuelConsumption = 0.15; // Per tick
  
  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _isPlaying = true;
      _gameOver = false;
      _score = 0;
      _speed = 2.0;
      _playerPosition = 0.5;
      _roadOffset = 0.0;
      _cars.clear();
      _fuel = 100.0;
    });

    _gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!_isPlaying) {
        timer.cancel();
        return;
      }

      setState(() {
        // Update road scroll
        _roadOffset += _speed;
        if (_roadOffset > 100) _roadOffset = 0;

        // Update fuel
        _fuel -= _fuelConsumption;
        if (_fuel <= 0) {
          _fuel = 0;
          _endGame();
          return;
        }

        // Increase difficulty over time
        if (_score % 500 == 0 && _score > 0) {
          _speed = min(_speed + 0.1, 8.0);
        }

        // Spawn new cars
        if (Random().nextDouble() < 0.02) {
          _cars.add(_Car(
            position: Random().nextDouble(),
            yOffset: -0.2,
            color: _getRandomCarColor(),
          ));
        }

        // Update cars
        for (var car in _cars) {
          car.yOffset += _speed * 0.008;
        }

        // Remove off-screen cars and add score
        _cars.removeWhere((car) {
          if (car.yOffset > 1.2) {
            _score += 10;
            return true;
          }
          return false;
        });

        // Check collisions
        for (var car in _cars) {
          if (_checkCollision(car)) {
            _endGame();
            return;
          }
        }
      });
    });
  }

  bool _checkCollision(_Car car) {
    // Simple collision detection
    if (car.yOffset > 0.7 && car.yOffset < 0.9) {
      double distance = (car.position - _playerPosition).abs();
      return distance < 0.15;
    }
    return false;
  }

  void _endGame() {
    setState(() {
      _isPlaying = false;
      _gameOver = true;
      if (_score > _highScore) {
        _highScore = _score;
      }
    });
    _gameTimer?.cancel();
    HapticFeedback.heavyImpact();
  }

  Color _getRandomCarColor() {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.yellow,
      Colors.green,
      Colors.purple,
      Colors.orange,
    ];
    return colors[Random().nextInt(colors.length)];
  }

  void _moveLeft() {
    if (!_isPlaying) return;
    setState(() {
      _playerPosition = max(0.15, _playerPosition - 0.15);
    });
    HapticFeedback.selectionClick();
  }

  void _moveRight() {
    if (!_isPlaying) return;
    setState(() {
      _playerPosition = min(0.85, _playerPosition + 0.15);
    });
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1B1C24) : const Color(0xFF87CEEB),
      appBar: AppBar(
        title: const Text('🏎️ POLE POSITION'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Score and Fuel Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SCORE: $_score', 
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
                    ),
                    Text('HIGH: $_highScore', 
                      style: TextStyle(fontSize: 14, color: Colors.grey[600])
                    ),
                  ],
                ),
                // Fuel gauge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('⛽ FUEL', 
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 100,
                      height: 20,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: _fuel / _maxFuel,
                          backgroundColor: Colors.grey[800],
                          valueColor: AlwaysStoppedAnimation(
                            _fuel > 30 ? Colors.green : (_fuel > 15 ? Colors.orange : Colors.red)
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Game area
          Expanded(
            child: Stack(
              children: [
                // Game canvas
                _buildGameArea(isDark),
                
                // Start/Game Over overlay
                if (!_isPlaying) _buildOverlay(),
              ],
            ),
          ),
          
          // Controls
          if (_isPlaying) _buildControls(),
        ],
      ),
    );
  }

  Widget _buildGameArea(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFF404040),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CustomPaint(
          painter: _RoadPainter(
            offset: _roadOffset,
            cars: _cars,
            playerPosition: _playerPosition,
            themeColor: widget.themeColor,
          ),
          child: Container(),
        ),
      ),
    );
  }

  Widget _buildOverlay() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_gameOver) ...[
              const Text(
                '💥 CRASH!',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Score: $_score',
                style: const TextStyle(fontSize: 32, color: Colors.white),
              ),
              const SizedBox(height: 8),
              if (_score == _highScore && _score > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '🏆 NEW HIGH SCORE!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              const SizedBox(height: 32),
            ] else ...[
              const Text(
                '🏁 POLE POSITION',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ontwijg andere auto\'s!\nManage je benzine!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.white70),
              ),
              const SizedBox(height: 32),
            ],
            ElevatedButton(
              onPressed: _startGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.themeColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                _gameOver ? 'RETRY' : 'START',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Left button
          GestureDetector(
            onTap: _moveLeft,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: widget.themeColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: widget.themeColor, width: 3),
              ),
              child: Icon(
                Icons.arrow_back,
                size: 40,
                color: widget.themeColor,
              ),
            ),
          ),
          
          // Right button
          GestureDetector(
            onTap: _moveRight,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: widget.themeColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: widget.themeColor, width: 3),
              ),
              child: Icon(
                Icons.arrow_forward,
                size: 40,
                color: widget.themeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Car {
  double position; // 0.0 to 1.0 (left to right)
  double yOffset; // 0.0 to 1.0 (top to bottom)
  Color color;

  _Car({
    required this.position,
    required this.yOffset,
    required this.color,
  });
}

class _RoadPainter extends CustomPainter {
  final double offset;
  final List<_Car> cars;
  final double playerPosition;
  final Color themeColor;

  _RoadPainter({
    required this.offset,
    required this.cars,
    required this.playerPosition,
    required this.themeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Draw horizon gradient (3D effect)
    final gradientPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF87CEEB), // Sky blue
          Color(0xFF404040), // Road grey
        ],
        stops: [0.0, 0.3],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.3), gradientPaint);

    // Draw road (gets wider towards bottom for 3D effect)
    final roadPath = Path();
    final roadTop = size.height * 0.3;
    
    roadPath.moveTo(size.width * 0.4, roadTop);
    roadPath.lineTo(0, size.height);
    roadPath.lineTo(size.width, size.height);
    roadPath.lineTo(size.width * 0.6, roadTop);
    roadPath.close();

    paint.color = const Color(0xFF404040);
    canvas.drawPath(roadPath, paint);

    // Draw road markings (dashed center line)
    paint.color = Colors.white;
    paint.strokeWidth = 4;
    
    for (double y = 0; y < size.height; y += 40) {
      final adjustedY = (y + offset) % size.height;
      final progress = adjustedY / size.height;
      final lineWidth = 4 + (progress * 12); // Gets wider towards bottom
      
      final centerX = size.width * 0.5;
      final dashHeight = 15 + (progress * 30);
      
      paint.strokeWidth = lineWidth;
      canvas.drawLine(
        Offset(centerX, adjustedY),
        Offset(centerX, adjustedY + dashHeight),
        paint,
      );
    }

    // Draw road edges (yellow lines)
    paint.color = Colors.yellow;
    paint.strokeWidth = 6;
    
    // Left edge
    canvas.drawLine(
      Offset(size.width * 0.4, roadTop),
      Offset(0, size.height),
      paint,
    );
    
    // Right edge
    canvas.drawLine(
      Offset(size.width * 0.6, roadTop),
      Offset(size.width, size.height),
      paint,
    );

    // Draw other cars
    for (var car in cars) {
      _drawCar(canvas, size, car.position, car.yOffset, car.color, false);
    }

    // Draw player car (at bottom)
    _drawCar(canvas, size, playerPosition, 0.8, themeColor, true);
  }

  void _drawCar(Canvas canvas, Size size, double xPos, double yPos, Color color, bool isPlayer) {
    final progress = yPos;
    final roadTop = size.height * 0.3;
    final roadBottom = size.height;
    
    // Calculate perspective scaling
    final scale = 0.3 + (progress * 0.7);
    
    // Calculate X position on the road
    final leftEdgeX = size.width * 0.4 * (1 - progress);
    final rightEdgeX = size.width - (size.width * 0.4 * (1 - progress));
    final carX = leftEdgeX + (rightEdgeX - leftEdgeX) * xPos;
    
    // Calculate Y position
    final carY = roadTop + (roadBottom - roadTop) * yPos;
    
    // Car dimensions
    final carWidth = 30 * scale;
    final carHeight = 50 * scale;

    final paint = Paint();

    // Car shadow
    paint.color = Colors.black.withValues(alpha: 0.3);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(carX, carY + carHeight * 0.6),
        width: carWidth * 1.2,
        height: carHeight * 0.3,
      ),
      paint,
    );

    // Car body
    paint.color = color;
    final carRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(carX, carY),
        width: carWidth,
        height: carHeight,
      ),
      Radius.circular(4 * scale),
    );
    canvas.drawRRect(carRect, paint);

    // Windshield
    paint.color = Colors.lightBlue.withValues(alpha: 0.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(carX, carY - carHeight * 0.15),
          width: carWidth * 0.8,
          height: carHeight * 0.3,
        ),
        Radius.circular(2 * scale),
      ),
      paint,
    );

    // Wheels
    paint.color = Colors.black;
    final wheelRadius = 4 * scale;
    
    canvas.drawCircle(Offset(carX - carWidth * 0.35, carY + carHeight * 0.3), wheelRadius, paint);
    canvas.drawCircle(Offset(carX + carWidth * 0.35, carY + carHeight * 0.3), wheelRadius, paint);
    canvas.drawCircle(Offset(carX - carWidth * 0.35, carY - carHeight * 0.3), wheelRadius, paint);
    canvas.drawCircle(Offset(carX + carWidth * 0.35, carY - carHeight * 0.3), wheelRadius, paint);

    // Player indicator
    if (isPlayer) {
      paint.color = Colors.white;
      paint.strokeWidth = 2 * scale;
      paint.style = PaintingStyle.stroke;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(carX, carY),
            width: carWidth + 8,
            height: carHeight + 8,
          ),
          Radius.circular(6 * scale),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_RoadPainter oldDelegate) => true;
}
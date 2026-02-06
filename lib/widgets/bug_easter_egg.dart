import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

class BugOverlay extends StatefulWidget {
  final VoidCallback onFinished;
  final VoidCallback onSecretUnlocked;

  const BugOverlay({super.key, required this.onFinished, required this.onSecretUnlocked});

  @override
  State<BugOverlay> createState() => _BugOverlayState();
}

class _BugOverlayState extends State<BugOverlay> with SingleTickerProviderStateMixin {
  double x = 100;
  double y = 100;
  double dx = 2; 
  double dy = 2; 
  double rotation = 0;
  bool isDead = false;
  bool isExiting = false;
  Timer? _moveTimer;
  
  late AnimationController _fadeCtrl;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _moveTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) => _updatePosition());
    
    // VEILIGHEID: Na 13 seconden altijd opruimen
    Future.delayed(const Duration(seconds: 13), () { 
      if (mounted && !isDead) {
        setState(() => isExiting = true); 
      }
    });

    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(_fadeCtrl);
    
    _opacity.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) widget.onFinished();
      }
    });
  }

  void _updatePosition() {
    // FIX VOOR VASTLOPEN: Stop direct als de widget niet meer op het scherm is
    if (!mounted || isDead) {
      _moveTimer?.cancel();
      return;
    }

    setState(() {
      final size = MediaQuery.of(context).size;
      
      // Logica voor 'vertrekken'
      if (isExiting) { 
        dy = 5; 
        dx = 0; 
        
        if (y > size.height + 50) {
          _moveTimer?.cancel();
          widget.onFinished();
          return;
        }
      }

      x += dx; 
      y += dy;
      
      if (!isExiting) {
        if (x < 0 || x > size.width - 30) dx = -dx;
        if (y < 0 || y > size.height - 30) dy = -dy;
      }
      rotation = atan2(dy, dx) + (pi / 2);
    });
  }

  @override
  void dispose() { 
    _moveTimer?.cancel(); 
    _fadeCtrl.dispose(); 
    super.dispose(); 
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // We gebruiken hier Positioned zodat we GEEN schermvullende container hebben
        // die de aanrakingen voor de swipe blokkeert.
        Positioned(
          left: x, top: y,
          child: GestureDetector(
            onTap: isDead ? () { 
              if (mounted) {
                widget.onSecretUnlocked(); 
                _fadeCtrl.forward(); 
              }
            } : () {
              // Tik op de bug: dood maken
              _moveTimer?.cancel();
              if (mounted) {
                setState(() => isDead = true);
                Future.delayed(const Duration(milliseconds: 1500), () {
                  if (mounted) _fadeCtrl.forward();
                });
              }
            },
            child: isDead 
              ? FadeTransition(opacity: _opacity, child: const Icon(Icons.egg_alt, color: Colors.red, size: 35))
              : Transform.rotate(
                  angle: rotation,
                  child: Icon(
                    Icons.bug_report, 
                    size: 28, 
                    color: isDark ? Colors.white38 : Colors.black26, 
                  ),
                ),
          ),
        ),
      ],
    );
  }
}
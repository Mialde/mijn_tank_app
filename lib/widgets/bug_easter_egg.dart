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
  // Positie & Beweging
  double x = 100;
  double y = 100;
  double dx = 2; 
  double dy = 2; 
  double rotation = 0;

  // Status
  bool isDead = false;
  bool isFading = false;
  bool isExiting = false; // Nieuwe status voor het weglopen
  Timer? _moveTimer;
  
  // Fade animatie voor het ei
  late AnimationController _fadeCtrl;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    
    // Start beweging loop
    _moveTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      _updatePosition();
    });

    // PLAN DE UITTOCHT: Na 13 seconden gaat hij naar beneden lopen
    Future.delayed(const Duration(seconds: 13), () {
      if (mounted && !isDead) {
        setState(() {
          isExiting = true;
        });
      }
    });

    // EINDE: Na 15 seconden (of als hij ver genoeg weg is) ruimen we op
    Future.delayed(const Duration(seconds: 16), () {
      if (mounted && !isDead) {
        widget.onFinished();
      }
    });

    // Setup fade controller
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(_fadeCtrl);
    
    _fadeCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onFinished();
      }
    });
  }

void _updatePosition() {
    if (isDead) return;

    final size = MediaQuery.of(context).size;
    final maxW = size.width - 25; 
    // maxH regel verwijderd

    setState(() {
      // LOGICA VOOR WEGLOPEN
      if (isExiting) {
        dx = 0; 
        dy = 4; 
        rotation = pi; 
        y += dy;
        
        if (y > size.height + 50) {
          widget.onFinished();
        }
        return;
      }

      // NORMALE BEWEGING
      x += dx;
      y += dy;

      if (x <= 0 || x >= maxW) {
        dx = -dx;
        dy += (Random().nextDouble() - 0.5); 
      }
      
      if (y <= 0) {
        dy = -dy;
        dx += (Random().nextDouble() - 0.5);
      }
      
      // Hier gebruiken we size.height direct
      if (y >= size.height - 100) {
         dy = -dy;
         dx += (Random().nextDouble() - 0.5);
      }

      rotation = atan2(dy, dx) + (pi / 2);
    });
  }

  void _squashBug() {
    if (isDead) return;
    
    _moveTimer?.cancel();
    setState(() {
      isDead = true;
    });

    // Start fade out na 1.5 seconde
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => isFading = true);
        _fadeCtrl.forward();
      }
    });
  }

  void _onEggTap() {
    widget.onSecretUnlocked();
    _fadeCtrl.duration = const Duration(milliseconds: 500);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _moveTimer?.cancel();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: Container(color: Colors.transparent)),
        
        Positioned(
          left: x,
          top: y,
          child: GestureDetector(
            onTap: isDead ? _onEggTap : _squashBug,
            child: isDead 
              ? FadeTransition(
                  opacity: _opacity,
                  child: const Icon(Icons.egg_alt, color: Colors.red, size: 35), 
                )
              : Transform.rotate(
                  angle: rotation,
                  // AANGEPAST: Kleiner en Zwart (Mier-achtig)
                  child: const Icon(Icons.bug_report, color: Colors.black, size: 22), 
                ),
          ),
        ),
      ],
    );
  }
}
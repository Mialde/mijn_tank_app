import 'package:flutter/material.dart';

class ZoomCarEasterEgg extends StatefulWidget {
  final VoidCallback onFinished; final bool isTimeMachine;
  const ZoomCarEasterEgg({super.key, required this.onFinished, required this.isTimeMachine});
  @override State<ZoomCarEasterEgg> createState() => _ZoomCarEasterEggState();
}
class _ZoomCarEasterEggState extends State<ZoomCarEasterEgg> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl; late Animation<double> _scale; late Animation<double> _opacity;
  @override void initState() {
    super.initState();
    int duration = widget.isTimeMachine ? 6 : 4;
    _ctrl = AnimationController(vsync: this, duration: Duration(seconds: duration));
    _scale = Tween<double>(begin: 0.1, end: 35.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInQuad));
    _opacity = TweenSequence([TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15), TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 70), TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 15)]).animate(_ctrl);
    _ctrl.forward().then((_) => widget.onFinished());
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    return Center(child: AnimatedBuilder(animation: _ctrl, builder: (context, child) {
              return Opacity(opacity: _opacity.value, child: Transform.scale(scale: _scale.value, child: widget.isTimeMachine ? Icon(Icons.rocket_launch, size: 80, color: Colors.blueGrey[300]) : Stack(alignment: Alignment.center, children: [const Icon(Icons.directions_car, size: 100, color: Colors.blue), Positioned(bottom: 22, child: Container(padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0.5), decoration: BoxDecoration(color: Colors.yellow, border: Border.all(color: Colors.black, width: 0.5), borderRadius: BorderRadius.circular(1)), child: const Text("53ND NUD35", style: TextStyle(color: Colors.black, fontSize: 5, fontWeight: FontWeight.bold, letterSpacing: 0.5))))])));
    }));
  }
}
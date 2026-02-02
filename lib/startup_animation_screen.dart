import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'main.dart';

class StartupAnimationScreen extends StatefulWidget {
  const StartupAnimationScreen({super.key});

  @override
  State<StartupAnimationScreen> createState() =>
      _StartupAnimationScreenState();
}

class _StartupAnimationScreenState extends State<StartupAnimationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    // Navigate after splash animation
    Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SplashDecider()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildLeaf(int index) {
    final startX = _random.nextDouble();
    final size = 16 + _random.nextDouble() * 14;
    final speed = 0.3 + _random.nextDouble();

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final progress =
            (_controller.value * speed + index * 0.1) % 1;

        return Positioned(
          left: MediaQuery.of(context).size.width * startX,
          top: MediaQuery.of(context).size.height * (1 - progress),
          child: Opacity(
            opacity: 0.4,
            child: Transform.rotate(
              angle: progress * 2 * pi,
              child: Text(
                '🍃',
                style: TextStyle(fontSize: size),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      body: Stack(
        children: [
          for (int i = 0; i < 18; i++) _buildLeaf(i),

          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  '♻️',
                  style: TextStyle(fontSize: 90),
                ),
                SizedBox(height: 20),
                Text(
                  'HARITHAM',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

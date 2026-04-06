import 'dart:math';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class MovingBallsAnimation extends StatefulWidget {
  const MovingBallsAnimation({super.key});

  @override
  State<MovingBallsAnimation> createState() => _MovingBallsAnimationState();
}

class _MovingBallsAnimationState extends State<MovingBallsAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Ball> _balls = [];
  final Random _random = Random();
  final int _ballCount = 24;
  final double _ballRadius = 18.0;

  final List<IconData> _symbols = [
    FontAwesomeIcons.droplet,
    FontAwesomeIcons.heart,
    FontAwesomeIcons.star,
    FontAwesomeIcons.bolt,
    FontAwesomeIcons.fire,
    FontAwesomeIcons.leaf,
    FontAwesomeIcons.sun,
    FontAwesomeIcons.moon,
    FontAwesomeIcons.cloud,
    FontAwesomeIcons.snowflake,
    FontAwesomeIcons.anchor,
    FontAwesomeIcons.bicycle,
    FontAwesomeIcons.camera,
    FontAwesomeIcons.compass,
    FontAwesomeIcons.gem,
    FontAwesomeIcons.globe,
    FontAwesomeIcons.key,
    FontAwesomeIcons.music,
    FontAwesomeIcons.rocket,
    FontAwesomeIcons.shield,
    FontAwesomeIcons.umbrella,
    FontAwesomeIcons.wrench,
    FontAwesomeIcons.tree,
    FontAwesomeIcons.skull,
  ];

  final List<Color> _colors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.purple,
    Colors.orange,
    Colors.pink,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(_updateBalls);
    _controller.repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_balls.isEmpty) {
      final size = MediaQuery.of(context).size;
      for (int i = 0; i < _ballCount; i++) {
        _balls.add(Ball(
          position: Offset(
            _random.nextDouble() * (size.width - _ballRadius * 2),
            _random.nextDouble() * 200, // Top area
          ),
          velocity: Offset(
            (_random.nextDouble() * 4 - 2),
            (_random.nextDouble() * 4 - 2),
          ),
          color: _colors[_random.nextInt(_colors.length)],
          symbol: _symbols[i % _symbols.length],
        ));
      }
    }
  }

  void _updateBalls() {
    final size = MediaQuery.of(context).size;
    final double areaHeight = 250.0;

    for (int i = 0; i < _balls.length; i++) {
      var ball = _balls[i];
      
      // Update position
      ball.position += ball.velocity;

      // Handle wall collisions
      if (ball.position.dx <= 0 || ball.position.dx >= size.width - _ballRadius * 2) {
        ball.velocity = Offset(-ball.velocity.dx, ball.velocity.dy);
      }
      if (ball.position.dy <= 0 || ball.position.dy >= areaHeight - _ballRadius * 2) {
        ball.velocity = Offset(ball.velocity.dx, -ball.velocity.dy);
      }

      // Handle ball-to-ball collisions
      for (int j = i + 1; j < _balls.length; j++) {
        var other = _balls[j];
        final distance = (ball.position - other.position).distance;
        if (distance < _ballRadius * 2) {
          // Swap velocities (elastic collision)
          final tempVelocity = ball.velocity;
          ball.velocity = other.velocity;
          other.velocity = tempVelocity;

          // Transfer colors
          final tempColor = ball.color;
          ball.color = other.color;
          other.color = tempColor;

          // Prevent overlapping
          final overlap = _ballRadius * 2 - distance;
          final direction = (ball.position - other.position) / distance;
          ball.position += direction * (overlap / 2);
          other.position -= direction * (overlap / 2);
        }
      }
    }
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: _balls.map((ball) => Positioned(
          left: ball.position.dx,
          top: ball.position.dy,
          child: Container(
            width: _ballRadius * 2,
            height: _ballRadius * 2,
            decoration: BoxDecoration(
              color: ball.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: ball.color.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                ball.symbol,
                size: _ballRadius * 0.8,
                color: Colors.black,
              ),
            ),
          ),
        )).toList(),
      ),
    );
  }
}

class Ball {
  Offset position;
  Offset velocity;
  Color color;
  IconData symbol;

  Ball({
    required this.position,
    required this.velocity,
    required this.color,
    required this.symbol,
  });
}

import 'package:flutter/material.dart';

class PointsBadge extends StatelessWidget {
  final int points;

  const PointsBadge({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const BoxDecoration(
        color: Color(0xFF1A6B3C),
        borderRadius: BorderRadius.all(Radius.circular(999)),
      ),
      child: Text(
        points == 1 ? '1 pt' : '$points pts',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

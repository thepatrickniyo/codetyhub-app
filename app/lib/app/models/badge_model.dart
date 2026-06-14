import 'package:flutter/material.dart';

class BadgeModel {
  const BadgeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.xpRequired,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  /// 0 means triggered by event, not XP threshold.
  final int xpRequired;
}

import 'package:flutter/material.dart';
import 'course_model.dart';

class PathwayModel {
  const PathwayModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.colorIndex,
    required this.courses,
    required this.totalHours,
  });

  final String id;
  final String title;
  final String description;
  final String icon;
  final int colorIndex;
  final List<CourseModel> courses;
  final int totalHours;

  int get courseCount => courses.length;

  IconData get iconData {
    switch (icon) {
      case 'ml-fundamentals':
      case 'brain':
        return Icons.psychology_outlined;
      case 'deep-learning':
      case 'microscope':
        return Icons.science_outlined;
      case 'nlp':
      case 'chat':
        return Icons.forum_outlined;
      case 'computer-vision':
      case 'eye':
        return Icons.visibility_outlined;
      case 'generative-ai':
      case 'sparkles':
        return Icons.auto_awesome_outlined;
      case 'mlops':
      case 'rocket':
        return Icons.rocket_launch_outlined;
      default:
        return Icons.school_outlined;
    }
  }
}


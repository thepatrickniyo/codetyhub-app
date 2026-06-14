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

  /// Returns a curated Unsplash cover image URL for this pathway.
  String get imageUrl {
    switch (id) {
      case 'ml-fundamentals':
        return 'https://images.unsplash.com/photo-1677442135703-1787eea5ce01?w=800&q=80&fit=crop';
      case 'deep-learning':
        return 'https://images.unsplash.com/photo-1620712943543-bcc4688e7485?w=800&q=80&fit=crop';
      case 'nlp':
        return 'https://images.unsplash.com/photo-1655720828018-edd2daec9349?w=800&q=80&fit=crop';
      case 'computer-vision':
        return 'https://images.unsplash.com/photo-1633412802994-5c058f151b66?w=800&q=80&fit=crop';
      case 'generative-ai':
        return 'https://images.unsplash.com/photo-1686191128892-3b37add4c844?w=800&q=80&fit=crop';
      case 'mlops':
        return 'https://images.unsplash.com/photo-1667372393119-3d4c48d07fc9?w=800&q=80&fit=crop';
      default:
        return 'https://images.unsplash.com/photo-1504639725590-34d0984388bd?w=800&q=80&fit=crop';
    }
  }
}


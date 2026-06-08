import 'dart:convert';

import 'package:flutter/material.dart';

class DrawingStroke {
  final List<Offset> points;
  final Color color;
  final double width;

  const DrawingStroke({
    required this.points,
    required this.color,
    required this.width,
  });

  Map<String, dynamic> toJson() => {
        'points': points.map((p) => [p.dx, p.dy]).toList(),
        'color': color.toARGB32(),
        'width': width,
      };

  factory DrawingStroke.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['points'] as List<dynamic>? ?? [];
    final points = rawPoints.map((p) {
      final pair = p as List<dynamic>;
      return Offset((pair[0] as num).toDouble(), (pair[1] as num).toDouble());
    }).toList();

    return DrawingStroke(
      points: points,
      color: Color(json['color'] as int? ?? 0xFF4A1800),
      width: (json['width'] as num?)?.toDouble() ?? 3,
    );
  }

  static String encode(List<DrawingStroke> strokes) {
    return jsonEncode(strokes.map((s) => s.toJson()).toList());
  }

  static List<DrawingStroke> decode(String? raw) {
    if (raw == null || raw.trim().isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => DrawingStroke.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }
}

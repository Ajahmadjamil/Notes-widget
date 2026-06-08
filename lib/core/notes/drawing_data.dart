import 'dart:convert';

import 'package:flutter/material.dart';

class DrawingPoint {
  final double dx;
  final double dy;

  const DrawingPoint(this.dx, this.dy);

  Map<String, dynamic> toJson() => {'dx': dx, 'dy': dy};

  factory DrawingPoint.fromJson(Map<String, dynamic> json) {
    return DrawingPoint(
      (json['dx'] as num).toDouble(),
      (json['dy'] as num).toDouble(),
    );
  }
}

class DrawingStroke {
  final Color color;
  final double width;
  final List<DrawingPoint> points;

  const DrawingStroke({
    required this.color,
    required this.width,
    required this.points,
  });

  Map<String, dynamic> toJson() => {
        'color': '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
        'width': width,
        'points': points.map((p) => p.toJson()).toList(),
      };

  factory DrawingStroke.fromJson(Map<String, dynamic> json) {
    final colorHex = json['color'] as String? ?? '#4a1800';
    final color = _colorFromHex(colorHex);
    final points = (json['points'] as List? ?? [])
        .map((p) => DrawingPoint.fromJson(Map<String, dynamic>.from(p as Map)))
        .toList();
    return DrawingStroke(
      color: color,
      width: (json['width'] as num?)?.toDouble() ?? 3,
      points: points,
    );
  }

  static Color _colorFromHex(String hex) {
    var value = hex.replaceFirst('#', '');
    if (value.length == 6) value = 'FF$value';
    final intVal = int.tryParse(value, radix: 16) ?? 0xFF4A1800;
    return Color(intVal);
  }
}

class DrawingData {
  final List<DrawingStroke> strokes;
  final double viewportWidth;
  final double viewportHeight;

  const DrawingData({
    this.strokes = const [],
    this.viewportWidth = 0,
    this.viewportHeight = 0,
  });

  bool get isEmpty => strokes.isEmpty;

  bool get hasViewport => viewportWidth > 0 && viewportHeight > 0;

  DrawingData copyWith({
    List<DrawingStroke>? strokes,
    double? viewportWidth,
    double? viewportHeight,
  }) {
    return DrawingData(
      strokes: strokes ?? this.strokes,
      viewportWidth: viewportWidth ?? this.viewportWidth,
      viewportHeight: viewportHeight ?? this.viewportHeight,
    );
  }

  String encode() {
    if (strokes.isEmpty && !hasViewport) return '';
    return jsonEncode({
      'version': 1,
      'strokes': strokes.map((s) => s.toJson()).toList(),
      if (hasViewport) 'viewportWidth': viewportWidth,
      if (hasViewport) 'viewportHeight': viewportHeight,
    });
  }

  static DrawingData decode(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const DrawingData();
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final list = (map['strokes'] as List? ?? [])
          .map((s) => DrawingStroke.fromJson(Map<String, dynamic>.from(s as Map)))
          .toList();
      return DrawingData(
        strokes: list,
        viewportWidth: (map['viewportWidth'] as num?)?.toDouble() ?? 0,
        viewportHeight: (map['viewportHeight'] as num?)?.toDouble() ?? 0,
      );
    } catch (_) {
      return const DrawingData();
    }
  }
}

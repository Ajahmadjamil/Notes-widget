import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/notes/drawing_data.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';
import 'package:noteswidgetapp/core/widget/widget_drawing_dimensions.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Renders shared handwriting into a PNG for the Android home widget.
class WidgetDrawingRenderer {
  WidgetDrawingRenderer._();

  static Future<String?> renderToBase64(DrawingData data) async {
    final bytes = await renderToPngBytes(data);
    if (bytes == null) return null;
    return base64Encode(bytes);
  }

  /// Legacy file path (kept as fallback for the native widget reader).
  static Future<String?> renderToFile(DrawingData data) async {
    final bytes = await renderToPngBytes(data);
    if (bytes == null) return null;

    final dir = p.join(await getDatabasesPath(), 'widget_assets');
    await Directory(dir).create(recursive: true);
    final file = File(p.join(dir, 'shared_note_drawing_preview.png'));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  static Future<Uint8List?> renderToPngBytes(DrawingData data) async {
    final logicalW = data.hasViewport
        ? data.viewportWidth
        : WidgetDrawingDimensions.referenceWidthDp.toDouble();
    final logicalH = data.hasViewport
        ? data.viewportHeight
        : WidgetDrawingDimensions.heightForWidth(logicalW);

    final pixels = WidgetDrawingDimensions.renderPixelsForWidth(logicalW);
    final scaleX = pixels.width / logicalW;
    final scaleY = pixels.height / logicalH;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, pixels.width.toDouble(), pixels.height.toDouble()),
      Paint()..color = AppColors.bgColor,
    );

    for (final stroke in data.strokes) {
      if (stroke.points.isEmpty) continue;

      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width * scaleX
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (stroke.points.length == 1) {
        final pt = stroke.points.first;
        canvas.drawCircle(
          Offset(pt.dx * scaleX, pt.dy * scaleY),
          paint.strokeWidth / 2,
          Paint()
            ..color = stroke.color
            ..style = PaintingStyle.fill,
        );
        continue;
      }

      final path = Path()
        ..moveTo(
          stroke.points.first.dx * scaleX,
          stroke.points.first.dy * scaleY,
        );
      for (var i = 1; i < stroke.points.length; i++) {
        final pt = stroke.points[i];
        path.lineTo(pt.dx * scaleX, pt.dy * scaleY);
      }
      canvas.drawPath(path, paint);
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(pixels.width, pixels.height);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes?.buffer.asUint8List();
  }
}

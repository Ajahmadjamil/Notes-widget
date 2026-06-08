import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/notes/drawing_data.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';

class HandwritingCanvas extends StatefulWidget {
  final DrawingData initialData;
  final ValueChanged<DrawingData> onChanged;
  final Color strokeColor;

  const HandwritingCanvas({
    super.key,
    required this.initialData,
    required this.onChanged,
    this.strokeColor = AppColors.selected,
  });

  @override
  State<HandwritingCanvas> createState() => HandwritingCanvasState();
}

class HandwritingCanvasState extends State<HandwritingCanvas> {
  late List<DrawingStroke> _strokes;
  DrawingStroke? _activeStroke;

  @override
  void initState() {
    super.initState();
    _strokes = List<DrawingStroke>.from(widget.initialData.strokes);
  }

  @override
  void didUpdateWidget(HandwritingCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialData.encode() != widget.initialData.encode()) {
      setState(() {
        _strokes = List<DrawingStroke>.from(widget.initialData.strokes);
        _activeStroke = null;
      });
    }
  }

  void undo() {
    if (_strokes.isEmpty) return;
    setState(() {
      _strokes.removeLast();
      _notify();
    });
  }

  void clear() {
    if (_strokes.isEmpty) return;
    setState(() {
      _strokes.clear();
      _notify();
    });
  }

  void _notify() {
    widget.onChanged(DrawingData(strokes: List.unmodifiable(_strokes)));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onPanStart: (d) {
            setState(() {
              _activeStroke = DrawingStroke(
                color: widget.strokeColor,
                width: 3,
                points: [DrawingPoint(d.localPosition.dx, d.localPosition.dy)],
              );
            });
          },
          onPanUpdate: (d) {
            if (_activeStroke == null) return;
            setState(() {
              final pts = List<DrawingPoint>.from(_activeStroke!.points)
                ..add(DrawingPoint(d.localPosition.dx, d.localPosition.dy));
              _activeStroke = DrawingStroke(
                color: _activeStroke!.color,
                width: _activeStroke!.width,
                points: pts,
              );
            });
          },
          onPanEnd: (_) {
            if (_activeStroke == null) return;
            setState(() {
              _strokes.add(_activeStroke!);
              _activeStroke = null;
              _notify();
            });
          },
          child: CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: _CanvasPainter(
              strokes: _strokes,
              activeStroke: _activeStroke,
            ),
          ),
        );
      },
    );
  }
}

class _CanvasPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final DrawingStroke? activeStroke;

  _CanvasPainter({required this.strokes, this.activeStroke});

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in [...strokes, if (activeStroke != null) activeStroke!]) {
      if (stroke.points.length < 2) continue;
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path()..moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (var i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CanvasPainter oldDelegate) => true;
}

/// Tiny preview for note cards.
class DrawingPreview extends StatelessWidget {
  final DrawingData data;
  final double height;

  const DrawingPreview({super.key, required this.data, this.height = 72});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Icon(Icons.draw_rounded, color: AppColors.textColor2, size: 28),
        ),
      );
    }
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _CanvasPainter(strokes: data.strokes),
      ),
    );
  }
}

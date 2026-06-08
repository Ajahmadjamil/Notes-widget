import 'package:flutter/material.dart';
import 'package:noteswidgetapp/core/notes/drawing_data.dart';
import 'package:noteswidgetapp/core/theme/app_colors.dart';

/// Handwriting pad for shared notes — fixed widget aspect ratio + pinch zoom.
class SharedHandwritingCanvas extends StatefulWidget {
  final DrawingData initialData;
  final double canvasWidth;
  final double canvasHeight;
  final ValueChanged<DrawingData> onChanged;
  final Color? strokeColor;

  const SharedHandwritingCanvas({
    super.key,
    required this.initialData,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.onChanged,
    this.strokeColor,
  });

  Color get effectiveStrokeColor => strokeColor ?? AppColors.selected;

  @override
  State<SharedHandwritingCanvas> createState() => SharedHandwritingCanvasState();
}

class SharedHandwritingCanvasState extends State<SharedHandwritingCanvas> {
  late List<DrawingStroke> _strokes;
  DrawingStroke? _activeStroke;

  double _scale = 1;
  Offset _offset = Offset.zero;
  final Map<int, Offset> _pointers = {};
  double? _pinchStartDistance;
  double _pinchStartScale = 1;
  Offset _pinchFocal = Offset.zero;
  bool _isPinching = false;

  @override
  void initState() {
    super.initState();
    _strokes = List<DrawingStroke>.from(widget.initialData.strokes);
  }

  @override
  void didUpdateWidget(SharedHandwritingCanvas oldWidget) {
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

  Offset _toCanvasSpace(Offset local) {
    final matrix = Matrix4.identity()
      ..translate(_offset.dx, _offset.dy)
      ..scale(_scale);
    final inverse = Matrix4.inverted(matrix);
    return MatrixUtils.transformPoint(inverse, local);
  }

  void _notify() {
    widget.onChanged(
      DrawingData(
        strokes: List.unmodifiable(_strokes),
        viewportWidth: widget.canvasWidth,
        viewportHeight: widget.canvasHeight,
      ),
    );
  }

  void _onPointerDown(PointerDownEvent event) {
    _pointers[event.pointer] = event.localPosition;

    if (_pointers.length >= 2) {
      _isPinching = true;
      _activeStroke = null;
      final pts = _pointers.values.toList();
      _pinchStartDistance = (pts[0] - pts[1]).distance;
      _pinchStartScale = _scale;
      _pinchFocal = Offset(
        (pts[0].dx + pts[1].dx) / 2,
        (pts[0].dy + pts[1].dy) / 2,
      );
      return;
    }

    if (!_isPinching) {
      final pt = _toCanvasSpace(event.localPosition);
      setState(() {
        _activeStroke = DrawingStroke(
          color: widget.effectiveStrokeColor,
          width: 3 / _scale,
          points: [DrawingPoint(pt.dx, pt.dy)],
        );
      });
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    _pointers[event.pointer] = event.localPosition;

    if (_pointers.length >= 2) {
      final pts = _pointers.values.toList();
      final dist = (pts[0] - pts[1]).distance;
      if (_pinchStartDistance != null && _pinchStartDistance! > 0) {
        final nextScale =
            (_pinchStartScale * (dist / _pinchStartDistance!)).clamp(0.5, 4.0);
        final ratio = nextScale / _scale;
        setState(() {
          _scale = nextScale;
          _offset = Offset(
            _pinchFocal.dx - ratio * (_pinchFocal.dx - _offset.dx),
            _pinchFocal.dy - ratio * (_pinchFocal.dy - _offset.dy),
          );
        });
      }
      return;
    }

    if (_isPinching || _activeStroke == null) return;

    final pt = _toCanvasSpace(event.localPosition);
    setState(() {
      final points = List<DrawingPoint>.from(_activeStroke!.points)
        ..add(DrawingPoint(pt.dx, pt.dy));
      _activeStroke = DrawingStroke(
        color: _activeStroke!.color,
        width: _activeStroke!.width,
        points: points,
      );
    });
  }

  void _onPointerUp(PointerUpEvent event) {
    _pointers.remove(event.pointer);
    if (_pointers.isEmpty) {
      _isPinching = false;
      _pinchStartDistance = null;
      if (_activeStroke != null) {
        setState(() {
          _strokes.add(_activeStroke!);
          _activeStroke = null;
          _notify();
        });
      }
      return;
    }
    if (_pointers.length < 2) {
      _pinchStartDistance = null;
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _pointers.remove(event.pointer);
    _activeStroke = null;
    _isPinching = false;
    _pinchStartDistance = null;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.canvasWidth,
      height: widget.canvasHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _onPointerDown,
          onPointerMove: _onPointerMove,
          onPointerUp: _onPointerUp,
          onPointerCancel: _onPointerCancel,
          child: Stack(
            children: [
              Transform(
                transform: Matrix4.identity()
                  ..translate(_offset.dx, _offset.dy)
                  ..scale(_scale),
                child: CustomPaint(
                  size: Size(widget.canvasWidth, widget.canvasHeight),
                  painter: _CanvasPainter(
                    strokes: _strokes,
                    activeStroke: _activeStroke,
                  ),
                ),
              ),
              if (_scale != 1)
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.selectedColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${(_scale * 100).round()}%',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textColor2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CanvasPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final DrawingStroke? activeStroke;

  _CanvasPainter({required this.strokes, this.activeStroke});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );

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

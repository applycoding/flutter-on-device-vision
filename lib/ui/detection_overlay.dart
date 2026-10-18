import 'package:flutter/material.dart';
import 'package:on_device_vision/domain/detection.dart';
import 'package:on_device_vision/ui/theme.dart';

class DetectionOverlay extends StatelessWidget {
  const DetectionOverlay({
    required this.detections,
    required this.child,
    this.inferenceTime,
    this.fps,
    this.modelName,
    super.key,
  });

  final List<Detection> detections;
  final Widget child;
  final Duration? inferenceTime;
  final double? fps;
  final String? modelName;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        child,
        CustomPaint(
          painter: _BoxPainter(detections),
          child: const SizedBox.expand(),
        ),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return Stack(
              children: <Widget>[
                for (final Detection detection in detections)
                  Positioned(
                    left: detection.left * constraints.maxWidth,
                    top: (detection.top * constraints.maxHeight - 22).clamp(
                      0,
                      constraints.maxHeight,
                    ),
                    child: _Label(detection: detection),
                  ),
              ],
            );
          },
        ),
        Positioned(
          left: 12,
          top: 12,
          right: 12,
          child: _Hud(
            inferenceTime: inferenceTime,
            fps: fps,
            modelName: modelName,
            count: detections.length,
          ),
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.detection});

  final Detection detection;

  @override
  Widget build(BuildContext context) {
    final int percent = (detection.confidence * 100).round();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xE6121611),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          '${detection.label} $percent%',
          style: const TextStyle(
            color: visionAccent,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _Hud extends StatelessWidget {
  const _Hud({
    required this.inferenceTime,
    required this.fps,
    required this.modelName,
    required this.count,
  });

  final Duration? inferenceTime;
  final double? fps;
  final String? modelName;
  final int count;

  @override
  Widget build(BuildContext context) {
    final String timing = inferenceTime == null
        ? 'waiting'
        : '${inferenceTime!.inMilliseconds} ms';
    final String rate = fps == null ? '0 fps' : '${fps!.round()} fps';
    return Align(
      alignment: Alignment.topLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xCC121611),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: visionLine),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: DefaultTextStyle(
            style: const TextStyle(color: Colors.white, fontSize: 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  'On-Device Vision',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text('$timing  ·  $rate  ·  $count boxes'),
                if (modelName != null)
                  Text(
                    modelName!,
                    style: const TextStyle(color: visionMuted, fontSize: 12),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BoxPainter extends CustomPainter {
  _BoxPainter(this.detections);

  final List<Detection> detections;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = visionAccent;
    for (final Detection detection in detections) {
      canvas.drawRect(
        Rect.fromLTRB(
          detection.left * size.width,
          detection.top * size.height,
          detection.right * size.width,
          detection.bottom * size.height,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BoxPainter oldDelegate) => true;
}

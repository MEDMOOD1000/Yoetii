import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'yoeti_plan.dart';

Color planCategoryColor(BuildContext context, String category) {
  final scheme = Theme.of(context).colorScheme;
  return switch (category) {
    'Work / School' => scheme.primary,
    'Deep Study' => scheme.tertiary,
    'Workout' => const Color(0xFF19AE87),
    'Personal' => const Color(0xFFE85472),
    'Sleep' => scheme.secondary,
    _ => const Color(0xFFFFA726),
  };
}

class DayDial extends StatefulWidget {
  const DayDial({
    super.key,
    required this.blocks,
    this.size = 296,
    this.start,
    this.end,
    this.onRangeChanged,
    this.rotation = 0,
    this.centerLabel,
  });
  final List<PlanBlock> blocks;
  final double size;
  final int? start;
  final int? end;
  final void Function(int start, int end)? onRangeChanged;
  final double rotation;
  final String? centerLabel;
  @override
  State<DayDial> createState() => _DayDialState();
}

class _DayDialState extends State<DayDial> {
  bool _movingStart = false;
  int _minute(Offset point) {
    final center = widget.size / 2;
    final angle =
        (math.atan2(point.dy - center, point.dx - center) +
            math.pi / 2 +
            math.pi * 2) %
        (math.pi * 2);
    return ((angle / (math.pi * 2) * 96).round() % 96) * 15;
  }

  void _begin(Offset point) {
    if (widget.onRangeChanged == null) return;
    final minute = _minute(point);
    int distance(int a, int b) => math.min((a - b).abs(), 1440 - (a - b).abs());
    _movingStart =
        distance(minute, widget.start ?? 540) <=
        distance(minute, widget.end ?? 600);
    _change(point);
  }

  void _change(Offset point) {
    final callback = widget.onRangeChanged;
    if (callback == null) return;
    final minute = _minute(point);
    if (_movingStart) {
      callback(minute.clamp(0, (widget.end ?? 600) - 15), widget.end ?? 600);
    } else {
      callback(
        widget.start ?? 540,
        (minute == 0 ? 1440 : minute).clamp((widget.start ?? 540) + 15, 1440),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: widget.onRangeChanged == null
            ? null
            : (d) => _begin(d.localPosition),
        onPanUpdate: widget.onRangeChanged == null
            ? null
            : (d) => _change(d.localPosition),
        onTapDown: widget.onRangeChanged == null
            ? null
            : (d) => _begin(d.localPosition),
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size.square(widget.size),
              painter: _DialPainter(
                background: scheme.surfaceContainerHighest,
                foreground: scheme.onSurface,
                accent: scheme.primary,
                blocks: widget.blocks,
                blockColors: [
                  for (final b in widget.blocks)
                    planCategoryColor(context, b.category),
                ],
                start: widget.start,
                end: widget.end,
                rotation: widget.rotation,
              ),
            ),
            IgnorePointer(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.centerLabel ?? '24 HOURS',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      letterSpacing: 2,
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    widget.start == null
                        ? planTime(
                            DateTime.now().hour * 60 + DateTime.now().minute,
                          )
                        : planTime(widget.start!) +
                              ' – ' +
                              planTime(widget.end!),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                  if (widget.start != null)
                    Text(
                      _duration(widget.end! - widget.start!),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _duration(int minutes) => minutes ~/ 60 == 0
    ? (minutes % 60).toString() + ' min'
    : (minutes ~/ 60).toString() +
          'h ' +
          (minutes % 60 == 0 ? '' : (minutes % 60).toString() + 'm');

class _DialPainter extends CustomPainter {
  const _DialPainter({
    required this.background,
    required this.foreground,
    required this.accent,
    required this.blocks,
    required this.blockColors,
    required this.start,
    required this.end,
    required this.rotation,
  });
  final Color background, foreground, accent;
  final List<PlanBlock> blocks;
  final List<Color> blockColors;
  final int? start, end;
  final double rotation;
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 26;
    final ring = Rect.fromCircle(center: center, radius: radius - 17);
    final base = Paint()
      ..color = background
      ..style = PaintingStyle.stroke
      ..strokeWidth = 25;
    canvas.drawCircle(center, radius - 17, base);
    for (var hour = 0; hour < 96; hour++) {
      final angle = -math.pi / 2 + hour * math.pi * 2 / 96 + rotation;
      final major = hour % 12 == 0;
      final inner = radius + (major ? 2 : 6);
      final outer = radius + 11;
      canvas.drawLine(
        center + Offset(math.cos(angle) * inner, math.sin(angle) * inner),
        center + Offset(math.cos(angle) * outer, math.sin(angle) * outer),
        Paint()
          ..color = foreground.withValues(alpha: major ? .72 : .25)
          ..strokeWidth = major ? 1.7 : .8,
      );
    }
    for (var i = 0; i < blocks.length; i++) {
      final b = blocks[i];
      canvas.drawArc(
        ring,
        -math.pi / 2 + b.start / 1440 * math.pi * 2 + rotation,
        (b.end - b.start) / 1440 * math.pi * 2,
        false,
        Paint()
          ..color = blockColors[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 25
          ..strokeCap = StrokeCap.round,
      );
    }
    if (start != null && end != null) {
      final sweep = (end! - start!) / 1440 * math.pi * 2;
      canvas.drawArc(
        ring,
        -math.pi / 2 + start! / 1440 * math.pi * 2,
        sweep,
        false,
        Paint()
          ..color = accent.withValues(alpha: .65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 26
          ..strokeCap = StrokeCap.round,
      );
      for (final minute in [start!, end!]) {
        final angle = -math.pi / 2 + minute / 1440 * math.pi * 2;
        final p =
            center +
            Offset(
              math.cos(angle) * (radius - 17),
              math.sin(angle) * (radius - 17),
            );
        canvas.drawCircle(p, 13, Paint()..color = accent);
        canvas.drawCircle(p, 4, Paint()..color = foreground);
      }
    } else if (rotation == 0) {
      final now = DateTime.now();
      final angle =
          -math.pi / 2 + (now.hour * 60 + now.minute) / 1440 * math.pi * 2;
      canvas.drawLine(
        center +
            Offset(
              math.cos(angle) * (radius - 40),
              math.sin(angle) * (radius - 40),
            ),
        center +
            Offset(
              math.cos(angle) * (radius + 9),
              math.sin(angle) * (radius + 9),
            ),
        Paint()
          ..color = accent
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );
    }
    for (var hour = 0; hour < 24; hour += 3) {
      final angle = -math.pi / 2 + hour / 24 * math.pi * 2 + rotation;
      final p =
          center +
          Offset(
            math.cos(angle) * (radius + 19),
            math.sin(angle) * (radius + 19),
          );
      final tp = TextPainter(
        text: TextSpan(
          text: hour.toString().padLeft(2, '0'),
          style: TextStyle(
            color: foreground.withValues(alpha: .72),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
      tp.dispose();
    }
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.blocks != blocks ||
      old.start != start ||
      old.end != end ||
      old.rotation != rotation ||
      old.background != background ||
      old.accent != accent;
}

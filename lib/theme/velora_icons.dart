import 'package:flutter/material.dart';

/// Custom Painter for the Velora Geometric Wheat / Palm / Sunburst Brand Icon
class VeloraLogoPainter extends CustomPainter {
  final Color color;
  VeloraLogoPainter({this.color = const Color(0xFFF59E0B)});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;
    final bottomCenter = Offset(w / 2, h * 0.95);

    // Center stem & vertical leaf
    canvas.drawLine(bottomCenter, Offset(w / 2, h * 0.1), paint);

    // Left fan leaves
    canvas.drawLine(bottomCenter, Offset(w * 0.28, h * 0.22), paint);
    canvas.drawLine(bottomCenter, Offset(w * 0.12, h * 0.45), paint);
    canvas.drawLine(bottomCenter, Offset(w * 0.05, h * 0.72), paint);

    // Right fan leaves
    canvas.drawLine(bottomCenter, Offset(w * 0.72, h * 0.22), paint);
    canvas.drawLine(bottomCenter, Offset(w * 0.88, h * 0.45), paint);
    canvas.drawLine(bottomCenter, Offset(w * 0.95, h * 0.72), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom Painter for the Velora Pulpit / Lectern / Altar Navigation Icon (Screenshot 1)
class VeloraPulpitPainter extends CustomPainter {
  final Color color;
  final bool glow;

  VeloraPulpitPainter({
    this.color = const Color(0xFFD4AF37),
    this.glow = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    if (glow) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      _drawPulpit(canvas, w, h, glowPaint);
    }

    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    _drawPulpit(canvas, w, h, strokePaint);
  }

  void _drawPulpit(Canvas canvas, double w, double h, Paint paint) {
    // Top desk rim / slant
    final topDeskPath = Path();
    topDeskPath.moveTo(w * 0.18, h * 0.28);
    topDeskPath.lineTo(w * 0.82, h * 0.28);
    topDeskPath.lineTo(w * 0.72, h * 0.48);
    topDeskPath.lineTo(w * 0.28, h * 0.48);
    topDeskPath.close();
    canvas.drawPath(topDeskPath, paint);

    // Top open book / microphone cue on top
    final micPath = Path();
    micPath.moveTo(w * 0.44, h * 0.28);
    micPath.lineTo(w * 0.44, h * 0.12);
    micPath.lineTo(w * 0.56, h * 0.12);
    canvas.drawPath(micPath, paint);

    // Center vertical column / stand
    canvas.drawLine(Offset(w * 0.42, h * 0.48), Offset(w * 0.42, h * 0.95), paint);
    canvas.drawLine(Offset(w * 0.58, h * 0.48), Offset(w * 0.58, h * 0.95), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom Painter for the Velora Quote Badge [99] (Screenshot 5)
class VeloraQuoteBadgePainter extends CustomPainter {
  final Color color;
  VeloraQuoteBadgePainter({this.color = const Color(0xFFFBBF24)});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // First quote mark 9
    canvas.drawCircle(Offset(w * 0.35, h * 0.38), w * 0.18, fillPaint);
    final tail1 = Path()
      ..moveTo(w * 0.48, h * 0.38)
      ..quadraticBezierTo(w * 0.48, h * 0.72, w * 0.25, h * 0.82);
    canvas.drawPath(tail1, paint);

    // Second quote mark 9
    canvas.drawCircle(Offset(w * 0.72, h * 0.38), w * 0.18, fillPaint);
    final tail2 = Path()
      ..moveTo(w * 0.85, h * 0.38)
      ..quadraticBezierTo(w * 0.85, h * 0.72, w * 0.62, h * 0.82);
    canvas.drawPath(tail2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

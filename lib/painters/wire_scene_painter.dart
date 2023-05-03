import 'package:flutter/material.dart';
import '../algorithms/types.dart';

class WireScenePainter extends CustomPainter {
  final List<Section> sections;

  WireScenePainter({required this.sections});

  @override
  void paint(Canvas canvas, Size size) {
    var linePaint = Paint()
      ..color = Colors.black87
      ..isAntiAlias=true
      ..strokeWidth = 1;
    for (Section s in sections) {
      canvas.drawLine(
          Offset(s.start.x, s.start.y), Offset(s.end.x, s.end.y), linePaint);
      // print(s);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

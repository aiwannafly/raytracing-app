import 'package:flutter/material.dart';
import 'package:icg_raytracing/config/widget_config.dart';
import '../algorithms/types.dart';

class WireScenePainter extends CustomPainter {
  final List<Section> sections;

  WireScenePainter({required this.sections});

  @override
  void paint(Canvas canvas, Size size) {
    var linePaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1;
    // var dotPaint = Paint()
    //   ..color = WidgetConfig.primaryColor
    //   ..strokeWidth = 3;
    // print(sections.length);
    for (Section s in sections) {
      // canvas.drawCircle(Offset(s.start.x, s.start.y), 3, dotPaint);
      // canvas.drawCircle(Offset(s.end.x, s.end.y), 1, dotPaint);
      canvas.drawLine(
          Offset(s.start.x, s.start.y), Offset(s.end.x, s.end.y), linePaint);
      // print('${s.start.x} ${s.start.y} ${s.start.z}');
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

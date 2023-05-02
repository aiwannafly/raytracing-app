import 'dart:math';

import 'package:icg_raytracing/algorithms/types.dart';
import 'figure.dart';

class Sphere extends Figure {
  Point3D center;
  double radius;

  Sphere(
      {required this.center,
      required this.radius,
        required Optics optics})
      : super(optics: optics) {
    minPos = Point3D(center.x - radius, center.y - radius, center.z - radius);
    maxPos = Point3D(center.x + radius, center.y + radius, center.z + radius);
    const int stride = 15;
    const int indFreq = stride ~/ 5;
    double step = 2 * pi / stride;
    for (int i = 0; i < stride / 2; i++) {
      double angleZ = step * i;
      double y = radius * cos(angleZ);
      List<Point3D> points = [];
      for (int j = 0; j <= stride; j++) {
        double angle = step * j;
        double x = radius * cos(angle) * sin(angleZ);
        double z = radius * sin(angle) * sin(angleZ);
        points.add(center + Point3D(x, y, z));
        if (j % indFreq == 0) {
          indicators.add(center + Point3D(x, y, z));
        }
      }
      for (int k = 0; k < points.length; k++) {
        int next = (k + 1) % points.length;
        sections.add(Section(points[k], points[next]));
      }
    }
    for (int i = 0; i < stride / 2; i++) {
      double angleX = step * i;
      double x = radius * cos(angleX);
      List<Point3D> points = [];
      for (int j = 0; j < stride; j++) {
        double angle = step * j;
        double z = radius * cos(angle) * sin(angleX);
        double y = radius * sin(angle) * sin(angleX);
        points.add(center + Point3D(x, y, z));
        if (j % indFreq == 0) {
          indicators.add(center + Point3D(x, y, z));
        }
      }
      for (int k = 0; k < points.length; k++) {
        int next = (k + 1) % points.length;
        sections.add(Section(points[k], points[next]));
      }
    }
    for (int i = 0; i < stride / 2; i++) {
      double angleX = step * i;
      double z = radius * cos(angleX);
      List<Point3D> points = [];
      for (int j = 0; j < stride; j++) {
        double angle = step * j;
        double x = radius * cos(angle) * sin(angleX);
        double y = radius * sin(angle) * sin(angleX);
        points.add(center + Point3D(x, y, z));
        if (j % indFreq == 0) {
          indicators.add(center + Point3D(x, y, z));
        }
      }
      for (int k = 0; k < points.length; k++) {
        int next = (k + 1) % points.length;
        sections.add(Section(points[k], points[next]));
      }
    }
  }
}

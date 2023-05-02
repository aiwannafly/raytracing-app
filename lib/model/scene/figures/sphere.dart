import 'dart:math';

import 'package:icg_raytracing/algorithms/types.dart';
import 'figure.dart';

class Sphere extends Figure {
  Point3D center;
  double radius;

  Sphere(
      {required this.center,
      required this.radius,
      required Point3D diffusionCoeffs,
      required Point3D sightCoeffs,
      required int reflectPower})
      : super(
            diffusionCoeffs: diffusionCoeffs,
            sightCoeffs: sightCoeffs,
            reflectPower: reflectPower) {
    minPos = Point3D(center.x - radius, center.y - radius, center.z - radius);
    maxPos = Point3D(center.x + radius, center.y + radius, center.z + radius);
    const int stride = 15;
    double step = 2 * pi / stride;
    for (int i = 1; i < stride; i++) {
      double angleZ = step * i;
      double y = radius * cos(angleZ);
      List<Point3D> points = [];
      for (int j = 0; j < stride; j++) {
        double angle = step * j;
        double z = radius * cos(angle) * sin(angleZ);
        double x = radius * sin(angle) * sin(angleZ);
        points.add(center + Point3D(x, y, z));
      }
      for (int i = 0; i < points.length; i++) {
        int next = (i + 1) % points.length;
        sections.add(Section(points[i], points[next]));
      }
    }
    for (int i = 1; i < stride; i++) {
      double angleX = step * i;
      double x = radius * cos(angleX);
      List<Point3D> points = [];
      for (int j = 0; j < stride; j++) {
        double angle = step * j;
        double z = radius * cos(angle) * sin(angleX);
        double y = radius * sin(angle) * sin(angleX);
        points.add(center + Point3D(x, y, z));
      }
      for (int i = 0; i < points.length; i++) {
        int next = (i + 1) % points.length;
        sections.add(Section(points[i], points[next]));
      }
    }
    for (int i = 1; i < stride; i++) {
      double angleX = step * i;
      double z = radius * cos(angleX);
      List<Point3D> points = [];
      for (int j = 0; j < stride; j++) {
        double angle = step * j;
        double x = radius * cos(angle) * sin(angleX);
        double y = radius * sin(angle) * sin(angleX);
        points.add(center + Point3D(x, y, z));
      }
      for (int i = 0; i < points.length; i++) {
        int next = (i + 1) % points.length;
        sections.add(Section(points[i], points[next]));
      }
    }
  }
}

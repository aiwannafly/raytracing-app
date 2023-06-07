import 'dart:math';

import 'package:icg_raytracing/algorithms/types.dart';
import 'package:icg_raytracing/model/scene/figures/plane.dart';

import 'figure.dart';

class Triangle extends Figure {
  Point3D first;
  Point3D second;
  Point3D third;
  late double area;
  late Plane plane;

  Triangle(
      {required this.first,
      required this.second,
      required this.third,
        required Optics optics})
      : super(optics: optics) {
    double minZ = min(first.z, min(second.z, third.z));
    double minX = min(first.x, min(second.x, third.x));
    double minY = min(first.y, min(second.y, third.y));
    double maxZ = max(first.z, max(second.z, third.z));
    double maxX = max(first.x, max(second.x, third.x));
    double maxY = max(first.y, max(second.y, third.y));
    minPos = Point3D(minX, minY, minZ);
    maxPos = Point3D(maxX, maxY, maxZ);
    indicators.addAll([first, second, third]);
    sections.addAll(split([
      Section(first, second),
      Section(second, third),
      Section(third, first),
    ]));
    area = _getTriangleArea(first, second, third);
    plane = Plane.fromDots(first, second, third);
  }

  @override
  String toString() {
    return 'QUADRANGLE $first\n$second\n$third\n$optics';
  }

  @override
  Intersection? intersect({required Point3D rayStart, required Point3D rayDir}) {
    double? t = plane.intersect(rayStart: rayStart, rayDir: rayDir);
    if (t == null) {
      return null;
    }
    var pos = rayStart + rayDir * t;
    double alpha = _getTriangleArea(second, third, pos);
    double beta = _getTriangleArea(first, third, pos);
    double gamma = _getTriangleArea(second, first, pos);
    const epsilon = 0.0001;
    if (alpha + beta + gamma > area + epsilon) {
      return null;
    }
    Point3D normal = plane.normal;
    if (rayDir.scalarDot(normal) >= 0) {
      normal = -normal;
    }
    return Intersection(pos: pos, normal: normal, t: t);
  }

  double _getTriangleArea(Point3D a, Point3D b, Point3D c) {
   return (c - a).vectorMul(b - a).norm() / 2;
  }

  @override
  void shift(Point3D delta) {
    super.shift(delta);
    first -= delta;
    second -= delta;
    third -= delta;
    plane = Plane.fromDots(first, second, third);
  }
}

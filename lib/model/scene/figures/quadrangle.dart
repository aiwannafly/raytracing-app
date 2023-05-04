import 'dart:math';

import 'package:icg_raytracing/algorithms/types.dart';
import 'package:icg_raytracing/model/scene/figures/plane.dart';

import 'figure.dart';

class Quadrangle extends Figure {
  Point3D first;
  Point3D second;
  Point3D third;
  Point3D fourth;
  late Plane plane;

  Quadrangle(
      {required this.first,
      required this.second,
      required this.third,
      required this.fourth,
      required Optics optics})
      : super(optics: optics) {
    double minZ = min(first.z, min(second.z, min(third.z, fourth.z)));
    double minX = min(first.x, min(second.x, min(third.x, fourth.x)));
    double minY = min(first.y, min(second.y, min(third.y, fourth.y)));
    double maxZ = max(first.z, max(second.z, max(third.z, fourth.z)));
    double maxX = max(first.x, max(second.x, max(third.x, fourth.x)));
    double maxY = max(first.y, max(second.y, max(third.y, fourth.y)));
    minPos = Point3D(minX, minY, minZ);
    maxPos = Point3D(maxX, maxY, maxZ);
    indicators.addAll([first, second, third, fourth]);
    sections.addAll(split([
      Section(first, second),
      Section(second, third),
      Section(third, fourth),
      Section(fourth, first)
    ]));
    plane = Plane.fromDots(first, second, third);
  }

  @override
  void shift(Point3D delta) {
    super.shift(delta);
    first -= delta;
    second -= delta;
    third -= delta;
    fourth -= delta;
    plane = Plane.fromDots(first, second, third);
  }

  @override
  Intersection? intersect({required Point3D rayStart, required Point3D rayDir}) {
    return null;
    double? t = plane.intersect(rayStart: rayStart, rayDir: rayDir);
    if (t == null) {
      return null;
    }
    Point3D pos = rayStart + rayDir * t;
    bool inside = pos >= minPos && pos <= maxPos;
    if (!inside) {
      return null;
    }
    Point3D normal = plane.normal;
    if (rayDir.scalarDot(normal) >= 0) {
      normal = -normal;
    }
    return Intersection(pos: pos, normal: normal);
  }
}

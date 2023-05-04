import 'dart:math';

import 'package:icg_raytracing/algorithms/types.dart';

import 'figure.dart';

class Triangle extends Figure {
  Point3D first;
  Point3D second;
  Point3D third;

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
  }

  @override
  Intersection? intersect({required Point3D rayStart, required Point3D rayDir}) {
    return null;
  }
}

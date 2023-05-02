import 'package:icg_raytracing/algorithms/types.dart';

import 'figure.dart';

class Box extends Figure {
  List<Point3D> points = [];

  Box({required Point3D minPos, required Point3D maxPos, required Point3D diffusionCoeffs,
    required Point3D sightCoeffs, required int reflectPower})
      : super(diffusionCoeffs: diffusionCoeffs, sightCoeffs: sightCoeffs, reflectPower: reflectPower) {
    this.minPos = minPos;
    this.maxPos = maxPos;
    assert(minPos.x < maxPos.x);
    assert(minPos.y < maxPos.y);
    assert(minPos.z < maxPos.z);
    for (int z = 0; z < 2; z++) {
      for (int y = 0; y < 2; y++) {
        for (int x = 0; x < 2; x++) {
          points.add(Point3D(x == 0 ? minPos.x : maxPos.x,
              y == 0 ? minPos.y : maxPos.y, z == 0 ? minPos.z : maxPos.z));
        }
      }
    }
    sections.addAll(split(sectionsFromPoints(points)));
  }

  List<Section> sectionsFromPoints(List<Point3D> points) {
    List<Section> result = [];
    assert(points.length.isEven);
    if (points.length == 2) {
      result.add(Section(points.first, points.last));
      return result;
    }
    List<Point3D> firstPart = points.sublist(0, points.length ~/ 2);
    List<Point3D> secondPart = points.sublist(points.length ~/ 2);
    result.addAll(sectionsFromPoints(firstPart));
    result.addAll(sectionsFromPoints(secondPart));
    for (int i = 0; i < points.length ~/ 2; i++) {
      result.add(Section(firstPart[i], secondPart[i]));
    }
    return result;
  }
}

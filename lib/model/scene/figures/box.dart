import 'dart:math';

import 'package:icg_raytracing/algorithms/types.dart';
import 'package:icg_raytracing/model/scene/figures/plane.dart';

import 'figure.dart';

class Box extends Figure {
  List<Point3D> points = [];
  List<Plane> planes = [];

  Box(
      {required Point3D minPos,
      required Point3D maxPos,
      required Optics optics})
      : super(optics: optics) {
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
    initPlanes();
    indicators.addAll(points);
    sections.addAll(split(sectionsFromPoints(points)));
  }

  @override
  void shift(Point3D delta) {
    super.shift(delta);
    for (int i = 0; i < points.length; i++) {
      points[i] -= delta;
    }
    initPlanes();
  }

  void initPlanes() {
    assert(points.length == 8);
    planes.clear();
    planes.add(Plane.fromDots(points[0], points[1], points[2]));
    planes.add(Plane.fromDots(points[0], points[1], points[4]));
    planes.add(Plane.fromDots(points[7], points[6], points[5]));
    planes.add(Plane.fromDots(points[7], points[3], points[2]));
    planes.add(Plane.fromDots(points[1], points[3], points[5]));
    planes.add(Plane.fromDots(points[0], points[2], points[4]));
    // for (Plane plane in planes) {
    //   print('${plane.normal} ${plane.d}');
    // }
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

  @override
  Intersection? intersect({required Point3D rayStart, required Point3D rayDir}) {
    if (!_doesIntersect(rayStart: rayStart, rayDir: rayDir)) {
      return null;
    }
    List<double?> planeInts = [];
    for (int i = 0; i < planes.length; i++) {
      planeInts.add(planes[i].intersect(rayStart: rayStart, rayDir: rayDir));
    }
    for (int i = 0; i < planes.length; i++) {
      if (planeInts[i] == null) {
        continue;
      }
      if (!_isInside(rayStart + rayDir * planeInts[i]!)) {
        planeInts[i] = null;
      }
    }
    double minT = double.infinity;
    int idx = -1;
    for (int i = 0; i < planes.length; i++) {
      if (planeInts[i] == null) {
        continue;
      }
      // print('${rayStart + rayDir * planeInts[i]!}');
      if (planeInts[i]! < minT) {
        minT = planeInts[i]!;
        idx = i;
      }
    }
    if (idx < 0) {
      return null;
    }
    assert(idx >= 0);
    Point3D pos = rayStart + rayDir * minT;
    Point3D normal = planes[idx].normal;
    if (rayDir.scalarDot(normal) >= 0) {
      normal = -normal;
    }
    // print('pos: $pos, normal: $normal');
    return Intersection(pos: pos, normal: normal, t: minT);
  }

  bool _isInside(Point3D p) {
    final epsilon = Point3D(0.001, 0.001, 0.001);
    return p >= minPos - epsilon && p <= maxPos + epsilon;
  }

  bool _doesIntersect({required Point3D rayStart, required Point3D rayDir}) {
    bool checkX = _doesIntersectPlanes(
        coordStart: rayStart.x,
        coordDir: rayDir.x,
        minCoord: minPos.x,
        maxCoord: maxPos.x);
    if (!checkX) {
      return false;
    }
    bool checkY = _doesIntersectPlanes(
        coordStart: rayStart.y,
        coordDir: rayDir.y,
        minCoord: minPos.y,
        maxCoord: maxPos.y);
    if (!checkY) {
      return false;
    }
    bool checkZ = _doesIntersectPlanes(
        coordStart: rayStart.z,
        coordDir: rayDir.z,
        minCoord: minPos.z,
        maxCoord: maxPos.z);
    if (!checkZ) {
      return false;
    }
    return true;
  }

  bool _doesIntersectPlanes(
      {required double coordStart,
      required double coordDir,
      required double minCoord,
      required double maxCoord}) {
    double tNear = double.negativeInfinity;
    double tFar = double.infinity;
    if (coordDir == 0) {
      return (coordStart >= minCoord && coordStart <= maxCoord);
    }
    double t1 = (minCoord - coordStart) / coordDir;
    double t2 = (maxCoord - coordStart) / coordDir;
    if (t2 < t1) {
      double temp = t2;
      t2 = t1;
      t1 = temp;
    }
    if (t1 > tNear) {
      tNear = t1;
    }
    if (t2 < tFar) {
      tFar = t2;
    }
    if (tNear > tFar) {
      return false;
    }
    if (tFar < 0) {
      return false;
    }
    return true;
  }
}

import 'package:icg_raytracing/algorithms/types.dart';

class Plane {
  late Point3D normal;
  late double d;

  Plane({required this.normal, required this.d});

  Plane.fromDots(Point3D p1, Point3D p2, Point3D p3) {
    Point3D dir1 = p1 - p2;
    Point3D dir2 = p3 - p2;
    if (dir1.isZero() || dir2.isZero()) {
      throw "p1, p2, p3 don't make a plane";
    }
    Point3D normal = dir1.vectorMul(dir2);
    if (normal.isZero()) {
      throw "p1, p2, p3 don't make a plane";
    }
    this.normal = normal / normal.norm();
    // print(p1);
    d = -this.normal.scalarDot(p1);
  }

  double? intersect({required Point3D rayStart, required Point3D rayDir}) {
    double vd = normal.scalarDot(rayDir);
    if (vd == 0) {
      // parallel
      return null;
    }
    double v0 = -normal.scalarDot(rayStart) - d;
    double t = v0 / vd;
    if (t < 0) {
      return null;
    }
    return t;
  }

  Point3D? intersectNormal({required Point3D rayStart, required Point3D rayDir}) {
    return null;
  }

}

import 'dart:math';

class IntPoint2D {
  int x;
  int y;

  IntPoint2D(this.x, this.y);
}

class Point2D {
  double x;
  double y;

  Point2D(this.x, this.y);
}

class Point3D {
  double x;
  double y;
  double z;

  Point3D(this.x, this.y, this.z);

  @override
  String toString() {
    return "$x $y $z";
  }

  bool isZero() {
    return x == 0 && y == 0 && z == 0;
  }

  bool isBetween(Point3D a, Point3D b) {
    Point3D minPos = a;
    Point3D maxPos = b;
    minPos.x = min(a.x, b.x);
    minPos.y = min(a.y, b.y);
    minPos.z = min(a.z, b.z);
    maxPos.x = max(a.x, b.x);
    maxPos.y = max(a.y, b.y);
    maxPos.z = max(a.z, b.z);
    return minPos <= this && this <= maxPos;
  }

  Point3D operator +(Point3D o) {
    return Point3D(x + o.x, y + o.y, z + o.z);
  }

  Point3D operator -(Point3D o) {
    return Point3D(x - o.x, y - o.y, z - o.z);
  }

  Point3D operator *(double a) {
    return Point3D(x * a, y * a, z * a);
  }

  Point3D operator ^(double a) {
    return Point3D(pow(x, a) as double, pow(y, a) as double, pow(z, a) as double);
  }

  Point3D operator /(double a) {
    return Point3D(x / a, y / a, z / a);
  }

  bool operator >(Point3D o) {
    return x > o.x && y > o.y && z > o.z;
  }

  bool operator <(Point3D o) {
    return x < o.x && y < o.y && z < o.z;
  }

  bool operator >=(Point3D o) {
    return x >= o.x && y >= o.y && z >= o.z;
  }

  bool operator <=(Point3D o) {
    return x <= o.x && y <= o.y && z <= o.z;
  }

  Point3D operator -() {
    return Point3D(-x, -y, -z);
  }

  Point3D vectorMul(Point3D o) {
    return Point3D(y * o.z - z * o.y, z * o.x - x * o.z, x * o.y - y * o.x);
  }

  double scalarDot(Point3D o) {
    return x * o.x + y * o.y + z * o.z;
  }

  double norm() {
    return sqrt(x * x + y * y + z * z);
  }
}

class Section {
  Point3D start;
  Point3D end;

  Section(this.start, this.end);

  @override
  String toString() {
    return '($start, $end)';
  }
}

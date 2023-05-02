import 'dart:math';

import 'package:icg_raytracing/algorithms/types.dart';
import 'package:ml_linalg/matrix.dart';
import 'package:ml_linalg/vector.dart';

class Transform3D {
  Transform3D._internal();

  factory Transform3D() {
    return Transform3D._internal();
  }

  Matrix getScaleMatrix(
      {required double scaleX,
      required double scaleY,
      required double scaleZ}) {
    return Matrix.fromList([
      [scaleX, 0, 0, 0],
      [0, scaleY, 0, 0],
      [0, 0, scaleZ, 0],
      [0, 0, 0, 1]
    ]);
  }

  Matrix getRotationMatrixZ(double angle) {
    double sinA = sin(angle);
    double cosA = cos(angle);
    return Matrix.fromList([
      [cosA, -sinA, 0, 0],
      [sinA, cosA, 0, 0],
      [0, 0, 1, 0],
      [0, 0, 0, 1]
    ]);
  }

  Matrix getRotationMatrixX(double angle) {
    double sinA = sin(angle);
    double cosA = cos(angle);
    return Matrix.fromList([
      [1, 0, 0, 0],
      [0, cosA, -sinA, 0],
      [0, sinA, cosA, 0],
      [0, 0, 0, 1]
    ]);
  }

  Matrix getRotationMatrixY(double angle) {
    double sinA = sin(angle);
    double cosA = cos(angle);
    return Matrix.fromList([
      [cosA, 0, sinA, 0],
      [0, 1, 0, 0],
      [-sinA, 0, cosA, 0],
      [0, 0, 0, 1]
    ]);
  }

  Matrix getTranslationMatrix(
      {required double trX, required double trY, required double trZ}) {
    return Matrix.fromList([
      [1, 0, 0, trX],
      [0, 1, 0, trY],
      [0, 0, 1, trZ],
      [0, 0, 0, 1],
    ]);
  }

  Point3D applyMatrix(Point3D p, Matrix m) {
    Vector expanded = Vector.fromList([p.x, p.y, p.z, 1]);
    expanded = (m * expanded).columns.first;
    if (expanded.last != 1 && expanded.last != 0) {
      expanded = expanded / expanded.last;
    }
    return Point3D(expanded[0], expanded[1], expanded[2]);
  }

  Matrix getVisibleAreaMatrix(
      {required double zNear,
      required double zFar,
      required double sWidth,
      required double sHeight}) {
    double a = zFar / (zFar - zNear);
    double b = -zNear * zFar / (zFar - zNear);
    return Matrix.fromList([
      [2 * zNear / sWidth, 0, 0, 0],
      [0, 2 * zNear / sHeight, 0, 0],
      [0, 0, a, b],
      [0, 0, 1, 0]
    ]);
  }

  Matrix getCameraMatrix(
      {required Point3D eye, required Point3D view, required Point3D up}) {
    Point3D dir = eye - view;
    // print('dir: $dir');
    Point3D k = dir / dir.norm();
    Point3D I = up.vectorMul(k);
    Point3D i = I / I.norm();
    Point3D j = k.vectorMul(i);
    // print('i: $i, j: $j, k: $k');
    return Matrix.fromList([
      [i.x, i.y, i.z, 0],
      [j.x, j.y, j.z, 0],
      [k.x, k.y, k.z, 0],
      [0, 0, 0, 1]
    ]) * getTranslationMatrix(trX: -eye.x, trY: -eye.y, trZ: -eye.z);
    // return getTranslationMatrix(trX: -eye.x, trY: -eye.y, trZ: -eye.z);
  }
}

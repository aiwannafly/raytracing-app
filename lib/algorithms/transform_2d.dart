import 'package:icg_raytracing/algorithms/types.dart';
import 'package:ml_linalg/matrix.dart';
import 'package:ml_linalg/vector.dart';

class T2D {
  T2D._internal();

  factory T2D() {
    return T2D._internal();
  }

  Matrix getScaleMatrix({required double scaleX, required double scaleY}) {
    return Matrix.fromList([
      [scaleX, 0, 0],
      [0, scaleY, 0],
      [0, 0, 1],
    ]);
  }

  Matrix getTranslationMatrix({required double translateX, required double translateY}) {
    return Matrix.fromList([
      [1, 0, translateX],
      [0, 1, translateY],
      [0, 0, 1],
    ]);
  }

  Point2D applyMatrix(Point2D p, Matrix m) {
    Vector expanded = Vector.fromList([p.x, p.y, 1]);
    expanded = (m * expanded).columns.first;
    if (expanded.last != 1 && expanded.last != 0) {
      expanded = expanded / expanded.last;
    }
    return Point2D(expanded[0], expanded[1]);
  }

  List<Point2D> applyMatrixToAll(List<Point2D> points, Matrix m) {
    for (int i = 0; i < points.length; i++) {
      Vector expanded = Vector.fromList([points[i].x, points[i].y, 1]);
      expanded = (m * expanded).columns.first;
      if (expanded.last != 1 && expanded.last != 0) {
        expanded = expanded / expanded.last;
      }
      points[i].x = expanded[0];
      points[i].y = expanded[1];
    }
    return points;
  }
}

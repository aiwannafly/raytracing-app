import 'package:icg_raytracing/algorithms/types.dart';

class Optics {
  Point3D diff;
  Point3D sight;
  int power;

  Optics({required this.diff, required this.sight, required this.power});
}

abstract class Figure {
  final Optics optics;
  final List<Section> sections = [];
  final List<Point3D> indicators = [];
  late Point3D minPos;
  late Point3D maxPos;

  Figure({required this.optics});

  Point3D? intersect({required Point3D rayStart, required Point3D rayDir});

  Point3D? intersectNormal({required Point3D rayStart, required Point3D rayDir});

  List<Section> split(List<Section> baseSections, [double stride = 20]) {
    List<Section> sections = [];
    for (Section base in baseSections) {
      Point3D part = (base.end - base.start) / stride;
      for (double i = 0; i < stride; i++) {
        sections.add(Section(base.start + part * i, base.start + part * (i + 1)));
      }
    }
    return sections;
  }

  void shift(Point3D delta) {
    maxPos -= delta;
    minPos -= delta;
    for (Section s in sections) {
      s.start -= delta;
      s.end -= delta;
    }
  }
}

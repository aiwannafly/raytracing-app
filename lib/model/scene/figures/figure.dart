import 'package:icg_raytracing/algorithms/types.dart';

abstract class Figure {
  final Point3D diffusionCoeffs;
  final Point3D sightCoeffs;
  final int reflectPower;
  final List<Section> sections = [];
  late Point3D minPos;
  late Point3D maxPos;

  Figure({required this.diffusionCoeffs, required this.sightCoeffs, required this.reflectPower});

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
}

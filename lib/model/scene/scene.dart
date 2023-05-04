import 'package:icg_raytracing/algorithms/types.dart';

import 'figures/figure.dart';
import 'light_source.dart';

class Scene {
  final List<Figure> figures;
  final List<LightSource> lightSources;
  final Point3D ambient;

  Scene({required this.figures, required this.lightSources, required this.ambient});
}

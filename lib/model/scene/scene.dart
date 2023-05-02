import 'package:icg_raytracing/algorithms/types.dart';

import 'figures/figure.dart';
import 'light_source.dart';

class Scene {
  final List<Figure> objects;
  final List<LightSource> lightSources;
  final Point3D ambientColor;

  Scene({required this.objects, required this.lightSources, required this.ambientColor});
}

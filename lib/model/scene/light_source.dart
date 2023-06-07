import 'package:icg_raytracing/algorithms/types.dart';

import '../../algorithms/rgb.dart';

class LightSource {
  Point3D pos;
  final Point3D color;

  LightSource({required this.pos, required this.color});

  @override
  String toString() {
    var c = color * 255;
    var rgb = RGB(c.x.round(), c.y.round(), c.z.round());
    return '$pos $rgb';
  }
}

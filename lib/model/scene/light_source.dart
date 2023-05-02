import 'package:icg_raytracing/algorithms/types.dart';

class LightSource {
  Point3D pos;
  final Point3D color;

  LightSource({required this.pos, required this.color});
}

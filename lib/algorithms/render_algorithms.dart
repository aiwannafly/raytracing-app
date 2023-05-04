import 'dart:math';

import 'package:icg_raytracing/algorithms/bmp.dart';
import 'package:icg_raytracing/algorithms/rgb.dart';
import 'package:icg_raytracing/algorithms/transform_3d.dart';
import 'package:icg_raytracing/algorithms/types.dart';
import 'package:icg_raytracing/model/render/render_settings.dart';
import 'package:icg_raytracing/model/scene/light_source.dart';
import 'package:icg_raytracing/model/scene/scene.dart';
import 'package:ml_linalg/matrix.dart';

import '../model/scene/figures/figure.dart';

class RenderAlgorithms {
  RenderAlgorithms._internal();

  factory RenderAlgorithms() {
    return RenderAlgorithms._internal();
  }

  BMPImage renderScene({
    required Scene scene,
    required RenderSettings settings,
    required double width,
    required double height,
    int zRotAngle = 0,
    int yRotAngle = 0,
  }) {
    BMPImage image = BMPImage(width: width.round(), height: height.round());
    double w = width / 2;
    double h = height / 2;
    Matrix invMatrix = T3D().getInvCamMatrix(
            eye: settings.eye, view: settings.view, up: settings.up) *
        T3D()
            .getVisibleAreaMatrix(
                zNear: settings.zNear,
                zFar: settings.zFar,
                sWidth: settings.planeWidth,
                sHeight: settings.planeHeight)
            .inverse() *
        T3D().getTranslationMatrix(trX: -1, trY: -1, trZ: 0) *
        T3D().getScaleMatrix(scaleX: 1 / w, scaleY: 1 / h, scaleZ: 1);

    double z = settings.zNear;
    Point3D rStart = settings.eye;

    // Point3D start = Point3D(0, 0, 0);
    // Point3D dir = Point3D(0, 0, 1);
    // for (Figure f in scene.figures) {
    //   Intersection? int = f.intersect(rStart: start, rDir: dir);
    //   if (int == null) {
    //     continue;
    //   }
    //   print('figure: ${f.minPos} ${f.maxPos}');
    //   print('int pos: ${int.pos}');
    // }

    for (double y = 0; y < height; y++) {
      for (double x = 0; x < width; x++) {
        Point3D scenePoint = T3D().apply(Point3D(x, y, z), invMatrix);
        Point3D rDir = scenePoint - rStart;
        rDir /= rDir.norm();
        Figure? intFigure;
        double? minDist;
        for (Figure figure in scene.figures) {
          Intersection? int = figure.intersect(rayStart: rStart, rayDir: rDir);
          if (int != null) {
            if (minDist == null) {
              intFigure = figure;
              var ray = int.pos - rStart;
              minDist = ray.scalarDot(ray);
            } else {
              var ray = int.pos - rStart;
              var dist = ray.scalarDot(ray);
              if (dist < minDist) {
                minDist = dist;
                intFigure = figure;
              }
            }
          }
        }
        if (intFigure == null) {
          continue;
        }
        var figure = intFigure;
        Intersection? int = figure.intersect(rayStart: rStart, rayDir: rDir);
        if (int == null) {
          continue;
        }
        Point3D view = settings.eye - int.pos;
        view /= view.norm();
        RGBD light = RGBD(
            scene.ambientColor.x, scene.ambientColor.y, scene.ambientColor.z);
        for (LightSource l in scene.lightSources) {
          var lDir = l.pos - int.pos;
          lDir /= lDir.norm();
          var cosO = int.normal.scalarDot(lDir);
          if (cosO <= 0) {
            continue;
          }
          Point3D reflected = int.normal * 2 * cosO - lDir;
          var d = figure.optics.diff;
          light +=
              RGBD(l.color.x * d.x, l.color.y * d.y, l.color.z * d.z) * cosO;
          var s = figure.optics.sight;
          num cosA = reflected.scalarDot(view);
          if (cosA <= 0) {
            continue;
          }
          double power = pow(cosA, figure.optics.power) as double;
          light +=
              RGBD(l.color.x * s.x, l.color.y * s.y, l.color.z * s.z) * power;
        }
        light *= 255;
        image.setRGB(x: x.round(), y: y.round(), color: light.toRGB());
      }
    }
    return image;
  }
}

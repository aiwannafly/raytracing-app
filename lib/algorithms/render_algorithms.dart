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
    Matrix transformMatrix = T3D()
            .getScaleMatrix(scaleX: w, scaleY: h, scaleZ: 1) *
        T3D().getTranslationMatrix(trX: 1, trY: 1, trZ: 0) *
        T3D().getVisibleAreaMatrix(
            zNear: settings.zNear,
            zFar: settings.zFar,
            sWidth: settings.planeWidth,
            sHeight: settings.planeHeight) *
        T3D().getCamMatrix(
            eye: settings.eye, view: settings.view, up: settings.up);
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
    Point3D rayStart = settings.eye;

    for (double y = 0; y < height; y++) {
      for (double x = 0; x < width; x++) {
        Point3D scenePoint = T3D().apply(Point3D(x, y, z), invMatrix);
        Point3D rayDir = scenePoint - rayStart;
        rayDir /= rayDir.norm();
        for (Figure figure in scene.figures) {
          Point3D? intNormal =
              figure.intersectNormal(rayStart: rayStart, rayDir: rayDir);
          if (intNormal == null) {
            continue;
          }
          Point3D int = figure.intersect(rayStart: rayStart, rayDir: rayDir)!;
          Point3D view = settings.eye - int;
          view /= view.norm();
          RGBDouble light = RGBDouble(
              scene.ambientColor.x, scene.ambientColor.y, scene.ambientColor.z);
          for (LightSource l in scene.lightSources) {
            var lDir = l.pos - int;
            lDir /= lDir.norm();
            var cosO = intNormal.scalarDot(lDir);
            if (cosO <= 0) {
              continue;
            }
            Point3D reflected = intNormal * 2 * cosO - lDir;
            var d = figure.optics.diff;
            light +=
                RGBDouble(l.color.x * d.x, l.color.y * d.y, l.color.z * d.z) *
                    cosO;
            var s = figure.optics.sight;
            num cosA = reflected.scalarDot(view);
            if (cosA <= 0) {
              continue;
            }
            double power = pow(cosA, figure.optics.power) as double;
            light +=
                RGBDouble(l.color.x * s.x, l.color.y * s.y, l.color.z * s.z) *
                    power;
          }
          light *= 255;
          image.setRGB(x: x.round(), y: y.round(), color: light.toRGB());
        }
      }
    }
    return image;
  }
}

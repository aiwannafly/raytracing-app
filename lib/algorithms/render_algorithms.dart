import 'dart:math';

import 'package:flutter/material.dart';
import 'package:icg_raytracing/algorithms/bmp.dart';
import 'package:icg_raytracing/algorithms/transform_3d.dart';
import 'package:icg_raytracing/algorithms/types.dart';
import 'package:icg_raytracing/model/render/render_settings.dart';
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
    Matrix transformMatrix =
        Transform3D().getScaleMatrix(scaleX: w, scaleY: h, scaleZ: 1) *
            Transform3D().getTranslationMatrix(trX: 1, trY: 1, trZ: 0) *
            Transform3D().getVisibleAreaMatrix(
                zNear: settings.zNear,
                zFar: settings.zFar,
                sWidth: settings.planeWidth,
                sHeight: settings.planeHeight) *
            Transform3D().getCameraMatrix(
                eye: settings.eye, view: settings.view, up: settings.up);
    Matrix invMatrix = transformMatrix.inverse();
    double z = settings.zNear;
    Point3D rayStart = settings.eye;
    for (double y = 0; y < height; y++) {
      for (double x = 0; x < width; x++) {
        Point3D scenePoint =
            Transform3D().applyMatrix(Point3D(x, y, z), invMatrix);
        Point3D rayDir = scenePoint - rayStart;
        rayDir /= rayDir.norm();
        for (Figure figure in scene.figures) {
          Point3D? intersectPoint =
              figure.intersect(rayStart: rayStart, rayDir: rayDir);
          if (intersectPoint == null) {
            continue;
          } else {
            image.setPixel(x: x.round(), y: y.round(), color: Colors.red);
          }
        }
      }
    }
    return image;
  }
}

import 'dart:math';

import 'package:icg_raytracing/algorithms/types.dart';
import 'package:icg_raytracing/model/scene/light_source.dart';
import 'package:icg_raytracing/model/scene/scene.dart';

import '../scene/figures/figure.dart';

enum Quality { rough, normal, fine }

class RenderSettings {
  final Point3D backgroundColor;
  double gamma;
  int tracingDepth;
  Quality quality;

  late Point3D eye;
  late Point3D view;
  late Point3D up;
  late double zNear;
  late double zFar;
  late double planeWidth;
  late double planeHeight;
  late Point3D overallSizes;

  static const overallBoxExpand = 0.05;

  static const minZNear = .8;

  static const maxZNear = 2.0;

  static const minRotAngle = 0;
  static const maxRotAngle = 360;

  static int normalizeAngle(int angle) {
    while (angle < minRotAngle) {
      angle += 360;
    }
    while (angle > maxRotAngle) {
      angle -= 360;
    }
    return angle;
  }

  RenderSettings(
      {required this.backgroundColor,
      required this.gamma,
      required this.tracingDepth,
      required this.quality,
      required this.eye,
      required this.view,
      required this.up,
      required this.zNear,
      required this.zFar,
      required this.planeWidth,
      required this.planeHeight});

  RenderSettings.fromScene(
      {required Scene scene,
      required this.quality,
      required this.tracingDepth,
      required this.backgroundColor,
      required this.gamma,
      required double desiredWidth,
      required double desiredHeight}) {
    if (scene.figures.isEmpty) {
      throw 'scene.objects must not be empty';
    }
    Point3D minPos = scene.figures.first.minPos;
    Point3D maxPos = scene.figures.first.maxPos;
    for (Figure object in scene.figures) {
      minPos.x = min(minPos.x, object.minPos.x);
      minPos.y = min(minPos.y, object.minPos.y);
      minPos.z = min(minPos.z, object.minPos.z);
      maxPos.x = max(maxPos.x, object.maxPos.x);
      maxPos.y = max(maxPos.y, object.maxPos.y);
      maxPos.z = max(maxPos.z, object.maxPos.z);
    }
    overallSizes = (maxPos - minPos) * (1 + overallBoxExpand);
    Point3D shift = (minPos + maxPos) / 2;
    for (Figure figure in scene.figures) {
      figure.maxPos -= shift;
      figure.minPos -= shift;
      minPos.x = min(minPos.x, figure.minPos.x);
      minPos.y = min(minPos.y, figure.minPos.y);
      minPos.z = min(minPos.z, figure.minPos.z);
      for (Section section in figure.sections) {
        section.start -= shift;
        section.end -= shift;
      }
    }
    maxPos = -minPos;
    for (LightSource l in scene.lightSources) {
      l.pos -= shift;
    }
    Point3D center = Point3D(0, 0, 0);
    view = center;
    up = Point3D(0, 0, 1);
    eye = Point3D(center.x, center.y, center.z);
    eye.x -= overallSizes.x;
    zNear = (minPos.x - eye.x) / 2;
    zFar = maxPos.x - eye.x + overallSizes.x / 2;
    planeHeight = max(overallSizes.y, overallSizes.x * (desiredHeight) / desiredWidth);
    planeWidth = planeHeight * (desiredWidth / desiredHeight);
    for (Figure object in scene.figures) {
      minPos.x = min(minPos.x, object.minPos.x);
      minPos.y = min(minPos.y, object.minPos.y);
      minPos.z = min(minPos.z, object.minPos.z);
      maxPos.x = max(maxPos.x, object.maxPos.x);
      maxPos.y = max(maxPos.y, object.maxPos.y);
      maxPos.z = max(maxPos.z, object.maxPos.z);
    }
  }
}

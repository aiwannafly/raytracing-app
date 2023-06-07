import 'dart:math';

import 'package:icg_raytracing/algorithms/types.dart';
import 'package:icg_raytracing/model/scene/light_source.dart';
import 'package:icg_raytracing/model/scene/scene.dart';

import '../../algorithms/rgb.dart';
import '../scene/figures/figure.dart';

enum Quality { rough, normal, fine }

extension on Quality {
  String get name {
    switch (this) {
      case Quality.rough:
        return "Rough";
      case Quality.normal:
        return "Normal";
      case Quality.fine:
        return "Fine";
    }
  }
}

class RenderSettings {
  late RGB backColor;
  late double gamma;
  late int depth;
  late Quality quality;

  late Point3D eye;
  late Point3D view;
  late Point3D up;
  late double zNear;
  late double zFar;
  late double planeWidth;
  late double planeHeight;
  Point3D? overallSizes;

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
      {required this.backColor,
      required this.gamma,
      required this.depth,
      required this.quality,
      required this.eye,
      required this.view,
      required this.up,
      required this.zNear,
      required this.zFar,
      required this.planeWidth,
      required this.planeHeight}) {}

  RenderSettings.fromScene(
      {required Scene scene,
      required this.quality,
      required this.depth,
      required this.backColor,
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
      figure.shift(shift);
      minPos.x = min(minPos.x, figure.minPos.x);
      minPos.y = min(minPos.y, figure.minPos.y);
      minPos.z = min(minPos.z, figure.minPos.z);
    }
    maxPos = -minPos;
    for (LightSource l in scene.lightSources) {
      l.pos -= shift;
    }
    Point3D center = Point3D(0, 0, 0);
    view = center;
    up = Point3D(0, 0, 1);
    eye = Point3D(center.x, center.y, center.z);
    eye.x -= overallSizes!.x;
    zNear = (minPos.x - eye.x) / 2;
    zFar = maxPos.x - eye.x + overallSizes!.x / 2;
    planeHeight =
        max(overallSizes!.y, overallSizes!.x * (desiredHeight) / desiredWidth);
    planeWidth = planeHeight * (desiredWidth / desiredHeight);
  }

  RenderSettings.fromExisting(
      {required RenderSettings settings,
      required double desiredWidth,
      required double desiredHeight,
      required Scene scene}) {
    backColor = settings.backColor;
    depth = settings.depth;
    quality = settings.quality;
    eye = settings.eye;
    view = settings.view;
    up = settings.up;
    zNear = settings.zNear;
    zFar = settings.zFar;
    gamma = settings.gamma;

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
      figure.shift(shift);
      minPos.x = min(minPos.x, figure.minPos.x);
      minPos.y = min(minPos.y, figure.minPos.y);
      minPos.z = min(minPos.z, figure.minPos.z);
    }
    maxPos = -minPos;
    for (LightSource l in scene.lightSources) {
      l.pos -= shift;
    }
    planeHeight =
        max(overallSizes!.y, overallSizes!.x * (desiredHeight) / desiredWidth);
    planeWidth = planeHeight * (desiredWidth / desiredHeight);
  }
}

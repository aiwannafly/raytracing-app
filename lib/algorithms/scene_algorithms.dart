import 'dart:math';

import 'package:icg_raytracing/algorithms/transform_3d.dart';
import 'package:icg_raytracing/algorithms/types.dart';
import 'package:icg_raytracing/model/render/render_settings.dart';
import 'package:icg_raytracing/model/scene/scene.dart';
import 'package:ml_linalg/matrix.dart';

import '../model/scene/figures/figure.dart';

class SceneAlgorithms {
  SceneAlgorithms._internal();

  factory SceneAlgorithms() {
    return SceneAlgorithms._internal();
  }

  /*
  Translates sections from 3D scene to 2D canvas
   */
  List<Section> applyCamViewMatrix(
      {required Scene scene,
      required RenderSettings settings,
      required double sceneWidth,
      required double sceneHeight}) {
    if (settings.overallSizes != null) {
      settings.planeHeight = max(settings.overallSizes!.y,
          settings.overallSizes!.x * (sceneHeight) / sceneWidth);
      settings.planeWidth = settings.planeHeight * (sceneWidth / sceneHeight);
    }
    List<Section> result = [];
    double w = sceneWidth / 2;
    double h = sceneHeight / 2;
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
    Point3D dir = settings.eye - settings.view;
    for (Figure object in scene.figures) {
      for (Section section in object.sections) {
        Point3D sDir = settings.eye - section.start;
        if (sDir.scalarDot(dir) <= 0) {
          continue;
        }
        sDir = settings.eye - section.end;
        if (sDir.scalarDot(dir) <= 0) {
          continue;
        }
        Section transformed = Section(
            T3D().apply(section.start, transformMatrix),
            T3D().apply(section.end, transformMatrix));
        result.add(transformed);
      }
    }
    return result;
  }
}

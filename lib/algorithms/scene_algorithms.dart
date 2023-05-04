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
      int zRotAngle = 0,
      int yRotAngle = 0,
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
    // print('\n${settings.zNear}\n${settings.zFar}\n${settings.eye}\n${settings.view}\n');
    return result;
  }

  /*
  Translates points from 2D canvas to 3D scene
   */
  List<Point3D> applyReverseCamViewMatrix(
      {required List<Point3D> points,
      required RenderSettings settings,
      int zRotAngle = 0,
      int yRotAngle = 0,
      required double sceneWidth,
      required double sceneHeight}) {
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
            eye: settings.eye, view: settings.view, up: settings.up) *
        T3D().getRotationMatrixZ((zRotAngle + 1) * pi / 180) *
        T3D().getRotationMatrixY(yRotAngle * pi / 180);
    Matrix invMatrix = transformMatrix.inverse();
    List<Point3D> res = [];
    for (Point3D p in points) {
      res.add(T3D().apply(p, invMatrix));
    }
    return res;
  }
}

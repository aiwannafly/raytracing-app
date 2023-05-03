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
    settings.planeHeight = max(settings.overallSizes.y,
        settings.overallSizes.x * (sceneHeight) / sceneWidth);
    settings.planeWidth = settings.planeHeight * (sceneWidth / sceneHeight);
    List<Section> result = [];
    double w = sceneWidth / 2;
    double h = sceneHeight / 2;
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
    // Matrix rotMatrix =
    //     Transform3D().getRotationMatrixZ((zRotAngle + 1) * pi / 180) *
    //         Transform3D().getRotationMatrixY(yRotAngle * pi / 180);
    Matrix rotMatrix = Matrix.identity(4);
    Point3D dir = settings.eye - settings.view;
    for (Figure object in scene.figures) {
      for (Section section in object.sections) {
        Section rotated = Section(
            Transform3D().applyMatrix(section.start, rotMatrix),
            Transform3D().applyMatrix(section.end, rotMatrix));
        Point3D sDir = settings.eye - rotated.start;
        if (sDir.scalarDot(dir) <= 0) {
          continue;
        }
        sDir = settings.eye - rotated.end;
        if (sDir.scalarDot(dir) <= 0) {
          continue;
        }
        Section transformed = Section(
            Transform3D().applyMatrix(rotated.start, transformMatrix),
            Transform3D().applyMatrix(rotated.end, transformMatrix));
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
    Matrix transformMatrix =
        Transform3D().getScaleMatrix(scaleX: w, scaleY: h, scaleZ: 1) *
            Transform3D().getTranslationMatrix(trX: 1, trY: 1, trZ: 0) *
            Transform3D().getVisibleAreaMatrix(
                zNear: settings.zNear,
                zFar: settings.zFar,
                sWidth: settings.planeWidth,
                sHeight: settings.planeHeight) *
            Transform3D().getCameraMatrix(
                eye: settings.eye, view: settings.view, up: settings.up) *
            Transform3D().getRotationMatrixZ((zRotAngle + 1) * pi / 180) *
            Transform3D().getRotationMatrixY(yRotAngle * pi / 180);
    Matrix invMatrix = transformMatrix.inverse();
    List<Point3D> res = [];
    for (Point3D p in points) {
      res.add(Transform3D().applyMatrix(p, invMatrix));
    }
    return res;
  }
}

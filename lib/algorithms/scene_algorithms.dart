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
  Надо решить проблему с ненужными линиями, которые сильно искажаются.
  Их надо не показывать в кадре / показывать только видимую часть.

  Изначально все объекты лежат в боксе [-sWidth/2, sWidth/2] x [-sHeight/2, sHeight/2] x [0, 1]
  Потом применяется матрица камеры. Она состоит из двух матриц. В первом набор единичных векторов,
  которые делают своеобразный поворот. Во втором сдвиг на вектор -eye

  Надо просто отбрасывать отрезки, которых не должно быть видно. Вопрос:
  как понять, что отрезок не должен быть виден? Как?

  Есть точка view, есть положение камеры. Мы должны видеть все отрезки
  в направлении eye - view. И не должны видеть отрезков в обратном направлении.
  Все как в жизни.
  Просто как это имплементировать?
  Будем работать с иксом. С нашей матрицей камеры по нему и идет обрез
  zNear и zFar.
  Окей, у нас только икс, это уже лучше.

   */
  List<Section> applyCamViewMatrix(
      {required Scene scene,
      required RenderSettings settings,
      int zRotAngle = 0,
      int yRotAngle = 0}) {
    List<Section> result = [];
    double w = 500;
    double h = 400;
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
    Matrix rotMatrix =
    Transform3D().getRotationMatrixZ(zRotAngle * pi / 180) *
        Transform3D().getRotationMatrixY(yRotAngle * pi / 180);
    Point3D dir = settings.eye - settings.view;
    for (Figure object in scene.objects) {
      for (Section s in object.sections) {
        Section rotated = Section(
            Transform3D().applyMatrix(s.start, rotMatrix),
            Transform3D().applyMatrix(s.end, rotMatrix));
        Point3D sDir = settings.eye - rotated.start;
        if (sDir.scalarDot(dir) < 0) {
          continue;
        }
        sDir = settings.eye - rotated.end;
        if (sDir.scalarDot(dir) < 0) {
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
}

import 'dart:isolate';
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

class FigureIntersection {
  Intersection int;
  Figure figure;
  double dist;

  FigureIntersection(
      {required this.int, required this.figure, required this.dist});
}

class _Trace {
  double dist;
  RGBD light;

  _Trace({required this.light, required this.dist});
}

class RenderData {
  Scene scene;
  RenderSettings settings;
  double width;
  double height;
  SendPort sendPort;

  RenderData(
      {required this.scene,
      required this.settings,
      required this.width,
      required this.height,
      required this.sendPort});
}

Future<BMPImage> callRender(RenderData data) async {
  return await RenderAlgorithms().renderScene(
      scene: data.scene,
      settings: data.settings,
      areaWidth: data.width,
      areaHeight: data.height,
      statusPort: data.sendPort);
}

class RenderAlgorithms {
  RenderAlgorithms._internal();

  static const epsilon = 0.001;

  factory RenderAlgorithms() {
    return RenderAlgorithms._internal();
  }

  Matrix _getInvSceneMatrix(
      {required Scene scene,
      required RenderSettings settings,
      required double width,
      required double height}) {
    double w = width / 2;
    double h = height / 2;
    return T3D().getInvCamMatrix(
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
  }

  FigureIntersection? _findClosestFigure(
      {required Point3D rStart,
      required Point3D rDir,
      required List<Figure> figures}) {
    double? minDist;
    FigureIntersection? fInt;
    for (Figure figure in figures) {
      Intersection? int = figure.intersect(rayStart: rStart, rayDir: rDir);
      if (int == null) {
        continue;
      }
      if (minDist == null) {
        var ray = int.pos - rStart;
        minDist = ray.scalarDot(ray);
        fInt =
            FigureIntersection(int: int, figure: figure, dist: sqrt(minDist));
      } else {
        var ray = int.pos - rStart;
        var dist = ray.scalarDot(ray);
        if (dist < minDist) {
          minDist = dist;
          fInt =
              FigureIntersection(int: int, figure: figure, dist: sqrt(minDist));
        }
      }
    }
    return fInt;
  }

  bool _crossesFigures(
      {required Intersection int,
      required Point3D lDir,
      required double lDist,
      required List<Figure> figures}) {
    var start = int.pos + lDir * epsilon;
    for (Figure f in figures) {
      Intersection? int = f.intersect(rayStart: start, rayDir: lDir);
      if (int != null) {
        if (int.t <= lDist - epsilon) {
          return true;
        }
      }
    }
    return false;
  }

  _Trace? _traceRay(
      {required Point3D rStart,
      required Point3D rDir,
      required RenderSettings settings,
      required Scene scene,
      int depth = 0}) {
    FigureIntersection? closest =
        _findClosestFigure(rStart: rStart, rDir: rDir, figures: scene.figures);
    if (closest == null) {
      return null;
    }
    var figure = closest.figure;
    Intersection int = closest.int;
    Point3D view = settings.eye - int.pos;
    view /= view.norm();
    RGBD light = RGBD(scene.ambient.x, scene.ambient.y, scene.ambient.z);
    for (LightSource l in scene.lightSources) {
      var lDir = l.pos - int.pos;
      var lDist = lDir.norm();
      lDir /= lDist;
      if (_crossesFigures(
          int: int, lDir: lDir, lDist: lDist, figures: scene.figures)) {
        continue;
      }
      var cosO = int.normal.scalarDot(lDir);
      if (cosO <= 0) {
        continue;
      }
      var fade = 1 / lDist;
      Point3D reflected = int.normal * 2 * cosO - lDir;
      var d = figure.optics.diff * fade;
      light += RGBD(l.color.x * d.x, l.color.y * d.y, l.color.z * d.z) * cosO;
      var s = figure.optics.sight * fade;
      num cosA = reflected.scalarDot(view);
      if (cosA <= 0) {
        continue;
      }
      double power = pow(cosA, figure.optics.power) as double;
      light += RGBD(l.color.x * s.x, l.color.y * s.y, l.color.z * s.z) * power;
    }
    if (depth > 0) {
      var cosO = int.normal.scalarDot(rDir);
      Point3D reflectedDir = int.normal * 2 * cosO - rDir;
      var rTrace = _traceRay(
          rStart: int.pos + reflectedDir * epsilon,
          rDir: reflectedDir,
          settings: settings,
          scene: scene,
          depth: depth - 1);
      if (rTrace != null) {
        var fade = 1 / rTrace.dist;
        var s = figure.optics.sight * fade;
        light += RGBD(rTrace.light.red * s.x, rTrace.light.green * s.y,
            rTrace.light.blue * s.z);
      }
    }
    return _Trace(light: light, dist: closest.dist);
  }

  Future<BMPImage> renderScene(
      {required Scene scene,
      required RenderSettings settings,
      required double areaWidth,
      required double areaHeight,
      required SendPort statusPort}) async {
    int width = areaWidth.round();
    int height = areaHeight.round();
    while (width % 4 != 0) {
      width++;
    }
    while (height % 4 != 0) {
      height++;
    }

    BMPImage image = BMPImage(width: width, height: height);
    Matrix invMatrix = _getInvSceneMatrix(
        scene: scene, settings: settings, width: areaWidth, height: areaHeight);
    double z = settings.zNear;
    Point3D rStart = settings.eye;
    int count = 0;
    int sendFreq = width * height ~/ 200;
    var t2 = DateTime.now();
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        Point3D scenePoint =
            T3D().apply(Point3D(x.toDouble(), y.toDouble(), z), invMatrix);
        Point3D rDir = scenePoint - rStart;
        rDir /= rDir.norm();
        _Trace? trace = _traceRay(
            rStart: rStart,
            rDir: rDir,
            settings: settings,
            scene: scene,
            depth: settings.depth);
        count++;
        if (count % sendFreq == 0) {
          statusPort.send(count);
        }
        if (trace == null) {
          image.setRGB(x: x, y: y, color: settings.backgroundColor);
          continue;
        }
        trace.light ^= 1 / settings.gamma;
        trace.light *= 255;
        image.setRGB(x: x, y: y, color: trace.light.toRGB());
      }
    }
    // var a1 = _traceImagePart(
    //     image: image,
    //     settings: settings,
    //     invMatrix: invMatrix,
    //     scene: scene,
    //     rStart: rStart,
    //     yMin: 0,
    //     yMax: height / 2,
    //     xMin: 0,
    //     xMax: width);
    // var a2 = _traceImagePart(
    //     image: image,
    //     settings: settings,
    //     invMatrix: invMatrix,
    //     scene: scene,
    //     rStart: rStart,
    //     yMin: height / 2,
    //     yMax: height,
    //     xMin: 0,
    //     xMax: width);
    // await a1.whenComplete(() => a2.whenComplete(() => null));
    var t3 = DateTime.now();
    print(t3.difference(t2).inMilliseconds);
    return image;
  }

  /*
  Так, нужно распараллелить. Есть идея такая: каждую часть
  картинки определяем через смещение + размер.
  Результатом работы изолята может быть List<List<RGB>>.
  Не будут создаваться лишние BMPImage
   */
  Future _traceImagePart(
      {required BMPImage image,
      required RenderSettings settings,
      required Matrix invMatrix,
      required Scene scene,
      required Point3D rStart,
      required double yMin,
      required double yMax,
      required double xMin,
      required double xMax}) async {
    double z = settings.zNear;
    for (double y = yMin; y < yMax; y++) {
      for (double x = xMin; x < xMax; x++) {
        Point3D scenePoint = T3D().apply(Point3D(x, y, z), invMatrix);
        Point3D rDir = scenePoint - rStart;
        rDir /= rDir.norm();
        _Trace? trace = _traceRay(
            rStart: rStart,
            rDir: rDir,
            settings: settings,
            scene: scene,
            depth: settings.depth);
        // count++;
        // if (count % sendFreq == 0) {
        //   statusPort.send(count);
        // }
        if (trace == null) {
          image.setRGB(
              x: x.round(), y: y.round(), color: settings.backgroundColor);
          continue;
        }
        trace.light ^= 1 / settings.gamma;
        trace.light *= 255;
        image.setRGB(x: x.round(), y: y.round(), color: trace.light.toRGB());
      }
    }
  }
}

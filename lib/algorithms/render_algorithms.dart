import 'dart:ffi';
import 'dart:isolate';
import 'dart:math';

import 'package:flutter/foundation.dart';
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
      rDir = -rDir;
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
    var t1 = DateTime.now();
    int width = areaWidth.round();
    int height = areaHeight.round();
    while (width % 16 != 0) {
      width++;
    }
    while (height % 16 != 0) {
      height++;
    }
    BMPImage image = BMPImage(width: width, height: height);
    Matrix invMatrix = _getInvSceneMatrix(
        scene: scene, settings: settings, width: areaWidth, height: areaHeight);
    int count = 0;
    int sendFreq = width * height ~/ 200;
    int xSplit = 2;
    int ySplit = 2;
    int xStep = width ~/ xSplit;
    int yStep = height ~/ ySplit;
    IntPoint2D extent = IntPoint2D(xStep, yStep);
    List<Future<_TracePartRes>> tasks = [];
    void fillPart(_TracePartRes r) {
      for (int y = r.offset.y; y < r.extent.y + r.offset.y; y++) {
        for (int x = r.offset.x; x < r.extent.x + r.offset.x; x++) {
          image.setRGB(
              x: x,
              y: y,
              color: r.image.getRGB(x: x - r.offset.x, y: y - r.offset.y)!);
        }
      }
    }

    for (int i = 0; i < xSplit; i++) {
      for (int j = 0; j < ySplit; j++) {
        var port = ReceivePort();
        var c = compute(
            _callTracePart,
            _TracePartArgs(
                settings: settings,
                invMatrix: invMatrix,
                scene: scene,
                sendFreq: sendFreq,
                offset: IntPoint2D(i * xStep, j * yStep),
                extent: extent,
                statusPort: port.sendPort));
        c.then(fillPart);
        tasks.add(c);
        port.listen((partsCount) {
          count += sendFreq * partsCount as int;
          statusPort.send(count);
        });
      }
    }
    for (var task in tasks) {
      await task;
    }
    var t2 = DateTime.now();
    print('time to compute: ${t2.difference(t1).inMilliseconds} millis');
    return image;
  }

  Future<_TracePartRes> _traceImagePartNormal(
      {required RenderSettings settings,
      required Matrix invMatrix,
      required Scene scene,
      required IntPoint2D offset,
      required IntPoint2D extent,
      required int sendFreq,
      required SendPort statusPort}) async {
    assert(settings.quality == Quality.normal);
    BMPImage image = BMPImage(width: extent.x, height: extent.y);
    Point3D rStart = settings.eye;
    double z = settings.zNear;
    int count = 0;
    for (int y = offset.y; y < extent.y + offset.y; y++) {
      for (int x = offset.x; x < extent.x + offset.x; x++) {
        Point3D scenePoint = T3D().apply(Point3D(x + .5, y + .5, z), invMatrix);
        Point3D rDir = scenePoint - rStart;
        rDir /= rDir.norm();
        _Trace? trace = _traceRay(
            rStart: rStart,
            rDir: rDir,
            settings: settings,
            scene: scene,
            depth: settings.depth);
        count++;
        if (count == sendFreq) {
          count = 0;
          statusPort.send(1);
        }
        if (trace == null) {
          image.setRGB(
              x: x - offset.x, y: y - offset.y, color: settings.backColor);
          continue;
        }
        trace.light ^= 1 / settings.gamma;
        trace.light *= 255;
        image.setRGB(
            x: x - offset.x, y: y - offset.y, color: trace.light.toRGB());
      }
    }
    return _TracePartRes(image: image, offset: offset, extent: extent);
  }

  Future<_TracePartRes> _traceImagePartRough(
      {required RenderSettings settings,
      required Matrix invMatrix,
      required Scene scene,
      required IntPoint2D offset,
      required IntPoint2D extent,
      required int sendFreq,
      required SendPort statusPort}) async {
    assert(settings.quality == Quality.rough);
    BMPImage image = BMPImage(width: extent.x, height: extent.y);
    Point3D rStart = settings.eye;
    double z = settings.zNear;
    int count = 0;
    const step = 2;
    for (int y = offset.y; y < extent.y + offset.y; y += step) {
      for (int x = offset.x; x < extent.x + offset.x; x += step) {
        Point3D scenePoint =
            T3D().apply(Point3D(x + step / 2, y + step / 2, z), invMatrix);
        Point3D rDir = scenePoint - rStart;
        rDir /= rDir.norm();
        _Trace? trace = _traceRay(
            rStart: rStart,
            rDir: rDir,
            settings: settings,
            scene: scene,
            depth: settings.depth);
        count++;
        if (count == sendFreq) {
          count = 0;
          statusPort.send(step * step);
        }
        void setRoughPixel(RGB color) {
          for (int i = y; i < y + step; i++) {
            for (int j = x; j < x + step; j++) {
              image.setRGB(x: j - offset.x, y: i - offset.y, color: color);
            }
          }
        }

        if (trace == null) {
          setRoughPixel(settings.backColor);
          continue;
        }
        trace.light ^= 1 / settings.gamma;
        trace.light *= 255;
        setRoughPixel(trace.light.toRGB());
      }
    }
    return _TracePartRes(image: image, offset: offset, extent: extent);
  }

  Future<_TracePartRes> _traceImagePartFine(
      {required RenderSettings settings,
      required Matrix invMatrix,
      required Scene scene,
      required IntPoint2D offset,
      required IntPoint2D extent,
      required int sendFreq,
      required SendPort statusPort}) async {
    assert(settings.quality == Quality.fine);
    BMPImage image = BMPImage(width: extent.x, height: extent.y);
    Point3D rStart = settings.eye;
    double z = settings.zNear;
    int count = 0;
    const step = 2;
    RGBD backRGBD = RGBD(settings.backColor.red / 255,
        settings.backColor.green / 255, settings.backColor.blue / 255);
    for (int y = offset.y; y < extent.y + offset.y; y++) {
      for (int x = offset.x; x < extent.x + offset.x; x++) {
        RGBD full = RGBD(0, 0, 0);
        for (int i = 0; i < step; i++) {
          for (int j = 0; j < step; j++) {
            Point3D scenePoint = T3D().apply(
                Point3D(1 / 4 + x + j / 2, 1 / 4 + y + i / 2, z), invMatrix);
            Point3D rDir = scenePoint - rStart;
            rDir /= rDir.norm();
            _Trace? trace = _traceRay(
                rStart: rStart,
                rDir: rDir,
                settings: settings,
                scene: scene,
                depth: settings.depth);
            if (trace == null) {
              full += backRGBD;
            } else {
              full += trace.light;
            }
          }
        }
        full /= (step * step);
        full ^= 1 / settings.gamma;
        full *= 255;
        image.setRGB(x: x - offset.x, y: y - offset.y, color: full.toRGB());
        count++;
        if (count == sendFreq) {
          count = 0;
          statusPort.send(1);
        }
      }
    }
    return _TracePartRes(image: image, offset: offset, extent: extent);
  }
}

class _TracePartRes {
  BMPImage image;
  final IntPoint2D offset;
  final IntPoint2D extent;

  _TracePartRes(
      {required this.image, required this.offset, required this.extent});
}

class _TracePartArgs {
  final RenderSettings settings;
  final Matrix invMatrix;
  final Scene scene;
  final IntPoint2D offset;
  final IntPoint2D extent;
  final SendPort statusPort;
  final int sendFreq;

  _TracePartArgs(
      {required this.settings,
      required this.invMatrix,
      required this.scene,
      required this.offset,
      required this.extent,
      required this.sendFreq,
      required this.statusPort});
}

Future<_TracePartRes> _callTracePart(_TracePartArgs a) async {
  if (a.settings.quality == Quality.rough) {
    return await RenderAlgorithms()._traceImagePartRough(
        settings: a.settings,
        invMatrix: a.invMatrix,
        scene: a.scene,
        offset: a.offset,
        extent: a.extent,
        sendFreq: a.sendFreq,
        statusPort: a.statusPort);
  }
  if (a.settings.quality == Quality.fine) {
    return await RenderAlgorithms()._traceImagePartFine(
        settings: a.settings,
        invMatrix: a.invMatrix,
        scene: a.scene,
        offset: a.offset,
        extent: a.extent,
        sendFreq: a.sendFreq,
        statusPort: a.statusPort);
  }
  return await RenderAlgorithms()._traceImagePartNormal(
      settings: a.settings,
      invMatrix: a.invMatrix,
      scene: a.scene,
      offset: a.offset,
      extent: a.extent,
      sendFreq: a.sendFreq,
      statusPort: a.statusPort);
}

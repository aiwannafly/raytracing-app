import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:icg_raytracing/algorithms/scene_algorithms.dart';
import 'package:icg_raytracing/algorithms/types.dart';
import 'package:icg_raytracing/config/widget_config.dart';
import 'package:icg_raytracing/model/render/render_settings.dart';
import 'package:icg_raytracing/model/scene/figures/box.dart';
import 'package:icg_raytracing/model/scene/figures/figure.dart';
import 'package:icg_raytracing/model/scene/figures/sphere.dart';
import 'package:icg_raytracing/model/scene/figures/triangle.dart';
import 'package:icg_raytracing/model/scene/scene.dart';
import 'package:icg_raytracing/painters/wire_scene_painter.dart';

class ScenePage extends StatefulWidget {
  const ScenePage({super.key});

  @override
  State<ScenePage> createState() => _ScenePageState();
}

class _ScenePageState extends State<ScenePage> {
  late Scene scene;
  late RenderSettings renderSettings;
  final zNearScale = ValueNotifier(1.0);
  late final double zNear;
  final keyboardFocusNode = FocusNode();
  DateTime lastCTRLPressed = DateTime.now();
  int prevZ = 0;
  int prevY = 0;
  int startDx = 0;
  int startDy = 0;
  bool dragJustStarted = false;
  static final zRotAngle = ValueNotifier(0);
  static final yRotAngle = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    List<Figure> objects = [];
    Point3D diffusionCoeffs = Point3D(1, 1, 1);
    Point3D sightCoeffs = Point3D(1, 1, 1);
    int reflectPower = 4;
    objects.add(Box(
        minPos: Point3D(1, 1, 1),
        maxPos: Point3D(10, 10, 10),
        diffusionCoeffs: diffusionCoeffs,
        sightCoeffs: sightCoeffs,
        reflectPower: reflectPower));
    objects.add(Box(
        minPos: Point3D(2, 2, 2),
        maxPos: Point3D(3, 4, 5),
        diffusionCoeffs: diffusionCoeffs,
        sightCoeffs: sightCoeffs,
        reflectPower: reflectPower));
    objects.add(Sphere(
        center: Point3D(1.5, 2, 2.5),
        radius: 1,
        diffusionCoeffs: diffusionCoeffs,
        sightCoeffs: sightCoeffs,
        reflectPower: reflectPower));
    objects.add(Triangle(
        first: Point3D(4, 4, 4),
        second: Point3D(4, 3, 3),
        third: Point3D(5, 2, 9),
        diffusionCoeffs: diffusionCoeffs,
        sightCoeffs: sightCoeffs,
        reflectPower: reflectPower));
    scene = Scene(
        objects: objects, lightSources: [], ambientColor: Point3D(1, 1, 1));
    renderSettings = RenderSettings.fromScene(
        scene: scene,
        quality: Quality.normal,
        tracingDepth: 3,
        backgroundColor: Point3D(1, 1, 1),
        gamma: 1,
        desiredWidth: 1000,
        desiredHeight: 800);
    zNear = renderSettings.zNear;
    zNearScale.addListener(updateZNear);
    keyboardFocusNode.requestFocus();
    yRotAngle.addListener(updateView);
    zRotAngle.addListener(updateView);
  }

  @override
  void dispose() {
    zNearScale.removeListener(updateZNear);
    yRotAngle.removeListener(updateView);
    zRotAngle.removeListener(updateView);
    super.dispose();
  }

  void updateView() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: handleMouseWheel,
      child: KeyboardListener(
        focusNode: keyboardFocusNode,
        onKeyEvent: handleKeyEvent,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Container(
            padding: WidgetConfig.paddingAll,
            alignment: Alignment.topCenter,
            // decoration: const BoxDecoration(
            //   image: DecorationImage(image: AssetImage("assets/space.jpeg")
            //   )
            // ),
            child: Container(
                height: 800,
                width: 1000,
                padding: WidgetConfig.paddingAll,
                decoration: BoxDecoration(
                    borderRadius: WidgetConfig.borderRadius,
                    border: Border.all(color: Colors.black, width: 1)),
                child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onPanDown: onPressed,
                      onPanUpdate: onDragged,
                      child: ClipRRect(
                          child: FittedBox(
                              child: CustomPaint(
                        size: const Size(1000, 800),
                        painter: WireScenePainter(
                            sections: SceneAlgorithms().applyCamViewMatrix(
                                scene: scene,
                                settings: renderSettings,
                                yRotAngle: zRotAngle.value,
                                zRotAngle: yRotAngle.value)),
                      ))),
                    ))),
          ),
        ),
      ),
    );
  }

  void updateZNear() {
    setState(() {
      renderSettings.zNear = zNearScale.value * zNear;
    });
  }

  void handleKeyEvent(KeyEvent e) {
    if (e.physicalKey == PhysicalKeyboardKey.controlLeft ||
        e.physicalKey == PhysicalKeyboardKey.controlRight) {
      lastCTRLPressed = DateTime.now();
      return;
    }
    double step = 0.3;
    if (e.physicalKey == PhysicalKeyboardKey.keyW) {
      setState(() {
        renderSettings.eye.x += step;
      });
    } else if (e.physicalKey == PhysicalKeyboardKey.keyS) {
      setState(() {
        renderSettings.eye.x -= step;
      });
    } else if (e.physicalKey == PhysicalKeyboardKey.keyD) {
      setState(() {
        renderSettings.eye.y += step;
      });
    } else if (e.physicalKey == PhysicalKeyboardKey.keyA) {
      setState(() {
        renderSettings.eye.y -= step;
      });
    }
  }

  void handleMouseWheel(PointerSignalEvent e) {
    if (e is! PointerScrollEvent) {
      return;
    }
    double delta = -e.scrollDelta.dy /
        (120 * (RenderSettings.maxZNear - RenderSettings.minZNear));
    var ctrlTimeDelta = DateTime.now().difference(lastCTRLPressed);
    if (ctrlTimeDelta.inMilliseconds < 1000) {
      Point3D dir = renderSettings.view - renderSettings.eye;
      double len = dir.norm();
      if (len < 0.1) {
        return;
      }
      Point3D k = dir / len;
      setState(() {
        renderSettings.eye += k * delta;
      });
      return;
    }
    double newZNear = max(
        min(zNearScale.value + delta, RenderSettings.maxZNear),
        RenderSettings.minZNear);
    zNearScale.value = newZNear;
  }

  void onPressed(DragDownDetails details) {
    dragJustStarted = true;
    prevY = yRotAngle.value;
    prevZ = zRotAngle.value;
  }

  void onDragged(DragUpdateDetails details) {
    double sign = (renderSettings.eye.x - renderSettings.view.x).sign;
    if (prevZ.abs() > 90) {
      sign *= -1;
    }
    print(sign);
    int delimiter = 6;
    int dx = sign * details.localPosition.dy.round() ~/ delimiter;
    int dy = -details.localPosition.dx.round() ~/ delimiter;
    if (dragJustStarted) {
      startDx = dx;
      startDy = dy;
      dragJustStarted = false;
      return;
    }
    dx -= startDx;
    dy -= startDy;
    int newRotX = RenderSettings.normalizeAngle(prevZ + dx);
    int newRotY = RenderSettings.normalizeAngle(prevY + dy);
    zRotAngle.value = newRotX;
    yRotAngle.value = newRotY;
  }
}

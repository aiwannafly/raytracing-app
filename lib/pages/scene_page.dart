import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:icg_raytracing/algorithms/bmp.dart';
import 'package:icg_raytracing/algorithms/render_algorithms.dart';
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
import 'package:icg_raytracing/services/scene_file_service.dart';

class ScenePage extends StatefulWidget {
  const ScenePage({super.key});

  @override
  State<ScenePage> createState() => _ScenePageState();

  static double areaWidth(BuildContext context) =>
      WidgetConfig.pageWidth(context) * .9;

  static double areaHeight(BuildContext context) =>
      WidgetConfig.pageHeight(context) * .8;
}

class _ScenePageState extends State<ScenePage> {
  late Scene scene;
  late RenderSettings settings;
  final zNearScale = ValueNotifier(1.0);
  late double zNear;
  final keyboardFocusNode = FocusNode();
  DateTime lastCTRLPressed = DateTime.now();
  int prevZ = 0;
  int prevY = 0;
  int startDx = 0;
  int startDy = 0;
  bool dragJustStarted = false;
  static final zRotAngle = ValueNotifier(0);
  static final yRotAngle = ValueNotifier(0);
  BMPImage? image;

  @override
  void initState() {
    super.initState();
    List<Figure> objects = [];
    Point3D diffusionCoeffs = Point3D(1, 1, 1);
    Point3D sightCoeffs = Point3D(1, 1, 1);
    int reflectPower = 4;
    var optics =
        Optics(diff: diffusionCoeffs, sight: sightCoeffs, power: reflectPower);
    objects.add(Box(
        minPos: Point3D(1, 1, 1), maxPos: Point3D(10, 10, 10), optics: optics));
    objects.add(Box(
        minPos: Point3D(2, 2, 2), maxPos: Point3D(3, 4, 5), optics: optics));
    objects
        .add(Sphere(center: Point3D(1.5, 2, 2.5), radius: 1, optics: optics));
    objects.add(Triangle(
        first: Point3D(4, 4, 4),
        second: Point3D(4, 3, 3),
        third: Point3D(5, 2, 9),
        optics: optics));
    scene = Scene(
        figures: objects, lightSources: [], ambientColor: Point3D(1, 1, 1));
    keyboardFocusNode.requestFocus();
    zNearScale.addListener(updateZNear);
    yRotAngle.addListener(updateView);
    zRotAngle.addListener(updateView);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    updateRenderSettings();
  }

  void updateRenderSettings() {
    settings = RenderSettings.fromScene(
        scene: scene,
        quality: Quality.normal,
        tracingDepth: 3,
        backgroundColor: Point3D(1, 1, 1),
        gamma: 1,
        desiredWidth: ScenePage.areaWidth(context),
        desiredHeight: ScenePage.areaHeight(context));
    zNear = settings.zNear;
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

  Widget listenWrapper(BuildContext context, {required Widget child}) {
    return Listener(
        onPointerSignal: handleMouseWheel,
        child: KeyboardListener(
            focusNode: keyboardFocusNode,
            onKeyEvent: handleKeyEvent,
            child: child));
  }

  double get width => ScenePage.areaWidth(context);

  double get height => ScenePage.areaHeight(context);

  @override
  Widget build(BuildContext context) {
    return listenWrapper(context,
        child: Scaffold(
            backgroundColor: WidgetConfig.backColor,
            body: Container(
              padding: WidgetConfig.paddingAll,
              alignment: Alignment.topCenter,
              child: Column(
                children: [
                  Container(
                      height: height,
                      width: width,
                      decoration: const BoxDecoration(
                        color: Colors.white, // const Color(0xFF08112D),
                        borderRadius: WidgetConfig.borderRadius,
                        // border: Border.all(color: Colors.black, width: 1)
                      ),
                      child: image != null
                          ? Image.memory(image!.bytes)
                          : MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onPanDown: onPressed,
                                onPanUpdate: onDragged,
                                child: ClipRRect(
                                    child: FittedBox(
                                  child: CustomPaint(
                                    size: Size(width, height),
                                    painter: WireScenePainter(
                                        sections: SceneAlgorithms()
                                            .applyCamViewMatrix(
                                                scene: scene,
                                                sceneHeight: height,
                                                sceneWidth: width,
                                                settings: settings,
                                                yRotAngle: zRotAngle.value,
                                                zRotAngle: yRotAngle.value)),
                                  ),
                                )),
                              ))),
                  Container(
                    padding: WidgetConfig.paddingAll,
                    width: ScenePage.areaWidth(context),
                    child: Row(
                      children: [
                        buildButton(context,
                            onTap: openScene,
                            text: "Open scene",
                            iconData: Icons.open_in_browser),
                        const SizedBox(
                          width: WidgetConfig.padding,
                        ),
                        buildButton(context,
                            onTap: init,
                            text: "Init",
                            iconColor: Colors.green,
                            iconData: Icons.restart_alt),
                        const SizedBox(
                          width: WidgetConfig.padding,
                        ),
                        buildButton(context,
                            onTap: render,
                            text: "Render",
                            iconColor: Colors.red,
                            iconData: Icons.sunny),
                        const SizedBox(
                          width: WidgetConfig.padding,
                        ),
                        buildButton(context,
                            onTap: selectView,
                            text: "Select view",
                            iconColor: Colors.purple,
                            iconData: Icons.remove_red_eye_outlined),
                        const SizedBox(
                          width: WidgetConfig.padding,
                        ),
                      ],
                    ),
                  )
                ],
              ),
            )));
  }

  void openScene() async {
    Scene? res = await SceneFileService().openSceneFile();
    if (res == null) {
      return;
    }
    scene = res;
    setState(() {
      updateRenderSettings();
    });
  }

  void init() {
    updateRenderSettings();
    yRotAngle.value = 0;
    zRotAngle.value = 0;
    setState(() {
      image = null;
    });
  }

  void render() {
    image = RenderAlgorithms().renderScene(
        scene: scene, settings: settings, width: width, height: height);
    setState(() {});
  }

  void selectView() {
    setState(() {
      image = null;
    });
  }

  Widget buildButton(BuildContext context,
      {required String text,
      required IconData iconData,
      required VoidCallback onTap,
      Color iconColor = WidgetConfig.seedColor}) {
    return ElevatedButton(
        onPressed: onTap,
        style: ButtonStyle(
          foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
          backgroundColor: MaterialStateProperty.all<Color>(Colors.white),
          overlayColor: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.hovered)) {
                return WidgetConfig.seedColor.withOpacity(0.04);
              }
              if (states.contains(MaterialState.focused) ||
                  states.contains(MaterialState.pressed)) {
                return WidgetConfig.seedColor.withOpacity(0.12);
              }
              return null; // Defer to the widget's default.
            },
          ),
        ),
        child: Container(
          width: 150,
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  iconData,
                  color: iconColor,
                ),
                const SizedBox(
                  width: WidgetConfig.padding / 2,
                ),
                WidgetConfig.defaultText(text),
                const SizedBox(
                  width: WidgetConfig.padding * 2.3,
                ),
              ],
            ),
          ),
        ));
  }

  void updateZNear() {
    setState(() {
      settings.zNear = zNearScale.value * zNear;
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
        settings.eye.x += step;
      });
    } else if (e.physicalKey == PhysicalKeyboardKey.keyS) {
      setState(() {
        settings.eye.x -= step;
      });
    } else if (e.physicalKey == PhysicalKeyboardKey.keyD) {
      setState(() {
        settings.eye.y += step;
      });
    } else if (e.physicalKey == PhysicalKeyboardKey.keyA) {
      setState(() {
        settings.eye.y -= step;
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
      Point3D dir = settings.view - settings.eye;
      double len = dir.norm();
      if (len < 0.1) {
        return;
      }
      Point3D k = dir / len;
      setState(() {
        settings.eye += k * delta;
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
    double sign = (settings.eye.x - settings.view.x).sign;
    if (prevZ.abs() > 90) {
      sign *= -1;
    }
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

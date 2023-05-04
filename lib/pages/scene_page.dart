import 'dart:isolate';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:icg_raytracing/algorithms/bmp.dart';
import 'package:icg_raytracing/algorithms/render_algorithms.dart';
import 'package:icg_raytracing/algorithms/scene_algorithms.dart';
import 'package:icg_raytracing/algorithms/types.dart';
import 'package:icg_raytracing/components/progress_bar.dart';
import 'package:icg_raytracing/config/widget_config.dart';
import 'package:icg_raytracing/model/render/render_settings.dart';
import 'package:icg_raytracing/model/scene/figures/box.dart';
import 'package:icg_raytracing/model/scene/figures/figure.dart';
import 'package:icg_raytracing/model/scene/figures/sphere.dart';
import 'package:icg_raytracing/model/scene/figures/triangle.dart';
import 'package:icg_raytracing/model/scene/scene.dart';
import 'package:icg_raytracing/painters/wire_scene_painter.dart';
import 'package:icg_raytracing/services/scene_file_service.dart';

import '../services/service_io.dart';

class ScenePage extends StatefulWidget {
  const ScenePage({super.key});

  @override
  State<ScenePage> createState() => _ScenePageState();

  static double areaWidth(BuildContext context) =>
      Config.pageWidth(context) * .9;

  static double areaHeight(BuildContext context) =>
      Config.pageHeight(context) * .8;
}

class _ScenePageState extends State<ScenePage> {
  late Scene scene;
  late RenderSettings settings;
  bool initializedEye = false;
  final zNearScale = ValueNotifier(1.0);
  late double zNear;
  final keyboardFocusNode = FocusNode();
  DateTime lastCTRLPressed = DateTime.now();
  int prevZ = 0;
  int prevY = 0;
  int startDx = 0;
  int startDy = 0;
  int pixelsCount = 1000;

  bool dragJustStarted = false;
  static final zRotAngle = ValueNotifier(0);
  static final yRotAngle = ValueNotifier(0);
  static final currentTrace = ValueNotifier(0);

  BMPImage? image;

  bool get isRendering => currentTrace.value > 0;

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
    scene =
        Scene(figures: objects, lightSources: [], ambient: Point3D(1, 1, 1));
    keyboardFocusNode.requestFocus();
    zNearScale.addListener(updateZNear);
    yRotAngle.addListener(updateView);
    zRotAngle.addListener(updateView);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    updateRenderSettings();
    initializedEye = true;
  }

  void updateRenderSettings() {
    Point3D? oldEye;
    if (initializedEye) {
      oldEye = settings.eye;
    }
    settings = RenderSettings.fromScene(
        scene: scene,
        quality: Quality.normal,
        tracingDepth: 3,
        backgroundColor: Point3D(1, 1, 1),
        gamma: 1,
        desiredWidth: ScenePage.areaWidth(context),
        desiredHeight: ScenePage.areaHeight(context));
    if (oldEye != null) {
      settings.eye = oldEye;
    }
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
            backgroundColor: Config.backColor,
            body: Container(
              padding: Config.paddingAll,
              alignment: Alignment.topCenter,
              child: Column(
                children: [
                  Container(
                      height: height,
                      width: width,
                      decoration: const BoxDecoration(
                        color: Colors.white, // const Color(0xFF08112D),
                        borderRadius: Config.borderRadius,
                      ),
                      child: mainContent(context)),
                  Visibility(
                    visible: currentTrace.value == 0,
                    child: Container(
                      padding: Config.paddingAll,
                      width: ScenePage.areaWidth(context),
                      child: Row(
                        children: [
                          buildButton(context,
                              onTap: openScene,
                              text: "Open scene",
                              iconData: Icons.open_in_browser),
                          const SizedBox(
                            width: Config.padding,
                          ),
                          buildButton(context,
                              onTap: init,
                              text: "Init",
                              iconColor: Colors.green,
                              iconData: Icons.restart_alt),
                          const SizedBox(
                            width: Config.padding,
                          ),
                          buildButton(context,
                              onTap: render,
                              text: "Render",
                              iconColor: Colors.red,
                              iconData: Icons.sunny),
                          const SizedBox(
                            width: Config.padding,
                          ),
                          buildButton(context,
                              onTap: selectView,
                              text: "Select view",
                              iconColor: Colors.purple,
                              iconData: Icons.remove_red_eye_outlined),
                          const SizedBox(
                            width: Config.padding,
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            )));
  }

  Widget mainContent(BuildContext context) {
    if (image != null) {
      return ClipRRect(
          borderRadius: Config.borderRadius, child: Image.memory(image!.bytes));
    }
    return Stack(
      children: [
        MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onPanDown: onPressed,
              onPanUpdate: onDragged,
              child: ClipRRect(
                  child: FittedBox(
                child: CustomPaint(
                  size: Size(width, height),
                  painter: WireScenePainter(
                      sections: SceneAlgorithms().applyCamViewMatrix(
                          scene: scene,
                          sceneHeight: height,
                          sceneWidth: width,
                          settings: settings,
                          yRotAngle: zRotAngle.value,
                          zRotAngle: yRotAngle.value)),
                ),
              )),
            )),
        Visibility(
            visible: currentTrace.value > 0,
            child: Center(
              child: Container(
                alignment: Alignment.center,
                height: 150,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.8),
                    borderRadius: Config.borderRadius),
                width: Config.pageWidth(context) * .6,
                child: TraceProgressIndicator(
                    current: currentTrace, desired: pixelsCount),
              ),
            ))
      ],
    );
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
    initializedEye = false;
    updateRenderSettings();
    initializedEye = true;
    yRotAngle.value = 0;
    zRotAngle.value = 0;
    setState(() {
      image = null;
    });
  }

  void render() async {
    setState(() {
      currentTrace.value++;
    });
    pixelsCount = width.round() * height.round();
    var receivePort = ReceivePort();
    compute(
            callRender,
            RenderData(
                scene: scene,
                settings: settings,
                width: width,
                height: height,
                sendPort: receivePort.sendPort))
        .then((res) {
      image = res;
      setState(() {
        currentTrace.value = 0;
      });
    });
    receivePort.listen((value) {
      currentTrace.value = value;
    });
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
      Color iconColor = Config.seedColor}) {
    return ElevatedButton(
        onPressed: onTap,
        style: ButtonStyle(
          foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
          backgroundColor: MaterialStateProperty.all<Color>(Colors.white),
          overlayColor: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.hovered)) {
                return Config.seedColor.withOpacity(0.04);
              }
              if (states.contains(MaterialState.focused) ||
                  states.contains(MaterialState.pressed)) {
                return Config.seedColor.withOpacity(0.12);
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
                  width: Config.padding / 2,
                ),
                Config.defaultText(text),
                const SizedBox(
                  width: Config.padding * 2.3,
                ),
              ],
            ),
          ),
        ));
  }

  void updateZNear() {
    if (isRendering) {
      return;
    }
    setState(() {
      settings.zNear = zNearScale.value * zNear;
    });
  }

  void handleKeyEvent(KeyEvent e) {
    if (isRendering) {
      return;
    }
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
    if (isRendering) {
      return;
    }
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
    if (isRendering) {
      return;
    }
    dragJustStarted = true;
    prevY = yRotAngle.value;
    prevZ = zRotAngle.value;
  }

  void onDragged(DragUpdateDetails details) {
    if (isRendering) {
      return;
    }
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

Future<BMPImage> callRender(RenderData data) async {
  return await RenderAlgorithms().renderScene(
      scene: data.scene,
      settings: data.settings,
      width: data.width,
      height: data.height,
      statusPort: data.sendPort);
}

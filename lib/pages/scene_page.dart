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
import 'package:icg_raytracing/components/interactive_box.dart';
import 'package:icg_raytracing/components/progress_bar.dart';
import 'package:icg_raytracing/config/config.dart';
import 'package:icg_raytracing/model/render/render_settings.dart';
import 'package:icg_raytracing/model/scene/figures/box.dart';
import 'package:icg_raytracing/model/scene/figures/figure.dart';
import 'package:icg_raytracing/model/scene/figures/sphere.dart';
import 'package:icg_raytracing/model/scene/figures/triangle.dart';
import 'package:icg_raytracing/model/scene/scene.dart';
import 'package:icg_raytracing/painters/wire_scene_painter.dart';
import 'package:icg_raytracing/services/image_file_service.dart';
import 'package:icg_raytracing/services/scene_file_service.dart';

import '../components/menu_button.dart';
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
  bool hasScene = false;
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
  bool dragJustStarted = false;
  int pixelsCount = 1000000;
  static final zRotAngle = ValueNotifier(0);
  static final yRotAngle = ValueNotifier(0);
  static final currentTrace = ValueNotifier(0);
  final openSceneActive = ValueNotifier(true);
  final saveImageActive = ValueNotifier(true);
  final initActive = ValueNotifier(true);
  final selectViewActive = ValueNotifier(true);
  final renderActive = ValueNotifier(true);

  BMPImage? image;

  bool get isRendering => currentTrace.value > 0;

  @override
  void initState() {
    super.initState();
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
    if (!hasScene) {
      return;
    }
    Point3D? oldEye;
    if (initializedEye) {
      oldEye = settings.eye;
    }
    settings = RenderSettings.fromScene(
        scene: scene,
        quality: Quality.normal,
        depth: 3,
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

  double get width => ScenePage.areaWidth(context);

  double get height => ScenePage.areaHeight(context);

  Widget listenWrapper(BuildContext context, {required Widget child}) {
    return Listener(
        onPointerSignal: handleMouseWheel,
        child: KeyboardListener(
            focusNode: keyboardFocusNode,
            onKeyEvent: handleKeyEvent,
            child: child));
  }

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
                  const SizedBox(
                    height: Config.padding,
                  ),
                  Container(
                    padding: Config.paddingAll,
                    width: ScenePage.areaWidth(context),
                    child: Row(
                      children: [
                        MenuButton(
                            onTap: openScene,
                            isActive: openSceneActive,
                            text: "Open scene",
                            iconColor: Colors.blue,
                            iconData: Icons.open_in_browser),
                        const SizedBox(
                          width: Config.padding,
                        ),
                        MenuButton(
                            onTap: init,
                            isActive: initActive,
                            text: "Init",
                            iconColor: Colors.green,
                            iconData: Icons.restart_alt),
                        const SizedBox(
                          width: Config.padding,
                        ),
                        MenuButton(
                            onTap: selectView,
                            isActive: selectViewActive,
                            text: "Select view",
                            iconColor: Colors.purple,
                            iconData: Icons.remove_red_eye_outlined),
                        const SizedBox(
                          width: Config.padding,
                        ),
                        MenuButton(
                            onTap: render,
                            isActive: renderActive,
                            text: "Render",
                            iconColor: Colors.red,
                            iconData: Icons.sunny),
                        const SizedBox(
                          width: Config.padding,
                        ),
                        InteractiveBox(
                            onTap: openRenderSettings,
                            child: const Icon(
                              Icons.settings,
                              color: Colors.black87,
                            ))
                      ],
                    ),
                  ),
                  Container(
                    padding: Config.paddingAll,
                    width: ScenePage.areaWidth(context),
                    child: Row(
                      children: [
                        MenuButton(
                            onTap: saveImage,
                            isActive: saveImageActive,
                            text: "Save image",
                            iconColor: Colors.purple,
                            iconData: Icons.save_alt),
                        const SizedBox(
                          width: Config.padding,
                        ),
                        MenuButton(
                            onTap: loadRenderSettings,
                            isActive: saveImageActive,
                            text: "Load settings",
                            iconColor: Colors.red,
                            iconData: Icons.open_in_new),
                        const SizedBox(
                          width: Config.padding,
                        ),
                        MenuButton(
                            onTap: saveRenderSettings,
                            isActive: saveImageActive,
                            text: "Save settings",
                            iconColor: Colors.green,
                            iconData: Icons.save),
                      ],
                    ),
                  )
                ],
              ),
            )));
  }

  List<Section> transformedSections() {
    return SceneAlgorithms().applyCamViewMatrix(
        scene: scene,
        sceneHeight: height,
        sceneWidth: width,
        settings: settings,
        yRotAngle: zRotAngle.value,
        zRotAngle: yRotAngle.value);
  }

  Widget mainContent(BuildContext context) {
    return Stack(
      children: [
        Visibility(
          visible: !hasScene,
          child: Center(
            child: Config.defaultText("No scene is opened", 24),
          ),
        ),
        hasScene
            ? MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onPanDown: onPressed,
                  onPanUpdate: onDragged,
                  child: ClipRRect(
                      child: FittedBox(
                    child: CustomPaint(
                      size: Size(width, height),
                      painter:
                          WireScenePainter(sections: transformedSections()),
                    ),
                  )),
                ))
            : const SizedBox(),
        image != null
            ? Center(
                child: ClipRRect(
                    borderRadius: Config.borderRadius,
                    child: Image.memory(image!.bytes)),
              )
            : const SizedBox(),
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

  void saveRenderSettings() {
    if (!hasScene) {
      ServiceIO.showMessage("Scene is not selected", context);
      return;
    }
  }

  void loadRenderSettings() {
    if (!hasScene) {
      ServiceIO.showMessage("Scene is not selected", context);
      return;
    }
  }

  void saveImage() {
    if (!hasScene) {
      ServiceIO.showMessage("Scene is not selected", context);
      return;
    }
    if (image != null) {
      ImageFileService.saveImageBMP(context, image!);
    } else {
      ImageFileService.saveCanvasScene(context,
          sections: transformedSections(), width: width, height: height);
    }
  }

  void openRenderSettings() {
    if (!hasScene) {
      ServiceIO.showMessage("Scene is not selected", context);
      return;
    }
    ServiceIO.showRenderSettingsMenu(context, settings: settings);
  }

  void openScene() async {
    Scene? res = await SceneFileService().openSceneFile();
    if (res == null) {
      return;
    }
    scene = res;
    setState(() {
      image = null;
      hasScene = true;
      selectViewActive.value = false;
      initializedEye = false;
      updateRenderSettings();
    });
  }

  void init() {
    if (!hasScene) {
      ServiceIO.showMessage("Scene is not selected", context);
      return;
    }
    selectViewActive.value = false;
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
    if (!hasScene) {
      ServiceIO.showMessage("Scene is not selected", context);
      return;
    }
    setState(() {
      currentTrace.value++;
      openSceneActive.value = false;
      initActive.value = false;
      selectViewActive.value = false;
      renderActive.value = false;
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
        openSceneActive.value = true;
        initActive.value = true;
        selectViewActive.value = true;
        renderActive.value = true;
      });
    });
    receivePort.listen((value) {
      currentTrace.value = value;
    });
  }

  void selectView() {
    if (!hasScene) {
      ServiceIO.showMessage("Scene is not selected", context);
      return;
    }
    setState(() {
      selectViewActive.value = false;
      image = null;
    });
  }

  void updateZNear() {
    if (isRendering || image != null) {
      return;
    }
    setState(() {
      settings.zNear = zNearScale.value * zNear;
    });
  }

  void handleKeyEvent(KeyEvent e) {
    if (isRendering || image != null) {
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
    if (isRendering || image != null) {
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
    if (isRendering || image != null) {
      return;
    }
    dragJustStarted = true;
    prevY = yRotAngle.value;
    prevZ = zRotAngle.value;
  }

  void onDragged(DragUpdateDetails details) {
    if (isRendering || image != null) {
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

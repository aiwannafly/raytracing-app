import 'package:flutter/material.dart';
import 'package:icg_raytracing/icgraytracing_app.dart';
import 'package:desktop_window/desktop_window.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:icg_raytracing/services/scene_file_service.dart';

/*
  TODO:
   - speed up and optimize ray tracing
 */
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await DesktopWindow.setMinWindowSize(const Size(1000, 800));
  }
  runApp(const ICGRaytracingApp());
  await Future.delayed(const Duration(seconds: 1), () {
    SceneFileService().saveCustomScene();
  });
}

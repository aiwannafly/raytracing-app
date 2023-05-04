import 'package:flutter/material.dart';
import 'package:icg_raytracing/icgraytracing_app.dart';
import 'package:desktop_window/desktop_window.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/*
  TODO:
   - fix wire scene graphics artefacts
   - add error handling for .scene and .render files
   - parallelize process of ray tracing
   - add different quality levels of rendering
   - create fine testing data
   - speed up and optimize ray tracing
 */
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await DesktopWindow.setMinWindowSize(const Size(1000, 800));
  }
  runApp(const ICGRaytracingApp());
}

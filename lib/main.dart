import 'package:flutter/material.dart';
import 'package:icg_raytracing/icgraytracing_app.dart';
import 'package:desktop_window/desktop_window.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/*
  TODO:
   - add rotation around view with use of a mouse
   - turn select view and render into radio buttons
   - fix wire scene graphics artefacts
   - add support of saving wire scene pictures, rendered pictures
   - add render settings menu
   - add render settings file support
   - add error handling for .scene and .render files
   - parallelize process of ray tracing
   - add gamma correction
   - speed up and optimize ray tracing
   - add different quality levels of rendering
   - create fine testing data
 */
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await DesktopWindow.setMinWindowSize(const Size(1000, 600));
  }
  runApp(const ICGRaytracingApp());
}

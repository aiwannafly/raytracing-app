import 'package:flutter/material.dart';
import 'package:icg_raytracing/icgraytracing_app.dart';
import 'package:desktop_window/desktop_window.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/*
  TODO:
   - check reflections of rays computation
   - create fine testing data
   - speed up and optimize ray tracing
   - add quadrangles tracing
   - add auto .render file opening
 */
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await DesktopWindow.setMinWindowSize(const Size(1000, 800));
  }
  runApp(const ICGRaytracingApp());
}

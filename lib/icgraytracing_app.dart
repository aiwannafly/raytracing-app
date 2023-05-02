import 'package:flutter/material.dart';
import 'package:icg_raytracing/pages/scene_page.dart';

import 'config/widget_config.dart';

class ICGRaytracingApp extends StatelessWidget {
  const ICGRaytracingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ICG Raytracing',
      theme: ThemeData(
          colorSchemeSeed: WidgetConfig.seedColor,
          useMaterial3: true
      ),
      home: const ScenePage()
    );
  }
}

import 'package:flutter/material.dart';
import 'package:icg_raytracing/pages/scene_page.dart';

import 'config/config.dart';

class ICGRaytracingApp extends StatelessWidget {
  const ICGRaytracingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ICG Raytracing',
      theme: ThemeData(
          colorSchemeSeed: Config.seedColor,
          brightness: Brightness.light,
          useMaterial3: true
      ),
      home: const ScenePage()
    );
  }
}

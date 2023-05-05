import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:icg_raytracing/components/value_selector.dart';
import 'package:icg_raytracing/components/value_setter.dart';
import 'package:icg_raytracing/model/render/render_settings.dart';

import '../algorithms/rgb.dart';
import '../algorithms/types.dart';
import '../config/config.dart';

class ServiceIO {
  static void showProgressCircle(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  static void showAbout(BuildContext context) {
    String message =
        "Created by Aleksandr Ivanov, @aiwannafly, a.ivanov15@g.nsu.ru.\n"
        "© All rights reserved.";
    showMessage(message, context, false, 180);
  }

  static void showMessage(String text, BuildContext context,
      [bool noShadow = false, double height = 70]) {
    showDialog(
        barrierColor: noShadow ? Colors.transparent : Colors.black54,
        context: context,
        builder: (context) => AlertDialog(
              backgroundColor: Colors.white,
              content: Container(
                alignment: Alignment.center,
                height: height,
                child: Text(
                  text,
                  style: const TextStyle(
                      color: Config.iconColor,
                      fontFamily: Config.fontFamily,
                      fontSize: 20),
                ),
              ),
            ));
  }

  static void showRenderSettingsMenu(BuildContext context,
      {required RenderSettings settings}) {
    var gamma = ValueNotifier(1.0);
    var depth = ValueNotifier(3);
    var quality = ValueNotifier(Quality.normal);
    quality.value = settings.quality;
    gamma.value = settings.gamma;
    depth.value = settings.depth;
    quality.addListener(() {
      settings.quality = quality.value;
    });
    gamma.addListener(() {
      settings.gamma = gamma.value;
    });
    depth.addListener(() {
      settings.depth = depth.value;
    });
    RGB color = settings.backColor;
    Color pickerColor = Color.fromRGBO(color.red, color.green, color.blue, 1);
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              content: Container(
                  alignment: Alignment.center,
                  height: 500,
                  width: 700,
                  child: Column(
                    children: [
                      Config.defaultText("Render settings", 22),
                      const SizedBox(
                        height: Config.padding * 2,
                      ),
                      SizedBox(
                        width: 240,
                        child: ValueSelector(
                            notifier: quality,
                            values: Quality.values,
                            getName: (q) => q.name),
                      ),
                      const SizedBox(
                        height: Config.padding,
                      ),
                      SliderTextSetter(
                          minVal: 0.1,
                          maxVal: 10.0,
                          notifier: gamma,
                          leading: "Gamma"),
                      const SizedBox(
                        height: Config.padding,
                      ),
                      SliderTextSetter(
                          minVal: 1,
                          maxVal: 10,
                          notifier: depth,
                          leading: "Depth"),
                      const SizedBox(
                        height: Config.padding * 2,
                      ),
                      Align(
                          alignment: Alignment.center,
                          child: Config.defaultText("Background color", 20)),
                      const SizedBox(
                        height: Config.padding,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 90),
                        child: ColorPicker(
                          pickerColor: pickerColor,
                          colorPickerWidth: 150,
                          onColorChanged: (newColor) {
                            pickerColor = newColor;
                            settings.backColor = RGB(
                                newColor.red, newColor.green, newColor.blue);
                          },
                        ),
                      )
                    ],
                  )),
            ));
  }

  static void showColorPicker(BuildContext context,
      {required void Function(Color) onColorChange,
      required void Function() onEnd,
      required Color pickerColor}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Pick a color!',
          style: TextStyle(
              fontSize: 20,
              fontFamily: Config.fontFamily,
              color: Config.iconColor),
        ),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickerColor,
            onColorChanged: onColorChange,
          ),
        ),
        actions: <Widget>[
          ElevatedButton(
            child: const Text('Select'),
            onPressed: () {
              onEnd();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

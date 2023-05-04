import 'package:flutter/material.dart';

import '../config/widget_config.dart';

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
    showAlertDialog(message, context, false, 180);
  }

  static void showAlertDialog(String text, BuildContext context,
      [bool noShadow = false, double height = 50]) {
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
}

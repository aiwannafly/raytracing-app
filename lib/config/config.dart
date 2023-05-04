import 'package:flutter/material.dart';

class Config {
  static const defaultRadius = 8.0;
  static const borderRadius = BorderRadius.all(Radius.circular(defaultRadius));
  static const iconColor = Colors.black87;
  static const menuColor = Color(0xFFF5EDEB);
  static final backIconColor = Colors.grey.shade100;
  static final hoverColor = Colors.grey.shade300;
  static const seedColor = Colors.orange;
  static final backColor = Colors.grey.shade200; // Color(0xFF070824);
  static const primaryColor = Colors.orangeAccent;
  static const padding = 10.0;
  static const iconSize = 25.0;
  static const paddingAll = EdgeInsets.all(padding);
  static const fontFamily = "Montserrat";

  static double pageWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double pageHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static Text defaultText(String text, [double fontSize = 18]) {
    return Text(
      text,
      style: TextStyle(
          color: Config.iconColor,
          fontFamily: Config.fontFamily,
          fontSize: fontSize),
    );
  }
}

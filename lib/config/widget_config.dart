import 'package:flutter/material.dart';

class WidgetConfig {
  static const defaultRadius = 8.0;
  static const borderRadius = BorderRadius.all(Radius.circular(defaultRadius));
  static const iconColor = Colors.black87;
  static const menuColor = Color(0xFFF5EDEB);
  static const backIconColor = Color(0xFFfff5f2);
  static const hoverColor = Color(0xFFACC2CB);
  static const seedColor = Colors.blue;
  static const backColor = Color(0xFF070824);
  static const primaryColor = Colors.blueAccent;
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
          color: WidgetConfig.iconColor,
          fontFamily: WidgetConfig.fontFamily,
          fontSize: fontSize),
    );
  }
}

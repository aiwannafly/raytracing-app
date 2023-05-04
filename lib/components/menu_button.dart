import 'package:flutter/material.dart';

import '../config/config.dart';

class MenuButton extends StatelessWidget {
  const MenuButton(
      {super.key,
      required this.text,
      required this.iconData,
      required this.onTap,
      required this.iconColor,
      required this.isActive});

  final String text;
  final IconData iconData;
  final VoidCallback onTap;
  final Color iconColor;
  final ValueNotifier isActive;

  Color get backColor => isActive.value ? Colors.white : Colors.grey.shade200;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: isActive,
      builder: (context, isActive, child) => ElevatedButton(
          onPressed: () {
            if (isActive) {
              onTap();
            }
          },
          style: ButtonStyle(
            foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
            backgroundColor: MaterialStateProperty.all<Color>(backColor),
            overlayColor: MaterialStateProperty.resolveWith<Color?>(
                  (Set<MaterialState> states) {
                if (states.contains(MaterialState.hovered)) {
                  return Config.seedColor.withOpacity(0.04);
                }
                if (states.contains(MaterialState.focused) ||
                    states.contains(MaterialState.pressed)) {
                  return Config.seedColor.withOpacity(0.12);
                }
                return null; // Defer to the widget's default.
              },
            ),
          ),
          child: Container(
            width: 140,
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    iconData,
                    color: iconColor,
                  ),
                  const SizedBox(
                    width: Config.padding / 2,
                  ),
                  Config.defaultText(text),
                  const SizedBox(
                    width: Config.padding,
                  ),
                ],
              ),
            ),
          )),
    );
  }
}

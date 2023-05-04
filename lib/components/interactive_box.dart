import 'package:flutter/material.dart';

import '../config/config.dart';

class InteractiveBox extends StatefulWidget {
  const InteractiveBox(
      {super.key,
      required this.child,
        required this.onTap,
        this.toolTip,
        this.size,
      this.backColor});

  final Widget child;
  final Color? backColor;
  final String? toolTip;
  final double? size;
  final VoidCallback onTap;

  @override
  State<InteractiveBox> createState() => _InteractiveBoxState();
}

class _InteractiveBoxState extends State<InteractiveBox> {
  bool hovered = false;
  static const padding = 2.0;
  static const _size = 40.0;

  double get size => widget.size?? _size;

  BorderRadius get borderRadius => Config.borderRadius;

  Color get borderColor => Colors.black54;

  double get borderWidth => 1;

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(
        horizontal: Config.padding / 2),
    child: Tooltip(
      message: widget.toolTip?? "",
      child: InkWell(
              onHover: (h) => setState(() => hovered = h),
              onTap: widget.onTap,
              borderRadius: borderRadius,
              child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: size,
                  width: size,
                  decoration: BoxDecoration(
                      borderRadius: borderRadius,
                      color: !hovered ? Config.backIconColor : Config.hoverColor,
                      // border: Border.all(color: borderColor, width: borderWidth)
                  ),
                  padding: const EdgeInsets.all(padding),
                  child: widget.child),
            )
          ),
    );
  }
}

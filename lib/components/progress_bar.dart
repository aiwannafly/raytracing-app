import 'package:flutter/material.dart';

import '../config/config.dart';

class TraceProgressIndicator extends StatefulWidget {
  const TraceProgressIndicator(
      {super.key, required this.current, required this.desired});

  final ValueNotifier<int> current;
  final int desired;

  @override
  State<TraceProgressIndicator> createState() => _TraceProgressIndicatorState();
}

class _TraceProgressIndicatorState extends State<TraceProgressIndicator> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: Config.paddingAll,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Config.defaultText('Ray tracing is running', 20),
          const SizedBox(height: 20),
          ValueListenableBuilder(
              valueListenable: widget.current,
              builder: (context, value, child) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                          width: 50,
                          alignment: Alignment.center,
                          child: Config.defaultText(
                              "${((value / widget.desired) * 100).round()}%",
                              20)),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: Config.pageWidth(context) * .5,
                        child: LinearProgressIndicator(
                          value: value / widget.desired,
                          color: Colors.orange,
                          minHeight: 10,
                          borderRadius: Config.borderRadius,
                          semanticsLabel: 'Progress indicator',
                        ),
                      ),
                    ],
                  )),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../config/config.dart';

class ValueSelector<T> extends StatelessWidget {
  const ValueSelector(
      {super.key,
      required this.notifier,
      required this.values,
      required this.getName});

  final ValueNotifier<T> notifier;
  final List<T> values;
  final String Function(T) getName;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: notifier,
      builder: (context, currentValue, child) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: values
              .map((value) => InkWell(
                    onTap: () {
                      notifier.value = value;
                    },
                    child: Container(
                      decoration: BoxDecoration(
                          borderRadius: Config.borderRadius,
                          border: Border.all(
                              color: Config.seedColor,
                              width: currentValue == value ? 2 : .5)),
                      padding: Config.paddingAll,
                      alignment: Alignment.center,
                      child: Config.defaultText(getName(value), 18),
                    ),
                  ))
              .toList()),
    );
  }
}

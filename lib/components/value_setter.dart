import 'package:flutter/material.dart';

import '../config/config.dart';
import '../services/service_io.dart';

class SliderTextSetter<T extends num> extends StatelessWidget {
  const SliderTextSetter({super.key, required this.minVal,
    required this.maxVal,
    required this.notifier,
    required this.leading,
    this.showText = true});

  final T minVal;
  final T maxVal;
  final ValueNotifier<T> notifier;
  final String leading;
  final bool showText;

  @override
  Widget build(BuildContext context) {
    final inputController = TextEditingController();
    void setCurrent() {
      if (T == int) {
        inputController.text = notifier.value.toString();
      } else {
        inputController.text = notifier.value.toStringAsFixed(2);
      }
    }
    setCurrent();
    return Container(
      alignment: Alignment.center,
      width: 420,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              leading,
              style: const TextStyle(
                  fontSize: 20,
                  fontFamily: Config.fontFamily,
                  color: Config.iconColor),
            ),
          ),
          Expanded(
            flex: 6,
            child: ValueListenableBuilder(
              valueListenable: notifier,
              builder: (ctx, val, child) => Slider(
                  max: maxVal.toDouble(),
                  min: minVal.toDouble(),
                  activeColor: Config.primaryColor,
                  thumbColor: Config.seedColor,
                  inactiveColor: Colors.grey,
                  value: notifier.value.toDouble(),
                  onChanged: (newVal) {
                    if (T == int) {
                      notifier.value = newVal.floor() as T;
                    } else {
                      notifier.value = newVal as T;
                    }
                    if (T == int) {
                      inputController.text = notifier.value.toString();
                    } else {
                      inputController.text = notifier.value.toStringAsFixed(2);
                    }
                  }),
            ),
          ),
          Expanded(
            flex: 2,
            child: ValueListenableBuilder(
              valueListenable: notifier,
              builder: (ctx, val, child) => Container(
                width: 70,
                alignment: Alignment.center,
                child: Visibility(
                  visible: showText,
                  child: TextFormField(
                    controller: inputController,
                    decoration: buildInputDecoration(),
                    textAlign: TextAlign.center,
                    onFieldSubmitted: (s) {
                      double? newVal = double.tryParse(s);
                      if (newVal == null) {
                        ServiceIO.showMessage("Enter a valid number", context);
                        setCurrent();
                        return;
                      }
                      if (newVal < minVal || newVal > maxVal) {
                        ServiceIO.showMessage(
                            "Enter a number in range [$minVal, ..., $maxVal]",
                            context);
                        setCurrent();
                        return;
                      }
                      if (T == int) {
                        notifier.value = newVal.floor() as T;
                      } else {
                        notifier.value = newVal as T;
                      }
                    },
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  static InputDecoration buildInputDecoration() {
    return InputDecoration(
      labelStyle: TextStyle(
          color: Config.iconColor.withOpacity(.7),
          fontFamily: Config.fontFamily),
      hintStyle: TextStyle(
        color: Config.iconColor.withOpacity(.7),
        fontFamily: Config.fontFamily,
      ),
      contentPadding: const EdgeInsets.all(0),
      floatingLabelAlignment: FloatingLabelAlignment.start,
      enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(width: .2, color: Colors.black87),
          borderRadius: Config.borderRadius),
      focusedBorder: const OutlineInputBorder(
          borderRadius: Config.borderRadius,
          borderSide: BorderSide(
              color: Colors.black54)),
      hoverColor: Config.primaryColor.shade100,
      fillColor: Colors.white70,
      filled: true,);
  }
}
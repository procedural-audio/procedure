import 'package:flutter/material.dart';
import 'dart:ffi';

import '../views/variables.dart';
import '../patch.dart';
import 'widget.dart';
import '../core.dart';
import '../module.dart';
import '../main.dart';

double Function(RawWidgetPointer) ffiInputGetValue = core
    .lookup<NativeFunction<Float Function(RawWidgetPointer)>>(
        "ffi_input_get_value")
    .asFunction();
void Function(RawWidgetPointer, double) ffiInputSetValue = core
    .lookup<NativeFunction<Void Function(RawWidgetPointer, Float)>>(
        "ffi_input_set_value")
    .asFunction();

class InputWidget extends ModuleWidget {
  InputWidget(Node n, RawNode m, RawWidget w) : super(n, m, w) {
    knobValue = ffiInputGetValue(widgetRaw.pointer);
  }

  TextEditingController controller = TextEditingController();

  double knobValue = 0.0;
  bool ignoreNextUpdate = false;

  @override
  bool canAcceptVars() {
    return true;
  }

  @override
  bool willAcceptVar(Var v) {
    return v.notifier.value is double ||
        v.notifier.value is bool ||
        v.notifier.value is int;
  }

  @override
  void onVarUpdate(dynamic value) {
    if (!ignoreNextUpdate) {
      if (value is double) {
        knobValue = value;
      } else if (value is int) {
        knobValue = value.toDouble();
      } else if (value is bool) {
        knobValue = value ? 1.0 : 0.0;
      } else {
        print("ERROR: Invalid type in input");
      }

      ffiInputSetValue(widgetRaw.pointer, knobValue);
      setState(() {});
    } else {
      ignoreNextUpdate = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    controller.text = knobValue.toString();

    return TextField(
      controller: controller,
      onChanged: (String s) {
        var v = double.tryParse(s);
        if (v != null) {
          knobValue = v;
          ffiInputSetValue(widgetRaw.pointer, v);
          ignoreNextUpdate = true;

          if (assignedVar.value != null) {
            if (assignedVar.value!.notifier.value is double) {
              assignedVar.value!.notifier.value = v;
            } else if (assignedVar.value!.notifier.value is int) {
              assignedVar.value!.notifier.value = v.toInt();
            } else if (assignedVar.value!.notifier.value is bool) {
              assignedVar.value!.notifier.value = v > 0.5;
            }
          }
        } else {
          print("Error: Invalid input");
        }
      },
      cursorColor: Colors.grey,
      style: const TextStyle(color: Colors.red, fontSize: 16),
      decoration: const InputDecoration(
        filled: true,
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.all(5.0),
        fillColor: Color.fromRGBO(20, 20, 20, 1.0),
        focusColor: Colors.red,
        iconColor: Colors.red,
        enabledBorder: OutlineInputBorder(
          borderSide:
              BorderSide(color: Color.fromRGBO(60, 60, 60, 1.0), width: 2.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red, width: 2.0),
        ),
      ),
    );
  }
}

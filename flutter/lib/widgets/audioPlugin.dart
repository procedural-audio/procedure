import 'package:flutter/material.dart';

import 'widget.dart';
import '../host.dart';

class AudioPluginWidget extends ModuleWidget {
  AudioPluginWidget(Host h, FFINode m, FFIWidget w) : super(h, m, w);

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 30,
        decoration: BoxDecoration(
            color: const Color.fromRGBO(40, 40, 40, 1.0),
            border: Border.all(color: Colors.blue, width: 2.0),
            borderRadius: const BorderRadius.all(Radius.circular(5))),
        child: Row(children: [
          GestureDetector(
              onTap: () {
                host.audioPlugins.showPlugin(api.ffiNodeGetId(moduleRaw));
              },
              child: Container(
                  width: 40,
                  decoration: const BoxDecoration(
                      color: Color.fromRGBO(40, 40, 40, 1.0),
                      borderRadius: BorderRadius.all(Radius.circular(5))),
                  child: const Icon(
                    Icons.desktop_windows,
                    color: Colors.blue,
                    size: 14,
                  ))),
          Container(
            width: 1,
            color: Colors.blue,
          ),
          Expanded(
              child: ValueListenableBuilder<List<String>>(
            valueListenable: host.audioPlugins.plugins,
            builder: (context, plugins, v) {
              return DropdownButton<String>(
                value: null,
                isExpanded: true,
                items: plugins
                    .map((String e) => DropdownMenuItem(
                        value: e,
                        child: Text(
                          e,
                          style:
                              const TextStyle(color: Colors.blue, fontSize: 14),
                        )))
                    .toList(),
                onChanged: (v) {
                  host.audioPlugins
                      .createPlugin(api.ffiNodeGetId(moduleRaw), v.toString());
                },
                isDense: true,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
                dropdownColor: const Color.fromRGBO(20, 20, 20, 1.0),
                iconSize: 20,
                underline: const SizedBox(),
              );
            },
          )),
        ]));
  }
}

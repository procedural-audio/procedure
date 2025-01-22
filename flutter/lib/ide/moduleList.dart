import 'package:flutter/material.dart';

import '../module/module.dart';
import '../plugins.dart';

class ModuleListSidebar extends StatefulWidget {
  const ModuleListSidebar({required this.selectedModule, Key? key})
      : super(key: key);

  final ValueNotifier<Module?> selectedModule;

  @override
  State<ModuleListSidebar> createState() => _ModuleListSidebarState();
}

class _ModuleListSidebarState extends State<ModuleListSidebar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      child: ModuleList(
        selectedModule: widget.selectedModule,
      ),
    );
  }
}

class ModuleList extends StatefulWidget {
  ModuleList({required this.selectedModule, Key? key}) : super(key: key);

  ValueNotifier<Module?> selectedModule;

  @override
  _ModuleListState createState() => _ModuleListState();
}

class _ModuleListState extends State<ModuleList> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: ValueListenableBuilder<List<Plugin>>(
          valueListenable: Plugins.list(),
          builder: (context, plugins, child) {
            if (plugins.isEmpty) {
              return Text("No plugins");
            }

            for (var plugin in plugins) {
              if (!plugin.modules().value.isEmpty) {
                return ValueListenableBuilder(
                  valueListenable: plugin.modules(),
                  builder: (context, modules, child) {
                    return ListView.builder(
                      itemCount: modules.length,
                      itemBuilder: (context, index) {
                        var module = modules[index];
                        return ListTile(
                            dense: true,
                            title: Text(module.name),
                            onTap: () {
                              print("Selected module: ${module.name}");
                              widget.selectedModule.value = module;
                            },
                            onLongPress: () {
                              print("Deselecting module");
                              widget.selectedModule.value = null;
                            });
                      },
                    );
                  },
                );
              }
            }

            return Text("No modules");
          },
        ),
      ),
      color: Colors.blueGrey,
    );
  }
}

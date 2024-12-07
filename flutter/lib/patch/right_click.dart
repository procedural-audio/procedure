import 'package:flutter/material.dart';

import '../views/settings.dart';

import '../plugins.dart';
import '../module/info.dart';

void add_module_to_category(
  Module module,
  double indent,
  List<String> categoryNames,
  List<RightClickCategory> categories,
  void Function(Module) onAddModule,
) {
  if (categoryNames.length == 0) {
    categoryNames = ["Miscellaneous"];
  }

  for (var category in categories) {
    if (category.name == categoryNames[0]) {
      if (categoryNames.length == 1) {
        category.elements.add(
          RightClickElement(
            module,
            indent,
            onAddModule,
          ),
        );
        return;
      } else {
        add_module_to_category(
          module,
          indent + 10,
          categoryNames.sublist(1),
          category.categories,
          onAddModule,
        );
        return;
      }
    }
  }

  RightClickCategory newCategory = RightClickCategory(
    categoryNames[0],
    indent,
  );

  if (categoryNames.length == 1) {
    // print("Adding " + module.name + " to category " + categoryNames.toString());
    newCategory.elements.add(
      RightClickElement(
        module,
        indent + 10,
        onAddModule,
      ),
    );
  } else {
    add_module_to_category(
      module,
      indent + 10,
      categoryNames.sublist(1),
      newCategory.categories,
      onAddModule,
    );
  }

  categories.add(newCategory);
}

class RightClickView extends StatefulWidget {
  RightClickView({super.key, required this.onAddModule});

  void Function(Module) onAddModule;

  @override
  State<RightClickView> createState() => _RightClickView();
}

class _RightClickView extends State<RightClickView> {
  String searchText = "";

  @override
  Widget build(BuildContext context) {
    // Build the plugin list
    return ValueListenableBuilder<List<Plugin>>(
      valueListenable: Plugins.list(),
      builder: (context, plugins, child) {
        return Stack(
          children: plugins.map((plugin) {
            // Build the module list
            return ValueListenableBuilder<List<Module>>(
              valueListenable: plugin.modules(),
              builder: (context, modules, child) {
                List<RightClickCategory> categories = [];

                for (var module in modules) {
                  add_module_to_category(
                    module,
                    4,
                    module.category,
                    categories,
                    widget.onAddModule,
                  );
                }

                return MouseRegion(
                  onEnter: (event) {
                    // widget.app.patchingScaleEnabled = false;
                  },
                  onExit: (event) {
                    // widget.app.patchingScaleEnabled = true;
                  },
                  child: Container(
                    width: 300,
                    child: Column(
                      children: [
                        /* Title */
                        Container(
                          height: 35,
                          padding: const EdgeInsets.all(10.0),
                          child: const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Modules",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                        ),

                        /* Search bar */
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 0, 10, 5),
                          child: Container(
                            height: 20,
                            child: TextField(
                              maxLines: 1,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                              ),
                              decoration: const InputDecoration(
                                fillColor: Color.fromARGB(255, 112, 35, 30),
                                border: OutlineInputBorder(),
                                contentPadding:
                                    EdgeInsets.fromLTRB(10, 10, 0, 3),
                              ),
                              onChanged: (data) {
                                setState(() {
                                  searchText = data;
                                });
                              },
                            ),
                            decoration: const BoxDecoration(
                              color: Colors.white70,
                              borderRadius: BorderRadius.all(
                                Radius.circular(5.0),
                              ),
                            ),
                          ),
                        ),

                        /* List */
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 300),
                          child: SingleChildScrollView(
                            controller: ScrollController(),
                            child: Column(
                              children: categories,
                            ),
                          ),
                        ),
                      ],
                    ),
                    decoration: BoxDecoration(
                      color: MyTheme.grey20,
                      border: Border.all(color: MyTheme.grey40),
                    ),
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }
}

class RightClickCategory extends StatefulWidget {
  final String name;
  final double indent;
  final List<RightClickCategory> categories = [];
  final List<RightClickElement> elements = [];

  RightClickCategory(this.name, this.indent, {super.key});

  @override
  State<RightClickCategory> createState() => _RightClickCategoryState();
}

class _RightClickCategoryState extends State<RightClickCategory> {
  bool hovering = false;
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
            MouseRegion(
              hitTestBehavior: HitTestBehavior.opaque,
              onEnter: (event) {
                setState(() {
                  hovering = true;
                });
              },
              onExit: (event) {
                setState(() {
                  hovering = false;
                });
              },
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    expanded = !expanded;
                  });
                },
                onSecondaryTap: () {},
                onPanStart: (e) {
                  setState(() {
                    expanded = !expanded;
                  });
                },
                onLongPress: () {},
                child: Container(
                  padding: EdgeInsets.fromLTRB(widget.indent, 0, 0, 0),
                  height: 24,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Icon(
                          expanded
                              ? Icons.arrow_drop_up
                              : Icons.arrow_drop_down,
                          color: MyTheme.textColorLight,
                          size: 20,
                        ),
                        Text(
                          widget.name,
                          style: const TextStyle(
                            color: MyTheme.textColorLight,
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: hovering ? MyTheme.grey40 : MyTheme.grey20,
                  ),
                ),
              ),
            ),
          ] +
          (expanded ? <Widget>[] + widget.elements + widget.categories : []),
    );
  }
}

class RightClickElement extends StatefulWidget {
  final Module module;
  final double indent;
  final void Function(Module info) onAddModule;

  const RightClickElement(this.module, this.indent, this.onAddModule,
      {super.key});

  @override
  State<RightClickElement> createState() => _RightClickElementState();
}

class _RightClickElementState extends State<RightClickElement> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    String name = widget.module.name;

    return MouseRegion(
      onEnter: (event) {
        setState(() {
          hovering = true;
        });
      },
      onExit: (event) {
        if (mounted) {
          setState(() {
            hovering = false;
          });
        }
      },
      child: GestureDetector(
        onTap: () {
          widget.onAddModule(widget.module);
        },
        child: Container(
          padding: EdgeInsets.fromLTRB(widget.indent, 0, 0, 0),
          height: 22,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Container(
                  width: 15,
                  height: 8,
                  decoration: BoxDecoration(
                    color: widget.module.color,
                    borderRadius: const BorderRadius.all(
                      Radius.circular(5.0),
                    ),
                  ),
                ),
                Container(
                  width: 6,
                ),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
          decoration: BoxDecoration(
            color: hovering ? MyTheme.grey40 : MyTheme.grey20,
          ),
        ),
      ),
    );
  }
}

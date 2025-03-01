import 'dart:io';

import 'package:flutter/material.dart';

import '../plugin/config.dart';
import '../views/settings.dart';
import '../plugin/plugin.dart';
import 'module.dart';

const int INDENT_SIZE = 10;

void add_module_to_category(
  Module module,
  double indent,
  String searchText,
  List<String> categoryNames,
  List<RightClickCategory> categories,
  void Function(Module) onAddModule,
) {
  if (categoryNames.length == 0) {
    categoryNames = ["Uncategorized"];
  }

  for (var category in categories) {
    if (category.name == categoryNames[0]) {
      if (categoryNames.length == 1) {
        // Add new element to the category
        category.elements.add(
          RightClickElement(
            module,
            indent + INDENT_SIZE,
            searchText,
            onAddModule,
          ),
        );

        // Sort elements of the added category
        category.elements.sort(
          (a, b) => a.module.name.compareTo(b.module.name),
        );

        return;
      } else {
        add_module_to_category(
          module,
          indent + INDENT_SIZE,
          searchText,
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
    searchText,
  );

  if (categoryNames.length == 1) {
    newCategory.elements.add(
      RightClickElement(
        module,
        indent + INDENT_SIZE,
        searchText,
        onAddModule,
      ),
    );
  } else {
    add_module_to_category(
      module,
      indent + INDENT_SIZE,
      searchText,
      categoryNames.sublist(1),
      newCategory.categories,
      onAddModule,
    );
  }

  // Add the new category to the list
  categories.add(newCategory);

  // Sort categories of the new category
  categories.sort((a, b) => a.name.compareTo(b.name));
}

class RightClickView extends StatefulWidget {
  RightClickView({super.key, required this.plugins, required this.onAddModule});

  List<Plugin> plugins;
  void Function(Module) onAddModule;

  @override
  State<RightClickView> createState() => _RightClickView();
}

class _RightClickView extends State<RightClickView> {
  String searchText = "";

  @override
  Widget build(BuildContext context) {
    // Build the module list
    List<RightClickCategory> categories = [];

    String lowerSearchText = searchText.toLowerCase();

    for (var plugin in widget.plugins) {
      for (var module in plugin.modules) {
        bool matchesSearch =
            module.name.toLowerCase().contains(lowerSearchText);

        for (var category in module.category) {
          if (category.toLowerCase().contains(lowerSearchText)) {
            matchesSearch = true;
            break;
          }
        }

        if (matchesSearch) {
          add_module_to_category(
            module,
            4,
            lowerSearchText,
            module.category,
            categories,
            widget.onAddModule,
          );
        }
      }
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
            Row(
              children: [
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
                Expanded(child: SizedBox()),
                IconButton(
                  icon: Icon(
                    Icons.code,
                    color: Colors.grey.shade600,
                    size: 14,
                  ),
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    print("Should open editor");
                    // Plugins.openEditor();
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.settings,
                    color: Colors.grey.shade600,
                    size: 14,
                  ),
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    showPluginConfig(context, widget.plugins);
                  },
                ),
              ],
            ),

            /* Search bar */
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 5),
              child: Container(
                height: 25,
                child: TextField(
                  maxLines: 1,
                  cursorHeight: 14,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(5.0),
                      ),
                      borderSide: BorderSide(
                        width: 2,
                        color: Colors.blueGrey,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(5.0),
                      ),
                      borderSide: BorderSide(
                        width: 2,
                        color: Colors.blueGrey,
                      ),
                    ),
                    contentPadding: EdgeInsets.fromLTRB(10, 10, 0, 3),
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
              constraints: const BoxConstraints(
                maxHeight: 300,
              ),
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
  }
}

class RightClickCategory extends StatefulWidget {
  final String name;
  final double indent;
  final String searchText;
  final List<RightClickCategory> categories = [];
  final List<RightClickElement> elements = [];

  RightClickCategory(
    this.name,
    this.indent,
    this.searchText, {
    super.key,
  });

  @override
  State<RightClickCategory> createState() => _RightClickCategoryState();
}

class _RightClickCategoryState extends State<RightClickCategory> {
  bool hovering = false;
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    bool searched = widget.searchText.length > 0;

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
          (expanded || searched
              ? <Widget>[] + widget.elements + widget.categories
              : []),
    );
  }
}

class RightClickElement extends StatefulWidget {
  final Module module;
  final double indent;
  final String searchText;
  final void Function(Module info) onAddModule;

  const RightClickElement(
    this.module,
    this.indent,
    this.searchText,
    this.onAddModule, {
    super.key,
  });

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
                    color: widget.module.color ??
                        widget.module.titleColor ??
                        widget.module.iconColor ??
                        Colors.grey,
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

import 'package:flutter/material.dart';

import 'settings.dart';

import '../main.dart';
import '../module.dart';
import '../plugins.dart';

class RightClickView extends StatefulWidget {
  RightClickView({
    required this.addPosition,
    required this.onAddModule,
  });

  Offset addPosition;
  void Function(ModuleInfo) onAddModule;

  @override
  State<RightClickView> createState() => _RightClickView();
}

class _RightClickView extends State<RightClickView> {
  String searchText = "";

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Plugin>>(
      valueListenable: PLUGINS.list(),
      builder: (context, plugins, child) {
        List<ModuleInfo> specs = [];

        for (var plugin in plugins) {
          specs.addAll(plugin.list().value);
        }

        List<RightClickCategory> categories = [];

        for (var spec in specs) {
          var path = spec.path;

          if (path.length == 1) {
            var name = path[0];
          } else if (path.length == 2) {
            var categoryName = path[0];
            var elementName = path[1];

            var element = RightClickElement(
              spec,
              Icons.piano,
              spec.color,
              20,
              widget.addPosition,
              widget.onAddModule,
            );

            bool foundCategory = false;
            for (var category in categories) {
              if (category.name == categoryName) {
                foundCategory = true;
                category.elements.add(element);
                break;
              }
            }

            if (!foundCategory) {
              categories.add(RightClickCategory(categoryName, 10, [element]));
            }
          } else if (path.length == 3) {
            var categoryName = path[0];
            var subCategoryName = path[1];
            var elementName = path[2];

            var element = RightClickElement(
              spec,
              Icons.piano,
              spec.color,
              30,
              widget.addPosition,
              widget.onAddModule,
            );

            bool foundCategory = false;
            for (var category in categories) {
              if (category.name == categoryName) {
                foundCategory = true;
                bool foundSubCategory = false;
                for (var subCategory in category.elements) {
                  if (subCategory is RightClickCategory) {
                    if (subCategory.name == subCategoryName) {
                      foundSubCategory = true;
                      subCategory.elements.add(element);
                      break;
                    }
                  }
                }

                if (!foundSubCategory) {
                  category.elements
                      .add(RightClickCategory(subCategoryName, 20, [element]));
                }
                break;
              }
            }

            if (!foundCategory) {
              categories.add(RightClickCategory(categoryName, 10, [
                RightClickCategory(subCategoryName, 20, [element])
              ]));
            }
          }
        }

        List<Widget> filteredWidgets = [];

        if (searchText != "") {
          for (var category in categories) {
            bool addedCategory = false;
            for (var element in category.elements) {
              bool addedSubCategory = false;
              if (element.runtimeType == RightClickCategory) {
                for (var element2 in (element as RightClickCategory).elements) {
                  if ((element2 as RightClickElement)
                      .spec
                      .path
                      .join("/")
                      .toLowerCase()
                      .contains(searchText.toLowerCase())) {
                    filteredWidgets.add(element2);
                  }
                }
              }
            }
          }
        } else {
          filteredWidgets = categories;
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
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: SingleChildScrollView(
                    controller: ScrollController(),
                    child: Column(
                      children: filteredWidgets,
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
  }
}

class RightClickCategory extends StatefulWidget {
  final String name;
  final double indent;
  final List<Widget> elements;

  RightClickCategory(this.name, this.indent, this.elements);

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
                    onTap: () {
                      setState(() {
                        expanded = !expanded;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.fromLTRB(widget.indent, 0, 0, 0),
                      height: 24,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Row(children: [
                          Icon(
                            expanded
                                ? Icons.arrow_drop_up
                                : Icons.arrow_drop_down,
                            //color: Colors.white,
                            color: MyTheme.textColorLight,
                            size: 20,
                          ),
                          Text(
                            widget.name,
                            style: const TextStyle(
                                //color: Colors.white,
                                color: MyTheme.textColorLight,
                                fontSize: 14,
                                fontWeight: FontWeight.w300),
                          )
                        ]),
                      ),
                      decoration: BoxDecoration(
                        color: hovering ? MyTheme.grey40 : MyTheme.grey20,
                      ),
                    )))
          ] +
          (expanded ? widget.elements : []),
    );
  }
}

class RightClickElement extends StatefulWidget {
  final ModuleInfo spec;
  final double indent;
  final IconData icon;
  final Color color;
  final Offset addPosition;
  final void Function(ModuleInfo info) onAddModule;

  // App app;

  RightClickElement(
      // this.app,
      this.spec,
      this.icon,
      this.color,
      this.indent,
      this.addPosition,
      this.onAddModule);

  @override
  State<RightClickElement> createState() => _RightClickElementState();
}

class _RightClickElementState extends State<RightClickElement> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    String name = widget.spec.path.last;

    return MouseRegion(
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
            onTap: () {
              print("TODO: Implement add module");
              widget.onAddModule(widget.spec);
              /*if (widget.app.project.value.patch.value
                  .addModule(widget.spec.id, widget.addPosition)) {
                gGridState?.refresh();
              } else {
                print("Couldn't add module");
              }*/
            },
            child: Container(
              padding: EdgeInsets.fromLTRB(widget.indent, 0, 0, 0),
              height: 22,
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: Row(children: [
                    Icon(
                      widget.icon,
                      color: widget.color,
                      size: 16,
                    ),
                    /*SvgPicture.file(
                  File(iconPath),
                  height: 16,
                  width: 16,
                  color: widget.color,
                  fit: BoxFit.fill,
                ),*/
                    Container(
                      width: 5,
                    ),
                    Text(
                      name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w300),
                    ),
                  ])),
              decoration: BoxDecoration(
                color: hovering ? MyTheme.grey40 : MyTheme.grey20,
              ),
            )));
  }
}

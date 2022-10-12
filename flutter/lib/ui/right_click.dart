import 'package:flutter/material.dart';

class RightClickMenu extends StatefulWidget {
  RightClickMenu({required this.addPosition});

  Offset addPosition;

  @override
  State<RightClickMenu> createState() => _RightClickMenu();
}

class _RightClickMenu extends State<RightClickMenu> {
  String searchText = "";

  @override
  Widget build(BuildContext context) {
    List<RightClickCategory> widgets = [];

    {
      List<Widget> category = [];

      category.add(RightClickElement("Container", Icons.loop, Colors.grey, 30, widget.addPosition));
      category.add(RightClickElement("Text", Icons.loop, Colors.grey, 30, widget.addPosition));
      category.add(RightClickElement("TextField", Icons.loop, Colors.grey, 30, widget.addPosition));

      widgets.add(RightClickCategory("Basic", 10, category));
    }

    {
      List<Widget> category = [];

      category.add(RightClickElement("Color", Icons.loop, Colors.grey, 30, widget.addPosition));
      category.add(RightClickElement("Image", Icons.loop, Colors.grey, 30, widget.addPosition));

      widgets.add(RightClickCategory("Decoration", 10, category));
    }

    {
      List<Widget> category = [];

      category.add(RightClickElement("Knob", Icons.loop, Colors.grey, 30, widget.addPosition));
      category.add(RightClickElement("Fader", Icons.loop, Colors.grey, 30, widget.addPosition));
      category.add(RightClickElement("Pad", Icons.loop, Colors.grey, 30, widget.addPosition));
      category.add(RightClickElement("Button", Icons.loop, Colors.grey, 30, widget.addPosition));

      widgets.add(RightClickCategory("Interactive", 10, category));
    }

    {
      List<Widget> category = [];

      category.add(RightClickElement("Stack", Icons.loop, Colors.grey, 30, widget.addPosition));
      category.add(RightClickElement("Row", Icons.loop, Colors.grey, 30, widget.addPosition));
      category.add(RightClickElement("Column", Icons.loop, Colors.grey, 30, widget.addPosition));
      category.add(RightClickElement("Grid", Icons.loop, Colors.grey, 30, widget.addPosition));

      category.add(RightClickElement("Position", Icons.loop, Colors.grey, 30, widget.addPosition));
      category.add(RightClickElement("Padding", Icons.loop, Colors.grey, 30, widget.addPosition));
      category.add(RightClickElement("Sized", Icons.loop, Colors.grey, 30, widget.addPosition));

      widgets.add(RightClickCategory("Layout", 10, category));
    }

    {
      List<Widget> category = [];

      category.add(RightClickElement("Volume Meter", Icons.loop, Colors.grey, 30, widget.addPosition));
      category.add(RightClickElement("Spectrum", Icons.loop, Colors.grey, 30, widget.addPosition));
      category.add(RightClickElement("Line Meter", Icons.loop, Colors.grey, 30, widget.addPosition));
      category.add(RightClickElement("Grid", Icons.loop, Colors.grey, 30, widget.addPosition));

      widgets.add(RightClickCategory("Metering", 10, category));
    }

    List<Widget> filteredWidgets = [];

    if (searchText != "") {
      for (var category in widgets) {
        bool addedCategory = false;
        for (var element in category.elements) {
          bool addedSubCategory = false;
          if (element.runtimeType == RightClickCategory) {
            for (var element2 in (element as RightClickCategory).elements) {
              if ((element2 as RightClickElement)
                  .name
                  .toLowerCase()
                  .contains(searchText.toLowerCase())) {
                /*if (!addedCategory) {
                  filteredWidgets.add(category);
                }

                if (!addedSubCategory) {
                  filteredWidgets.add(element);
                }*/

                filteredWidgets.add(element2);
              }
            }
          }
        }
      }
    } else {
      filteredWidgets = widgets;
    }

    return MouseRegion(
        onEnter: (event) {
          // globals.patchingScaleEnabled = false;
          // globals.window.patchingView.refresh();
        },
        onExit: (event) {
          // globals.patchingScaleEnabled = true;
          // globals.window.patchingView.refresh();
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
                    "Widgets",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.normal),
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
                        contentPadding: EdgeInsets.fromLTRB(10, 10, 0, 3)),
                    onChanged: (data) {
                      setState(() {
                        searchText = data;
                      });
                    },
                  ),
                  decoration: const BoxDecoration(
                      color: Colors.white70,
                      borderRadius: BorderRadius.all(Radius.circular(5.0))),
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
              color: const Color.fromRGBO(20, 20, 20, 1.0), border: Border.all(color: const Color.fromRGBO(40, 40, 40, 1.0))),
        ));
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
                            color: const Color.fromRGBO(200, 200, 200, 1.0),
                            size: 20,
                          ),
                          Text(
                            widget.name,
                            style: const TextStyle(
                                //color: Colors.white,
                                color: Color.fromRGBO(200, 200, 200, 1.0),
                                fontSize: 14,
                                fontWeight: FontWeight.w300),
                          )
                        ]),
                      ),
                      decoration: BoxDecoration(
                        color: hovering ? const Color.fromRGBO(40, 40, 40, 1.0) : const Color.fromRGBO(20, 20, 20, 1.0),
                      ),
                    )))
          ] +
          (expanded ? widget.elements : []),
    );
  }
}

class RightClickElement extends StatefulWidget {
  final String name;
  final double indent;
  final IconData icon;
  final Color color;
  String path = "logic/and.svg";
  final Offset addPosition;

  RightClickElement(this.name, this.icon, this.color, this.indent, this.addPosition);

  @override
  State<RightClickElement> createState() => _RightClickElementState();
}

class _RightClickElementState extends State<RightClickElement> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    //var iconPath = globals.contentPath + "/assets/icons/" + widget.path;
    //print(iconPath);

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
              /*if (globals.host.graph.addModule(widget.name, widget.addPosition)) {
                gGridState?.refresh();
              } else {
                print("Couldn't add module");
              }*/
              print("Add widget here");
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
                      widget.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w300),
                    ),
                  ])),
              decoration: BoxDecoration(
                color: hovering ? const Color.fromRGBO(40, 40, 40, 1.0) : const Color.fromRGBO(20, 20, 20, 1.0),
              ),
            )));
  }
}

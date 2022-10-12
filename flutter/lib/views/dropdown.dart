import 'package:metasampler/widgets/dropdown.dart';

import '../main.dart';
import 'package:flutter/material.dart';
import 'settings.dart';

class DropdownCategory {
  final String name;
  final List<DropdownElement> elements;

  DropdownCategory({required this.name, required this.elements});
}

class DropdownElement {
  final String name;
  bool checked = false;
  DropdownElement(this.name);
}

class DropdownCheckbox extends StatefulWidget {
  final String name;
  final bool checked;
  final void Function(bool) onChanged;

  DropdownCheckbox({required this.name, required this.checked, required this.onChanged});

  @override
  _DropdownCheckboxState createState() => _DropdownCheckboxState();
}

class _DropdownCheckboxState extends State<DropdownCheckbox> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
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
            widget.onChanged(!widget.checked);
          },
            child: Container(
              width: 140,
              height: 35,
              child: Row(
              children: [
                Transform.scale(
                  scale: 0.8,
                  child: Checkbox(
                    value: widget.checked,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(5))
                    ),
                    side: BorderSide(
                      color: MyTheme.grey70
                    ),
                    onChanged: (val) {
                      widget.onChanged(val ?? false);
                    },
                  ),
                ),
                Text(
                  widget.name,
                  style: const TextStyle(
                    color: MyTheme.textColorLight,
                    fontSize: 14
                  ), 
                ),
              ],
            ),
            decoration: BoxDecoration(
              color: hovering ? MyTheme.grey50 : MyTheme.grey40,
              borderRadius: BorderRadius.circular(5),
              /*border: Border.all(
                color: MyTheme.grey60,
                width: 1,
              ),*/
            ),
        )
      ),
    );
  }
}

class DropdownOverlay extends StatefulWidget {
  final DropdownOverlayState state;
  final List<DropdownCategory> categories;
  final double width;
  final void Function(String) onAdd;
  final void Function(String) onRemove;

  DropdownOverlay({required this.width, required this.state, required this.categories, required this.onAdd, required this.onRemove});

  @override
  DropdownOverlayState createState() => state;
}

class DropdownOverlayState extends State<DropdownOverlay> {
  bool _visible = false;
  bool hovering = false;

  void show() {
    setState(() {
      _visible = true;
    });
  }

  void hide () {
    setState(() {
      _visible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Column> columns = [];

    for (var category in widget.categories) {
      List<Widget> elements = [];
      elements.add(
        Container(
          padding: const EdgeInsets.fromLTRB(10, 5, 5, 5),
          width: 150,
          height: 30,
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Text(
              category.name,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14
              ),
            ),
          ),
        )
      );

      for (var element in category.elements) {
        elements.add(
          DropdownCheckbox(
            name: element.name,
            checked: element.checked,
            onChanged: (val) {
              setState(() {
                element.checked = val;
                if (val) {
                  widget.onAdd(element.name);
                } else {
                  widget.onRemove(element.name);
                }
              });
            },
          )
        );
      }
      columns.add(
        Column(
          children: elements,
        )
      );
    }

    return Visibility(
      visible: _visible || hovering,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
        child: Container(
          width: 1000,
          child: Align(
            alignment: Alignment.topCenter,
              child: Container(
                width: widget.width,
                height: 195,
                child: MouseRegion(
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
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: columns,
                    ),
                  )
                ),
                decoration: BoxDecoration(
                  color: MyTheme.grey40,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(5), top: Radius.circular(5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      spreadRadius: 5,
                      blurRadius: 5,
                      offset: const Offset(0, 10)
                    ),
                  ],
                ),
              ),
            ),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10.0))
            ),
          ),
        ),
      );
  }
}

class CustomDropdown extends StatefulWidget {
  const CustomDropdown({required this.text, required this.icon, required this.color, required this.onEnter, required this.onExit, Key? key}) : super(key: key);

  final String text;
  final Icon icon;
  final Color color;
  final void Function() onEnter;
  final void Function() onExit;

  @override
  _CustomDropdownState createState() => _CustomDropdownState();
}

class _CustomDropdownState extends State<CustomDropdown> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0), 
      child: MouseRegion(
        onEnter: (event) {
          widget.onEnter();

          setState(() {
            hovering = true;
          });
        },
        onExit: (event) {
          widget.onExit();

          setState(() {
            hovering = false;
          });
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
          height: 50,
          child: Row(
            children: [
              IconButton(
                icon: widget.icon,
                iconSize: 16,
                padding: const EdgeInsets.all(0),
                color: hovering ? widget.color: widget.color.withAlpha(180),
                onPressed: () {

                },
              ),
              Text(
                widget.text,
                style: TextStyle(
                  color: hovering ? Colors.white : Colors.white70,
                  fontSize: 14,
                ),
              ),
              /*IconButton(
                icon: const Icon(Icons.close),
                iconSize: 16,
                padding: const EdgeInsets.all(0),
                color: hovering ? Colors.white : MyTheme.grey40,
                onPressed: () {

                },
              ),*/
            ]
          ),
          decoration: BoxDecoration(
            color: hovering ? MyTheme.grey40 : MyTheme.grey30,
          ),
        )
      )
    );
  }
}

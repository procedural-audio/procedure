import 'package:flutter/material.dart';

class Category {
  Category({required this.name, required this.elements});

  String name;
  List<CategoryElement> elements;
}

class CategoryElement {
  CategoryElement(this.name, {this.color, this.icon});

  String name;
  Color? color;
  Icon? icon;
}

class TextBox extends StatelessWidget {
  TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: (String s) {},
      cursorColor: Colors.grey,
      style: const TextStyle(
        color: Colors.red,
        fontSize: 16,
      ),
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

class Dropdown extends StatefulWidget {
  Dropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    required this.color,
    this.underline = true,
    Key? key,
  }) : super(key: key);

  List<String> items;
  String value;
  void Function(int) onChanged;
  final Color color;
  final bool underline;

  @override
  State<Dropdown> createState() => _DropdownState();
}

class _DropdownState extends State<Dropdown> {
  @override
  Widget build(BuildContext context) {
    return ButtonTheme(
      padding: const EdgeInsets.all(0),
      layoutBehavior: ButtonBarLayoutBehavior.constrained,
      child: DropdownButton<String>(
        value: widget.value,
        iconEnabledColor: widget.color,
        iconDisabledColor: const Color.fromRGBO(30, 30, 30, 1.0),
        focusColor: const Color.fromRGBO(40, 40, 40, 1.0),
        icon: const Icon(
          Icons.keyboard_arrow_down,
        ),
        elevation: 14,
        style: TextStyle(
          color: widget.color,
          fontSize: 14,
        ),
        dropdownColor: const Color.fromRGBO(30, 30, 30, 1.0),
        iconSize: 14,
        itemHeight: 48,
        underline: Container(
          height: widget.underline ? 1 : 0,
          color: widget.color,
        ),
        onChanged: (String? newValue) {
          int i = 0;

          for (var item in widget.items) {
            if (item == newValue!) {
              widget.onChanged(i);
            }

            i++;
          }

          setState(() {
            widget.value = newValue!;
          });
        },
        isDense: false,
        items: widget.items.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
              style: TextStyle(
                color: widget.color,
                fontSize: 14,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class SearchableDropdown extends StatefulWidget {
  SearchableDropdown({
    required this.value,
    required this.categories,
    required this.onSelect,
    this.width,
    this.height,
    this.titleStyle = const TextStyle(fontSize: 14, color: Colors.grey),
    this.decoration = const BoxDecoration(
      color: Color.fromRGBO(20, 20, 20, 1.0),
      borderRadius: BorderRadius.all(Radius.circular(3)),
    ),
  });

  String? value;
  List<Category> categories;
  void Function(String?) onSelect;
  double? width;
  double? height;
  BoxDecoration decoration;
  TextStyle titleStyle;

  @override
  State<SearchableDropdown> createState() => _SearchableDropdown();
}

class _SearchableDropdown extends State<SearchableDropdown>
    with TickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  AnimationController? _animationController;

  // final FocusNode textFieldFocus = FocusNode();
  final FocusScopeNode _focusScopeNode = FocusScopeNode();

  TextEditingController searchController = TextEditingController(text: "");

  // final FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 0));

    // textFieldFocus.addListener(onTextFieldFocus);
  }

  void toggleDropdown({bool? open}) async {
    if (_isOpen || open == false) {
      await _animationController?.reverse();
      _overlayEntry?.remove();
      setState(() {
        _isOpen = false;
      });
    } else if (!_isOpen || open == true) {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context)?.insert(_overlayEntry!);
      setState(() => _isOpen = true);
      _animationController?.forward();
    }
  }

  /*void onTextFieldFocus() async {
    print("CHANGED FOCUS HERE");
    if (_isOpen) {
      await _animationController?.reverse();
      _overlayEntry?.remove();
      setState(() {
        _isOpen = false;
      });
    } else {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
      setState(() => _isOpen = true);
      _animationController?.forward();
    }
  }*/

  @override
  void dispose() {
    _focusScopeNode.dispose();
    // textFieldFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
        link: _layerLink,
        child: GestureDetector(
            onTap: () {
              toggleDropdown();
            },
            child: Container(
                width: widget.width,
                height: widget.height,
                decoration: widget.decoration,
                padding: const EdgeInsets.fromLTRB(10, 0, 5, 0),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(widget.value ?? "", style: widget.titleStyle),
                      const Icon(
                        Icons.arrow_drop_down,
                        size: 20,
                        color: Color.fromRGBO(200, 200, 200, 1.0),
                      )
                    ]))));
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;

    var size = renderBox.size;
    var offset = renderBox.localToGlobal(Offset.zero);

    print("Width is " + MediaQuery.of(context).size.width.toString());

    return OverlayEntry(
        maintainState: false,
        opaque: false,
        builder: (entryContext) {
          return FocusScope(
              node: _focusScopeNode,
              child: GestureDetector(
                  onTap: () {
                    toggleDropdown(open: false);
                  },
                  onSecondaryTap: () {
                    toggleDropdown(open: false);
                  },
                  onPanStart: (e) {
                    toggleDropdown(open: false);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                      child: Stack(children: [
                        Positioned(
                            left: offset.dx - 50,
                            top: offset.dy + size.height + 5,
                            child: CompositedTransformFollower(
                                offset: Offset(0, size.height),
                                link: _layerLink,
                                showWhenUnlinked: false,
                                child: Material(
                                    elevation: 0,
                                    borderRadius: BorderRadius.zero,
                                    color: Colors.transparent,
                                    child: Container(
                                      decoration: BoxDecoration(
                                          color: const Color.fromRGBO(
                                              20, 20, 20, 1.0),
                                          borderRadius:
                                              BorderRadius.circular(5),
                                          border: Border.all(
                                              color: const Color.fromRGBO(
                                                  40, 40, 40, 1.0),
                                              width: 1.0)),
                                      child: Column(
                                          mainAxisSize: MainAxisSize.max,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: widget.categories.map((e) {
                                            return SearchableDropdownCategory(
                                              name: e.name,
                                              elements: e.elements,
                                              onSelect: widget.onSelect,
                                            );
                                          }).toList()),
                                    ))))
                      ]))));
        });
  }
}

class SearchableDropdownCategory extends StatefulWidget {
  final String name;
  final List<CategoryElement> elements;
  void Function(String?) onSelect;

  SearchableDropdownCategory(
      {required this.name, required this.elements, required this.onSelect});

  @override
  State<SearchableDropdownCategory> createState() =>
      _SearchableDropdownCategory();
}

class _SearchableDropdownCategory extends State<SearchableDropdownCategory> {
  bool hovering = false;
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 200,
        child: Column(
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
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          print("Tapped");
                          setState(() {
                            expanded = !expanded;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                          height: 24,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Row(children: [
                              Icon(
                                expanded
                                    ? Icons.arrow_drop_up
                                    : Icons.arrow_drop_down,
                                color: const Color.fromRGBO(200, 200, 200, 1.0),
                                size: 20,
                              ),
                              Text(
                                widget.name,
                                style: const TextStyle(
                                    color: Color.fromRGBO(200, 200, 200, 1.0),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w300),
                              )
                            ]),
                          ),
                          decoration: BoxDecoration(
                            color: !hovering
                                ? const Color.fromRGBO(20, 20, 20, 1.0)
                                : const Color.fromRGBO(40, 40, 40, 1.0),
                          ),
                        )))
              ] +
              (expanded
                  ? widget.elements
                      .map((e) =>
                          SearchableDropdownElement(e.name, widget.onSelect))
                      .toList()
                  : []),
        ));
  }
}

class SearchableDropdownElement extends StatefulWidget {
  final String name;
  final void Function(String) onSelect;

  const SearchableDropdownElement(this.name, this.onSelect);

  @override
  State<SearchableDropdownElement> createState() =>
      _SearchableDropdownElement();
}

class _SearchableDropdownElement extends State<SearchableDropdownElement> {
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
              print("Tapped child");
              widget.onSelect(widget.name);
            },
            child: Container(
              height: 22,
              padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: Row(children: [
                    const Icon(
                      Icons.settings,
                      color: Colors.blue,
                      size: 16,
                    ),
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
                color: !hovering
                    ? const Color.fromRGBO(20, 20, 20, 1.0)
                    : const Color.fromRGBO(40, 40, 40, 1.0),
              ),
            )));
  }
}

class Keyboard extends StatelessWidget {
  Keyboard(
      {this.keyWidth = 25.0,
      this.keySpacing = 1.0,
      this.keyHeight = 50,
      this.keyCount = 88,
      this.widthRatio = 2 / 3,
      this.heightRatio = 2 / 3,
      required this.onKeyPress,
      required this.onKeyRelease,
      required this.getKeyDown});

  final double keyWidth;
  final double keySpacing;
  final double keyHeight;
  final double widthRatio;
  final double heightRatio;
  final int keyCount;
  void Function(int) onKeyPress;
  void Function(int) onKeyRelease;
  bool Function(int) getKeyDown;

  ScrollController controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    List<Widget> whiteKeys = [];
    List<Widget> blackKeys = [];

    double x = 0.0;
    for (int i = 0; i < keyCount; i++) {
      int j = i % 12;
      if (j == 1 || j == 3 || j == 6 || j == 8 || j == 10) {
        blackKeys.add(Positioned(
            left: x - keyWidth * (widthRatio / 2),
            top: 0,
            child: KeyWidget(
              index: i,
              onPress: (i) {
                onKeyPress(i);
              },
              onRelease: (i) {
                onKeyRelease(i);
              },
              color: Colors.black,
              down: getKeyDown(i),
              width: keyWidth * widthRatio,
              spacing: keySpacing,
              height: keyHeight * heightRatio,
            )));
      } else {
        whiteKeys.add(Positioned(
            left: x,
            top: 0,
            child: KeyWidget(
              index: i,
              onPress: (i) {
                onKeyPress(i);
              },
              onRelease: (i) {
                onKeyRelease(i);
              },
              color: Colors.white,
              down: getKeyDown(i),
              width: keyWidth,
              spacing: keySpacing,
              height: keyHeight,
            )));

        x += keyWidth;
      }
    }

    return Scrollbar(
        thumbVisibility: true,
        trackVisibility: true,
        thickness: 4,
        controller: controller,
        scrollbarOrientation: ScrollbarOrientation.bottom,
        child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: controller,
            child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                child: Container(
                    width: x,
                    height: keyHeight,
                    color: const Color.fromRGBO(20, 20, 20, 1.0),
                    child: Stack(
                      children: whiteKeys + blackKeys,
                    )))));
  }
}

class KeyWidget extends StatelessWidget {
  KeyWidget(
      {required this.index,
      required this.color,
      required this.down,
      required this.width,
      required this.spacing,
      required this.height,
      required this.onPress,
      required this.onRelease});

  int index;
  Color color;
  bool down;
  double width;
  double spacing;
  double height;
  void Function(int) onPress;
  void Function(int) onRelease;

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.all(spacing),
        child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (details) {
              onPress(index);
            },
            onPointerUp: (details) {
              onRelease(index);
            },
            onPointerCancel: (details) {
              onRelease(index);
            },
            child: GestureDetector(
                onTap: () {},
                child: Container(
                    width: width - spacing * 2,
                    height: height,
                    decoration: BoxDecoration(
                        color: down ? color.withOpacity(0.5) : color,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(0),
                            bottom: Radius.circular(3)))))));
  }
}

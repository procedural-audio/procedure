import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

class SearchableDropdown extends StatefulWidget {
  SearchableDropdown(
      {required this.value,
      required this.categories,
      required this.onSelect,
      this.width,
      this.height});

  String? value;
  List<Category> categories;
  void Function(String?) onSelect;
  double? width;
  double? height;

  @override
  State<SearchableDropdown> createState() => _SearchableDropdown();
}

class _SearchableDropdown extends State<SearchableDropdown>
    with TickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  AnimationController? _animationController;

  FocusNode textFieldFocus = FocusNode();

  TextEditingController controller = TextEditingController(text: "");

  final FocusScopeNode _focusScopeNode = FocusScopeNode();
  final FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 0));

    textFieldFocus.addListener(onTextFieldFocus);
  }

  void onTextFieldFocus() async {
    if (_isOpen) {
      await _animationController?.reverse();
      _overlayEntry?.remove();
      setState(() {
        _isOpen = false;
      });
    } else {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context)?.insert(_overlayEntry!);
      setState(() => _isOpen = true);
      _animationController?.forward();
    }
  }

  @override
  void dispose() {
    _focusScopeNode.dispose();
    textFieldFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
        link: _layerLink,
        child: Container(
            width: widget.width,
            height: widget.height,
            padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
            decoration: BoxDecoration(
                color: const Color.fromRGBO(20, 20, 20, 1.0),
                border: Border.all(
                    color: const Color.fromRGBO(80, 80, 80, 1.0), width: 1),
                borderRadius: BorderRadius.circular(5)),
            child: Row(children: [
              Expanded(
                  child: TextField(
                      focusNode: textFieldFocus,
                      controller: controller,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                          hintText: widget.value,
                          hintStyle:
                              const TextStyle(color: Colors.grey, fontSize: 14),
                          isDense: true,
                          border: InputBorder.none),
                      onChanged: (v) {
                        print("Search updated");
                      })),
              const SizedBox(
                width: 14,
                child: Icon(Icons.search,
                    color: Color.fromRGBO(60, 60, 60, 1.0), size: 16),
              )
            ])));
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;

    var size = renderBox.size;
    var offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
        maintainState: false,
        opaque: false,
        builder: (entryContext) {
          return FocusScope(
              autofocus: true,
              node: _focusScopeNode,
              child: GestureDetector(
                  onTap: () {
                    textFieldFocus.unfocus();
                  },
                  behavior: HitTestBehavior.opaque,
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
                                      color:
                                          const Color.fromRGBO(20, 20, 20, 1.0),
                                      borderRadius: BorderRadius.circular(5),
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
                  ])));
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
                        onTap: () {
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

import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:metasampler/views/info.dart';

import '../host.dart';
import 'settings.dart';

class BrowserView extends StatefulWidget {
  BrowserView(this.host);

  Host host;

  @override
  State<BrowserView> createState() => _BrowserView();
}

class _BrowserView extends State<BrowserView> {
  bool expanded = false;
  String searchText = "";
  ValueNotifier<int> selectedIndex = ValueNotifier(-1);

  ScrollController controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.fromLTRB(0, 15, 0, 0),
        child: Stack(children: [
          Column(children: [
            Padding(
                padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
                child: BrowserSearchBar(onFilter: (s) {
                  setState(() {
                    searchText = s;
                  });
                })),
            const SizedBox(height: 10),
            Expanded(
                child: ValueListenableBuilder<List<InstrumentInfo>>(
              valueListenable: widget.host.globals.instruments,
              builder: (context, instruments, w) {
                List<InstrumentInfo> filteredInstruments = [];

                if (searchText == "") {
                  filteredInstruments = instruments;
                } else {
                  for (var instrument in instruments) {
                    if (instrument.name
                            .toLowerCase()
                            .contains(searchText.toLowerCase()) ||
                        instrument.description
                            .toLowerCase()
                            .contains(searchText.toLowerCase())) {
                      filteredInstruments.add(instrument);
                    }
                  }
                }

                if (filteredInstruments.isEmpty) {
                  return Container();
                }

                return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
                    controller: controller,
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 200,
                            childAspectRatio: 1.0,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 15),
                    itemCount: filteredInstruments.length,
                    itemBuilder: (BuildContext ctx, index) {
                      return BrowserViewElement(
                        index: index,
                        info: filteredInstruments[index],
                        selectedIndex: selectedIndex,
                      );
                    });
              },
            ))
          ]),
          InfoView(
            widget.host,
            index: selectedIndex,
          )
        ]));
  }
}

class BrowserSearchBar extends StatelessWidget {
  BrowserSearchBar({required this.onFilter});

  void Function(String) onFilter;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
          width: 200,
          height: 26,
          decoration: const BoxDecoration(
              color: Color.fromRGBO(30, 30, 30, 1.0),
              borderRadius: BorderRadius.all(Radius.circular(5))),
          child: TextField(
              maxLines: 1,
              style: const TextStyle(
                color: Color.fromRGBO(220, 220, 220, 1.0),
                fontSize: 14,
              ),
              decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(8),
                  prefixIconColor: Colors.grey,
                  prefixIcon: Icon(
                    Icons.search,
                  )),
              onChanged: (text) {
                onFilter(text);
              })),
      Expanded(
          child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                BrowserTag(title: "Type", tags: [
                  "Sound",
                  "Effect",
                  "Application",
                ]),
                BrowserTag(title: "Category", tags: []),
                BrowserTag(title: "Genre", tags: []),
                BrowserTag(
                    title: "Other", tags: ["Generative", "Analog", "Digital"]),
              ])))
    ]);
  }
}

class BrowserTag extends StatelessWidget {
  BrowserTag({required this.title, required this.tags});

  String title;
  List<String> tags;

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
        child: Container(
          height: 24,
          alignment: Alignment.center,
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
          decoration: const BoxDecoration(
              color: Color.fromRGBO(50, 50, 50, 1.0),
              borderRadius: BorderRadius.all(Radius.circular(12)),
              boxShadow: []),
          child: Text(
            title,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ));
  }
}

class InfoView extends StatefulWidget {
  InfoView(this.host, {required this.index});

  Host host;

  ValueNotifier<int> index;

  @override
  State<InfoView> createState() => _InfoView();
}

class _InfoView extends State<InfoView> {
  bool mouseOver = false;

  var name = "";
  var description = "";

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      double width = constraints.maxWidth;

      return ValueListenableBuilder<int>(
          valueListenable: widget.index,
          builder: (context, index, w) {
            if (index >= 0) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                // STUFF HERE?
                color: const Color.fromRGBO(40, 40, 40, 1.0),
              );
            } else {
              return const SizedBox(
                width: 0,
                height: 0,
              );
            }
          });
    });
  }
}

class BrowserViewElement extends StatefulWidget {
  BrowserViewElement(
      {required this.index, required this.info, required this.selectedIndex});

  int index;
  InstrumentInfo info;
  ValueNotifier<int> selectedIndex;

  @override
  State<BrowserViewElement> createState() => _BrowserViewElement();
}

class _BrowserViewElement extends State<BrowserViewElement> {
  bool mouseOver = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
        onEnter: (details) {
          setState(() {
            mouseOver = true;
          });
        },
        onExit: (details) {
          setState(() {
            mouseOver = false;
          });
        },
        child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 290,
            height: mouseOver ? 300 : 200,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(5)),
                color: mouseOver
                    ? const Color.fromRGBO(70, 70, 70, 1.0)
                    : const Color.fromRGBO(50, 50, 50, 1.0),
                boxShadow: [
                  BoxShadow(
                      blurRadius: 3,
                      spreadRadius: 3,
                      offset: const Offset(0, 3),
                      color: Color.fromRGBO(0, 0, 0, mouseOver ? 0.3 : 0.0))
                ]),
            child: Column(children: [
              Expanded(
                  child: ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(5)),
                      child: Image.file(widget.info.image,
                          width: 290, fit: BoxFit.cover))),
              Container(
                  height: 56,
                  alignment: Alignment.topLeft,
                  padding: const EdgeInsets.all(4),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Text(widget.info.name,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color.fromRGBO(220, 220, 220, 1.0))),
                        const SizedBox(height: 4),
                        Text(
                            widget.info.description.substring(0,
                                    min(40, widget.info.description.length)) +
                                (widget.info.description.length < 40
                                    ? ""
                                    : "..."),
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                color: Colors.grey)),
                      ]))
            ])));
  }
}

/*class _BrowserViewElement extends State<BrowserViewElement> {
  bool mouseOver = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
        onEnter: (details) {
          setState(() {
            mouseOver = true;
          });
        },
        onExit: (details) {
          setState(() {
            mouseOver = false;
          });
        },
        child: Stack(children: [
          ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(5)),
              child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: const Color.fromRGBO(60, 60, 60, 1.0),
                      borderRadius: BorderRadius.circular(5)),
                  child: Stack(children: [
                    Image.file(
                      widget.info.image,
                      width: 290,
                      fit: BoxFit.fitWidth,
                    ),
                    AnimatedOpacity(
                        opacity: mouseOver ? 0.3 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          color: Colors.grey,
                        )),
                    GestureDetector(onTap: () {
                      widget.selectedIndex.value = widget.index;
                    })
                  ]))),
          Align(
              alignment: Alignment.bottomLeft,
              child: Row(children: [
                ClipRect(
                    child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
                        child: Container(
                            height: 26,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                            decoration: const BoxDecoration(
                                color: Color.fromRGBO(0, 0, 0, 0.4),
                                borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(5))),
                            child: Text(widget.info.name,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400)))))
              ]))
        ])));
  }
}*/

class BrowserListCard extends StatelessWidget {
  final String name;
  final String selected;
  final IconData icon;
  final bool visible;
  final bool dense;
  final void Function() onTap;

  BrowserListCard(
      {required this.name,
      required this.icon,
      required this.selected,
      required this.visible,
      required this.dense,
      required this.onTap})
      : super(key: UniqueKey());

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: visible,
      child: Card(
        margin: !dense
            ? const EdgeInsets.fromLTRB(5, 5, 5, 0)
            : const EdgeInsets.fromLTRB(5, 0, 5, 0),
        color: MyTheme.grey20,
        child: ListTile(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
          leading: dense ? Icon(icon, size: 18) : Icon(icon, size: 22),
          title: Text(
            name,
            style: dense
                ? const TextStyle(fontSize: 14)
                : const TextStyle(fontSize: 16),
          ),
          textColor: selected == name ? Colors.white : Colors.white30,
          iconColor: selected == name ? Colors.white : Colors.white30,
          tileColor: selected == name
              ? const Color.fromRGBO(255, 255, 255, 0.1)
              : MyTheme.grey20,
          dense: dense,
          minLeadingWidth: 26,
          onTap: onTap,
        ),
      ),
    );
  }
}

class BrowserInfoWidget extends StatefulWidget {
  BrowserInfoWidget(this.host, {Key? key}) : super(key: key);

  Host host;

  @override
  _BrowserInfoWidgetState createState() => _BrowserInfoWidgetState();
}

class _BrowserInfoWidgetState extends State<BrowserInfoWidget> {
  bool editing = false;

  // AudioPlayer player = AudioPlayer();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 1100,
        ),
        child: Padding(
          padding: widget.host.globals.settings.showTopBar
              ? const EdgeInsets.fromLTRB(51, 54 + 55, 51, 51)
              : const EdgeInsets.fromLTRB(51, 51 + 50 + 1, 51, 51),
          child: Container(
            decoration: BoxDecoration(
              color: MyTheme.grey30,
            ),
            child: Column(children: <Widget>[
              InfoContentsWidget(
                widget.host,
                instrument: widget.host.globals.browserInstrument,
              ),
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.download),
              ),
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.download),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

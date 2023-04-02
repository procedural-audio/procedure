import 'package:metasampler/plugins.dart';
import 'package:metasampler/views/presets.dart';
import 'package:flutter/material.dart';

import '../patch.dart';
import '../main.dart';
import '../projects.dart';

import 'browser.dart';

class Bar extends StatefulWidget {
  Bar({
    required this.app,
    required this.instViewVisible,
    required this.onViewSwitch,
    required this.onUserInterfaceEdit,
  });

  App app;
  bool instViewVisible;
  void Function() onViewSwitch;
  void Function() onUserInterfaceEdit;

  @override
  _Bar createState() => _Bar();
}

class _Bar extends State<Bar> {
  bool barExpanded = false;

  bool showInstrumentView = false;
  bool showPresetView = false;
  bool showOtherView = false;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Project>(
      valueListenable: widget.app.project,
      builder: (context, project, child) {
        return Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BarButton(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(10.0),
                    ),
                    iconData:
                        widget.instViewVisible ? Icons.cable : Icons.piano,
                    onTap: () {
                      widget.onViewSwitch();
                    },
                  ),
                  ValueListenableBuilder<String>(
                    valueListenable: project.info.name,
                    builder: (context, name, child) {
                      return BarDropdown(
                        width: 180,
                        text: name,
                        onTap: () {
                          setState(() {
                            showInstrumentView = !showInstrumentView;
                            showPresetView = false;
                            showOtherView = false;
                          });
                        },
                      );
                    },
                  ),
                  ValueListenableBuilder<Patch>(
                    valueListenable: project.patch,
                    builder: (context, patch, child) {
                      return ValueListenableBuilder<String>(
                        valueListenable: patch.name,
                        builder: (context, name, child) {
                          return BarDropdown(
                            width: 180,
                            text: name,
                            onTap: () {
                              setState(() {
                                showPresetView = !showPresetView;
                                showInstrumentView = false;
                                showOtherView = false;
                              });
                            },
                          );
                        },
                      );
                    },
                  ),
                  BarButton(
                    iconData: Icons.edit,
                    onTap: () {
                      widget.onUserInterfaceEdit();
                    },
                  ),
                  BarButton(
                    iconData: showOtherView
                        ? Icons.arrow_drop_down
                        : Icons.arrow_drop_up,
                    onTap: () {
                      setState(() {
                        showOtherView = !showOtherView;
                        showInstrumentView = false;
                        showPresetView = false;
                      });
                    },
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(10.0),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Visibility(
                visible: showInstrumentView || showPresetView || showOtherView,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 40, 0, 0),
                  child: Container(
                    width: barExpanded ? 710 : 525,
                    height: 600,
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(40, 40, 40, 1.0),
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                      border: Border.all(
                        width: 1,
                        color: const Color.fromRGBO(70, 70, 70, 1.0),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Visibility(
                          visible: showInstrumentView,
                          child: BrowserView(widget.app),
                        ),
                        Visibility(
                          visible: showPresetView,
                          child: project.presets,
                        ),
                        Visibility(
                          visible: showOtherView,
                          child: OtherView(widget.app),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class BarButton extends StatefulWidget {
  BarButton(
      {required this.iconData,
      required this.onTap,
      this.borderRadius,
      this.iconColor});

  IconData iconData;
  void Function() onTap;
  BorderRadius? borderRadius;
  Color? iconColor;

  @override
  _BarButton createState() => _BarButton();
}

class _BarButton extends State<BarButton> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (e) => setState(() {
        hovering = true;
      }),
      onExit: (e) => setState(() {
        hovering = false;
      }),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.fastLinearToSlowEaseIn,
          width: 45,
          height: 35,
          decoration: BoxDecoration(
            color: hovering
                ? const Color.fromRGBO(60, 60, 60, 1.0)
                : const Color.fromRGBO(50, 50, 50, 1.0),
            borderRadius: widget.borderRadius,
          ),
          child: Icon(
            widget.iconData,
            color: hovering ? Colors.white : Colors.grey,
            size: 18,
          ),
        ),
      ),
    );
  }
}

class BarDropdown extends StatefulWidget {
  BarDropdown({required this.text, required this.onTap, this.width});

  double? width;
  String text;
  void Function() onTap;

  @override
  _BarDropdown createState() => _BarDropdown();
}

class _BarDropdown extends State<BarDropdown> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (e) => setState(() {
        hovering = true;
      }),
      onExit: (e) => setState(() {
        hovering = false;
      }),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 35,
          width: widget.width,
          alignment: Alignment.center,
          color: hovering
              ? const Color.fromRGBO(60, 60, 60, 1.0)
              : const Color.fromRGBO(50, 50, 50, 1.0),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: Text(
            widget.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
      ),
    );
  }
}

class OtherView extends StatelessWidget {
  OtherView(this.app, {super.key});

  App app;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color.fromRGBO(20, 20, 20, 1.0),
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        child: DefaultTabController(
          initialIndex: 0,
          length: 4,
          child: Scaffold(
            backgroundColor: const Color.fromRGBO(80, 80, 80, 1.0),
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(50),
              child: Theme(
                data: ThemeData(splashFactory: NoSplash.splashFactory),
                child: AppBar(
                  toolbarHeight: 0,
                  foregroundColor: Colors.black,
                  backgroundColor: const Color.fromRGBO(50, 50, 50, 1.0),
                  bottom: const TabBar(
                    tabs: <Widget>[
                      Tab(
                        text: "Assets",
                      ),
                      Tab(
                        text: "Samples",
                      ),
                      Tab(
                        text: "Plugins",
                      ),
                      Tab(
                        text: "Settings",
                      ),
                    ],
                  ),
                ),
              ),
            ),
            body: Container(
              color: const Color.fromRGBO(40, 40, 40, 1.0),
              child: TabBarView(
                children: <Widget>[
                  const Center(
                    child: Text("It's cloudy here"),
                  ),
                  const Center(
                    child: Text("It's rainy here"),
                  ),
                  PLUGINS,
                  const Center(
                    child: Text("It's other here"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:metasampler/views/presets.dart';

import '../host.dart';
import '../main.dart';
import 'package:flutter/material.dart';

import 'browser.dart';
import 'info.dart';

class Bar extends StatefulWidget {
  Bar(this.window, this.host);

  Window window;
  Host host;

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
    return Stack(
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder(
                valueListenable: widget.window.instViewVisible,
                builder: (context, visible, child) {
                  return BarButton(
                    borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(10.0)),
                    iconData: widget.window.instViewVisible.value
                        ? Icons.cable
                        : Icons.piano,
                    onTap: () {
                      var vis = widget.window.instViewVisible;
                      vis.value = !vis.value;
                    },
                  );
                },
              ),
              ValueListenableBuilder<InstrumentInfo>(
                valueListenable: widget.host.loadedInstrument,
                builder: (context, value, child) {
                  return BarDropdown(
                    width: 180,
                    text: value.name,
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
              ValueListenableBuilder(
                // CHANGE TO LOADED PRESET
                valueListenable: widget.host.loadedInstrument,
                builder: (context, value, child) {
                  return BarDropdown(
                    width: 180,
                    text: widget.host.globals.preset.name,
                    onTap: () {
                      setState(() {
                        showPresetView = !showPresetView;
                        showInstrumentView = false;
                        showOtherView = false;
                      });
                    },
                  );
                },
              ),
              BarButton(
                iconData: Icons.edit,
                onTap: () {
                  setState(() {
                    var editing = widget.window.instrumentView.tree.editing;
                    editing.value = !editing.value;
                  });
                },
              ),
              BarButton(
                iconData:
                    showOtherView ? Icons.arrow_drop_down : Icons.arrow_drop_up,
                onTap: () {
                  setState(() {
                    showOtherView = !showOtherView;
                    showInstrumentView = false;
                    showPresetView = false;
                  });
                },
                borderRadius:
                    const BorderRadius.only(bottomRight: Radius.circular(10.0)),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (showInstrumentView || showPresetView || showOtherView) {
                return Padding(
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
                            child: BrowserView(widget.host)),
                        Visibility(
                            visible: showPresetView,
                            child: PresetsView(widget.host)),
                        Visibility(
                            visible: showOtherView,
                            child: OtherView(widget.host)),
                      ],
                    ),
                  ),
                );
              } else {
                return const SizedBox(width: 0, height: 0);
              }
            },
          ),
        ),
      ],
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
              borderRadius: widget.borderRadius),
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
                color: Colors.white, fontSize: 15, fontWeight: FontWeight.w300),
          ),
        ),
      ),
    );
  }
}

class OtherView extends StatelessWidget {
  OtherView(this.host, {super.key});

  Host host;

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
                  Center(
                    child: Text("It's cloudy here"),
                  ),
                  Center(
                    child: Text("It's rainy here"),
                  ),
                  Center(
                    child: Text("It's sunny here"),
                  ),
                  Center(
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

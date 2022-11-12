import 'dart:convert';
import 'dart:io';

import 'package:metasampler/instrument.dart';
import 'package:metasampler/views/presets.dart';

import '../host.dart';
import '../main.dart';
import 'package:flutter/material.dart';

import 'browser.dart';
import 'variables.dart';

class Bar extends StatefulWidget {
  Bar(this.window, this.host);

  Window window;
  Host host;

  @override
  _Bar createState() => _Bar();
}

class _Bar extends State<Bar> {
  bool barExpanded = false;

  bool instrumentBrowserExpanded = false;
  bool presetBrowserExpanded = false;

  bool variableViewVisible = false;

  @override
  Widget build(BuildContext context) {
    const double barWidth = 500.0;
    const double barExpandedWidth = 700.0;
    const double expandedHeight = 500;
    const double radius = 10.0;

    return Padding(
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
        child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BarButton(
                        borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(radius)),
                        iconData: widget.window.instViewVisible.value
                            ? Icons.cable
                            : Icons.piano,
                        onTap: () {
                          widget.window.instViewVisible.value =
                              !widget.window.instViewVisible.value;
                        }),
                    Container(
                      width: 1,
                      height: 35,
                      color: const Color.fromRGBO(50, 50, 50, 1.0),
                    ),
                    BarDropdown(
                        text: widget.host.globals.instrument.name,
                        onTap: () {
                          setState(() {
                            instrumentBrowserExpanded =
                                !instrumentBrowserExpanded;
                            presetBrowserExpanded = false;
                            variableViewVisible = false;
                          });
                        }),
                    /*Container(
                    width: 1,
                    height: barHeight-10,
                    color: const Color.fromRGBO(80, 80, 80, 1.0),
                  ),*/
                    BarDropdown(
                        text: widget.host.globals.preset.name,
                        onTap: () {
                          setState(() {
                            presetBrowserExpanded = !presetBrowserExpanded;
                            instrumentBrowserExpanded = false;
                            variableViewVisible = false;
                          });
                        }),
                    Container(
                      width: 1,
                      height: 35,
                      color: const Color.fromRGBO(50, 50, 50, 1.0),
                    ),
                    BarButton(
                        iconData: Icons.save,
                        onTap: () {
                          widget.host.saveInstrument();
                        }),
                    BarButton(
                        iconData: Icons.edit,
                        onTap: () {
                          setState(() {
                            widget.window.instrumentView.tree.editing.value =
                                !widget
                                    .window.instrumentView.tree.editing.value;
                          });
                        }),
                    AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.fastLinearToSlowEaseIn,
                        width: barExpanded ? 4 * 45 + 10 : 0,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: barExpanded
                              ? [
                                  Expanded(
                                      child: Container(
                                    color:
                                        const Color.fromRGBO(40, 40, 40, 1.0),
                                    height: 35,
                                  )),
                                  BarButton(
                                      iconData: Icons.functions,
                                      onTap: () {
                                        setState(() {
                                          variableViewVisible =
                                              !variableViewVisible;
                                          instrumentBrowserExpanded = false;
                                          presetBrowserExpanded = false;
                                        });
                                      }),
                                  BarButton(
                                      iconData: Icons.graphic_eq,
                                      onTap: () {
                                        setState(() {
                                          barExpanded = !barExpanded;
                                        });
                                      }),
                                  BarButton(
                                      iconData: Icons.plumbing,
                                      onTap: () {
                                        setState(() {
                                          barExpanded = !barExpanded;
                                        });
                                      }),
                                  BarButton(
                                      iconData: Icons.settings,
                                      onTap: () {
                                        setState(() {
                                          barExpanded = !barExpanded;
                                        });
                                      }),
                                  Expanded(
                                      child: Container(
                                    color:
                                        const Color.fromRGBO(40, 40, 40, 1.0),
                                    height: 35,
                                  ))
                                ]
                              : [
                                  Expanded(
                                    child: Container(
                                      color:
                                          const Color.fromRGBO(40, 40, 40, 1.0),
                                      height: 35,
                                    ),
                                  )
                                ],
                        )),
                    BarButton(
                        iconData: Icons.arrow_downward,
                        borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(radius)),
                        onTap: () {
                          setState(() {
                            barExpanded = !barExpanded;
                          });
                        }),
                  ]),
              Builder(builder: (context) {
                return LayoutBuilder(builder: (context, constraints) {
                  if (instrumentBrowserExpanded) {
                    return Padding(
                        padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                        child: Container(
                          height: 600,
                          width: barExpanded ? 600 : 500,
                          child: BrowserView(widget.host),
                        ));
                  } else if (presetBrowserExpanded) {
                    return Container(
                        height: 400,
                        width: barExpanded ? 600 : 500,
                        padding: const EdgeInsets.fromLTRB(5, 0, 5, 5),
                        child: PresetsView(widget.host));
                  } else if (variableViewVisible) {
                    return Padding(
                        padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                        child: Container(
                            height: 400,
                            width: barExpanded ? 600 : 500,
                            decoration: BoxDecoration(
                                color: const Color.fromRGBO(40, 40, 40, 1.0),
                                borderRadius: BorderRadius.circular(10)),
                            child: widget.host.vars));
                  } else {
                    return const SizedBox(width: 0, height: 0);
                  }
                });
              })
            ]))));
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
              width: hovering ? 50 : 45,
              height: hovering ? 40 : 35,
              decoration: BoxDecoration(
                  color: hovering
                      ? const Color.fromRGBO(50, 50, 50, 1.0)
                      : const Color.fromRGBO(40, 40, 40, 1.0),
                  borderRadius: hovering
                      ? BorderRadius.only(
                          topLeft: widget.borderRadius != null
                              ? widget.borderRadius!.topLeft
                              : Radius.zero,
                          topRight: widget.borderRadius != null
                              ? widget.borderRadius!.topRight
                              : Radius.zero,
                          bottomLeft: const Radius.circular(5),
                          bottomRight: const Radius.circular(5))
                      : widget.borderRadius),
              child: Icon(
                widget.iconData,
                color: hovering ? Colors.white : Colors.grey,
                size: 18,
              ))),
    );
  }
}

class BarDropdown extends StatefulWidget {
  BarDropdown({required this.text, required this.onTap});

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
                alignment: Alignment.center,
                color: hovering
                    ? const Color.fromRGBO(50, 50, 50, 1.0)
                    : const Color.fromRGBO(40, 40, 40, 1.0),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Text(
                  widget.text,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w300),
                ))));
  }
}

class ExtendedBar extends StatefulWidget {
  @override
  _ExtendedBar createState() => _ExtendedBar();
}

class _ExtendedBar extends State<Bar> {
  final double width = 50.0;
  final double height = 35.0;
  final double radius = 10.0;

  int selected = -1;
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      selected >= 0
          ? GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() {
                  selected = -1;
                });
              },
            )
          : Container(),
      AnimatedPositioned(
          top: 60,
          // bottom: 20,
          right: selected == 0 ? 10 : -290,
          curve: Curves.fastLinearToSlowEaseIn,
          duration: const Duration(milliseconds: 500),
          child: AnimatedOpacity(
              opacity: selected == 0 ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: widget.host.vars)),
      AnimatedPositioned(
        top: 60,
        right: selected == 1 ? 10 : -290,
        curve: Curves.fastLinearToSlowEaseIn,
        duration: const Duration(milliseconds: 500),
        child: AnimatedOpacity(
          opacity: selected == 1 ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Container(
            width: 290,
            height: 600,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(radius)),
                color: const Color.fromRGBO(40, 40, 40, 1.0)),
          ),
        ),
      ),
      AnimatedPositioned(
        top: 60,
        // bottom: 20,
        right: selected == 3 ? 10 : -290,
        curve: Curves.fastLinearToSlowEaseIn,
        duration: const Duration(milliseconds: 500),
        child: AnimatedOpacity(
            opacity: selected == 3 ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: BrowserView(widget.host)),
      ),
      Positioned(
        right: 0,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Container(
              //width: expanded ? width * 5 : width,
              height: height,
              decoration: BoxDecoration(
                  color: const Color.fromRGBO(50, 50, 50, 1.0),
                  borderRadius: BorderRadius.all(Radius.circular(radius))),
              child: Stack(children: [
                selected >= 0
                    ? AnimatedPositioned(
                        left: width * selected,
                        curve: Curves.fastLinearToSlowEaseIn,
                        duration: const Duration(milliseconds: 500),
                        child: Container(
                          width: width,
                          height: height,
                          decoration: BoxDecoration(
                              color: const Color.fromRGBO(80, 80, 80, 0.5),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(radius))),
                        ),
                      )
                    : Container(),
                Row(
                  children: [
                    AnimatedSize(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.fastLinearToSlowEaseIn,
                      child: SizedBox(
                          width: expanded ? width * 5 : 0,
                          height: height,
                          child: Row(
                            children: [
                              Container(
                                // Parameters
                                width: width,
                                alignment: Alignment.center,
                                child: IconButton(
                                  icon: const Icon(Icons.code),
                                  iconSize: 20,
                                  color: Colors.white,
                                  onPressed: () {
                                    setState(() {
                                      selected = 0;
                                    });
                                  },
                                ),
                              ),
                              Container(
                                // Samples
                                width: width,
                                alignment: Alignment.center,
                                child: IconButton(
                                  icon: const Icon(Icons.graphic_eq),
                                  iconSize: 18,
                                  color: Colors.white,
                                  onPressed: () {
                                    setState(() {
                                      selected = 1;
                                    });
                                  },
                                ),
                              ),
                              Container(
                                // Unknown
                                width: width,
                                alignment: Alignment.center,
                                child: IconButton(
                                  icon: const Icon(Icons.device_unknown),
                                  iconSize: 18,
                                  color: Colors.white,
                                  onPressed: () {
                                    setState(() {
                                      selected = 2;
                                    });
                                  },
                                ),
                              ),
                              Container(
                                // Browser
                                width: width,
                                alignment: Alignment.center,
                                child: IconButton(
                                  icon: const Icon(Icons.view_module),
                                  iconSize: 18,
                                  color: Colors.white,
                                  onPressed: () {
                                    setState(() {
                                      selected = 3;
                                    });
                                  },
                                ),
                              ),
                              Container(
                                // Settings
                                width: width,
                                alignment: Alignment.center,
                                child: IconButton(
                                  icon: const Icon(Icons.settings),
                                  iconSize: 18,
                                  color: Colors.white,
                                  onPressed: () {
                                    setState(() {
                                      selected = 4;
                                    });
                                  },
                                ),
                              ),
                            ],
                          )),
                    ),
                    expanded
                        ? Container(
                            width: 2,
                            height: height - 10,
                            decoration: BoxDecoration(
                                border: Border.all(
                                    color:
                                        const Color.fromRGBO(80, 80, 80, 1.0),
                                    width: 2.0)),
                          )
                        : Container(),
                    AnimatedRotation(
                      turns: expanded ? 0 : -0.25,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.fastLinearToSlowEaseIn,
                      child: Container(
                        width: 40,
                        alignment: Alignment.center,
                        child: IconButton(
                          icon: const Icon(Icons.chevron_left),
                          iconSize: 18,
                          color: Colors.white,
                          onPressed: () {
                            setState(() {
                              selected = -1;
                              expanded = !expanded;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ])),
        ),
      )
    ]);
  }
}

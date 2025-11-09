import 'dart:math';

import 'package:flutter/material.dart';
import 'package:procedure_ui/interface/ui.dart';

import 'package:procedure_ui/app_main.dart';

class TransformData {
  TransformData(
      {required this.width,
      required this.height,
      required this.left,
      required this.top,
      required this.alignment,
      required this.padding});
  double? width;
  double? height;

  double left;
  double top;

  Alignment alignment;
  EdgeInsets padding;

  static TransformData fromJson(Map<String, dynamic> json) {
    int a = json["alignment"];
    Alignment alignment = Alignment.center;

    if (a == 1) {
      alignment = Alignment.bottomCenter;
    } else if (a == 2) {
      alignment = Alignment.bottomLeft;
    } else if (a == 3) {
      alignment = Alignment.bottomRight;
    } else if (a == 4) {
      alignment = Alignment.center;
    } else if (a == 5) {
      alignment = Alignment.centerLeft;
    } else if (a == 6) {
      alignment = Alignment.centerRight;
    } else if (a == 7) {
      alignment = Alignment.topCenter;
    } else if (a == 8) {
      alignment = Alignment.topLeft;
    } else if (a == 9) {
      alignment = Alignment.topRight;
    }

    return TransformData(
        width: json["width"],
        height: json["height"],
        left: json["left"],
        top: json["top"],
        alignment: alignment,
        padding: EdgeInsets.fromLTRB(json["padding_left"], json["padding_top"],
            json["padding_right"], json["padding_bottom"]));
  }

  Map<String, dynamic> toJson() {
    int a = 0;

    if (alignment == Alignment.bottomCenter) {
      a = 1;
    } else if (alignment == Alignment.bottomLeft) {
      a = 2;
    } else if (alignment == Alignment.bottomRight) {
      a = 3;
    } else if (alignment == Alignment.center) {
      a = 4;
    } else if (alignment == Alignment.centerLeft) {
      a = 5;
    } else if (alignment == Alignment.centerRight) {
      a = 6;
    } else if (alignment == Alignment.topCenter) {
      a = 7;
    } else if (alignment == Alignment.topLeft) {
      a = 8;
    } else if (alignment == Alignment.topRight) {
      a = 9;
    }

    return {
      "width": width,
      "height": height,
      "left": left,
      "top": top,
      "alignment": a,
      "padding_left": padding.left,
      "padding_top": padding.top,
      "padding_right": padding.right,
      "padding_bottom": padding.bottom,
    };
  }
}

class TransformWidget extends StatefulWidget {
  TransformWidget({super.key, required this.data, required this.child});

  Widget? child;
  TransformData data;

  @override
  State<TransformWidget> createState() => _TransformWidget();
}

class _TransformWidget extends State<TransformWidget> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      double left = 0;
      double top = 0;

      if (widget.data.width != null) {
        // Left horizontal alignment
        if (widget.data.alignment == Alignment.topLeft ||
            widget.data.alignment == Alignment.centerLeft ||
            widget.data.alignment == Alignment.bottomLeft) {
          left = widget.data.left;
        }

        // Center horizontal alignment
        if (widget.data.alignment == Alignment.topCenter ||
            widget.data.alignment == Alignment.center ||
            widget.data.alignment == Alignment.bottomCenter) {
          left = constraints.maxWidth / 2 -
              widget.data.width! / 2 +
              widget.data.left;
        }

        // Right horizontal alignment
        if (widget.data.alignment == Alignment.topRight ||
            widget.data.alignment == Alignment.centerRight ||
            widget.data.alignment == Alignment.bottomRight) {
          left = constraints.maxWidth - widget.data.width! + widget.data.left;
        }
      }

      if (widget.data.height != null) {
        // Top vertical alignment
        if (widget.data.alignment == Alignment.topLeft ||
            widget.data.alignment == Alignment.topCenter ||
            widget.data.alignment == Alignment.topRight) {
          top = widget.data.top;
        }

        // Center vertical alignment
        if (widget.data.alignment == Alignment.centerLeft ||
            widget.data.alignment == Alignment.center ||
            widget.data.alignment == Alignment.centerRight) {
          top = constraints.maxHeight / 2 -
              widget.data.height! / 2 +
              widget.data.top;
        }

        // Bottom vertical alignment
        if (widget.data.alignment == Alignment.bottomLeft ||
            widget.data.alignment == Alignment.bottomCenter ||
            widget.data.alignment == Alignment.bottomRight) {
          top = constraints.maxHeight - widget.data.height! + widget.data.top;
        }
      }

      return Padding(
          padding: widget.data.padding,
          child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                  padding: EdgeInsets.fromLTRB(left, top, 0, 0),
                  child: SizedBox(
                    width: widget.data.width,
                    height: widget.data.height,
                    child: widget.child,
                  ))));
    });
  }
}

class TransformWidgetEditing extends StatefulWidget {
  TransformWidgetEditing(
      {super.key,
      required this.data,
      required this.child,
      required this.onUpdate,
      required this.onTap,
      required this.ui});

  Widget? child;
  TransformData data;
  Function(TransformData) onUpdate;
  Function() onTap;
  UserInterface ui;

  @override
  State<TransformWidgetEditing> createState() => _TransformWidgetEditing();
}

class _TransformWidgetEditing extends State<TransformWidgetEditing> {
  bool hovering = false;
  bool dragging = false;

  void constrain(BoxConstraints constraints) {
    print("Called constrain");

    if (widget.data.width != null) {
      if (widget.data.width! < 30) {
        widget.data.width = 30;
      }

      // Left alignment
      if (widget.data.alignment == Alignment.topLeft ||
          widget.data.alignment == Alignment.centerLeft ||
          widget.data.alignment == Alignment.bottomLeft) {
        if (widget.data.left < 0) {
          widget.data.left = 0;
        }

        if (widget.data.left >
            constraints.maxWidth -
                widget.data.width! -
                widget.data.padding.left -
                widget.data.padding.right) {
          widget.data.left = constraints.maxWidth -
              widget.data.width! -
              widget.data.padding.left -
              widget.data.padding.right;
        }
      }

      // Center alignment
      if (widget.data.alignment == Alignment.topCenter ||
          widget.data.alignment == Alignment.center ||
          widget.data.alignment == Alignment.bottomCenter) {
        if (widget.data.left <
            -constraints.maxWidth / 2 + widget.data.width! / 2) {
          widget.data.left = -constraints.maxWidth / 2 + widget.data.width! / 2;
        }

        if (widget.data.left >
            constraints.maxWidth / 2 -
                widget.data.width! / 2 -
                widget.data.padding.left -
                widget.data.padding.right) {
          widget.data.left = constraints.maxWidth / 2 -
              widget.data.width! / 2 -
              widget.data.padding.left -
              widget.data.padding.right;
        }
      }

      // Right alignment
      if (widget.data.alignment == Alignment.topRight ||
          widget.data.alignment == Alignment.centerRight ||
          widget.data.alignment == Alignment.bottomRight) {
        if (widget.data.left > 0) {
          widget.data.left = 0;
        }

        if (widget.data.left <
            -(constraints.maxWidth -
                widget.data.width! -
                widget.data.padding.left -
                widget.data.padding.right)) {
          widget.data.left = -(constraints.maxWidth -
              widget.data.width! -
              widget.data.padding.left -
              widget.data.padding.right);
        }
      }
    }

    if (widget.data.height != null) {
      if (widget.data.height! < 30) {
        widget.data.height = 30;
      }

      // Top alignment
      if (widget.data.alignment == Alignment.topLeft ||
          widget.data.alignment == Alignment.topCenter ||
          widget.data.alignment == Alignment.topRight) {
        if (widget.data.top < 0) {
          widget.data.top = 0;
        }

        if (widget.data.top >
            constraints.maxHeight -
                widget.data.height! -
                widget.data.padding.top -
                widget.data.padding.bottom) {
          widget.data.top = constraints.maxHeight -
              widget.data.height! -
              widget.data.padding.top -
              widget.data.padding.bottom;
        }
      }

      // Center alignment
      if (widget.data.alignment == Alignment.centerLeft ||
          widget.data.alignment == Alignment.center ||
          widget.data.alignment == Alignment.centerRight) {
        if (widget.data.top <
            -constraints.maxHeight / 2 + widget.data.height! / 2) {
          widget.data.top =
              -constraints.maxHeight / 2 + widget.data.height! / 2;
        }

        if (widget.data.top >
            constraints.maxHeight / 2 -
                widget.data.height! / 2 -
                widget.data.padding.top -
                widget.data.padding.bottom) {
          widget.data.top = constraints.maxHeight / 2 -
              widget.data.height! / 2 -
              widget.data.padding.top -
              widget.data.padding.bottom;
        }
      }

      // Bottom alignment
      if (widget.data.alignment == Alignment.bottomLeft ||
          widget.data.alignment == Alignment.bottomCenter ||
          widget.data.alignment == Alignment.bottomRight) {
        if (widget.data.top > 0) {
          widget.data.top = 0;
        }

        if (widget.data.top <
            -(constraints.maxHeight -
                widget.data.height! -
                widget.data.padding.top -
                widget.data.padding.bottom)) {
          widget.data.top = -(constraints.maxHeight -
              widget.data.height! -
              widget.data.padding.top -
              widget.data.padding.bottom);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // constrain(constraints);

        double left = 0;
        double top = 0;

        if (widget.data.width != null) {
          // Left horizontal alignment
          if (widget.data.alignment == Alignment.topLeft ||
              widget.data.alignment == Alignment.centerLeft ||
              widget.data.alignment == Alignment.bottomLeft) {
            left = widget.data.left;
          }

          // Center horizontal alignment
          if (widget.data.alignment == Alignment.topCenter ||
              widget.data.alignment == Alignment.center ||
              widget.data.alignment == Alignment.bottomCenter) {
            left = constraints.maxWidth / 2 -
                widget.data.width! / 2 +
                widget.data.left;
          }

          // Right horizontal alignment
          if (widget.data.alignment == Alignment.topRight ||
              widget.data.alignment == Alignment.centerRight ||
              widget.data.alignment == Alignment.bottomRight) {
            left = constraints.maxWidth - widget.data.width! + widget.data.left;
          }
        }

        if (widget.data.height != null) {
          // Top vertical alignment
          if (widget.data.alignment == Alignment.topLeft ||
              widget.data.alignment == Alignment.topCenter ||
              widget.data.alignment == Alignment.topRight) {
            top = widget.data.top;
          }

          // Center vertical alignment
          if (widget.data.alignment == Alignment.centerLeft ||
              widget.data.alignment == Alignment.center ||
              widget.data.alignment == Alignment.centerRight) {
            top = constraints.maxHeight / 2 -
                widget.data.height! / 2 +
                widget.data.top;
          }

          // Bottom vertical alignment
          if (widget.data.alignment == Alignment.bottomLeft ||
              widget.data.alignment == Alignment.bottomCenter ||
              widget.data.alignment == Alignment.bottomRight) {
            top = constraints.maxHeight - widget.data.height! + widget.data.top;
          }
        }

        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Padding(
            padding: widget.data.padding,
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: EdgeInsets.fromLTRB(left, top, 0, 0),
                child: SizedBox(
                  width: widget.data.width,
                  height: widget.data.height,
                  child: Resizer(
                    data: widget.data,
                    dragging: dragging,
                    onUpdate: (data) {
                      setState(() {
                        widget.data = data;
                        constrain(constraints);
                      });
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        MouseRegion(
                            opaque: true,
                            hitTestBehavior: HitTestBehavior.deferToChild,
                            onEnter: (e) {
                              setState(() {
                                hovering = true;
                              });
                            },
                            onExit: (e) {
                              setState(() {
                                hovering = false;
                              });
                            },
                            child: GestureDetector(
                              onTap: () {
                                widget.onTap();
                              },
                              onPanStart: (e) {
                                setState(() {
                                  dragging = true;
                                });
                              },
                              onPanUpdate: (details) {
                                widget.data.left += details.delta.dx;
                                widget.data.top += details.delta.dy;

                                constrain(constraints);

                                widget.onUpdate(widget.data);
                              },
                              onPanEnd: (details) {
                                setState(() {
                                  dragging = false;
                                });
                                widget.ui.selected.notifyListeners();
                              },
                              child: widget.child,
                            )),
                        IgnorePointer(
                          child: Visibility(
                            visible: hovering,
                            child: Container(
                              width: widget.data.width,
                              height: widget.data.height,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.blue,
                                  width: 2.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class Resizer extends StatefulWidget {
  Resizer(
      {super.key,
      required this.data,
      required this.onUpdate,
      required this.child,
      required this.dragging});

  TransformData data;
  void Function(TransformData) onUpdate;
  Widget? child;
  bool selected = false;
  bool dragging;

  @override
  _Resizer createState() => _Resizer();
}

class _Resizer extends State<Resizer> {
  bool hovering = false;
  bool panning = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (e) {
        setState(() {
          hovering = true;
        });
      },
      onExit: (e) {
        setState(() {
          hovering = false;
        });
      },
      child: Stack(
        children: [
          Padding(
            padding: (hovering || panning)
                ? const EdgeInsets.all(0)
                : const EdgeInsets.all(0),
            child: widget.child,
          ),
          Visibility(
            visible: hovering || panning,
            child: Padding(
              padding: (hovering || panning) && !widget.dragging
                  ? const EdgeInsets.all(0)
                  : const EdgeInsets.all(0),
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey,
                      width: 1.0,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: widget.selected ? Colors.blue : Colors.white,
                        width: 1.0,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey,
                          width: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Visibility(
            maintainState: true,
            visible: (hovering || panning) &&
                widget.data.width != null &&
                !widget.dragging,
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 2, 0),
                child: GestureDetector(
                  child: Container(
                      width: 8,
                      height: 25,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey, width: 1.0),
                        borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(10.0)),
                      )),
                  onPanStart: (e) {
                    setState(() {
                      panning = true;
                    });
                  },
                  onPanEnd: (e) {
                    setState(() {
                      panning = false;
                    });
                  },
                  onPanUpdate: (e) {
                    if (widget.data.width != null) {
                      widget.data.width = widget.data.width! + e.delta.dx;
                    }

                    widget.onUpdate(widget.data);
                  },
                ),
              ),
            ),
          ),
          Visibility(
            maintainState: true,
            visible: (hovering || panning) &&
                widget.data.height != null &&
                !widget.dragging,
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 2, 0, 0),
                child: GestureDetector(
                  child: Container(
                    width: 25,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: Colors.grey,
                        width: 1.0,
                      ),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(10.0),
                      ),
                    ),
                  ),
                  onPanStart: (e) {
                    setState(() {
                      panning = true;
                    });
                  },
                  onPanEnd: (e) {
                    setState(() {
                      panning = false;
                    });
                  },
                  onPanUpdate: (e) {
                    if (widget.data.height != null) {
                      widget.data.height = widget.data.height! - e.delta.dy;
                      widget.data.top += e.delta.dy;
                    }

                    widget.onUpdate(widget.data);
                  },
                ),
              ),
            ),
          ),
          Visibility(
            maintainState: true,
            visible: (hovering || panning) &&
                widget.data.height != null &&
                !widget.dragging,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 2),
                child: GestureDetector(
                  child: Container(
                      width: 25,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey, width: 1.0),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(10.0)),
                      )),
                  onPanStart: (e) {
                    setState(() {
                      panning = true;
                    });
                  },
                  onPanEnd: (e) {
                    setState(() {
                      panning = false;
                    });
                  },
                  onPanUpdate: (e) {
                    if (widget.data.height != null) {
                      widget.data.height = widget.data.height! + e.delta.dy;
                    }

                    widget.onUpdate(widget.data);
                  },
                ),
              ),
            ),
          ),
          Visibility(
            maintainState: true,
            visible: (hovering || panning) &&
                widget.data.width != null &&
                !widget.dragging,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(2, 0, 0, 0),
                child: GestureDetector(
                  child: Container(
                      width: 8,
                      height: 25,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey, width: 1.0),
                        borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(10.0)),
                      )),
                  onPanStart: (e) {
                    setState(() {
                      panning = true;
                    });
                  },
                  onPanEnd: (e) {
                    setState(() {
                      panning = false;
                    });
                  },
                  onPanUpdate: (e) {
                    if (widget.data.width != null) {
                      widget.data.width = widget.data.width! - e.delta.dx;
                      widget.data.left += e.delta.dx;
                    }

                    widget.onUpdate(widget.data);
                  },
                ),
              ),
            ),
          ),
          Visibility(
            maintainState: true,
            visible: (hovering || panning) &&
                widget.data.width != null &&
                widget.data.height != null &&
                !widget.dragging,
            child: Align(
              alignment: Alignment.topLeft,
              child: GestureDetector(
                child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey, width: 1.0),
                      borderRadius: const BorderRadius.only(
                        bottomRight: Radius.circular(5.0),
                      ),
                    )),
                onPanStart: (e) {
                  setState(() {
                    panning = true;
                  });
                },
                onPanEnd: (e) {
                  setState(() {
                    panning = false;
                  });
                },
                onPanUpdate: (e) {
                  if (widget.data.width != null) {
                    widget.data.width = widget.data.width! - e.delta.dx;
                    widget.data.left += e.delta.dx;
                  }

                  if (widget.data.height != null) {
                    widget.data.height = widget.data.height! - e.delta.dy;
                    widget.data.top += e.delta.dy;
                  }

                  widget.onUpdate(widget.data);
                },
              ),
            ),
          ),
          Visibility(
            maintainState: true,
            visible: (hovering || panning) &&
                widget.data.width != null &&
                widget.data.height != null &&
                !widget.dragging,
            child: Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey, width: 1.0),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(5.0),
                      ),
                    )),
                onPanStart: (e) {
                  setState(() {
                    panning = true;
                  });
                },
                onPanEnd: (e) {
                  setState(() {
                    panning = false;
                  });
                },
                onPanUpdate: (e) {
                  if (widget.data.width != null) {
                    widget.data.width = widget.data.width! + e.delta.dx;
                  }

                  if (widget.data.height != null) {
                    widget.data.height = widget.data.height! - e.delta.dy;
                    widget.data.top += e.delta.dy;
                  }

                  widget.onUpdate(widget.data);
                },
              ),
            ),
          ),
          Visibility(
            maintainState: true,
            visible: (hovering || panning) &&
                widget.data.width != null &&
                widget.data.height != null &&
                !widget.dragging,
            child: Align(
              alignment: Alignment.bottomRight,
              child: GestureDetector(
                child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey, width: 1.0),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(5.0),
                      ),
                    )),
                onPanStart: (e) {
                  setState(() {
                    panning = true;
                  });
                },
                onPanEnd: (e) {
                  setState(() {
                    panning = false;
                  });
                },
                onPanUpdate: (e) {
                  if (widget.data.width != null) {
                    widget.data.width = widget.data.width! + e.delta.dx;
                  }

                  if (widget.data.height != null) {
                    widget.data.height = widget.data.height! + e.delta.dy;
                  }

                  widget.onUpdate(widget.data);
                },
              ),
            ),
          ),
          Visibility(
            maintainState: true,
            visible: (hovering || panning) &&
                widget.data.width != null &&
                widget.data.height != null &&
                !widget.dragging,
            child: Align(
              alignment: Alignment.bottomLeft,
              child: GestureDetector(
                child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey, width: 1.0),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(5.0),
                      ),
                    )),
                onPanStart: (e) {
                  setState(() {
                    panning = true;
                  });
                },
                onPanEnd: (e) {
                  setState(() {
                    panning = false;
                  });
                },
                onPanUpdate: (e) {
                  if (widget.data.width != null) {
                    widget.data.width = widget.data.width! - e.delta.dx;
                    widget.data.left += e.delta.dx;
                  }

                  if (widget.data.height != null) {
                    widget.data.height = widget.data.height! + e.delta.dy;
                  }

                  widget.onUpdate(widget.data);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TransformWidgetEditor extends StatefulWidget {
  TransformWidgetEditor(
      {super.key,
      required this.data,
      required this.onUpdate,
      required this.ui});

  TransformData data;
  Function(TransformData) onUpdate;
  UserInterface ui;

  @override
  State<TransformWidgetEditor> createState() => _TransformWidgetEditor();
}

class _TransformWidgetEditor extends State<TransformWidgetEditor> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Section(
          title: "Size",
          child: Column(
            children: [
              Row(
                children: [
                  Field(
                    label: "W",
                    initialValue: widget.data.width == null
                        ? ""
                        : widget.data.width.toString(),
                    onChanged: (s) {
                      widget.data.width = double.tryParse(s);
                      widget.onUpdate(widget.data);
                    },
                  ),
                  Field(
                    label: "H",
                    initialValue: widget.data.height == null
                        ? ""
                        : widget.data.height.toString(),
                    onChanged: (s) {
                      widget.data.height = double.tryParse(s);
                      widget.onUpdate(widget.data);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        Section(
          title: "Position",
          child: Column(
            children: [
              Row(
                children: [
                  Field(
                    label: "X",
                    initialValue: widget.data.left.toString(),
                    onChanged: (s) {
                      var left = double.tryParse(s);

                      if (left != null) {
                        widget.data.left = left;
                        widget.onUpdate(widget.data);
                      }
                    },
                  ),
                  Field(
                    label: "Y",
                    initialValue: widget.data.top.toString(),
                    onChanged: (s) {
                      var top = double.tryParse(s);

                      if (top != null) {
                        widget.data.top = top;
                        widget.onUpdate(widget.data);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        Section(
          title: "Alignment",
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 5, 0, 10),
            child: AlignmentField(
              alignment: widget.data.alignment,
              onUpdate: (a) {
                if (widget.data.alignment.x != a.x) {
                  widget.data.left = 0;
                }

                if (widget.data.alignment.y != a.y) {
                  widget.data.top = 0;
                }

                widget.data.alignment = a;
                widget.onUpdate(widget.data);
                widget.ui.selected.notifyListeners();
              },
            ),
          ),
        ),
        Section(
          title: "Padding",
          child: Column(
            children: [
              Row(
                children: [
                  Field(
                    label: "L",
                    initialValue: widget.data.padding.left.toString(),
                    onChanged: (s) {
                      widget.data.padding = EdgeInsets.fromLTRB(
                          double.tryParse(s) ?? 0.0,
                          widget.data.padding.top,
                          widget.data.padding.right,
                          widget.data.padding.bottom);

                      if (widget.data.padding.left < 0) {
                        widget.data.padding = EdgeInsets.fromLTRB(
                            0,
                            widget.data.padding.top,
                            widget.data.padding.right,
                            widget.data.padding.bottom);
                      }

                      widget.onUpdate(widget.data);
                    },
                  ),
                  Field(
                    label: "R",
                    initialValue: widget.data.padding.right.toString(),
                    onChanged: (s) {
                      widget.data.padding = EdgeInsets.fromLTRB(
                        widget.data.padding.left,
                        widget.data.padding.top,
                        double.tryParse(s) ?? 0.0,
                        widget.data.padding.bottom,
                      );

                      if (widget.data.padding.right < 0) {
                        widget.data.padding = EdgeInsets.fromLTRB(
                          widget.data.padding.left,
                          widget.data.padding.top,
                          0,
                          widget.data.padding.bottom,
                        );
                      }

                      widget.onUpdate(widget.data);
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  Field(
                    label: "T",
                    initialValue: widget.data.padding.top.toString(),
                    onChanged: (s) {
                      widget.data.padding = EdgeInsets.fromLTRB(
                          widget.data.padding.left,
                          double.tryParse(s) ?? 0.0,
                          widget.data.padding.right,
                          widget.data.padding.bottom);

                      if (widget.data.padding.top < 0) {
                        widget.data.padding = EdgeInsets.fromLTRB(
                          widget.data.padding.left,
                          0,
                          widget.data.padding.right,
                          widget.data.padding.bottom,
                        );
                      }

                      widget.onUpdate(widget.data);
                    },
                  ),
                  Field(
                    label: "B",
                    initialValue: widget.data.padding.bottom.toString(),
                    onChanged: (s) {
                      widget.data.padding = EdgeInsets.fromLTRB(
                        widget.data.padding.left,
                        widget.data.padding.top,
                        widget.data.padding.right,
                        double.tryParse(s) ?? 0.0,
                      );

                      if (widget.data.padding.bottom < 0) {
                        widget.data.padding = EdgeInsets.fromLTRB(
                          widget.data.padding.left,
                          widget.data.padding.top,
                          widget.data.padding.right,
                          0,
                        );
                      }

                      widget.onUpdate(widget.data);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AlignmentField extends StatelessWidget {
  AlignmentField({super.key, required this.alignment, required this.onUpdate});

  Alignment alignment;
  Function(Alignment) onUpdate;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AlignmentFieldButton(
            iconData: Icons.align_horizontal_left,
            selected: alignment == Alignment.topLeft ||
                alignment == Alignment.centerLeft ||
                alignment == Alignment.bottomLeft,
            onTap: () {
              if (alignment == Alignment.topLeft ||
                  alignment == Alignment.topCenter ||
                  alignment == Alignment.topRight) {
                onUpdate(Alignment.topLeft);
              } else if (alignment == Alignment.centerLeft ||
                  alignment == Alignment.center ||
                  alignment == Alignment.centerRight) {
                onUpdate(Alignment.centerLeft);
              } else if (alignment == Alignment.bottomLeft ||
                  alignment == Alignment.bottomCenter ||
                  alignment == Alignment.bottomRight) {
                onUpdate(Alignment.bottomLeft);
              }
            },
          ),
          AlignmentFieldButton(
            iconData: Icons.align_horizontal_center,
            selected: alignment == Alignment.topCenter ||
                alignment == Alignment.center ||
                alignment == Alignment.bottomCenter,
            onTap: () {
              if (alignment == Alignment.topLeft ||
                  alignment == Alignment.topCenter ||
                  alignment == Alignment.topRight) {
                onUpdate(Alignment.topCenter);
              } else if (alignment == Alignment.centerLeft ||
                  alignment == Alignment.center ||
                  alignment == Alignment.centerRight) {
                onUpdate(Alignment.center);
              } else if (alignment == Alignment.bottomLeft ||
                  alignment == Alignment.bottomCenter ||
                  alignment == Alignment.bottomRight) {
                onUpdate(Alignment.bottomCenter);
              }
            },
          ),
          AlignmentFieldButton(
            iconData: Icons.align_horizontal_right,
            selected: alignment == Alignment.topRight ||
                alignment == Alignment.centerRight ||
                alignment == Alignment.bottomRight,
            onTap: () {
              if (alignment == Alignment.topLeft ||
                  alignment == Alignment.topCenter ||
                  alignment == Alignment.topRight) {
                onUpdate(Alignment.topRight);
              } else if (alignment == Alignment.centerLeft ||
                  alignment == Alignment.center ||
                  alignment == Alignment.centerRight) {
                onUpdate(Alignment.centerRight);
              } else if (alignment == Alignment.bottomLeft ||
                  alignment == Alignment.bottomCenter ||
                  alignment == Alignment.bottomRight) {
                onUpdate(Alignment.bottomRight);
              }
            },
          ),
        ],
      ),
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AlignmentFieldButton(
            iconData: Icons.align_vertical_top,
            selected: alignment == Alignment.topLeft ||
                alignment == Alignment.topCenter ||
                alignment == Alignment.topRight,
            onTap: () {
              if (alignment == Alignment.topLeft ||
                  alignment == Alignment.centerLeft ||
                  alignment == Alignment.bottomLeft) {
                onUpdate(Alignment.topLeft);
              } else if (alignment == Alignment.topCenter ||
                  alignment == Alignment.center ||
                  alignment == Alignment.bottomCenter) {
                onUpdate(Alignment.topCenter);
              } else if (alignment == Alignment.topRight ||
                  alignment == Alignment.centerRight ||
                  alignment == Alignment.bottomRight) {
                onUpdate(Alignment.topRight);
              }
            },
          ),
          AlignmentFieldButton(
            iconData: Icons.align_vertical_center,
            selected: alignment == Alignment.centerLeft ||
                alignment == Alignment.center ||
                alignment == Alignment.centerRight,
            onTap: () {
              if (alignment == Alignment.topLeft ||
                  alignment == Alignment.centerLeft ||
                  alignment == Alignment.bottomLeft) {
                onUpdate(Alignment.centerLeft);
              } else if (alignment == Alignment.topCenter ||
                  alignment == Alignment.center ||
                  alignment == Alignment.bottomCenter) {
                onUpdate(Alignment.center);
              } else if (alignment == Alignment.topRight ||
                  alignment == Alignment.centerRight ||
                  alignment == Alignment.bottomRight) {
                onUpdate(Alignment.centerRight);
              }
            },
          ),
          AlignmentFieldButton(
            iconData: Icons.align_vertical_bottom,
            selected: alignment == Alignment.bottomLeft ||
                alignment == Alignment.bottomCenter ||
                alignment == Alignment.bottomRight,
            onTap: () {
              if (alignment == Alignment.topLeft ||
                  alignment == Alignment.centerLeft ||
                  alignment == Alignment.bottomLeft) {
                onUpdate(Alignment.bottomLeft);
              } else if (alignment == Alignment.topCenter ||
                  alignment == Alignment.center ||
                  alignment == Alignment.bottomCenter) {
                onUpdate(Alignment.bottomCenter);
              } else if (alignment == Alignment.topRight ||
                  alignment == Alignment.centerRight ||
                  alignment == Alignment.bottomRight) {
                onUpdate(Alignment.bottomRight);
              }
            },
          ),
        ],
      ),
    ]);
  }
}

class AlignmentFieldButton extends StatelessWidget {
  AlignmentFieldButton(
      {super.key,
      required this.selected,
      required this.onTap,
      required this.iconData,
      this.borderRadius});

  BorderRadius? borderRadius;
  bool selected;
  Function() onTap;
  IconData iconData;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
        decoration: BoxDecoration(
            color: const Color.fromRGBO(40, 40, 40, 1.0),
            borderRadius: borderRadius),
        child: Icon(
          iconData,
          color: selected ? Colors.blue : Colors.grey,
        ),
      ),
    );
  }
}

class Label extends StatefulWidget {
  Label(
      {super.key,
      required this.text,
      required this.child,
      this.width,
      this.height});

  String text;
  Widget child;

  double? width;
  double? height;

  @override
  State<Label> createState() => _Label();
}

class _Label extends State<Label> {
  bool hovering = false;
  ValueNotifier<bool> editorShowing = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    /*return MouseRegion(
      hitTestBehavior: HitTestBehavior.translucent,
      opaque: true,
      onEnter: (e) {
        if (!editorShowing.value) {
          setState(() {
            hovering = true; 
          });
        }
      },
      onExit: (e) {
        if (!editorShowing.value) {
          setState(() {
            hovering = false;
          });
        }
      },
      child: Container(
        child: widget.child,
        decoration: hovering ? BoxDecoration(
          border: Border.all(
            color: Colors.blue,
            width: 2.0
          )
        ) : null
      )
    );*/

    return MouseRegion(
      hitTestBehavior: HitTestBehavior.deferToChild,
      onEnter: (e) {
        if (!editorShowing.value) {
          setState(() {
            hovering = true;
          });
        }
      },
      onExit: (e) {
        if (!editorShowing.value) {
          setState(() {
            hovering = false;
          });
        }
      },
      /*child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          border: hovering ? Border.all(
            color: Colors.blue,
            width: 2.0
          ) : null
        ),
        child: widget.child,
      )*/
      child: Stack(
        fit: StackFit.expand,
        children: [
          const AbsorbPointer(),
          widget.child,
          Visibility(
            visible: hovering,
            maintainState: true,
            child: IgnorePointer(
              child: Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.blue,
                    width: 2.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LabelDropdown extends StatefulWidget {
  LabelDropdown({super.key, required this.editor, required this.editorShowing});

  Widget? editor;
  ValueNotifier<bool> editorShowing;

  @override
  State<LabelDropdown> createState() => _LabelDropdown();
}

class _LabelDropdown extends State<LabelDropdown>
    with TickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  AnimationController? _animationController;
  Animation<double>? _expandAnimation;
  Animation<double>? _rotateAnimation;

  @override
  void initState() {
    super.initState();

    widget.editorShowing.value = false;

    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));

    _expandAnimation = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOut,
    );

    _rotateAnimation = Tween(begin: 0.0, end: 0.5).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onTap: () {
            print("Tapped background");
            _toggleDropdown(close: true);
          },
        ),
        Positioned(
            left: 0,
            top: 30,
            child: SizeTransition(
                axisAlignment: 1,
                sizeFactor: _expandAnimation!,
                child: Container(
                  width: 200,
                  height: 200,
                  color: const Color.fromRGBO(40, 40, 40, 1.0),
                  child: widget.editor,
                ))),
        Positioned(
          left: 0,
          top: 0,
          child: SizedBox(
            width: 150,
            height: 30,
            child: GestureDetector(
              onTap: () {
                print("Tapped bar");
                _toggleDropdown();
              },
            ),
          ),
        ),
      ],
    );
  }

  void _toggleDropdown({bool close = false}) async {
    // print("Toggling dropdown");
    if (_isOpen || close) {
      await _animationController?.reverse();
      setState(() {
        _isOpen = false;
        widget.editorShowing.value = false;
      });
    } else {
      setState(() => _isOpen = true);
      _animationController?.forward();
      widget.editorShowing.value = true;
    }
  }
}

class EditorTitle extends StatelessWidget {
  EditorTitle(this.text, {super.key});

  String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.fromLTRB(0, 15, 0, 5),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        const Divider(
          color: Color.fromRGBO(60, 60, 60, 1.0),
          thickness: 1.0,
        ),
      ],
    );
  }
}

class DualField extends StatefulWidget {
  DualField(
      {super.key,
      required this.label,
      required this.field1,
      required this.field2,
      required this.fieldLabel1,
      required this.fieldLabel2,
      required this.onUpdate1,
      required this.onUpdate2});

  String label;

  String field1;
  String field2;

  String fieldLabel1;
  String fieldLabel2;

  void Function(String) onUpdate1;
  void Function(String) onUpdate2;

  @override
  State<DualField> createState() => _DualField();
}

class _DualField extends State<DualField> {
  TextEditingController? controller1;
  TextEditingController? controller2;

  @override
  Widget build(BuildContext context) {
    if (controller1 == null) {
      controller1 = TextEditingController(text: widget.field1);
      controller2 = TextEditingController(text: widget.field2);
    }

    return Row(
      children: [
        Container(
          width: 80,
          padding: const EdgeInsets.all(10),
          alignment: Alignment.centerLeft,
          child: Text(
            widget.label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        Column(
          children: [
            SizedBox(
              width: 50,
              height: 35,
              child: TextField(
                onChanged: widget.onUpdate1,
                controller: controller1,
                textAlign: TextAlign.left,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Container(
              width: 50,
              height: 20,
              padding: const EdgeInsets.all(2),
              alignment: Alignment.centerLeft,
              child: Text(
                widget.fieldLabel1,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
          ],
        ),
        Column(
          children: [
            SizedBox(
              width: 50,
              height: 35,
              child: TextField(
                onChanged: widget.onUpdate2,
                controller: controller2,
                textAlign: TextAlign.left,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Container(
              width: 50,
              height: 20,
              padding: const EdgeInsets.all(2),
              alignment: Alignment.centerLeft,
              child: Text(
                widget.fieldLabel2,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class DropdownOverlay extends StatefulWidget {
  const DropdownOverlay({super.key});

  @override
  State<DropdownOverlay> createState() => _DropdownOverlay();
}

class _DropdownOverlay extends State<DropdownOverlay> {
  TextEditingController controller = TextEditingController(text: "hello");
  final FocusScopeNode _focusScopeNode = FocusScopeNode();

  @override
  Widget build(BuildContext context) {
    print("Building DropdownOverlay");

    return FocusScope(
      node: _focusScopeNode,
      child: Material(
        key: UniqueKey(),
        child: TextField(
          autofocus: true,
          controller: controller,
        ),
      ),
    );
  }
}

class CustomDropdown<T> extends StatefulWidget {
  /// the child widget for the button, this will be ignored if text is supplied
  final Widget header;
  final Widget? child;

  ValueNotifier<bool> editorShowing;

  /// list of DropdownItems
  final DropdownStyle dropdownStyle;

  /// dropdownButtonStyles passes styles to OutlineButton.styleFrom()
  final DropdownButtonStyle dropdownButtonStyle;

  /// dropdown button icon defaults to caret
  final Icon? icon;
  final bool hideIcon;

  /// if true the dropdown icon will as a leading icon, default to false
  final bool leadingIcon;
  CustomDropdown({
    super.key,
    this.hideIcon = false,
    required this.header,
    this.child,
    this.dropdownStyle = const DropdownStyle(),
    this.dropdownButtonStyle = const DropdownButtonStyle(),
    this.icon,
    this.leadingIcon = false,
    required this.editorShowing,
  });

  @override
  _CustomDropdownState<T> createState() => _CustomDropdownState<T>();
}

class _CustomDropdownState<T> extends State<CustomDropdown<T>>
    with TickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  AnimationController? _animationController;
  Animation<double>? _expandAnimation;
  Animation<double>? _rotateAnimation;

  TextEditingController controller = TextEditingController(text: "hello");

  final FocusScopeNode _focusScopeNode = FocusScopeNode();
  final FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    widget.editorShowing.value = false;

    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));

    _expandAnimation = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOut,
    );

    _rotateAnimation = Tween(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: Curves.easeInOut,
      ),
    );
  }

  /*@override
  void dispose() {
    _focusScopeNode.dispose();
    super.dispose();
  }*/

  @override
  Widget build(BuildContext context) {
    print("Building");
    var style = widget.dropdownButtonStyle;
    // link the overlay to the button
    return CompositedTransformTarget(
      link: _layerLink,
      child: SizedBox(
        width: style.width,
        height: style.height,
        child: GestureDetector(
          onTap: _toggleDropdown,
          child: Row(
            mainAxisAlignment:
                style.mainAxisAlignment ?? MainAxisAlignment.center,
            textDirection:
                widget.leadingIcon ? TextDirection.rtl : TextDirection.ltr,
            mainAxisSize: MainAxisSize.min,
            children: [
              widget.header,
              if (!widget.hideIcon)
                RotationTransition(
                  turns: _rotateAnimation!,
                  child: widget.icon ??
                      const Icon(
                        Icons.arrow_downward,
                        color: Colors.white,
                      ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;

    var size = renderBox.size;
    var offset = renderBox.localToGlobal(Offset.zero);
    var topOffset = offset.dy + size.height + 5;

    print("Create overlay entry");

    return OverlayEntry(
      maintainState: false,
      opaque: false,
      builder: (entryContext) {
        print("Overlay entry build");

        /*return Material(
          key: UniqueKey(),
          child: TextField(
            autofocus: true,
            focusNode: focusNode,
            controller: controller,
        ));*/

        /*return FocusScope(
          node: _focusScopeNode,
          child: Material(
            child: TextField(
              controller: controller,
            )
          )
        );*/

        return FocusScope(
          autofocus: true,
          node: _focusScopeNode,
          child: GestureDetector(
            onTap: () {
              _toggleDropdown(close: true);
            },
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 200,
              height: 200,
              // height: MediaQuery.of(entryContext).size.height,
              // width: MediaQuery.of(entryContext).size.width,
              child: Stack(
                children: [
                  Positioned(
                    left: offset.dx,
                    top: topOffset,
                    width: 200,
                    child: CompositedTransformFollower(
                      offset: widget.dropdownStyle.offset ??
                          Offset(0, size.height + 5),
                      link: _layerLink,
                      showWhenUnlinked: false,
                      child: Material(
                        elevation: widget.dropdownStyle.elevation ?? 0,
                        borderRadius: widget.dropdownStyle.borderRadius ??
                            BorderRadius.zero,
                        color: const Color.fromRGBO(30, 30, 30, 1.0),
                        child: SizeTransition(
                          axisAlignment: 1,
                          sizeFactor: _expandAnimation!,
                          child: widget.child,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _toggleDropdown({bool close = false}) async {
    print("Toggling dropdown");
    if (_isOpen || close) {
      await _animationController?.reverse();
      // _overlayEntry?.remove();
      setState(() {
        _isOpen = false;
        widget.editorShowing.value = false;
      });
    } else {
      // _overlayEntry = _createOverlayEntry();
      // Overlay.of(context)?.insert(_overlayEntry!);
      setState(() => _isOpen = true);
      _animationController?.forward();
      widget.editorShowing.value = true;
    }
  }
}

class DropdownButtonStyle {
  final MainAxisAlignment? mainAxisAlignment;
  final ShapeBorder? shape;
  final double? elevation;
  final Color? backgroundColor;
  final EdgeInsets? padding;
  final BoxConstraints? constraints;
  final double? width;
  final double? height;
  final Color? primaryColor;
  const DropdownButtonStyle({
    this.mainAxisAlignment,
    this.backgroundColor,
    this.primaryColor,
    this.constraints,
    this.height,
    this.width,
    this.elevation,
    this.padding,
    this.shape,
  });
}

class DropdownStyle {
  final BorderRadius? borderRadius;
  final double? elevation;
  final Color? color;
  final EdgeInsets? padding;
  final BoxConstraints? constraints;

  /// position of the top left of the dropdown relative to the top left of the button
  final Offset? offset;

  ///button width must be set for this to take effect
  final double? width;

  const DropdownStyle({
    this.constraints,
    this.offset,
    this.width,
    this.elevation,
    this.color,
    this.padding,
    this.borderRadius,
  });
}

class Section extends StatefulWidget {
  Section({super.key, required this.title, required this.child});

  String title;
  Widget child;

  @override
  State<Section> createState() => _Section();
}

class _Section extends State<Section> {
  ExpandableController controller = ExpandableController(initialExpanded: true);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ExpandablePanel(
          header: Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
              ),
            ),
          ),
          collapsed: Container(),
          controller: controller,
          theme: const ExpandableThemeData(
            animationDuration: Duration(milliseconds: 200),
            iconColor: Color.fromRGBO(120, 120, 120, 1.0),
            iconSize: 20,
          ),
          expanded: Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
            child: widget.child,
          ),
        ),
        const Divider(
          color: Color.fromRGBO(60, 60, 60, 1.0),
          thickness: 1.0,
        ),
      ],
    );
  }
}

class SubSection extends StatefulWidget {
  SubSection({super.key, required this.title, required this.child});

  String title;
  Widget child;

  @override
  State<SubSection> createState() => _SubSection();
}

class _SubSection extends State<SubSection> {
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
        child: Column(children: [
          ExpansionTile(
            title: Text(widget.title),
            initiallyExpanded: false,
            children: [
              Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                  child: widget.child)
            ],
            textColor: Colors.white,
            collapsedTextColor: Colors.grey,
            iconColor: Colors.grey,
            collapsedIconColor: Colors.grey,
          ),
          const Divider(
            color: Color.fromRGBO(60, 60, 60, 1.0),
            thickness: 1.0,
          )
        ]));
  }
}

class Field extends StatefulWidget {
  Field({
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.width,
    this.height,
    this.multiLine = false,
  }) : super(key: UniqueKey());

  String label;
  String initialValue;
  double? width;
  double? height;
  void Function(String) onChanged;
  bool multiLine;

  @override
  State<Field> createState() => _Field();
}

class _Field extends State<Field> {
  late TextEditingController controller;
  FocusNode focusNode = FocusNode();
  bool editing = false;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialValue);
    focusNode.addListener(onFocusChange);
  }

  @override
  void dispose() {
    super.dispose();
    focusNode.removeListener(onFocusChange);
    focusNode.dispose();
  }

  void onFocusChange() {
    setState(() {
      editing = !editing;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Container(
        width: widget.width ?? 80,
        height: widget.height ?? 35,
        decoration: BoxDecoration(
          color: const Color.fromRGBO(40, 40, 40, 1.0),
          border: Border.all(
            color:
                editing ? Colors.blue : const Color.fromRGBO(50, 50, 50, 1.0),
            width: 2.0,
          ),
          borderRadius: const BorderRadius.all(
            Radius.circular(5.0),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding:
                    EdgeInsets.fromLTRB(10, widget.multiLine ? 3.0 : 0.0, 0, 0),
                child: TextField(
                  expands: widget.multiLine,
                  textAlignVertical: TextAlignVertical.top,
                  maxLines: widget.multiLine ? null : 1,
                  onSubmitted: widget.onChanged,
                  focusNode: focusNode,
                  controller: controller,
                  style: TextStyle(
                    color: editing ? Colors.white : Colors.grey,
                    fontSize: 14,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
              child: Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FileField extends StatefulWidget {
  FileField(
      {required this.path,
      required this.extensions,
      required this.onChanged,
      this.width,
      this.height})
      : super(key: UniqueKey());

  String? path;
  void Function(String?) onChanged;
  double? width;
  double? height;
  List<String> extensions;

  @override
  State<FileField> createState() => _FileField();
}

class _FileField extends State<FileField> {
  void pickFile() async {
    //FilePickerResult? result = await FilePicker.platform.pickFiles();

    /*if (result != null) {
      widget.onChanged(result.files.single.path);
    } else {
      // User canceled the picker
    }*/
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.fromLTRB(10, 5, 10, 10),
        child: Container(
            width: widget.width ?? 120,
            height: widget.height ?? 40,
            decoration: BoxDecoration(
                color: const Color.fromRGBO(40, 40, 40, 1.0),
                border: Border.all(
                    color: const Color.fromRGBO(50, 50, 50, 1.0), width: 2.0),
                borderRadius: const BorderRadius.all(Radius.circular(5.0))),
            child: Row(
              children: [
                Expanded(
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                        child: TextField(
                          onSubmitted: widget.onChanged,
                          controller: TextEditingController(
                              text: widget.path == null
                                  ? ""
                                  : widget.path!.split("/").last),
                          enabled: false,
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 14),
                          decoration: const InputDecoration(
                              isDense: true, border: InputBorder.none),
                        ))),
                Container(
                  width: 10,
                  color: const Color.fromRGBO(40, 40, 40, 1.0),
                ),
                Container(
                  width: 40,
                  decoration: const BoxDecoration(
                      color: Color.fromRGBO(40, 40, 40, 1.0),
                      borderRadius:
                          BorderRadius.horizontal(right: Radius.circular(5))),
                  alignment: Alignment.center,
                  child: IconButton(
                    icon: const Icon(
                      Icons.folder,
                      color: Colors.blue,
                      size: 20,
                    ),
                    onPressed: () {
                      pickFile();
                    },
                  ),
                )
              ],
            )));
  }
}

Color fromHex(String hexString) {
  final buffer = StringBuffer();
  if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
  buffer.write(hexString.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

extension HexColor on Color {
  String toHex({bool leadingHashSign = true}) => '${leadingHashSign ? '#' : ''}'
      '${alpha.toRadixString(16).padLeft(2, '0')}'
      '${red.toRadixString(16).padLeft(2, '0')}'
      '${green.toRadixString(16).padLeft(2, '0')}'
      '${blue.toRadixString(16).padLeft(2, '0')}';
}

class ColorField extends StatefulWidget {
  ColorField(
      {required this.color, required this.onChanged, this.width, this.height})
      : super(key: UniqueKey());

  Color color;
  void Function(Color) onChanged;
  double? width;
  double? height;

  @override
  State<ColorField> createState() => _ColorField();
}

class _ColorField extends State<ColorField> {
  late TextEditingController controller;
  FocusNode focusNode = FocusNode();
  bool editing = false;

  @override
  void initState() {
    super.initState();
    controller =
        TextEditingController(text: widget.color.toHex(leadingHashSign: false));
    focusNode.addListener(onFocusChange);
  }

  @override
  void dispose() {
    super.dispose();
    focusNode.removeListener(onFocusChange);
    focusNode.dispose();
  }

  void onFocusChange() {
    setState(() {
      editing = !editing;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.fromLTRB(10, 5, 10, 10),
        child: Container(
            width: widget.width ?? 120,
            height: widget.height ?? 40,
            decoration: BoxDecoration(
                color: const Color.fromRGBO(40, 40, 40, 1.0),
                border: Border.all(
                    color: editing
                        ? Colors.blue
                        : const Color.fromRGBO(50, 50, 50, 1.0),
                    width: 2.0),
                borderRadius: const BorderRadius.all(Radius.circular(5.0))),
            child: Row(children: [
              Padding(
                  padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                  child: GestureDetector(
                      onTap: () {
                        print("Show color overlay");
                      },
                      child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                              color: widget.color,
                              borderRadius: const BorderRadius.all(
                                  Radius.circular(5)))))),
              const Padding(
                  padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                  child: Text("#",
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500))),
              Expanded(
                  child: Padding(
                      padding: const EdgeInsets.fromLTRB(3, 0, 0, 0),
                      child: TextField(
                        onChanged: (s) {
                          widget.onChanged(fromHex(s));
                          setState(() {});
                        },
                        focusNode: focusNode,
                        controller: controller,
                        style: TextStyle(
                            color: editing ? Colors.white : Colors.grey,
                            fontSize: 14),
                        decoration: const InputDecoration(
                            isDense: true, border: InputBorder.none),
                      )))
            ])));
  }
}

class FieldLabel extends StatefulWidget {
  FieldLabel({required this.text, required this.child})
      : super(key: UniqueKey());

  String text;
  Widget child;

  @override
  State<FieldLabel> createState() => _FieldLabel();
}

class _FieldLabel extends State<FieldLabel> {
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
          padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
          alignment: Alignment.centerLeft,
          child: Text(widget.text,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w400))),
      Expanded(
          child: Align(
              // padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
              alignment: Alignment.centerRight,
              child: widget.child))
    ]);
  }
}

class ChildDragTarget extends StatefulWidget {
  ChildDragTarget({
    super.key,
    this.width,
    this.height,
    this.child,
    this.showDragBoder = true,
    required this.onAddChild,
    required this.ui,
  });

  void Function(UIWidget widget) onAddChild;
  double? width;
  double? height;
  Widget? child;
  bool showDragBoder;

  UserInterface ui;

  @override
  State<ChildDragTarget> createState() => _ChildDragTarget();
}

class _ChildDragTarget extends State<ChildDragTarget> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      hitTestBehavior: HitTestBehavior.opaque,
      onEnter: (e) {
        setState(() {
          hovering = true;
        });
      },
      onExit: (e) {
        setState(() {
          hovering = false;
        });
      },
      child: DragTarget<String>(
        builder: (context, candidateData, rejectedData) {
          return Stack(
            children: [
              widget.child ?? Container(),
              IgnorePointer(
                child: Visibility(
                  visible: hovering && widget.showDragBoder,
                  child: Container(
                    color: Colors.white.withAlpha(10),
                    child: Center(
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(100),
                          borderRadius: BorderRadius.circular(13.0),
                          border: Border.all(
                            color: Colors.blue,
                            width: 2.0,
                          ),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        onWillAcceptWithDetails: (data) {
          return true;
        },
        onAcceptWithDetails: (name) {
          UIWidget? child = createUIWidget(name.data, widget.ui);

          if (child != null) {
            print("Creating child $name");
            widget.onAddChild(child);
            print("TODO: Refresh UI widget");
            setState(() {});
          } else {
            print("Couldn't create child $name");
          }
        },
      ),
    );
  }
}

class VarField extends StatefulWidget {
  VarField({super.key, required this.app, required this.varName});

  App app;
  ValueNotifier<String?> varName;

  @override
  State<VarField> createState() => _VarField();
}

class _VarField extends State<VarField> with TickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  AnimationController? _animationController;
  Animation<double>? _expandAnimation;

  TextEditingController controller = TextEditingController(text: "hello");

  final FocusScopeNode _focusScopeNode = FocusScopeNode();
  final FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));

    _expandAnimation = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOut,
    );
  }

  /*@override
  void dispose() {
    _focusScopeNode.dispose();
    super.dispose();
  }*/

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
        link: _layerLink,
        child: Container(
            width: 100,
            height: 16,
            decoration: BoxDecoration(
                color: Colors.grey, borderRadius: BorderRadius.circular(5)),
            child: GestureDetector(
                onTap: _toggleDropdown,
                child: ValueListenableBuilder<String?>(
                    valueListenable: widget.varName,
                    builder: (context, name, w) {
                      return Text(name ?? "");
                    }))));
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;

    var size = renderBox.size;
    var offset = renderBox.localToGlobal(Offset.zero);
    var topOffset = offset.dy + size.height + 5;

    print("Create overlay entry");

    return OverlayEntry(
        maintainState: false,
        opaque: false,
        builder: (entryContext) {
          return FocusScope(
              autofocus: true,
              node: _focusScopeNode,
              child: GestureDetector(
                  onTap: () {
                    _toggleDropdown(close: true);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Stack(children: [
                    Positioned(
                        left: offset.dx,
                        top: topOffset,
                        child: CompositedTransformFollower(
                            offset: Offset(0, size.height + 5),
                            link: _layerLink,
                            showWhenUnlinked: false,
                            child: Material(
                                elevation: 0,
                                borderRadius: BorderRadius.zero,
                                color: Colors.transparent,
                                child: SizeTransition(
                                    axisAlignment: 1,
                                    sizeFactor: _expandAnimation!,
                                    // child: widget.child,
                                    child: Container(
                                      decoration: BoxDecoration(
                                          color: const Color.fromRGBO(
                                              120, 120, 120, 1.0),
                                          borderRadius:
                                              BorderRadius.circular(5)),
                                      /*child:
                                            ValueListenableBuilder<List<Var>>(
                                          valueListenable: widget.host.vars,
                                          builder: (context, vars, w) {
                                            return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: vars
                                                    .map((e) => VarFieldElement(
                                                        e, widget.varName))
                                                    .toList());
                                          },
                                        )*/
                                    )))))
                  ])));
        });
  }

  void _toggleDropdown({bool close = false}) async {
    if (_isOpen || close) {
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
  }
}

class ExpandableThemeData {
  static const ExpandableThemeData defaults = ExpandableThemeData(
    iconColor: Colors.black54,
    useInkWell: true,
    inkWellBorderRadius: BorderRadius.zero,
    animationDuration: Duration(milliseconds: 300),
    scrollAnimationDuration: Duration(milliseconds: 300),
    crossFadePoint: 0.5,
    fadeCurve: Curves.linear,
    sizeCurve: Curves.fastOutSlowIn,
    alignment: Alignment.topLeft,
    headerAlignment: ExpandablePanelHeaderAlignment.top,
    bodyAlignment: ExpandablePanelBodyAlignment.left,
    iconPlacement: ExpandablePanelIconPlacement.right,
    tapHeaderToExpand: true,
    tapBodyToExpand: false,
    tapBodyToCollapse: false,
    hasIcon: true,
    iconSize: 24.0,
    iconPadding: EdgeInsets.all(8.0),
    iconRotationAngle: -pi,
    expandIcon: Icons.expand_more,
    collapseIcon: Icons.expand_more,
  );

  static const ExpandableThemeData empty = ExpandableThemeData();

  // Expand icon color.
  final Color? iconColor;

  // If true then [InkWell] will be used in the header for a ripple effect.
  final bool? useInkWell;

  // The duration of the transition between collapsed and expanded states.
  final Duration? animationDuration;

  // The duration of the scroll animation to make the expanded widget visible.
  final Duration? scrollAnimationDuration;

  /// The point in the cross-fade animation timeline (from 0 to 1)
  /// where the [collapsed] and [expanded] widgets are half-visible.
  ///
  /// If set to 0, the [expanded] widget will be shown immediately in full opacity
  /// when the size transition starts. This is useful if the collapsed widget is
  /// empty or if dealing with text that is shown partially in the collapsed state.
  /// This is the default value.
  ///
  /// If set to 0.5, the [expanded] and the [collapsed] widget will be shown
  /// at half of their opacity in the middle of the size animation with a
  /// cross-fade effect throughout the entire size transition.
  ///
  /// If set to 1, the [expanded] widget will be shown at the very end of the size animation.
  ///
  /// When collapsing, the effect of this setting is reversed. For example, if the value is 0
  /// then the [expanded] widget will remain to be shown until the end of the size animation.
  final double? crossFadePoint;

  /// The alignment of widgets during animation between expanded and collapsed states.
  final AlignmentGeometry? alignment;

  // Fade animation curve between expanded and collapsed states.
  final Curve? fadeCurve;

  // Size animation curve between expanded and collapsed states.
  final Curve? sizeCurve;

  // The alignment of the header for `ExpandablePanel`.
  final ExpandablePanelHeaderAlignment? headerAlignment;

  // The alignment of the body for `ExpandablePanel`.
  final ExpandablePanelBodyAlignment? bodyAlignment;

  /// Expand icon placement.
  final ExpandablePanelIconPlacement? iconPlacement;

  /// If true, the header of [ExpandablePanel] can be clicked by the user to expand or collapse.
  final bool? tapHeaderToExpand;

  /// If true, the body of [ExpandablePanel] can be clicked by the user to expand.
  final bool? tapBodyToExpand;

  /// If true, the body of [ExpandablePanel] can be clicked by the user to collapse.
  final bool? tapBodyToCollapse;

  /// If true, an icon is shown in the header of [ExpandablePanel].
  final bool? hasIcon;

  /// Expand icon size.
  final double? iconSize;

  /// Expand icon padding.
  final EdgeInsets? iconPadding;

  /// Icon rotation angle in clockwise radians. For example, specify `math.pi` to rotate the icon by 180 degrees
  /// clockwise when clicking on the expand button.
  final double? iconRotationAngle;

  /// The icon in the collapsed state.
  final IconData? expandIcon;

  /// The icon in the expanded state. If you specify the same icon as `expandIcon`, the `expandIcon` icon will
  /// be shown upside-down in the expanded state.
  final IconData? collapseIcon;

  ///The [BorderRadius] for the [InkWell], if `inkWell` is set to true
  final BorderRadius? inkWellBorderRadius;

  const ExpandableThemeData({
    this.iconColor,
    this.useInkWell,
    this.animationDuration,
    this.scrollAnimationDuration,
    this.crossFadePoint,
    this.fadeCurve,
    this.sizeCurve,
    this.alignment,
    this.headerAlignment,
    this.bodyAlignment,
    this.iconPlacement,
    this.tapHeaderToExpand,
    this.tapBodyToExpand,
    this.tapBodyToCollapse,
    this.hasIcon,
    this.iconSize,
    this.iconPadding,
    this.iconRotationAngle,
    this.expandIcon,
    this.collapseIcon,
    this.inkWellBorderRadius,
  });

  static ExpandableThemeData combine(
      ExpandableThemeData? theme, ExpandableThemeData? defaults) {
    if (defaults == null || defaults.isEmpty()) {
      return theme ?? empty;
    } else if (theme == null || theme.isEmpty()) {
      return defaults;
    } else if (theme.isFull()) {
      return theme;
    } else {
      return ExpandableThemeData(
        iconColor: theme.iconColor ?? defaults.iconColor,
        useInkWell: theme.useInkWell ?? defaults.useInkWell,
        inkWellBorderRadius:
            theme.inkWellBorderRadius ?? defaults.inkWellBorderRadius,
        animationDuration:
            theme.animationDuration ?? defaults.animationDuration,
        scrollAnimationDuration:
            theme.scrollAnimationDuration ?? defaults.scrollAnimationDuration,
        crossFadePoint: theme.crossFadePoint ?? defaults.crossFadePoint,
        fadeCurve: theme.fadeCurve ?? defaults.fadeCurve,
        sizeCurve: theme.sizeCurve ?? defaults.sizeCurve,
        alignment: theme.alignment ?? defaults.alignment,
        headerAlignment: theme.headerAlignment ?? defaults.headerAlignment,
        bodyAlignment: theme.bodyAlignment ?? defaults.bodyAlignment,
        iconPlacement: theme.iconPlacement ?? defaults.iconPlacement,
        tapHeaderToExpand:
            theme.tapHeaderToExpand ?? defaults.tapHeaderToExpand,
        tapBodyToExpand: theme.tapBodyToExpand ?? defaults.tapBodyToExpand,
        tapBodyToCollapse:
            theme.tapBodyToCollapse ?? defaults.tapBodyToCollapse,
        hasIcon: theme.hasIcon ?? defaults.hasIcon,
        iconSize: theme.iconSize ?? defaults.iconSize,
        iconPadding: theme.iconPadding ?? defaults.iconPadding,
        iconRotationAngle:
            theme.iconRotationAngle ?? defaults.iconRotationAngle,
        expandIcon: theme.expandIcon ?? defaults.expandIcon,
        collapseIcon: theme.collapseIcon ?? defaults.collapseIcon,
      );
    }
  }

  double get collapsedFadeStart =>
      crossFadePoint! < 0.5 ? 0 : (crossFadePoint! * 2 - 1);

  double get collapsedFadeEnd =>
      crossFadePoint! < 0.5 ? 2 * crossFadePoint! : 1;

  double get expandedFadeStart =>
      crossFadePoint! < 0.5 ? 0 : (crossFadePoint! * 2 - 1);

  double get expandedFadeEnd => crossFadePoint! < 0.5 ? 2 * crossFadePoint! : 1;

  ExpandableThemeData? nullIfEmpty() {
    return isEmpty() ? null : this;
  }

  bool isEmpty() {
    return this == empty;
  }

  bool isFull() {
    return iconColor != null &&
        useInkWell != null &&
        inkWellBorderRadius != null &&
        animationDuration != null &&
        scrollAnimationDuration != null &&
        crossFadePoint != null &&
        fadeCurve != null &&
        sizeCurve != null &&
        alignment != null &&
        headerAlignment != null &&
        bodyAlignment != null &&
        iconPlacement != null &&
        tapHeaderToExpand != null &&
        tapBodyToExpand != null &&
        tapBodyToCollapse != null &&
        hasIcon != null &&
        iconRotationAngle != null &&
        expandIcon != null &&
        collapseIcon != null;
  }

  @override
  bool operator ==(dynamic o) {
    if (identical(this, o)) {
      return true;
    } else if (o is ExpandableThemeData) {
      return iconColor == o.iconColor &&
          useInkWell == o.useInkWell &&
          inkWellBorderRadius == o.inkWellBorderRadius &&
          animationDuration == o.animationDuration &&
          scrollAnimationDuration == o.scrollAnimationDuration &&
          crossFadePoint == o.crossFadePoint &&
          fadeCurve == o.fadeCurve &&
          sizeCurve == o.sizeCurve &&
          alignment == o.alignment &&
          headerAlignment == o.headerAlignment &&
          bodyAlignment == o.bodyAlignment &&
          iconPlacement == o.iconPlacement &&
          tapHeaderToExpand == o.tapHeaderToExpand &&
          tapBodyToExpand == o.tapBodyToExpand &&
          tapBodyToCollapse == o.tapBodyToCollapse &&
          hasIcon == o.hasIcon &&
          iconRotationAngle == o.iconRotationAngle &&
          expandIcon == o.expandIcon &&
          collapseIcon == o.collapseIcon;
    } else {
      return false;
    }
  }

  @override
  int get hashCode {
    return 0; // we don't care
  }

  static ExpandableThemeData of(BuildContext context,
      {bool rebuildOnChange = true}) {
    final notifier = rebuildOnChange
        ? context.dependOnInheritedWidgetOfExactType<_ExpandableThemeNotifier>()
        : context.findAncestorWidgetOfExactType<_ExpandableThemeNotifier>();
    return notifier?.themeData ?? defaults;
  }

  static ExpandableThemeData withDefaults(
      ExpandableThemeData? theme, BuildContext context,
      {bool rebuildOnChange = true}) {
    if (theme != null && theme.isFull()) {
      return theme;
    } else {
      return combine(
          combine(theme, of(context, rebuildOnChange: rebuildOnChange)),
          defaults);
    }
  }
}

class ExpandableTheme extends StatelessWidget {
  final ExpandableThemeData data;
  final Widget child;

  const ExpandableTheme({super.key, required this.data, required this.child});

  @override
  Widget build(BuildContext context) {
    _ExpandableThemeNotifier? n =
        context.dependOnInheritedWidgetOfExactType<_ExpandableThemeNotifier>();
    return _ExpandableThemeNotifier(
      themeData: ExpandableThemeData.combine(data, n?.themeData),
      child: child,
    );
  }
}

/// Makes an [ExpandableController] available to the widget subtree.
/// Useful for making multiple [Expandable] widgets synchronized with a single controller.
class ExpandableNotifier extends StatefulWidget {
  final ExpandableController? controller;
  final bool? initialExpanded;
  final Widget child;

  const ExpandableNotifier(
      {
      // An optional key
      Key? key,

      /// If the controller is not provided, it's created with the initial value of `initialExpanded`.
      this.controller,

      /// Initial expanded state. Must not be used together with [controller].
      this.initialExpanded,

      /// The child can be any widget which contains [Expandable] widgets in its widget tree.
      required this.child})
      : assert(!(controller != null && initialExpanded != null)),
        super(key: key);

  @override
  _ExpandableNotifierState createState() => _ExpandableNotifierState();
}

class _ExpandableNotifierState extends State<ExpandableNotifier> {
  ExpandableController? controller;
  ExpandableThemeData? theme;

  @override
  void initState() {
    super.initState();
    controller = widget.controller ??
        ExpandableController(initialExpanded: widget.initialExpanded ?? false);
  }

  @override
  void didUpdateWidget(ExpandableNotifier oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller &&
        widget.controller != null) {
      setState(() {
        controller = widget.controller;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cn = _ExpandableControllerNotifier(
        controller: controller, child: widget.child);
    return theme != null
        ? _ExpandableThemeNotifier(themeData: theme, child: cn)
        : cn;
  }
}

/// Makes an [ExpandableController] available to the widget subtree.
/// Useful for making multiple [Expandable] widgets synchronized with a single controller.
class _ExpandableControllerNotifier
    extends InheritedNotifier<ExpandableController> {
  const _ExpandableControllerNotifier(
      {required ExpandableController? controller, required Widget child})
      : super(notifier: controller, child: child);
}

/// Makes an [ExpandableController] available to the widget subtree.
/// Useful for making multiple [Expandable] widgets synchronized with a single controller.
class _ExpandableThemeNotifier extends InheritedWidget {
  final ExpandableThemeData? themeData;

  const _ExpandableThemeNotifier(
      {required this.themeData, required Widget child})
      : super(child: child);

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) {
    return !(oldWidget is _ExpandableThemeNotifier &&
        oldWidget.themeData == themeData);
  }
}

/// Controls the state (expanded or collapsed) of one or more [Expandable].
/// The controller should be provided to [Expandable] via [ExpandableNotifier].
class ExpandableController extends ValueNotifier<bool> {
  /// Returns [true] if the state is expanded, [false] if collapsed.
  bool get expanded => value;

  ExpandableController({
    bool? initialExpanded,
  }) : super(initialExpanded ?? false);

  /// Sets the expanded state.
  set expanded(bool exp) {
    value = exp;
  }

  /// Sets the expanded state to the opposite of the current state.
  void toggle() {
    expanded = !expanded;
  }

  static ExpandableController? of(BuildContext context,
      {bool rebuildOnChange = true, bool required = false}) {
    final notifier = rebuildOnChange
        ? context
            .dependOnInheritedWidgetOfExactType<_ExpandableControllerNotifier>()
        : context
            .findAncestorWidgetOfExactType<_ExpandableControllerNotifier>();
    assert(notifier != null || !required,
        "ExpandableNotifier is not found in widget tree");
    return notifier?.notifier;
  }
}

/// Shows either the expanded or the collapsed child depending on the state.
/// The state is determined by an instance of [ExpandableController] provided by [ScopedModel]
class Expandable extends StatelessWidget {
  /// Whe widget to show when collapsed
  final Widget collapsed;

  /// The widget to show when expanded
  final Widget expanded;

  /// If the controller is not specified, it will be retrieved from the context
  final ExpandableController? controller;

  final ExpandableThemeData? theme;

  const Expandable({
    Key? key,
    required this.collapsed,
    required this.expanded,
    this.controller,
    this.theme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller =
        this.controller ?? ExpandableController.of(context, required: true);
    final theme = ExpandableThemeData.withDefaults(this.theme, context);

    return AnimatedCrossFade(
      alignment: theme.alignment!,
      firstChild: collapsed,
      secondChild: expanded,
      firstCurve: Interval(theme.collapsedFadeStart, theme.collapsedFadeEnd,
          curve: theme.fadeCurve!),
      secondCurve: Interval(theme.expandedFadeStart, theme.expandedFadeEnd,
          curve: theme.fadeCurve!),
      sizeCurve: theme.sizeCurve!,
      crossFadeState: controller?.expanded ?? true
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      duration: theme.animationDuration!,
    );
  }
}

typedef ExpandableBuilder = Widget Function(
    BuildContext context, Widget collapsed, Widget expanded);

/// Determines the placement of the expand/collapse icon in [ExpandablePanel]
enum ExpandablePanelIconPlacement {
  /// The icon is on the left of the header
  left,

  /// The icon is on the right of the header
  right,
}

/// Determines the alignment of the header relative to the expand icon
enum ExpandablePanelHeaderAlignment {
  /// The header and the icon are aligned at their top positions
  top,

  /// The header and the icon are aligned at their center positions
  center,

  /// The header and the icon are aligned at their bottom positions
  bottom,
}

/// Determines vertical alignment of the body
enum ExpandablePanelBodyAlignment {
  /// The body is positioned at the left
  left,

  /// The body is positioned in the center
  center,

  /// The body is positioned at the right
  right,
}

/// A configurable widget for showing user-expandable content with an optional expand button.
class ExpandablePanel extends StatelessWidget {
  /// If specified, the header is always shown, and the expandable part is shown under the header
  final Widget? header;

  /// The widget shown in the collapsed state
  final Widget collapsed;

  /// The widget shown in the expanded state
  final Widget expanded;

  /// Builds an Expandable object, optional
  final ExpandableBuilder? builder;

  /// An optional controller. If not specified, a default controller will be
  /// obtained from a surrounding [ExpandableNotifier]. If that does not exist,
  /// the controller will be created with the initial state of [initialExpanded].
  final ExpandableController? controller;

  final ExpandableThemeData? theme;

  const ExpandablePanel({
    Key? key,
    this.header,
    required this.collapsed,
    required this.expanded,
    this.controller,
    this.builder,
    this.theme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = ExpandableThemeData.withDefaults(this.theme, context);

    Widget buildHeaderRow() {
      CrossAxisAlignment calculateHeaderCrossAxisAlignment() {
        switch (theme.headerAlignment!) {
          case ExpandablePanelHeaderAlignment.top:
            return CrossAxisAlignment.start;
          case ExpandablePanelHeaderAlignment.center:
            return CrossAxisAlignment.center;
          case ExpandablePanelHeaderAlignment.bottom:
            return CrossAxisAlignment.end;
        }
      }

      Widget wrapWithExpandableButton(
          {required Widget? widget, required bool wrap}) {
        return wrap
            ? ExpandableButton(child: widget, theme: theme)
            : widget ?? Container();
      }

      if (!theme.hasIcon!) {
        return wrapWithExpandableButton(
            widget: header, wrap: theme.tapHeaderToExpand!);
      } else {
        final rowChildren = <Widget>[
          Expanded(
            child: header ?? Container(),
          ),
          // ignore: deprecated_member_use_from_same_package
          wrapWithExpandableButton(
              widget: ExpandableIcon(theme: theme),
              wrap: !theme.tapHeaderToExpand!)
        ];
        return wrapWithExpandableButton(
            widget: Row(
              crossAxisAlignment: calculateHeaderCrossAxisAlignment(),
              children:
                  theme.iconPlacement! == ExpandablePanelIconPlacement.right
                      ? rowChildren
                      : rowChildren.reversed.toList(),
            ),
            wrap: theme.tapHeaderToExpand!);
      }
    }

    Widget buildBody() {
      Widget wrapBody(Widget child, bool tap) {
        Alignment calcAlignment() {
          switch (theme.bodyAlignment!) {
            case ExpandablePanelBodyAlignment.left:
              return Alignment.topLeft;
            case ExpandablePanelBodyAlignment.center:
              return Alignment.topCenter;
            case ExpandablePanelBodyAlignment.right:
              return Alignment.topRight;
          }
        }

        final widget = Align(
          alignment: calcAlignment(),
          child: child,
        );

        if (!tap) {
          return widget;
        }
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          child: widget,
          onTap: () {
            final controller = ExpandableController.of(context);
            controller?.toggle();
          },
        );
      }

      final builder = this.builder ??
          (context, collapsed, expanded) {
            return Expandable(
              collapsed: collapsed,
              expanded: expanded,
              theme: theme,
            );
          };

      return builder(context, wrapBody(collapsed, theme.tapBodyToExpand!),
          wrapBody(expanded, theme.tapBodyToCollapse!));
    }

    Widget buildWithHeader() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          buildHeaderRow(),
          buildBody(),
        ],
      );
    }

    final panel = header != null ? buildWithHeader() : buildBody();

    if (controller != null) {
      return ExpandableNotifier(
        controller: controller,
        child: panel,
      );
    } else {
      final controller =
          ExpandableController.of(context, rebuildOnChange: false);
      if (controller == null) {
        return ExpandableNotifier(
          child: panel,
        );
      } else {
        return panel;
      }
    }
  }
}

/// An down/up arrow icon that toggles the state of [ExpandableController] when the user clicks on it.
/// The model is accessed via [ScopedModelDescendant].
class ExpandableIcon extends StatefulWidget {
  final ExpandableThemeData? theme;

  const ExpandableIcon({
    super.key,
    this.theme,
    // ignore: deprecated_member_use_from_same_package
  });

  @override
  _ExpandableIconState createState() => _ExpandableIconState();
}

class _ExpandableIconState extends State<ExpandableIcon>
    with SingleTickerProviderStateMixin {
  AnimationController? animationController;
  Animation<double>? animation;
  ExpandableThemeData? theme;
  ExpandableController? controller;

  @override
  void initState() {
    super.initState();
    final theme = ExpandableThemeData.withDefaults(widget.theme, context,
        rebuildOnChange: false);
    animationController =
        AnimationController(duration: theme.animationDuration, vsync: this);
    animation = animationController!.drive(Tween<double>(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: theme.sizeCurve!)));
    controller = ExpandableController.of(context,
        rebuildOnChange: false, required: true);
    controller?.addListener(_expandedStateChanged);
    if (controller?.expanded ?? true) {
      animationController!.value = 1.0;
    }
  }

  @override
  void dispose() {
    controller?.removeListener(_expandedStateChanged);
    animationController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ExpandableIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.theme != oldWidget.theme) {
      theme = null;
    }
  }

  _expandedStateChanged() {
    if (controller!.expanded &&
        const [AnimationStatus.dismissed, AnimationStatus.reverse]
            .contains(animationController!.status)) {
      animationController!.forward();
    } else if (!controller!.expanded &&
        const [AnimationStatus.completed, AnimationStatus.forward]
            .contains(animationController!.status)) {
      animationController!.reverse();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller2 = ExpandableController.of(context,
        rebuildOnChange: false, required: true);
    if (controller2 != controller) {
      controller?.removeListener(_expandedStateChanged);
      controller = controller2;
      controller?.addListener(_expandedStateChanged);
      if (controller?.expanded ?? true) {
        animationController!.value = 1.0;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ExpandableThemeData.withDefaults(widget.theme, context);

    return Padding(
      padding: theme.iconPadding!,
      child: AnimatedBuilder(
        animation: animation!,
        builder: (context, child) {
          final showSecondIcon = theme.collapseIcon! != theme.expandIcon! &&
              animationController!.value >= 0.5;
          return Transform.rotate(
            angle: theme.iconRotationAngle! *
                (showSecondIcon
                    ? -(1.0 - animationController!.value)
                    : animationController!.value),
            child: Icon(
              showSecondIcon ? theme.collapseIcon! : theme.expandIcon!,
              color: theme.iconColor!,
              size: theme.iconSize!,
            ),
          );
        },
      ),
    );
  }
}

/// Toggles the state of [ExpandableController] when the user clicks on it.
class ExpandableButton extends StatelessWidget {
  final Widget? child;
  final ExpandableThemeData? theme;

  const ExpandableButton({super.key, this.child, this.theme});

  @override
  Widget build(BuildContext context) {
    final controller = ExpandableController.of(context, required: true);
    final theme = ExpandableThemeData.withDefaults(this.theme, context);

    if (theme.useInkWell!) {
      return InkWell(
        onTap: controller?.toggle,
        child: child,
        borderRadius: theme.inkWellBorderRadius!,
      );
    } else {
      return GestureDetector(
        onTap: controller?.toggle,
        child: child,
      );
    }
  }
}

/// Ensures that the child is visible on the screen by scrolling the outer viewport
/// when the outer [ExpandableNotifier] delivers a change event.
///
/// See also:
///
/// * [RenderObject.showOnScreen]
class ScrollOnExpand extends StatefulWidget {
  final Widget child;

  /// If true then the widget will be scrolled to become visible when expanded
  final bool scrollOnExpand;

  /// If true then the widget will be scrolled to become visible when collapsed
  final bool scrollOnCollapse;

  final ExpandableThemeData? theme;

  const ScrollOnExpand({
    Key? key,
    required this.child,
    this.scrollOnExpand = true,
    this.scrollOnCollapse = true,
    this.theme,
  }) : super(key: key);

  @override
  _ScrollOnExpandState createState() => _ScrollOnExpandState();
}

class _ScrollOnExpandState extends State<ScrollOnExpand> {
  ExpandableController? _controller;
  int _isAnimating = 0;
  BuildContext? _lastContext;
  ExpandableThemeData? _theme;

  @override
  void initState() {
    super.initState();
    _controller = ExpandableController.of(context,
        rebuildOnChange: false, required: true);
    _controller?.addListener(_expandedStateChanged);
  }

  @override
  void didUpdateWidget(ScrollOnExpand oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newController = ExpandableController.of(context,
        rebuildOnChange: false, required: true);
    if (newController != _controller) {
      _controller?.removeListener(_expandedStateChanged);
      _controller = newController;
      _controller?.addListener(_expandedStateChanged);
    }
  }

  @override
  void dispose() {
    super.dispose();
    _controller?.removeListener(_expandedStateChanged);
  }

  _animationComplete() {
    _isAnimating--;
    if (_isAnimating == 0 && _lastContext != null && mounted) {
      if ((_controller?.expanded ?? true && widget.scrollOnExpand) ||
          (!(_controller?.expanded ?? true) && widget.scrollOnCollapse)) {
        _lastContext
            ?.findRenderObject()
            ?.showOnScreen(duration: _animationDuration);
      }
    }
  }

  Duration get _animationDuration {
    return _theme?.scrollAnimationDuration ??
        ExpandableThemeData.defaults.animationDuration!;
  }

  _expandedStateChanged() {
    if (_theme != null) {
      _isAnimating++;
      Future.delayed(_animationDuration + const Duration(milliseconds: 10),
          _animationComplete);
    }
  }

  @override
  Widget build(BuildContext context) {
    _lastContext = context;
    _theme = ExpandableThemeData.withDefaults(widget.theme, context);
    return widget.child;
  }
}

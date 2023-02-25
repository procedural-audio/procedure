import 'package:flutter/material.dart';
import 'package:metasampler/ui/ui.dart';
import 'package:file_picker/file_picker.dart';

import '../host.dart';
import '../views/variables.dart';

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
  TransformWidget({required this.data, required this.child});

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
      {required this.data,
      required this.child,
      required this.onUpdate,
      required this.onTap,
      required this.tree});

  Widget? child;
  TransformData data;
  Function(TransformData) onUpdate;
  Function() onTap;
  UITree tree;

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

  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
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
                              child: Stack(fit: StackFit.expand, children: [
                                MouseRegion(
                                    opaque: true,
                                    hitTestBehavior:
                                        HitTestBehavior.deferToChild,
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
                                        widget.tree.editorBuilder
                                            .notifyListeners();
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
                                                    width: 2.0)))))
                              ])))))));
    });
  }
}

class Resizer extends StatefulWidget {
  Resizer(
      {required this.data,
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
        child: Stack(children: [
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
                              border:
                                  Border.all(color: Colors.grey, width: 1.0)),
                          child: Container(
                              decoration: BoxDecoration(
                                  border: Border.all(
                                      color: widget.selected
                                          ? Colors.blue
                                          : Colors.white,
                                      width: 1.0)),
                              child: Container(
                                  decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.grey,
                                          width: 1.0)))))))),
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
                                border:
                                    Border.all(color: Colors.grey, width: 1.0),
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
                              widget.data.width =
                                  widget.data.width! + e.delta.dx;
                            }

                            widget.onUpdate(widget.data);
                          })))),
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
                                border:
                                    Border.all(color: Colors.grey, width: 1.0),
                                borderRadius: const BorderRadius.vertical(
                                    bottom: Radius.circular(10.0)),
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
                              widget.data.height =
                                  widget.data.height! - e.delta.dy;
                              widget.data.top += e.delta.dy;
                            }

                            widget.onUpdate(widget.data);
                          })))),
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
                              border:
                                  Border.all(color: Colors.grey, width: 1.0),
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
                            widget.data.height =
                                widget.data.height! + e.delta.dy;
                          }

                          widget.onUpdate(widget.data);
                        },
                      )))),
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
                                border:
                                    Border.all(color: Colors.grey, width: 1.0),
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
                              widget.data.width =
                                  widget.data.width! - e.delta.dx;
                              widget.data.left += e.delta.dx;
                            }

                            widget.onUpdate(widget.data);
                          })))),
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
                      }))),
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
                  ))),
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
                  ))),
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
                  )))
        ]));
  }
}

class TransformWidgetEditor extends StatefulWidget {
  TransformWidgetEditor(
      {required this.data, required this.onUpdate, required this.tree});

  TransformData data;
  Function(TransformData) onUpdate;
  UITree tree;

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
            child: Column(children: [
              Row(children: [
                Field(
                  label: "WIDTH",
                  initialValue: widget.data.width == null
                      ? ""
                      : widget.data.width.toString(),
                  onChanged: (s) {
                    widget.data.width = double.tryParse(s);
                    widget.onUpdate(widget.data);
                  },
                ),
                Field(
                    label: "HEIGHT",
                    initialValue: widget.data.height == null
                        ? ""
                        : widget.data.height.toString(),
                    onChanged: (s) {
                      widget.data.height = double.tryParse(s);
                      widget.onUpdate(widget.data);
                    })
              ])
            ])),
        Section(
            title: "Position",
            child: Column(children: [
              Row(children: [
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
                    })
              ])
            ])),
        Section(
            title: "Alignment",
            child: Container(
                padding: const EdgeInsets.fromLTRB(60, 5, 0, 10),
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
                    widget.tree.editorBuilder.notifyListeners();
                  },
                ))),
        Section(
            title: "Padding",
            child: Column(children: [
              Row(children: [
                Field(
                  label: "LEFT",
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
                  label: "RIGHT",
                  initialValue: widget.data.padding.right.toString(),
                  onChanged: (s) {
                    widget.data.padding = EdgeInsets.fromLTRB(
                        widget.data.padding.left,
                        widget.data.padding.top,
                        double.tryParse(s) ?? 0.0,
                        widget.data.padding.bottom);

                    if (widget.data.padding.right < 0) {
                      widget.data.padding = EdgeInsets.fromLTRB(
                          widget.data.padding.left,
                          widget.data.padding.top,
                          0,
                          widget.data.padding.bottom);
                    }

                    widget.onUpdate(widget.data);
                  },
                ),
              ]),
              Row(children: [
                Field(
                  label: "TOP",
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
                          widget.data.padding.bottom);
                    }

                    widget.onUpdate(widget.data);
                  },
                ),
                Field(
                  label: "BOTTOM",
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
                          0);
                    }

                    widget.onUpdate(widget.data);
                  },
                ),
              ]),
            ])),
      ],
    );
  }
}

class AlignmentField extends StatelessWidget {
  AlignmentField({required this.alignment, required this.onUpdate});

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
      {required this.selected,
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
            )));
  }
}

class Label extends StatefulWidget {
  Label({required this.text, required this.child, this.width, this.height});

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
                            border:
                                Border.all(color: Colors.blue, width: 2.0))))),
          ],
        ));
  }
}

class LabelDropdown extends StatefulWidget {
  LabelDropdown({required this.editor, required this.editorShowing});

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
          child: Container(
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
  EditorTitle(this.text);

  String text;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
          alignment: Alignment.center,
          height: 50,
          child: Text(text,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400))),
      const Divider(
        color: Color.fromRGBO(60, 60, 60, 1.0),
        thickness: 1.0,
      )
    ]);
  }
}

class DualField extends StatefulWidget {
  DualField(
      {required this.label,
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

    return Row(children: [
      Container(
          width: 80,
          padding: const EdgeInsets.all(10),
          alignment: Alignment.centerLeft,
          child: Text(widget.label,
              style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w400))),
      Column(children: [
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
                  fontWeight: FontWeight.w400),
            )),
        Container(
            width: 50,
            height: 20,
            padding: const EdgeInsets.all(2),
            alignment: Alignment.centerLeft,
            child: Text(widget.fieldLabel1,
                style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w300)))
      ]),
      Column(children: [
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
                  fontWeight: FontWeight.w400),
            )),
        Container(
            width: 50,
            height: 20,
            padding: const EdgeInsets.all(2),
            alignment: Alignment.centerLeft,
            child: Text(widget.fieldLabel2,
                style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w300)))
      ])
    ]);
  }
}

class DropdownOverlay extends StatefulWidget {
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
            )));
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
  CustomDropdown(
      {this.hideIcon = false,
      required this.header,
      this.child,
      this.dropdownStyle = const DropdownStyle(),
      this.dropdownButtonStyle = const DropdownButtonStyle(),
      this.icon,
      this.leadingIcon = false,
      required this.editorShowing});

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

    _rotateAnimation = Tween(begin: 0.0, end: 0.5).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOut,
    ));
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
      child: Container(
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
                      Icon(Icons.arrow_downward, color: Colors.white),
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
                      child: Stack(children: [
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
                                    elevation:
                                        widget.dropdownStyle.elevation ?? 0,
                                    borderRadius:
                                        widget.dropdownStyle.borderRadius ??
                                            BorderRadius.zero,
                                    color:
                                        const Color.fromRGBO(30, 30, 30, 1.0),
                                    child: SizeTransition(
                                      axisAlignment: 1,
                                      sizeFactor: _expandAnimation!,
                                      child: widget.child,
                                    ))))
                      ]))));
        });
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
  Section({required this.title, required this.child});

  String title;
  Widget child;

  @override
  State<Section> createState() => _Section();
}

class _Section extends State<Section> {
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      ExpansionTile(
        title: Text(widget.title),
        initiallyExpanded: true,
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
    ]);
  }
}

class SubSection extends StatefulWidget {
  SubSection({required this.title, required this.child});

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
  Field(
      {required this.label,
      required this.initialValue,
      required this.onChanged,
      this.width,
      this.height})
      : super(key: UniqueKey());

  String label;
  String initialValue;
  void Function(String) onChanged;
  double? width;
  double? height;

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
            child: Row(
              children: [
                Expanded(
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                        child: TextField(
                          onSubmitted: widget.onChanged,
                          focusNode: focusNode,
                          controller: controller,
                          style: TextStyle(
                              color: editing ? Colors.white : Colors.grey,
                              fontSize: 14),
                          decoration: const InputDecoration(
                              isDense: true, border: InputBorder.none),
                        ))),
                Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                    child: Text(widget.label,
                        style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500)))
              ],
            )));
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
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      widget.onChanged(result.files.single.path);
    } else {
      // User canceled the picker
    }
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
  ChildDragTarget(
      {this.width,
      this.height,
      this.child,
      required this.onAddChild,
      required this.tree,
      required this.host});

  void Function(UIWidget2 widget) onAddChild;
  double? width;
  double? height;
  Widget? child;

  UITree tree;
  Host host;

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
            return Stack(children: [
              widget.child ?? Container(),
              IgnorePointer(
                  child: Visibility(
                      visible: hovering,
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
                                          color: Colors.blue, width: 2.0)),
                                  child: const Icon(
                                    Icons.add,
                                    color: Colors.blue,
                                    size: 20,
                                  ))))))
            ]);
          },
          onWillAccept: (data) {
            return true;
          },
          onAccept: (name) {
            UIWidget2? child = createUIWidget(widget.host, name, widget.tree);

            if (child != null) {
              print("Creating child $name");
              widget.onAddChild(child);
              widget.tree.refresh();
            } else {
              print("Couldn't create child $name");
            }
          },
        ));
  }
}

class VarField extends StatefulWidget {
  VarField({required this.host, required this.varName});

  Host host;
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
      Overlay.of(context)?.insert(_overlayEntry!);
      setState(() => _isOpen = true);
      _animationController?.forward();
    }
  }
}

class VarFieldElement extends StatefulWidget {
  VarFieldElement(this.v, this.varName);

  Var v;
  ValueNotifier<String?> varName;

  @override
  State<VarFieldElement> createState() => _VarFieldElement();
}

class _VarFieldElement extends State<VarFieldElement> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    Color color = Colors.black;

    if (widget.v.notifier.value is double) {
      color = Colors.green;
    } else if (widget.v.notifier.value is bool) {
      color = Colors.red;
    }

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
        child: GestureDetector(
            onTap: () {
              // widget.varName.value = widget.v.name;
              print("SHOULD SET NAME HERE");
            },
            child: Container(
                height: 30,
                padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                color: hovering
                    ? const Color.fromRGBO(140, 140, 140, 1.0)
                    : const Color.fromRGBO(120, 120, 120, 1.0),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                            color: color,
                            borderRadius:
                                const BorderRadius.all(Radius.circular(5))),
                      ),
                      const SizedBox(width: 10),
                      Text("SOME VAR HERE",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w300))
                    ]))));
  }
}

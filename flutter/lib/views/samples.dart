import 'dart:io';
import 'dart:math';
import 'dart:ui';

import '../patch/patch.dart';
import '../main.dart';

import 'settings.dart';

import 'package:flutter/material.dart';

import '../config.dart';

class SamplesView extends StatefulWidget {
  SamplesView(this.app, {super.key});

  App app;

  @override
  State<SamplesView> createState() => _SamplesView();
}

class _SamplesView extends State<SamplesView> {
  _SamplesView() {
    view1 = SamplesBrowserWidget(widget.app);
  }

  bool fileView = true;
  late SamplesBrowserWidget view1;
  var view2 = const Samples2DWidget();

  //Directory currentDir = Directory(globals.contentPath + "/samples");
  Directory currentDir = Directory("" "/samples");

  String searchText = "";

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100, maxHeight: 1000),
        child: Padding(
          padding: const EdgeInsets.all(50),
          child: Container(
            child: Column(
              children: [
                SizedBox(
                  height: 50,
                  width: 1000,
                  child: Stack(
                    children: [
                      Positioned(
                        top: 2.5,
                        left: 5,
                        child: IconButton(
                          color: currentDir.path == contentPath + "/samples"
                              ? MyTheme.grey70
                              : Colors.white,
                          icon: const Icon(Icons.arrow_back),
                          iconSize: 25,
                          onPressed: () {
                            setState(() {
                              if (currentDir.path != contentPath + "/samples") {
                                currentDir = currentDir.parent;
                              }
                            });
                          },
                        ),
                      ),
                      Positioned(
                          top: 10,
                          left: 60,
                          child: Container(
                            width: 180,
                            height: 28,
                            child: TextField(
                              maxLines: 1,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              decoration: const InputDecoration(
                                  fillColor: Color.fromARGB(255, 112, 35, 30),
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.all(10)),
                              onChanged: (data) {
                                setState(() {
                                  searchText = data;
                                });
                              },
                            ),
                            decoration: BoxDecoration(color: MyTheme.grey40),
                            foregroundDecoration: BoxDecoration(
                                border: Border.all(
                                    color: const Color.fromRGBO(
                                        100, 100, 100, 1.0),
                                    width: 2.0),
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(4))),
                          )),
                      const Positioned(
                          left: 260,
                          top: 10,
                          child: SizedBox(
                              height: 30,
                              width: 690,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    TagWidget("Kick", Colors.red),
                                    TagWidget("Snare", Colors.blue),
                                    TagWidget("Piano", Colors.green),
                                    TagWidget("Strings", Colors.purple),
                                    TagWidget("Strings", Colors.purple),
                                    TagWidget("Strings", Colors.purple),
                                    TagWidget("Kick", Colors.red),
                                    TagWidget("Snare", Colors.blue),
                                    TagWidget("Piano", Colors.green),
                                    TagWidget("Strings", Colors.purple),
                                    TagWidget("Strings", Colors.purple),
                                    TagWidget("Strings", Colors.purple),
                                    TagWidget("Strings", Colors.purple),
                                  ],
                                ),
                              ))),
                      Positioned(
                        top: 2.5,
                        right: 5,
                        child: IconButton(
                          color: currentDir.path == contentPath + "/samples"
                              ? MyTheme.grey70
                              : Colors.white,
                          icon: fileView
                              ? const Icon(Icons.poll_outlined)
                              : const Icon(Icons.folder),
                          iconSize: 25,
                          onPressed: () {
                            setState(() {
                              fileView = !fileView;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 1,
                  decoration: const BoxDecoration(
                    color: Color.fromRGBO(10, 10, 10, 1.0),
                  ),
                ),
                /* Viewer */
                Expanded(
                  child: fileView ? view1 : view2,
                )
              ],
            ),
            decoration: BoxDecoration(
              color: MyTheme.grey30,
              borderRadius: BorderRadius.circular(10.0),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    spreadRadius: 5,
                    blurRadius: 10,
                    offset: const Offset(0, 5)),
                const BoxShadow(
                    color: Color.fromRGBO(200, 200, 200, 0.3), spreadRadius: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SamplesBrowserWidget extends StatefulWidget {
  SamplesBrowserWidget(this.app, {super.key});

  App app;

  @override
  State<SamplesBrowserWidget> createState() => _SamplesBrowserWidgetState();
}

class _SamplesBrowserWidgetState extends State<SamplesBrowserWidget> {
  _SamplesBrowserWidgetState() {
    currentDir = Directory(contentPath + "/samples");
  }

  late Directory currentDir;

  // SHOULD USE THIS INSTEAD
  Future<List<TableRow>> getRows() async {
    return Future.value([]);
  }

  String searchText = "";

  @override
  Widget build(BuildContext context) {
    if (!currentDir.existsSync()) {
      print("Error: Current folder doesn't exist");
      return Container();
    }

    var entries = currentDir.listSync(recursive: false).toList();

    if (searchText != "") {
      entries = currentDir.listSync(recursive: true).toList();
    }

    List<FileRow> rows = [];

    for (var entry in entries) {
      var file = File(entry.path);
      var directory = Directory(entry.path);

      var description = "Description here";

      if (searchText != "") {
        if (!file.name.contains(searchText) &&
            !file.path.contains(searchText) &&
            !description.contains(searchText)) {
          continue;
        }
      }

      if (file.existsSync()) {
        rows.add(FileRow(
          icon: Icons.audiotrack,
          name: entry.name,
          description: description,
          color: Colors.deepPurpleAccent,
          onTap: () {},
          onDoubleTap: () {
            setState(() {
              print("Selected file");
            });
          },
          onPanStart: (details) {},
          onPanUpdate: (details) {},
          onPanEnd: (details) {},
        ));
      } else if (directory.existsSync()) {
        rows.add(FileRow(
          icon: Icons.folder,
          name: entry.name,
          description: description,
          color: Colors.blueAccent,
          onTap: () {},
          onDoubleTap: () {
            setState(() {
              currentDir = Directory(entry.path);
            });
          },
          onPanStart: (details) {},
          onPanUpdate: (details) {},
          onPanEnd: (details) {},
        ));
      }
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
              child: Column(
            children: rows,
          )),
        )
      ],
    );
  }
}

class TagWidget extends StatefulWidget {
  final String text;
  final Color color;

  const TagWidget(this.text, this.color, {super.key});

  @override
  State<TagWidget> createState() => _TagWidgetState(text: text, color: color);
}

class _TagWidgetState extends State<TagWidget> {
  final String text;
  final Color color;
  bool hovering = false;

  _TagWidgetState({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
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
            child: Container(
              padding: const EdgeInsets.all(6),
              height: 40,
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
              decoration: BoxDecoration(
                  color: hovering ? color : color.withAlpha(200),
                  borderRadius: const BorderRadius.all(Radius.circular(5))),
            )));
  }
}

class FileRow extends StatefulWidget {
  FileRow(
      {required this.icon,
      required this.name,
      required this.description,
      required this.color,
      required this.onTap,
      required this.onDoubleTap,
      required this.onPanStart,
      required this.onPanUpdate,
      required this.onPanEnd})
      : super(key: UniqueKey());

  final IconData icon;
  final String name;
  final String description;
  final Color color;

  final void Function() onTap;
  final void Function() onDoubleTap;
  final void Function(DragStartDetails) onPanStart;
  final void Function(DragUpdateDetails) onPanUpdate;
  final void Function(DragEndDetails) onPanEnd;

  @override
  State<FileRow> createState() => _FileRowState(
      icon: icon,
      name: name,
      description: description,
      color: color,
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      onPanStart: onPanStart,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd);
}

class _FileRowState extends State<FileRow> {
  _FileRowState(
      {required this.icon,
      required this.name,
      required this.description,
      required this.color,
      required this.onTap,
      required this.onDoubleTap,
      required this.onPanStart,
      required this.onPanUpdate,
      required this.onPanEnd});

  final IconData icon;
  final String name;
  final String description;
  final Color color;

  final void Function() onTap;
  final void Function() onDoubleTap;
  final void Function(DragStartDetails) onPanStart;
  final void Function(DragUpdateDetails) onPanUpdate;
  final void Function(DragEndDetails) onPanEnd;

  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    var textColor = hovering ? Colors.white : Colors.white.withAlpha(180);
    var iconColor = hovering ? color : color.withAlpha(180);

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
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        onPanStart: onPanStart,
        onPanUpdate: onPanUpdate,
        onPanEnd: onPanEnd,
        child: Row(
          children: [
            const SizedBox(width: 0, height: 50),
            SizedBox(width: 50, child: Icon(icon, color: iconColor)),
            SizedBox(
                width: 400,
                child: Text(
                  name,
                  style: TextStyle(color: textColor, fontSize: 16),
                )),
            SizedBox(
                width: 300,
                child: Text(
                  description,
                  style: TextStyle(color: textColor, fontSize: 16),
                )),
            Container(
              alignment: Alignment.topRight,
              width: 200,
              child: RatingWidget(
                rating: 3,
                color: textColor,
                onRatingChange: (val) {
                  print("Changed rating to " + val.toString());
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RatingWidget extends StatelessWidget {
  const RatingWidget(
      {super.key,
      required this.rating,
      required this.color,
      required this.onRatingChange});

  final int rating;
  final void Function(int) onRatingChange;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const double iconSize = 15;
    const double spacing = 25;

    return SizedBox(
        width: 130,
        height: 50,
        child: Stack(
          children: [
            Positioned(
              top: 5,
              left: spacing * 0,
              child: IconButton(
                icon: rating >= 1
                    ? const Icon(Icons.circle)
                    : const Icon(Icons.circle_outlined),
                iconSize: iconSize,
                color: color,
                onPressed: () {
                  onRatingChange(1);
                },
              ),
            ),
            Positioned(
              top: 5,
              left: spacing * 1,
              child: IconButton(
                icon: rating >= 2
                    ? const Icon(Icons.circle)
                    : const Icon(Icons.circle_outlined),
                iconSize: iconSize,
                color: color,
                onPressed: () {
                  onRatingChange(2);
                },
              ),
            ),
            Positioned(
              top: 5,
              left: spacing * 2,
              child: IconButton(
                icon: rating >= 3
                    ? const Icon(Icons.circle)
                    : const Icon(Icons.circle_outlined),
                iconSize: iconSize,
                color: color,
                onPressed: () {
                  onRatingChange(3);
                },
              ),
            ),
            Positioned(
              top: 5,
              left: spacing * 3,
              child: IconButton(
                icon: rating >= 4
                    ? const Icon(Icons.circle)
                    : const Icon(Icons.circle_outlined),
                iconSize: iconSize,
                color: color,
                onPressed: () {
                  onRatingChange(4);
                },
              ),
            ),
            Positioned(
              top: 5,
              left: spacing * 4,
              child: IconButton(
                icon: rating >= 5
                    ? const Icon(Icons.circle)
                    : const Icon(Icons.circle_outlined),
                iconSize: iconSize,
                color: color,
                onPressed: () {
                  onRatingChange(5);
                },
              ),
            ),
          ],
        ));
  }
}

class Samples2DWidget extends StatelessWidget {
  const Samples2DWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [
        SamplesCloud(),
      ],
    );
  }
}

class SamplesCloud extends StatelessWidget {
  const SamplesCloud({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: SamplesCloudPainter(),
    );
  }
}

class SamplesCloudPainter extends CustomPainter {
  var rng = Random();

  List<Offset> redPoints = [];
  List<Offset> greenPoints = [];
  List<Offset> bluePoints = [];

  void populateLists(Size size) {
    size = Size(size.width - 10, size.height - 10);

    if (redPoints.length < 2) {
      for (double i = 0; i < 1000; i++) {
        redPoints.add(Offset(
          rng.nextDouble() * size.width + 5,
          rng.nextDouble() * size.height + 5,
        ));
      }

      for (double i = 0; i < 1000; i++) {
        greenPoints.add(Offset(
          rng.nextDouble() * size.width + 5,
          rng.nextDouble() * size.height + 5,
        ));
      }

      for (double i = 0; i < 1000; i++) {
        bluePoints.add(Offset(
          rng.nextDouble() * size.width + 5,
          rng.nextDouble() * size.height + 5,
        ));
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    populateLists(size);

    final paintRed = Paint()
      ..color = MyTheme.control
      ..strokeWidth = 2;

    final paintGreen = Paint()
      ..color = MyTheme.midi
      ..strokeWidth = 3;

    final paintBlue = Paint()
      ..color = MyTheme.audio
      ..strokeWidth = 5;

    /* Size points based on popularity or rating */

    canvas.drawPoints(PointMode.points, redPoints, paintRed);

    canvas.drawPoints(PointMode.points, greenPoints, paintGreen);

    canvas.drawPoints(
      PointMode.points,
      bluePoints,
      paintBlue,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

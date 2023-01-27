import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'settings.dart';
import '../host.dart';
import '../config.dart';

@JsonSerializable()
class InstrumentInfo {
  InstrumentInfo(this.name, this.path);

  String name = "Untitled Instrument";
  String description =
      "Here is a paragraph that can go below the title. It is here to fill some space.\n";
  String path = "";
  File image =
      File("/home/chase/github/content/assets/backgrounds/background_01.png");
  List<String> tags = ["Tag 1", "Tag 2"];

  int rating = -1;

  InstrumentInfo.fromJson(Map<String, dynamic> json, String dirPath) {
    name = json['name'];
    description = json['description'];
    rating = json['rating'];
    path = dirPath;

    File file1 = File(path + "/info/background.jpg");
    if (file1.existsSync()) {
      image = file1;
    }

    File file2 = File(path + "/info/background.png");
    if (file2.existsSync()) {
      image = file2;
    }

    File file3 = File(path + "/info/background.jpeg");
    if (file3.existsSync()) {
      image = file3;
    }
  }

  Map<String, dynamic> toJson() =>
      {'name': name, 'description': description, 'rating': rating};
}

class InfoContentsWidget extends StatefulWidget {
  InfoContentsWidget(this.host,
      {required this.instrument, required this.onClose, Key? key})
      : super(key: key);

  InstrumentInfo instrument;
  Host host;
  void Function() onClose;

  @override
  _InfoContentsWidgetState createState() => _InfoContentsWidgetState();
}

class _InfoContentsWidgetState extends State<InfoContentsWidget> {
  _InfoContentsWidgetState();

  bool editing = false;
  String nameText = "";
  bool titleError = false;

  bool mouseOverImage = false;

  void savePressed(String title, String description) {
    var instruments = widget.host.globals.instruments2;

    /* Save the instrument */
    for (int i = 0; i < instruments.length; i++) {
      if (instruments[i].path == widget.instrument.path) {
        instruments[i].description = description;

        /* Rename instrument */
        if (instruments[i].name != title) {
          if (title == "") {
            setState(() {
              titleError = true;
            });

            return;
          }

          /* Find new path */
          String newPath =
              Directory(instruments[i].path).parent.path + "/" + title;

          int count = 2;
          while (Directory(newPath).existsSync()) {
            newPath = Directory(instruments[i].path).parent.path +
                "/" +
                title +
                " (" +
                count.toString() +
                ")";
            count += 1;
          }

          /* Move file */
          Directory(instruments[i].path).renameSync(newPath);

          /* Update instrument list */
          instruments[i].name = title;
          instruments[i].path = newPath;
        }

        /* Update loaded instrument */
        if (widget.instrument.path == widget.host.globals.instrument.path) {
          widget.host.globals.instrument = instruments[i];
        }

        widget.instrument = instruments[i];

        /* Update info json */
        File file = File(instruments[i].path + "/info/info.json");
        String json = jsonEncode(instruments[i]);
        file.writeAsString(json);
      }
    }

    setState(() {
      if (editing) {
        /* Update local instrument metadata */
        widget.instrument.description = description;
        editing = false;
      } else {
        /* Start editing */
        // markdownEditor.controller.text = widget.instrument.description;
        // ^^^ Need this ???
        editing = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    /* Markdown Viewer */
    final markdownViewer = Padding(
        padding: const EdgeInsets.fromLTRB(15, 10, 0, 0),
        child: Text(
          widget.instrument.description,
          style: const TextStyle(
              fontWeight: FontWeight.w300,
              fontStyle: FontStyle.normal,
              fontSize: 14,
              color: Colors.white70,
              decoration: TextDecoration.none),
        ));

    /* Markdown Editor */
    var markdownEditor = EditableText(
        controller: TextEditingController.fromValue(
            TextEditingValue(text: widget.instrument.description)),
        focusNode: FocusNode(),
        cursorColor: Colors.grey,
        backgroundCursorColor: Colors.grey,
        maxLines: 20,
        style: const TextStyle(
            fontWeight: FontWeight.w300,
            fontStyle: FontStyle.normal,
            fontSize: 14,
            color: Colors.white,
            decoration: TextDecoration.none));

    TextEditingController titleController = TextEditingController.fromValue(
        TextEditingValue(text: widget.instrument.name));

    /* Title Editor */

    return LayoutBuilder(builder: (context, constraints) {
      double width = constraints.maxWidth;
      double height = constraints.maxHeight;

      return Container(
          decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              color: Color.fromRGBO(40, 40, 40, 1.0)),
          child: Row(children: [
            SingleChildScrollView(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                  GestureDetector(
                      child: const Icon(Icons.chevron_left, color: Colors.grey),
                      onTap: () => widget.onClose()),
                  Container(height: 20),
                  InfoViewImage(
                    width: width,
                    editing: editing,
                    path: widget.instrument.path,
                    onUpdate: () => setState(() {}),
                  ),
                  Container(
                      padding: editing
                          ? const EdgeInsets.fromLTRB(23, 30, 20, 0)
                          : const EdgeInsets.fromLTRB(30, 30, 20, 0),
                      width: max(width - 200, 0),
                      height: 60,
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InfoViewTitle(
                              editing: editing,
                              name: widget.instrument.name,
                              controller: titleController,
                            ),
                            IconButton(
                                color: Colors.white,
                                icon: Icon(editing ? Icons.save : Icons.edit,
                                    size: 18, color: Colors.white),
                                iconSize: 20,
                                onPressed: () => savePressed(
                                    titleController.text,
                                    markdownEditor.controller.text))
                          ])),

                  /* Description Container */
                  Padding(
                      padding: !editing
                          ? const EdgeInsets.fromLTRB(0, 0, 15, 15)
                          : const EdgeInsets.fromLTRB(0, 10, 0, 10),
                      child: Container(
                          padding: EdgeInsets.all(!editing ? 0 : 10),
                          width: max(width - 200 - 30, 0),
                          child: !editing ? markdownViewer : markdownEditor,
                          decoration: !editing
                              ? const BoxDecoration()
                              : BoxDecoration(
                                  color: MyTheme.grey40,
                                  border: Border.all(
                                      color: Colors.grey, width: 1))))
                ])),
            Container(
                width: min(max(width - 200, 0), 200),
                child: Column(
                  children: [
                    AuthorView(),
                    const AudioPreview(path: ""),
                    TagView()
                  ],
                ),
                decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                    color: Color.fromRGBO(40, 40, 40, 1.0)))
          ]));
    });
  }
}

// class InfoViewEditButton extends StatelessWidget {}

class InfoViewTitle extends StatelessWidget {
  InfoViewTitle(
      {required this.editing, required this.name, required this.controller});

  bool editing;
  String name;
  TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Visibility(
          visible: !editing,
          child: Text(
            name,
            style: const TextStyle(
                fontWeight: FontWeight.normal,
                fontStyle: FontStyle.normal,
                fontSize: 18,
                color: Colors.white,
                decoration: TextDecoration.none),
          )),
      Visibility(
          visible: editing,
          child: Container(
              padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
              height: 30,
              child: EditableText(
                  controller: controller,
                  focusNode: FocusNode(),
                  cursorColor: Colors.grey,
                  backgroundCursorColor: Colors.grey,
                  maxLines: 20,
                  style: const TextStyle(
                      fontWeight: FontWeight.normal,
                      fontStyle: FontStyle.normal,
                      fontSize: 18,
                      color: Colors.white,
                      decoration: TextDecoration.none)),
              decoration: BoxDecoration(
                  color: MyTheme.grey40,
                  border: Border.all(color: Colors.grey, width: 1))))
    ]);
  }
}

class InfoViewImage extends StatefulWidget {
  InfoViewImage(
      {required this.editing,
      required this.path,
      required this.onUpdate,
      required this.width});

  bool editing;
  String path;
  double width;
  void Function() onUpdate;

  File getBackgroundImage() {
    File file1 = File(path + "/info/background.jpg");
    if (file1.existsSync()) {
      return file1;
    }

    File file2 = File(path + "/info/background.png");
    if (file2.existsSync()) {
      return file2;
    }

    File file3 = File(path + "/info/background.jpeg");
    if (file3.existsSync()) {
      return file3;
    }

    return File(contentPath + "/assets/images/logo.png");
  }

  void browserForImage() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(allowedExtensions: [".png", ".jpg", ".jpeg"]);

    if (result != null) {
      File file = File(result.files.single.path!);

      /* Delete old image */

      File file1 = File(path + "/info/background.jpg");
      if (file1.existsSync()) {
        file1.delete();
      }

      File file2 = File(path + "/info/background.png");
      if (file2.existsSync()) {
        file2.delete();
      }

      File file3 = File(path + "/info/background.jpeg");
      if (file3.existsSync()) {
        file3.delete();
      }

      if (file.name.endsWith(".png")) {
        file.copySync(path + "/info/background.png");
      } else if (file.name.endsWith(".jpg")) {
        file.copySync(path + "/info/background.jpg");
      } else if (file.name.endsWith(".jpeg")) {
        file.copySync(path + "/info/background.jpeg");
      } else {
        print("ERROR: Couldn't find image extension");
      }

      onUpdate();
    }
  }

  @override
  State<StatefulWidget> createState() => _InfoViewImage();
}

class _InfoViewImage extends State<InfoViewImage> {
  bool mouseOverImage = false;

  @override
  Widget build(BuildContext context) {
    /* Main image */
    return LayoutBuilder(builder: (context, constraints) {
      return Stack(children: [
        ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(5)),
            child: Image.file(
              widget.getBackgroundImage(),
              width: min(450, widget.width - 200),
              height: 200,
              fit: BoxFit.cover,
            )),
        Visibility(
            visible: widget.editing,
            child: MouseRegion(
                onEnter: (event) {
                  setState(() {
                    mouseOverImage = true;
                  });
                },
                onExit: (event) {
                  setState(() {
                    mouseOverImage = false;
                  });
                },
                child: GestureDetector(
                    onTap: () {
                      widget.browserForImage();
                    },
                    child: Container(
                        width: min(450, widget.width - 200),
                        height: 200,
                        child: const Center(
                            child: Text(
                          "Select an image",
                          style: TextStyle(
                              fontWeight: FontWeight.normal,
                              fontStyle: FontStyle.normal,
                              fontSize: 20,
                              color: Colors.white,
                              decoration: TextDecoration.none),
                        )),
                        decoration: BoxDecoration(
                            color: mouseOverImage
                                ? const Color.fromRGBO(120, 120, 120, 100)
                                : const Color.fromRGBO(100, 100, 100, 100),
                            border: Border.all(
                              color: Colors.grey,
                              width: 1,
                            ))))))
      ]);
    });
  }
}

class AudioPreview extends StatefulWidget {
  const AudioPreview({required this.path, Key? key}) : super(key: key);

  final String path;

  @override
  _AudioPreviewState createState() => _AudioPreviewState(path: path);
}

class _AudioPreviewState extends State<AudioPreview> {
  _AudioPreviewState({required this.path});

  final String path;
  bool editing = false;
  int _currIndex = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(5, 10, 5, 0),
        child: Container(
          width: min(200, constraints.maxWidth),
          height: 60,
          child: Stack(
            children: [
              /* Play Button */
              Positioned(
                child: IconButton(
                  icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      transitionBuilder: (child, anim) => RotationTransition(
                            turns: child.key == const ValueKey('icon1')
                                ? Tween<double>(begin: 0.75, end: 1.0)
                                    .animate(anim)
                                : Tween<double>(begin: 1.0, end: 0.75)
                                    .animate(anim),
                            child: FadeTransition(opacity: anim, child: child),
                          ),
                      child: _currIndex == 0
                          ? const Icon(Icons.play_arrow, key: ValueKey('icon1'))
                          : const Icon(
                              Icons.stop,
                              key: ValueKey('icon2'),
                            )),
                  onPressed: () {
                    setState(() {
                      _currIndex = _currIndex == 0 ? 1 : 0;
                    });
                  },
                  iconSize: 40,
                  color: Colors.white,
                  padding: const EdgeInsets.all(10),
                ),
              ),
              Positioned(
                  left: 60,
                  top: 0,
                  width: min(200, constraints.maxWidth),
                  height: 50,
                  child: CustomPaint(
                    painter: WaveformPreview(),
                  )),
            ],
          ),
          decoration: const BoxDecoration(
            color: Color.fromRGBO(40, 40, 40, 1.0),
          ),
        ),
      );
    });
  }
}

class AuthorView extends StatefulWidget {
  @override
  _AuthorViewState createState() => _AuthorViewState();
}

class _AuthorViewState extends State<AuthorView> {
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(10),
        child: Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(5)),
                color: Color.fromRGBO(50, 50, 50, 1.0)),
            child: Column(children: [
              Image.network(
                "https://akns-images.eonline.com/eol_images/Entire_Site/2015717/rs_1024x759-150817131955-1024-kermit-lipton.jpg",
                fit: BoxFit.cover,
              ),
              const SizedBox(height: 10),
              const Text("Kermit the Frog",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ))
            ])));
  }
}

class WaveformPreview extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    int width = size.width.toInt();
    int height = size.height.toInt();

    var rng = Random();

    int count = 50;
    double barWidth = width / count - 1;
    int barHeight = height * 4 ~/ 5;

    Paint paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 1;

    for (int i = 0; i < count; i++) {
      canvas.drawRect(
          Rect.fromLTWH(i * barWidth + i, height.toDouble(), barWidth,
              -rng.nextInt(barHeight).toDouble()),
          paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class TagView extends StatefulWidget {
  @override
  _TagViewState createState() => _TagViewState();
}

class _TagViewState extends State<TagView> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Padding(
          padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
          child: Column(children: [
            Container(
                width: min(300, constraints.maxWidth),
                height: 100,
                decoration: const BoxDecoration(
                    color: Color.fromRGBO(45, 45, 45, 1.0))),
            Container(
                height: 40,
                width: min(300, constraints.maxWidth),
                padding: const EdgeInsets.all(8),
                child: const Text("Tags",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    )),
                decoration:
                    const BoxDecoration(color: Color.fromRGBO(45, 45, 45, 1.0)))
          ]));
    });
  }
}

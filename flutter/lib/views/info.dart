import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'settings.dart';

import '../patch.dart';

/*class InterfaceInfo {
  InterfaceInfo({
    required this.directory,
    required this.name,
    required this.description,
    required this.patches,
  });

  final Directory directory;
  final ValueNotifier<String> name;
  final ValueNotifier<String> description;
  final ValueNotifier<List<PresetInfo>> patches;

  static Future<InterfaceInfo?> load(Directory directory) async {
    File file = File(directory.path + "/info.json");
    if (file.existsSync()) {
      var contents = file.readAsStringSync();
      var json = jsonDecode(contents);
      List<PresetInfo> patches = [];

      Directory patchesDirectory = Directory(directory.path + "/patches");
      await for (var item in patchesDirectory.list()) {
        var patchDirectory = Directory(item.path);
        var PresetInfo = await PresetInfo.load(patchDirectory);
        if (PresetInfo != null) {
          patches.add(PresetInfo);
        }
      }

      return InterfaceInfo(
        directory: directory,
        name: ValueNotifier(json["name"]),
        description: ValueNotifier(json["description"]),
        patches: ValueNotifier(patches),
      );
    }

    return null;
  }

  Future<bool> save() async {
    print("Saving interface info");
    if (!await directory.exists()) {
      await directory.create();
    }

    File file = File(directory.path + "/info.json");

    var map = {
      'name': name.value,
      'description': description.value,
    };

    var contents = jsonEncode(map);
    await file.writeAsString(contents);
    return true;
  }
}*/

class ProjectInfo {
  ProjectInfo({
    required this.directory,
    required this.name,
    required this.description,
    required this.image,
    required this.date,
    required this.tags,
  });

  final Directory directory;
  final ValueNotifier<String> name;
  final ValueNotifier<String> description;
  final ValueNotifier<File?> image;
  final ValueNotifier<DateTime> date;
  final List<String> tags;

  static ProjectInfo blank() {
    return ProjectInfo(
      directory: Directory(
        "/Users/chasekanipe/Github/assets/projects/NewProject",
      ),
      name: ValueNotifier("New Project"),
      description: ValueNotifier("Description for a new project"),
      image: ValueNotifier(null),
      date: ValueNotifier(DateTime.fromMillisecondsSinceEpoch(0)),
      tags: [],
    );
  }

  static Future<ProjectInfo?> load(String path) async {
    File file = File(path + "/project.json");

    if (await file.exists()) {
      String contents = await file.readAsString();
      Map<String, dynamic> json = jsonDecode(contents);
      return ProjectInfo.fromJson(path, json);
    }

    return null;
  }

  Future<bool> save() async {
    print("Saving project info");

    if (!await directory.exists()) {
      await directory.create();
    }

    File file = File(directory.path + "/project.json");

    await file.writeAsString(
      jsonEncode(
        toJson(),
      ),
    );

    return true;
  }

  /*Future<int> getPatchCount() async {
    Directory presetsDirectory = Directory(directory.path + "/patches");
    if (await presetsDirectory.exists()) {
      return presetsDirectory.list().length;
    }

    return 0;
  }

  Future<int> getInterfaceCount() async {
    Directory presetsDirectory = Directory(directory.path + "/interfaces");
    if (await presetsDirectory.exists()) {
      return presetsDirectory.list().length;
    }

    return 0;
  }

  Future<int> getSubPatchCount() async {
    Directory presetsDirectory = Directory(directory.path + "/interfaces");

    int count = 0;

    if (await presetsDirectory.exists()) {
      var presets = presetsDirectory.list();
      await for (var preset in presets) {
        var presetDirectory = Directory(preset.path);
        if (await presetDirectory.exists()) {
          var patchesDirectory = Directory(presetDirectory.path + "/patches");
          if (await patchesDirectory.exists()) {
            count += await patchesDirectory.list().length;
          }
        }
      }
    }

    return count;
  }*/

  static ProjectInfo fromJson(String path, Map<String, dynamic> json) {
    File? image;

    File file1 = File(path + "/background.jpg");
    if (file1.existsSync()) {
      image = file1;
    }

    File file2 = File(path + "/background.png");
    if (file2.existsSync()) {
      image = file2;
    }

    File file3 = File(path + "/background.jpeg");
    if (file3.existsSync()) {
      image = file3;
    }

    String? tags = json['tags'];

    DateTime date = DateTime.fromMillisecondsSinceEpoch(0);
    String? dateString = json['date'];
    if (dateString != null) {
      date = DateTime.parse(dateString);
    }

    return ProjectInfo(
      directory: Directory(path),
      name: ValueNotifier(json['name']),
      description: ValueNotifier(json['description']),
      image: ValueNotifier(image),
      date: ValueNotifier(date),
      tags: tags != null ? tags.split(",") : [],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name.value,
        'description': description.value,
        'date': date.value.toIso8601String(),
        'tags': tags.join(","),
      };
}

/*class InfoContentsWidget extends StatefulWidget {
  InfoContentsWidget(
    this.app, {
    required this.project,
    required this.onClose,
    Key? key,
  }) : super(key: key);

  App app;
  ProjectInfo project;
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
    print("THIS SAVE NOT IMPLEMENTED");
    /*var instruments = widget.app.projects.value;

    /* Save the instrument */
    for (int i = 0; i < instruments.length; i++) {
      if (instruments[i].path == widget.project.path) {
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
        if (widget.project.path == widget.app.loadedProject.value.path) {
          widget.app.loadedProject.value = instruments[i];
        }

        widget.project = instruments[i];

        /* Update info json */
        File file = File(instruments[i].path + "/info/info.json");
        String json = jsonEncode(instruments[i]);
        file.writeAsString(json);
      }
    }

    setState(() {
      if (editing) {
        /* Update local instrument metadata */
        widget.project.description = description;
        editing = false;
      } else {
        /* Start editing */
        // markdownEditor.controller.text = widget.instrument.description;
        // ^^^ Need this ???
        editing = true;
      }
    });*/
  }

  @override
  Widget build(BuildContext context) {
    /* Markdown Viewer */
    final markdownViewer = Padding(
      padding: const EdgeInsets.fromLTRB(15, 10, 0, 0),
      child: Text(
        widget.project.description,
        style: const TextStyle(
          fontWeight: FontWeight.w300,
          fontStyle: FontStyle.normal,
          fontSize: 14,
          color: Colors.white70,
          decoration: TextDecoration.none,
        ),
      ),
    );

    /* Markdown Editor */
    var markdownEditor = EditableText(
      controller: TextEditingController.fromValue(
        TextEditingValue(
          text: widget.project.description,
        ),
      ),
      focusNode: FocusNode(),
      cursorColor: Colors.grey,
      backgroundCursorColor: Colors.grey,
      maxLines: 20,
      style: const TextStyle(
        fontWeight: FontWeight.w300,
        fontStyle: FontStyle.normal,
        fontSize: 14,
        color: Colors.white,
        decoration: TextDecoration.none,
      ),
    );

    TextEditingController titleController = TextEditingController.fromValue(
      TextEditingValue(text: widget.project.name.value),
    );

    /* Title Editor */

    return LayoutBuilder(
      builder: (context, constraints) {
        double width = constraints.maxWidth;

        return Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              color: Color.fromRGBO(40, 40, 40, 1.0)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          InfoViewImage(
                            editing: editing,
                            path: widget.project.background,
                            onUpdate: () => setState(() {}),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: IconButton(
                              icon: const Icon(Icons.chevron_left),
                              iconSize: 24,
                              color: Colors.grey,
                              onPressed: () => widget.onClose(),
                            ),
                          ),
                        ],
                      ),
                      Container(height: 20),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              // widget.app.loadProject(widget.project);
                            },
                            child: const Text("Load"),
                          ),
                          TextButton(
                            onPressed: () {
                              print("Delete instrument");
                            },
                            child: const Text("Delete"),
                          ),
                        ],
                      )
                      /*Container(
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
                          ])),*/

                      /* Description Container */
                      /*Padding(
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
                                      color: Colors.grey, width: 1))))*/
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: min(max(width - 200, 0), 200),
                child: Column(
                  children: [
                    AuthorView(),
                    const AudioPreview(path: ""),
                    Expanded(child: TagView())
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}*/

class InfoViewTitle extends StatelessWidget {
  InfoViewTitle(
      {required this.editing, required this.name, required this.controller});

  bool editing;
  String name;
  TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 40,
      child: Stack(
        children: [
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
            ),
          ),
          Visibility(
            visible: editing,
            child: Container(
              padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
              height: 30,
              child: EditableText(
                  controller: TextEditingController(text: name),
                  onChanged: (s) {},
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
                border: Border.all(color: Colors.grey, width: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InfoViewImage extends StatefulWidget {
  InfoViewImage(
      {required this.editing, required this.path, required this.onUpdate});

  bool editing;
  String path;
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

    return File(
        "/Users/chasekanipe/Github/assets/images/backgrounds/background_01.png");
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.all(10),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(5)),
                child: Image.file(
                  widget.getBackgroundImage(),
                  width: constraints.maxWidth,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
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
                      height: 200,
                      child: const Center(
                        child: Text(
                          "Select an image",
                          style: TextStyle(
                            fontWeight: FontWeight.normal,
                            fontStyle: FontStyle.normal,
                            fontSize: 20,
                            color: Colors.white,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                      decoration: BoxDecoration(
                        color: mouseOverImage
                            ? const Color.fromRGBO(120, 120, 120, 100)
                            : const Color.fromRGBO(100, 100, 100, 100),
                        border: Border.all(
                          color: Colors.grey,
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class AudioPreview extends StatefulWidget {
  const AudioPreview({required this.path, Key? key}) : super(key: key);

  final String path;

  @override
  _AudioPreviewState createState() => _AudioPreviewState();
}

class _AudioPreviewState extends State<AudioPreview> {
  bool editing = false;
  int _currIndex = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.all(10),
          child: Container(
            width: min(200, constraints.maxWidth),
            height: 40,
            decoration: const BoxDecoration(
              color: Color.fromRGBO(50, 50, 50, 1.0),
              borderRadius: BorderRadius.all(Radius.circular(5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                /* Play Button */
                IconButton(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    transitionBuilder: (child, anim) => RotationTransition(
                      turns: child.key == const ValueKey('icon1')
                          ? Tween<double>(begin: 0.75, end: 1.0).animate(anim)
                          : Tween<double>(begin: 1.0, end: 0.75).animate(anim),
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: _currIndex == 0
                        ? const Icon(
                            Icons.play_arrow,
                            key: ValueKey('icon1'),
                          )
                        : const Icon(
                            Icons.stop,
                            key: ValueKey('icon2'),
                          ),
                  ),
                  onPressed: () {
                    setState(() {
                      _currIndex = _currIndex == 0 ? 1 : 0;
                    });
                  },
                  iconSize: 28,
                  color: Colors.white,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 7, 10, 5),
                    child: CustomPaint(
                      painter: WaveformPreview(),
                      child: Container(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
          color: Color.fromRGBO(50, 50, 50, 1.0),
        ),
        child: Column(
          children: [
            Image.network(
              "https://akns-images.eonline.com/eol_images/Entire_Site/2015717/rs_1024x759-150817131955-1024-kermit-lipton.jpg",
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 10),
            const Text(
              "Kermit the Frog",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WaveformPreview extends CustomPainter {
  static int count = 50;

  static List<double> generateBuffer() {
    List<double> buffer = [];
    var rng = Random();

    for (int i = 0; i < count; i++) {
      buffer.add(rng.nextDouble());
    }

    return buffer;
  }

  List<double> buffer = generateBuffer();

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 1;

    for (int i = 0; i < count; i++) {
      double height = buffer[i] * size.height;

      canvas.drawRect(
        Rect.fromLTWH(
          size.width / count * i,
          size.height - height,
          size.width / count,
          height,
        ),
        paint,
      );
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
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          color: Color.fromRGBO(50, 50, 50, 1.0),
          borderRadius: BorderRadius.all(Radius.circular(5)),
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Tag("Tag Example 1"),
                  Tag("Tag 2"),
                  Tag("Tag 3"),
                  Tag("Tag 4"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Tag extends StatelessWidget {
  Tag(this.name);

  String name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 5),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: const BoxDecoration(
          color: Color.fromRGBO(70, 70, 70, 1.0),
          borderRadius: BorderRadius.all(Radius.circular(5)),
        ),
        child: Text(
          name,
          style: const TextStyle(fontSize: 12, color: Colors.white),
        ),
      ),
    );
  }
}

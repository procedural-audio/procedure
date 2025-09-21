import 'package:flutter/material.dart';
import 'package:procedure/main.dart';

class MyTheme {
  static Color grey20 = const Color.fromRGBO(20, 20, 20, 1);
  static Color grey30 = const Color.fromRGBO(30, 30, 30, 1);
  static Color grey40 = const Color.fromRGBO(40, 40, 40, 1);
  static Color grey50 = const Color.fromRGBO(50, 50, 50, 1);
  static Color grey60 = const Color.fromRGBO(60, 60, 60, 1);
  static Color grey70 = const Color.fromRGBO(70, 70, 70, 1);

  /* New Heading */

  static const Color greyDarkest = Color.fromRGBO(20, 20, 20, 1);
  static const Color greyDark = Color.fromRGBO(30, 30, 30, 1);
  static const Color greyMid = Color.fromRGBO(40, 40, 40, 1);
  static const Color greyLight = Color.fromRGBO(60, 60, 60, 1);
  static const Color greyLighter = Color.fromRGBO(70, 70, 70, 1);

  static const Color textColorMid = Color.fromRGBO(160, 160, 160, 1);
  static const Color textColorLight = Color.fromRGBO(200, 200, 200, 1);

  static const TextStyle textStyleHeading = TextStyle(
      color: textColorLight, fontSize: 18, fontWeight: FontWeight.w300);

  static const TextStyle textStyleSubHeading = TextStyle(
      color: textColorLight, fontSize: 16, fontWeight: FontWeight.w300);

  static const TextStyle textStyleParagraph =
      TextStyle(color: textColorMid, fontSize: 14, fontWeight: FontWeight.w300);

  static Color audio = Colors.blue;
  static Color midi = Colors.green;
  static Color control = Colors.red;
  static Color data = Colors.purple;

  static const Color icon = textColorLight;
}

class Settings {
  bool showTopBar = false;
}

class SettingsView extends StatefulWidget {
  SettingsView(this.app, {super.key});

  App app;

  @override
  State<SettingsView> createState() => _SettingsView();
}

class _SettingsView extends State<SettingsView> {
  int type = 0;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(50),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 900),
          child: Container(
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
            child: Row(
              children: [
                Column(
                  children: [
                    const SizedBox(
                      child: Center(
                        child: Text("Settings",
                            style: TextStyle(
                                fontWeight: FontWeight.normal,
                                fontStyle: FontStyle.normal,
                                fontSize: 24,
                                color: Colors.white,
                                decoration: TextDecoration.none)),
                      ),
                      height: 60,
                      width: 400,
                    ),
                    Expanded(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 400,
                        ),
                        child: Container(
                          width: 400,
                          child: Column(
                            children: [
                              const Text(
                                "Toggle Theme Editor",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.color_lens),
                                iconSize: 30,
                                color: Colors.white,
                                onPressed: () {
                                  print("SHOULD TOGGLE THEME EDITOR HERE");
                                  /*widget.app.window.setState(() {
                                    widget.app.window.themeViewVisible = !widget.app.window.themeViewVisible;
                                  });*/
                                },
                              ),
                            ],
                          ),
                          decoration: BoxDecoration(
                            color: MyTheme.grey30,
                            //borderRadius: BorderRadius.circular(10.0)
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsCard extends StatelessWidget {
  const SettingsCard(
      {super.key,
      required this.icon,
      required this.text,
      required this.type,
      required this.index,
      required this.onTap});

  final int type;
  final int index;
  final void Function() onTap;
  final Text text;
  final Icon icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: MyTheme.grey20,
      child: ListTile(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
          leading: icon,
          title: text,
          minLeadingWidth: 26,
          textColor: type == index ? Colors.white : Colors.white30,
          iconColor: type == index ? Colors.white : Colors.white30,
          tileColor: type == index
              ? const Color.fromRGBO(255, 255, 255, 0.1)
              : MyTheme.grey20,
          onTap: onTap),
    );
  }
}

/*

Info View
 - Title
 - Description
 - Edit button, close button
 - Tags
 - Photo gallery
 - Video preview
 - Audio previews
*/

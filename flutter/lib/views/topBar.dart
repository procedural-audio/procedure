import 'dart:convert';
import 'dart:io';

import 'package:metasampler/instrument.dart';
import 'package:metasampler/views/presets.dart';

import '../host.dart';
import '../main.dart';
import 'package:flutter/material.dart';

import 'browser.dart';
import 'info.dart';
import 'variables.dart';

class TopBar extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _TopBar();
}

class _TopBar extends State<TopBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      color: const Color.fromRGBO(30, 30, 30, 1.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          TopBarButton(
            text: "",
            iconData: Icons.settings,
          ),
          TopBarButton(
            text: "Modules",
            iconData: Icons.piano,
          ),
          TopBarButton(
            text: "Settings",
            iconData: Icons.settings,
          ),
        ],
      ),
    );
  }
}

class TopBarButton extends StatefulWidget {
  TopBarButton({required this.text, required this.iconData});

  String text;
  IconData iconData;

  @override
  State<StatefulWidget> createState() => _TopBarButton();
}

class _TopBarButton extends State<TopBarButton> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
        // padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
        padding: EdgeInsets.zero,
        child: MouseRegion(
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
                child: Container(
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
              height: 40,
              decoration: BoxDecoration(
                color: hovering
                    ? const Color.fromRGBO(40, 40, 40, 1.0)
                    : const Color.fromRGBO(30, 30, 30, 1.0),
                // borderRadius: BorderRadius.all(Radius.circular(5))
              ),
              child: Row(
                children: [
                  Icon(
                    widget.iconData,
                    color: hovering
                        ? const Color.fromRGBO(200, 200, 200, 1.0)
                        : Colors.grey,
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.text,
                    style: TextStyle(
                        color: hovering
                            ? const Color.fromRGBO(200, 200, 200, 1.0)
                            : Colors.grey,
                        fontSize: 14,
                        fontWeight: FontWeight.w300),
                  )
                ],
              ),
            ))));
  }
}

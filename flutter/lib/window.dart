import 'package:flutter/material.dart';

class PopupWindow extends StatefulWidget {
  const PopupWindow({super.key});

  @override
  State<StatefulWidget> createState() => _PopupWidow();
}

class _PopupWidow extends State<PopupWindow> {
  double left = 50;
  double bottom = 50;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      bottom: bottom,
      child: Container(
        width: 800,
        height: 400,
        decoration: BoxDecoration(
          color: const Color.fromRGBO(20, 20, 20, 1.0),
          borderRadius: const BorderRadius.all(
            Radius.circular(5),
          ),
          border: Border.all(
            color: const Color.fromRGBO(40, 40, 40, 1.0),
          ),
        ),
        child: Column(
          children: [
            GestureDetector(
              onPanUpdate: (e) {
                setState(() {
                  left += e.delta.dx;
                  bottom -= e.delta.dy;
                });
              },
              child: Container(
                height: 20,
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(50, 50, 50, 1.0),
                  borderRadius: BorderRadius.all(Radius.circular(5)),
                ),
              ),
            ),
            Expanded(
              child: Container(),
            )
          ],
        ),
      ),
    );
  }
}

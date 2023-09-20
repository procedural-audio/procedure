
import 'package:flutter/material.dart';

class PopupWindow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 50, 
      bottom: 50,
      child: Container(
        width: 400,
        height: 300,
        decoration: BoxDecoration(
          color: const Color.fromRGBO(20, 20, 20, 1.0),
          borderRadius: const BorderRadius.all(
            Radius.circular(5),
          ),
          border: Border.all(
            color: const Color.fromRGBO(40, 40, 40, 1.0),
          ),
        ),
      ),
    );
  }
}

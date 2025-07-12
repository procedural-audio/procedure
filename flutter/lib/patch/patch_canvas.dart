import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../settings.dart';
import 'node.dart';
import 'connector.dart';

class PatchViewer extends StatelessWidget {
  final List<Node> nodes;
  final List<Connector> connectors;
  final NewConnector newConnector;
  final FocusNode focusNode;
  final VoidCallback? onTap;
  final void Function(PointerDownEvent) onPointerDown;
  final void Function(KeyEvent) onKeyEvent;
  
  const PatchViewer({
    Key? key,
    required this.nodes,
    required this.connectors,
    required this.newConnector,
    required this.focusNode,
    this.onTap,
    required this.onPointerDown,
    required this.onKeyEvent,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: onPointerDown,
      child: GestureDetector(
        onTap: onTap,
        child: KeyboardListener(
          focusNode: focusNode,
          autofocus: true,
          onKeyEvent: onKeyEvent,
          child: SizedBox(
            width: 10000,
            height: 10000,
            child: CustomPaint(
              painter: GridPainter(),
              child: Stack(
                children: <Widget>[newConnector] +
                    nodes +
                    connectors,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  GridPainter();

  @override
  void paint(Canvas canvas, ui.Size size) {
    final paint = Paint()
      ..color = const Color.fromRGBO(25, 25, 25, 1.0)
      ..strokeWidth = 1;

    for (double i = 0;
        i < size.width;
        i += GlobalSettings.gridSize.toDouble()) {
      var p1 = Offset(i, 0);
      var p2 = Offset(i, size.height);
      canvas.drawLine(p1, p2, paint);
    }

    for (double i = 0;
        i < size.height;
        i += GlobalSettings.gridSize.toDouble()) {
      var p1 = Offset(0, i);
      var p2 = Offset(size.width, i);
      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
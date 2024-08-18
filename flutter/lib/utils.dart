import 'package:flutter/material.dart';

Color colorFromString(String color) {
  return switch (color) {
    "red" => Colors.red,
    "green" => Colors.green,
    "blue" => Colors.blue,
    "yellow" => Colors.yellow,
    "purple" => Colors.purple,
    "orange" => Colors.orange,
    "pink" => Colors.pink,
    "cyan" => Colors.cyan,
    _ => Colors.grey,
  };
}

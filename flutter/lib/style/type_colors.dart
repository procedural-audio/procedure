import 'package:flutter/material.dart';
import '../settings/theme.dart';

/// Utility class to get colors for CMajor types
class TypeColorProvider {
  static CMajorTypeColors? _currentColors;
  
  /// Set the current color configuration
  static void setColors(CMajorTypeColors colors) {
    _currentColors = colors;
  }
  
  /// Get the current color configuration or default if not set
  static CMajorTypeColors get colors => _currentColors ?? CMajorTypeColors.defaultColors();
  
  /// Get color for a specific CMajor type string
  static Color getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'void':
        return colors.voidColor;
      case 'bool':
        return colors.boolColor;
      case 'int32':
        return colors.int32Color;
      case 'int64':
        return colors.int64Color;
      case 'float32':
        return colors.float32Color;
      case 'float64':
        return colors.float64Color;
      case 'string':
        return colors.stringColor;
      case 'array':
        return colors.arrayColor;
      case 'object':
        return colors.objectColor;
      default:
        // Return a default color for unknown types
        return colors.objectColor;
    }
  }
  
  /// Get color for primitive types
  static Color getPrimitiveColor(String primitive) {
    return getColorForType(primitive);
  }
  
  /// Get color for array types
  static Color getArrayColor() {
    return colors.arrayColor;
  }
  
  /// Get color for object types
  static Color getObjectColor() {
    return colors.objectColor;
  }
  
  /// Get color for string types
  static Color getStringColor() {
    return colors.stringColor;
  }
}
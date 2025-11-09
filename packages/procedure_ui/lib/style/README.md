# Theme System Usage

## Overview

The theme system provides color management for CMajor types in the node editor. This system allows users to configure colors for different data types (void, bool, int32, int64, float32, float64, string, array, object) and save/load these configurations.

## Components

### 1. CMajorTypeColors
A data class that holds colors for all CMajor types:
- `voidColor`: Color for void types
- `boolColor`: Color for boolean types  
- `int32Color`: Color for 32-bit integers
- `int64Color`: Color for 64-bit integers
- `float32Color`: Color for 32-bit floats
- `float64Color`: Color for 64-bit floats
- `stringColor`: Color for string types
- `arrayColor`: Color for array types
- `objectColor`: Color for object types

### 2. TypeColorProvider
A utility class that provides global access to the current color configuration:

```dart
// Set colors (usually done by the theme settings widget)
TypeColorProvider.setColors(myColors);

// Get a color for a specific type
Color color = TypeColorProvider.getColorForType('int32');

// Get colors for specific categories
Color arrayColor = TypeColorProvider.getArrayColor();
Color stringColor = TypeColorProvider.getStringColor();
```

### 3. ThemeSettingsWidget
The UI widget that allows users to:
- Configure colors for each CMajor type
- Save configurations to JSON files
- Load configurations from JSON files
- Reset to default colors

## Usage in Node System

When creating pins, connectors, or node widgets, use the TypeColorProvider to get appropriate colors:

```dart
// For a pin with type 'int32'
Container(
  decoration: BoxDecoration(
    color: TypeColorProvider.getColorForType('int32'),
    shape: BoxShape.circle,
  ),
  child: MyPinWidget(),
)

// For an array type
Container(
  decoration: BoxDecoration(
    color: TypeColorProvider.getArrayColor(),
    borderRadius: BorderRadius.circular(4),
  ),
  child: MyArrayWidget(),
)
```

## Configuration File Format

The theme configurations are saved as JSON files with the following structure:

```json
{
  "name": "Custom Theme Configuration",
  "version": "1.0",
  "created": "2025-07-11T01:55:43.000Z",
  "typeColors": {
    "voidColor": 4285098255,
    "boolColor": 4283215890,
    "int32Color": 4280391935,
    "int64Color": 4281756080,
    "float32Color": 4289003520,
    "float64Color": 4294928640,
    "stringColor": 4286755379,
    "arrayColor": 4285098255,
    "objectColor": 4284769916
  }
}
```

## Integration Points

The theme system integrates with:
1. **Settings Panel**: Users can configure colors through the theme settings widget
2. **Node Editor**: Pins, connectors, and widgets should use TypeColorProvider for colors
3. **Persistence**: Configurations can be saved/loaded as JSON files
4. **Default Colors**: Sensible defaults are provided for all types

## Default Color Scheme

- **void**: Gray (#757575)
- **bool**: Green (#4CAF50)
- **int32**: Blue (#2196F3)
- **int64**: Indigo (#3F51B5)
- **float32**: Orange (#FF9800)
- **float64**: Deep Orange (#FF5722)
- **string**: Purple (#9C27B0)
- **array**: Blue Grey (#607D8B)
- **object**: Brown (#795548)
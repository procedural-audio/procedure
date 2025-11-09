import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../style/colors.dart';
import '../style/text.dart';
import '../style/type_colors.dart';

class ThemeSettingsWidget extends StatefulWidget {
  const ThemeSettingsWidget({super.key});

  @override
  State<ThemeSettingsWidget> createState() => _ThemeSettingsWidgetState();
}

// CMajor type color configuration
class CMajorTypeColors {
  Color voidColor;
  Color boolColor;
  Color int32Color;
  Color int64Color;
  Color float32Color;
  Color float64Color;
  Color stringColor;
  Color arrayColor;
  Color objectColor;

  CMajorTypeColors({
    required this.voidColor,
    required this.boolColor,
    required this.int32Color,
    required this.int64Color,
    required this.float32Color,
    required this.float64Color,
    required this.stringColor,
    required this.arrayColor,
    required this.objectColor,
  });

  // Default colors for CMajor types
  static CMajorTypeColors defaultColors() {
    return CMajorTypeColors(
      voidColor: const Color(0xFF757575),        // Gray
      boolColor: const Color(0xFF4CAF50),        // Green
      int32Color: const Color(0xFF2196F3),       // Blue
      int64Color: const Color(0xFF3F51B5),       // Indigo
      float32Color: const Color(0xFFFF9800),     // Orange
      float64Color: const Color(0xFFFF5722),     // Deep Orange
      stringColor: const Color(0xFF9C27B0),      // Purple
      arrayColor: const Color(0xFF607D8B),       // Blue Grey
      objectColor: const Color(0xFF795548),      // Brown
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'voidColor': voidColor.value,
      'boolColor': boolColor.value,
      'int32Color': int32Color.value,
      'int64Color': int64Color.value,
      'float32Color': float32Color.value,
      'float64Color': float64Color.value,
      'stringColor': stringColor.value,
      'arrayColor': arrayColor.value,
      'objectColor': objectColor.value,
    };
  }

  // Create from JSON
  static CMajorTypeColors fromJson(Map<String, dynamic> json) {
    return CMajorTypeColors(
      voidColor: Color(json['voidColor'] ?? 0xFF757575),
      boolColor: Color(json['boolColor'] ?? 0xFF4CAF50),
      int32Color: Color(json['int32Color'] ?? 0xFF2196F3),
      int64Color: Color(json['int64Color'] ?? 0xFF3F51B5),
      float32Color: Color(json['float32Color'] ?? 0xFFFF9800),
      float64Color: Color(json['float64Color'] ?? 0xFFFF5722),
      stringColor: Color(json['stringColor'] ?? 0xFF9C27B0),
      arrayColor: Color(json['arrayColor'] ?? 0xFF607D8B),
      objectColor: Color(json['objectColor'] ?? 0xFF795548),
    );
  }
}

class _ThemeSettingsWidgetState extends State<ThemeSettingsWidget> {
  CMajorTypeColors typeColors = CMajorTypeColors.defaultColors();

  @override
  void initState() {
    super.initState();
    // Initialize the TypeColorProvider with default colors
    TypeColorProvider.setColors(typeColors);
  }

  void _updateTypeColors() {
    // Update the global TypeColorProvider whenever colors change
    TypeColorProvider.setColors(typeColors);
  }

  void _onColorChanged(void Function() colorUpdate) {
    setState(() {
      colorUpdate();
    });
    _updateTypeColors();
    _autoSaveConfiguration();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CMajor Type Colors',
                style: AppTextStyles.headingSmall,
              ),
              const SizedBox(height: 16),
              
              // Primitive Types
              _buildColorSection(
                'Primitive Types',
                [
                  _buildColorPicker('void', typeColors.voidColor, (color) {
                    _onColorChanged(() => typeColors.voidColor = color);
                  }),
                  _buildColorPicker('bool', typeColors.boolColor, (color) {
                    _onColorChanged(() => typeColors.boolColor = color);
                  }),
                  _buildColorPicker('int32', typeColors.int32Color, (color) {
                    _onColorChanged(() => typeColors.int32Color = color);
                  }),
                  _buildColorPicker('int64', typeColors.int64Color, (color) {
                    _onColorChanged(() => typeColors.int64Color = color);
                  }),
                  _buildColorPicker('float32', typeColors.float32Color, (color) {
                    _onColorChanged(() => typeColors.float32Color = color);
                  }),
                  _buildColorPicker('float64', typeColors.float64Color, (color) {
                    _onColorChanged(() => typeColors.float64Color = color);
                  }),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Complex Types
              _buildColorSection(
                'Complex Types',
                [
                  _buildColorPicker('string', typeColors.stringColor, (color) {
                    _onColorChanged(() => typeColors.stringColor = color);
                  }),
                  _buildColorPicker('array', typeColors.arrayColor, (color) {
                    _onColorChanged(() => typeColors.arrayColor = color);
                  }),
                  _buildColorPicker('object', typeColors.objectColor, (color) {
                    _onColorChanged(() => typeColors.objectColor = color);
                  }),
                ],
              ),
              
              const SizedBox(height: 30),
              
              // Configuration Actions
              Text(
                'Configuration Management',
                style: AppTextStyles.headingSmall,
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveConfiguration,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Save Configuration',
                        style: AppTextStyles.body.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _loadConfiguration,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Load Configuration',
                        style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _resetToDefaults,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Reset to Defaults',
                        style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 30),
              
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.backgroundBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildColorPicker(String label, Color color, Function(Color) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: AppColors.backgroundBorder,
                width: 1,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.body,
            ),
          ),
          GestureDetector(
            onTap: () => _showColorPicker(label, color, onChanged),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppColors.backgroundBorder,
                  width: 1,
                ),
              ),
              child: Text(
                'Change',
                style: AppTextStyles.body.copyWith(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showColorPicker(String label, Color currentColor, Function(Color) onChanged) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            'Select Color for $label',
            style: AppTextStyles.headingSmall,
          ),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: currentColor,
              onColorChanged: onChanged,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: Text(
                'OK',
                style: AppTextStyles.body.copyWith(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // Save configuration to JSON file
  Future<void> _saveConfiguration() async {
    try {
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Theme Configuration',
        fileName: 'theme_config.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      
      if (outputFile != null) {
        final config = {
          'name': 'Custom Theme Configuration',
          'version': '1.0',
          'created': DateTime.now().toIso8601String(),
          'typeColors': typeColors.toJson(),
        };
        
        final file = File(outputFile);
        await file.writeAsString(jsonEncode(config));
        
        _showSuccess('Theme configuration saved successfully');
      }
    } catch (e) {
      _showError('Error saving configuration: $e');
    }
  }

  // Load configuration from JSON file
  Future<void> _loadConfiguration() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Load Theme Configuration',
      );
      
      if (result != null) {
        final file = File(result.files.single.path!);
        final contents = await file.readAsString();
        final config = jsonDecode(contents) as Map<String, dynamic>;
        
        if (config.containsKey('typeColors')) {
          setState(() {
            typeColors = CMajorTypeColors.fromJson(config['typeColors']);
          });
          _updateTypeColors();
          _autoSaveConfiguration();
          _showSuccess('Theme configuration loaded successfully');
        } else {
          _showError('Invalid configuration file format');
        }
      }
    } catch (e) {
      _showError('Error loading configuration: $e');
    }
  }

  // Reset to default colors
  void _resetToDefaults() {
    setState(() {
      typeColors = CMajorTypeColors.defaultColors();
    });
    _updateTypeColors();
    _autoSaveConfiguration();
    _showSuccess('Theme reset to defaults');
  }

  Future<void> _autoSaveConfiguration() async {
    try {
      // TODO: Implement backend integration to save theme colors
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate save
      
      // Optional: Show brief success indicator (comment out to reduce noise)
      // _showSuccess('Theme configuration saved');
    } catch (e) {
      _showError('Error saving theme configuration: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

}

// Simple color picker widget (you might want to use a proper color picker package)
class ColorPicker extends StatefulWidget {
  final Color pickerColor;
  final Function(Color) onColorChanged;
  final double pickerAreaHeightPercent;

  const ColorPicker({
    super.key,
    required this.pickerColor,
    required this.onColorChanged,
    this.pickerAreaHeightPercent = 0.8,
  });

  @override
  State<ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  late Color currentColor;

  @override
  void initState() {
    super.initState();
    currentColor = widget.pickerColor;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.backgroundBorder),
          ),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: _predefinedColors.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    currentColor = _predefinedColors[index];
                  });
                  widget.onColorChanged(currentColor);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: _predefinedColors[index],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: currentColor == _predefinedColors[index] 
                          ? Colors.white 
                          : AppColors.backgroundBorder,
                      width: currentColor == _predefinedColors[index] ? 2 : 1,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  static const List<Color> _predefinedColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
    Colors.black,
    Colors.white,
    Color(0xFF4CAF50),
    Color(0xFF2196F3),
    Color(0xFFFF9800),
    Color(0xFF9C27B0),
    Color(0xFFF44336),
    Color(0xFFE91E63),
    Color(0xFF607D8B),
    Color(0xFF795548),
    Color(0xFF2E7D32),
    Color(0xFF1565C0),
    Color(0xFFE65100),
    Color(0xFF6A1B9A),
  ];
}

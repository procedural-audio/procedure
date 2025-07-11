import 'package:flutter/material.dart';
import '../style/colors.dart';
import '../style/text.dart';
import '../style/buttons.dart';

class ThemeSettingsWidget extends StatefulWidget {
  const ThemeSettingsWidget({super.key});

  @override
  State<ThemeSettingsWidget> createState() => _ThemeSettingsWidgetState();
}

class _ThemeSettingsWidgetState extends State<ThemeSettingsWidget> {
  // Pin type colors
  Color audioInputColor = const Color(0xFF4CAF50);
  Color audioOutputColor = const Color(0xFF2196F3);
  Color midiInputColor = const Color(0xFFFF9800);
  Color midiOutputColor = const Color(0xFF9C27B0);
  Color controlInputColor = const Color(0xFFF44336);
  Color controlOutputColor = const Color(0xFFE91E63);
  Color dataInputColor = const Color(0xFF607D8B);
  Color dataOutputColor = const Color(0xFF795548);

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
                'Pin Type Colors',
                style: AppTextStyles.headingSmall,
              ),
              const SizedBox(height: 16),
              
              // Audio Pins
              _buildColorSection(
                'Audio Pins',
                [
                  _buildColorPicker('Audio Input', audioInputColor, (color) {
                    setState(() {
                      audioInputColor = color;
                    });
                    _autoSaveConfiguration();
                  }),
                  _buildColorPicker('Audio Output', audioOutputColor, (color) {
                    setState(() {
                      audioOutputColor = color;
                    });
                    _autoSaveConfiguration();
                  }),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // MIDI Pins
              _buildColorSection(
                'MIDI Pins',
                [
                  _buildColorPicker('MIDI Input', midiInputColor, (color) {
                    setState(() {
                      midiInputColor = color;
                    });
                    _autoSaveConfiguration();
                  }),
                  _buildColorPicker('MIDI Output', midiOutputColor, (color) {
                    setState(() {
                      midiOutputColor = color;
                    });
                    _autoSaveConfiguration();
                  }),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Control Pins
              _buildColorSection(
                'Control Pins',
                [
                  _buildColorPicker('Control Input', controlInputColor, (color) {
                    setState(() {
                      controlInputColor = color;
                    });
                    _autoSaveConfiguration();
                  }),
                  _buildColorPicker('Control Output', controlOutputColor, (color) {
                    setState(() {
                      controlOutputColor = color;
                    });
                    _autoSaveConfiguration();
                  }),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Data Pins
              _buildColorSection(
                'Data Pins',
                [
                  _buildColorPicker('Data Input', dataInputColor, (color) {
                    setState(() {
                      dataInputColor = color;
                    });
                    _autoSaveConfiguration();
                  }),
                  _buildColorPicker('Data Output', dataOutputColor, (color) {
                    setState(() {
                      dataOutputColor = color;
                    });
                    _autoSaveConfiguration();
                  }),
                ],
              ),
              
              const SizedBox(height: 30),
              
              // Theme Presets
              Text(
                'Theme Presets',
                style: AppTextStyles.headingSmall,
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _applyDefaultTheme,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Default',
                        style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _applyDarkTheme,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Dark',
                        style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _applyHighContrastTheme,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'High Contrast',
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

  void _applyDefaultTheme() {
    setState(() {
      audioInputColor = const Color(0xFF4CAF50);
      audioOutputColor = const Color(0xFF2196F3);
      midiInputColor = const Color(0xFFFF9800);
      midiOutputColor = const Color(0xFF9C27B0);
      controlInputColor = const Color(0xFFF44336);
      controlOutputColor = const Color(0xFFE91E63);
      dataInputColor = const Color(0xFF607D8B);
      dataOutputColor = const Color(0xFF795548);
    });
    _autoSaveConfiguration();
  }

  void _applyDarkTheme() {
    setState(() {
      audioInputColor = const Color(0xFF2E7D32);
      audioOutputColor = const Color(0xFF1565C0);
      midiInputColor = const Color(0xFFE65100);
      midiOutputColor = const Color(0xFF6A1B9A);
      controlInputColor = const Color(0xFFC62828);
      controlOutputColor = const Color(0xFFAD1457);
      dataInputColor = const Color(0xFF37474F);
      dataOutputColor = const Color(0xFF4E342E);
    });
    _autoSaveConfiguration();
  }

  void _applyHighContrastTheme() {
    setState(() {
      audioInputColor = const Color(0xFF00FF00);
      audioOutputColor = const Color(0xFF0080FF);
      midiInputColor = const Color(0xFFFF8000);
      midiOutputColor = const Color(0xFF8000FF);
      controlInputColor = const Color(0xFFFF0000);
      controlOutputColor = const Color(0xFFFF0080);
      dataInputColor = const Color(0xFF808080);
      dataOutputColor = const Color(0xFF804000);
    });
    _autoSaveConfiguration();
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

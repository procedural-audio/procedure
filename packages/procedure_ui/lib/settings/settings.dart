import 'package:flutter/material.dart';
import 'package:procedure_bindings/bindings/api/io.dart';
import '../style/colors.dart';
import '../style/text.dart';
import 'audio.dart';
import 'midi.dart';
import 'theme.dart';
import 'debug.dart';
import 'directories.dart';

class SettingsWidget extends StatefulWidget {
  const SettingsWidget({
    super.key,
    this.audioManager,
  });

  final AudioManager? audioManager;

  @override
  State<SettingsWidget> createState() => _SettingsWidgetState();
}

class _SettingsWidgetState extends State<SettingsWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Audio Settings
            _buildSettingsSection(
              'Audio Configuration',
              Icons.audiotrack,
              AudioSettingsWidget(audioManager: widget.audioManager),
            ),
            
            // MIDI Settings
            _buildSettingsSection(
              'MIDI Configuration',
              Icons.music_note,
              MidiSettingsWidget(audioManager: widget.audioManager),
            ),
            
            // Theme Settings
            _buildSettingsSection(
              'Theme Configuration',
              Icons.palette,
              const ThemeSettingsWidget(),
            ),
            
            // Debug Settings
            _buildSettingsSection(
              'Debug Configuration',
              Icons.bug_report,
              const DebugSettingsWidget(),
            ),
            
            // Directory Settings
            _buildSettingsSection(
              'Directory Configuration',
              Icons.folder,
              const DirectoriesSettingsWidget(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(String title, IconData icon, Widget content) {
    return Container(
      margin: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.backgroundBorder,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: AppColors.textPrimary,
                  size: AppTextStyles.headingMedium.fontSize,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: AppTextStyles.headingMedium,
                ),
              ],
            ),
          ),
          
          // Section Content
          content,
        ],
      ),
    );
  }
}

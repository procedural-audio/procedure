import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../style/colors.dart';
import '../style/text.dart';
import '../settings.dart';

class DirectoriesSettingsWidget extends StatefulWidget {
  const DirectoriesSettingsWidget({super.key});

  @override
  State<DirectoriesSettingsWidget> createState() => _DirectoriesSettingsWidgetState();
}

class _DirectoriesSettingsWidgetState extends State<DirectoriesSettingsWidget> {
  String? projectsDirectory;
  String? pluginsDirectory;
  String? samplesDirectory;
  
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDirectorySettings();
  }

  Future<void> _loadDirectorySettings() async {
    try {
      final directories = await SettingsService.getAllDirectories();
      
      setState(() {
        projectsDirectory = directories['projects'];
        pluginsDirectory = directories['plugins'];
        samplesDirectory = directories['samples'];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showError('Error loading directory settings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Projects Directory
                _buildDirectorySection(
                  'Projects Directory',
                  'Location where your projects are stored',
                  projectsDirectory ?? '',
                  (path) async {
                    setState(() {
                      projectsDirectory = path;
                    });
                    await SettingsService.setProjectsDirectory(path);
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Plugins Directory
                _buildDirectorySection(
                  'Plugins Directory',
                  'Location where plugins are installed',
                  pluginsDirectory ?? '',
                  (path) async {
                    setState(() {
                      pluginsDirectory = path;
                    });
                    await SettingsService.setPluginsDirectory(path);
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Samples Directory
                _buildDirectorySection(
                  'Samples Directory',
                  'Location where sample files are stored',
                  samplesDirectory ?? '',
                  (path) async {
                    setState(() {
                      samplesDirectory = path;
                    });
                    await SettingsService.setSamplesDirectory(path);
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Reset All Settings
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _resetAllSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Reset All Settings to Default',
                      style: AppTextStyles.body.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDirectorySection(String title, String description, String path, Function(String) onChanged) {
    return _buildSection(
      title,
      [
        Text(
          description,
          style: AppTextStyles.body.copyWith(
            color: AppColors.textMuted,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.backgroundBorder,
                    width: 1,
                  ),
                ),
                child: Text(
                  path.isEmpty ? 'No directory selected' : path,
                  style: AppTextStyles.body.copyWith(
                    color: path.isEmpty ? AppColors.textMuted : AppColors.textPrimary,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _pickDirectory(title, onChanged),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surface,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(
                'Browse',
                style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              _getDirectoryStatusIcon(path),
              size: 16,
              color: _getDirectoryStatusColor(path),
            ),
            const SizedBox(width: 8),
            Text(
              _getDirectoryStatusText(path),
              style: AppTextStyles.body.copyWith(
                fontSize: 12,
                color: _getDirectoryStatusColor(path),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
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

  Future<void> _pickDirectory(String title, Function(String) onChanged) async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select $title',
      );
      
      if (selectedDirectory != null) {
        await onChanged(selectedDirectory);
      }
    } catch (e) {
      _showError('Error selecting directory: $e');
    }
  }

  Future<void> _resetAllSettings() async {
    // Show confirmation dialog
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            'Reset All Settings',
            style: AppTextStyles.headingSmall,
          ),
          content: Text(
            'This will reset all application settings to their default values. This action cannot be undone.',
            style: AppTextStyles.body,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text(
                'Reset All Settings',
                style: AppTextStyles.body.copyWith(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
    
    if (confirmed == true) {
      try {
        // Clear all directories
        await SettingsService.clearDirectories();
        
        // TODO: Reset other settings (audio, MIDI, theme, debug)
        // This would require adding reset methods to SettingsService
        
        // Reload the directory settings
        await _loadDirectorySettings();
        
        _showSuccess('All settings have been reset to default');
      } catch (e) {
        _showError('Error resetting settings: $e');
      }
    }
  }

  IconData _getDirectoryStatusIcon(String path) {
    if (path.isEmpty) {
      return Icons.help_outline;
    }
    
    print("Checking directory status synchronously");
    final directory = Directory(path);
    if (directory.existsSync()) {
      return Icons.folder;
    } else {
      return Icons.folder_off;
    }
  }

  Color _getDirectoryStatusColor(String path) {
    if (path.isEmpty) {
      return AppColors.textMuted;
    }
    
    final directory = Directory(path);
    if (directory.existsSync()) {
      return Colors.green;
    } else {
      return Colors.orange;
    }
  }

  String _getDirectoryStatusText(String path) {
    if (path.isEmpty) {
      return 'No directory selected';
    }
    
    final directory = Directory(path);
    if (directory.existsSync()) {
      return 'Directory exists';
    } else {
      return 'Directory does not exist';
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

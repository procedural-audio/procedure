import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../style/colors.dart';
import '../style/text.dart';
import '../style/buttons.dart';

class DirectoriesSettingsWidget extends StatefulWidget {
  const DirectoriesSettingsWidget({super.key});

  @override
  State<DirectoriesSettingsWidget> createState() => _DirectoriesSettingsWidgetState();
}

class _DirectoriesSettingsWidgetState extends State<DirectoriesSettingsWidget> {
  String projectsDirectory = '';
  String pluginsDirectory = '';
  String samplesDirectory = '';
  
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDirectorySettings();
  }

  Future<void> _loadDirectorySettings() async {
    // TODO: Implement backend integration to load directory settings
    await Future.delayed(const Duration(milliseconds: 300));
    
    setState(() {
      // Mock settings for now
      projectsDirectory = '/Users/chase/Music/Procedural Audio/Projects';
      pluginsDirectory = '/Users/chase/Music/Procedural Audio/Plugins';
      samplesDirectory = '/Users/chase/Music/Procedural Audio/Samples';
      isLoading = false;
    });
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
                  projectsDirectory,
                  (path) {
                    setState(() {
                      projectsDirectory = path;
                    });
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Plugins Directory
                _buildDirectorySection(
                  'Plugins Directory',
                  'Location where plugins are installed',
                  pluginsDirectory,
                  (path) {
                    setState(() {
                      pluginsDirectory = path;
                    });
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Samples Directory
                _buildDirectorySection(
                  'Samples Directory',
                  'Location where sample files are stored',
                  samplesDirectory,
                  (path) {
                    setState(() {
                      samplesDirectory = path;
                    });
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Directory Actions
                _buildSection(
                  'Directory Actions',
                  [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _createDirectories,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              'Create Directories',
                              style: AppTextStyles.body.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
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
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 30),
                
                // Save Configuration Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveConfiguration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Save Configuration',
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
        onChanged(selectedDirectory);
      }
    } catch (e) {
      _showError('Error selecting directory: $e');
    }
  }

  Future<void> _createDirectories() async {
    try {
      final directories = [
        projectsDirectory,
        pluginsDirectory,
        samplesDirectory,
      ];
      
      for (final dir in directories) {
        if (dir.isNotEmpty) {
          final directory = Directory(dir);
          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }
        }
      }
      
      _showSuccess('All directories created successfully');
    } catch (e) {
      _showError('Error creating directories: $e');
    }
  }

  Future<void> _resetToDefaults() async {
    try {
      setState(() {
        projectsDirectory = '/Users/chase/Music/Procedural Audio/Projects';
        pluginsDirectory = '/Users/chase/Music/Procedural Audio/Plugins';
        samplesDirectory = '/Users/chase/Music/Procedural Audio/Samples';
      });
      
      _showSuccess('Directories reset to defaults');
    } catch (e) {
      _showError('Error resetting directories: $e');
    }
  }

  Future<void> _saveConfiguration() async {
    try {
      // TODO: Implement backend integration to save directory settings
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate save
      
      _showSuccess('Directory configuration saved successfully');
    } catch (e) {
      _showError('Error saving directory configuration: $e');
    }
  }

  IconData _getDirectoryStatusIcon(String path) {
    if (path.isEmpty) {
      return Icons.help_outline;
    }
    
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

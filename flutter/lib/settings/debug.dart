import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../style/colors.dart';
import '../style/text.dart';
import '../style/buttons.dart';
import '../style/dropdown.dart';

class DebugSettingsWidget extends StatefulWidget {
  const DebugSettingsWidget({super.key});

  @override
  State<DebugSettingsWidget> createState() => _DebugSettingsWidgetState();
}

class _DebugSettingsWidgetState extends State<DebugSettingsWidget> {
  bool enableDebugLogging = false;
  bool enableVerboseLogging = false;
  bool enablePerformanceLogging = false;
  bool enableErrorLogging = true;
  
  String logLevel = 'Info';
  String logFilePath = '';
  
  final List<String> logLevels = ['Debug', 'Info', 'Warning', 'Error'];
  final List<String> logEntries = [];

  @override
  void initState() {
    super.initState();
    _loadDebugSettings();
    _generateMockLogEntries();
  }

  Future<void> _loadDebugSettings() async {
    // TODO: Implement backend integration to load debug settings
    await Future.delayed(const Duration(milliseconds: 300));
    
    setState(() {
      // Mock settings for now
      enableDebugLogging = false;
      enableVerboseLogging = false;
      enablePerformanceLogging = false;
      enableErrorLogging = true;
      logLevel = 'Info';
      logFilePath = '/tmp/metasampler.log';
    });
  }

  void _generateMockLogEntries() {
    // Generate some mock log entries for demonstration
    final now = DateTime.now();
    logEntries.addAll([
      '${now.subtract(const Duration(minutes: 5))} [INFO] Application started',
      '${now.subtract(const Duration(minutes: 4))} [INFO] Audio system initialized',
      '${now.subtract(const Duration(minutes: 3))} [DEBUG] Loading project configuration',
      '${now.subtract(const Duration(minutes: 2))} [WARNING] MIDI device not found',
      '${now.subtract(const Duration(minutes: 1))} [ERROR] Failed to load plugin: invalid_format',
      '${now} [INFO] Settings panel opened',
    ]);
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
              // Debug Logging Toggle
              _buildSection(
                'Debug Logging',
                [
                  _buildSwitch(
                    'Enable Debug Logging',
                    enableDebugLogging,
                    (value) {
                      setState(() {
                        enableDebugLogging = value;
                      });
                      _autoSaveConfiguration();
                    },
                  ),
                  _buildSwitch(
                    'Enable Verbose Logging',
                    enableVerboseLogging,
                    (value) {
                      setState(() {
                        enableVerboseLogging = value;
                      });
                      _autoSaveConfiguration();
                    },
                  ),
                  _buildSwitch(
                    'Enable Performance Logging',
                    enablePerformanceLogging,
                    (value) {
                      setState(() {
                        enablePerformanceLogging = value;
                      });
                      _autoSaveConfiguration();
                    },
                  ),
                  _buildSwitch(
                    'Enable Error Logging',
                    enableErrorLogging,
                    (value) {
                      setState(() {
                        enableErrorLogging = value;
                      });
                      _autoSaveConfiguration();
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Log Level Selection
              _buildSection(
                'Log Level',
                [
                  AppDropdownWithLabel<String>(
                    label: 'Minimum Log Level',
                    value: logLevel,
                    items: logLevels,
                    onChanged: (value) {
                      setState(() {
                        logLevel = value ?? 'Info';
                      });
                      _autoSaveConfiguration();
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Log File Configuration
              _buildSection(
                'Log File',
                [
                  _buildFilePicker(
                    'Log File Path',
                    logFilePath,
                    (path) {
                      setState(() {
                        logFilePath = path;
                      });
                      _autoSaveConfiguration();
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Log Actions
              _buildSection(
                'Log Actions',
                [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _exportLogs,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            'Export Logs',
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
                          onPressed: _clearLogs,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.surface,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            'Clear Logs',
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
              
              const SizedBox(height: 24),
              
              // Recent Log Entries
              _buildSection(
                'Recent Log Entries',
                [
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.backgroundBorder,
                        width: 1,
                      ),
                    ),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: logEntries.length,
                      itemBuilder: (context, index) {
                        final entry = logEntries[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            entry,
                            style: AppTextStyles.body.copyWith(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: _getLogLevelColor(entry),
                            ),
                          ),
                        );
                      },
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

  Widget _buildSwitch(String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.body,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePicker(String label, String value, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.body,
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
                  value.isEmpty ? 'No file selected' : value,
                  style: AppTextStyles.body.copyWith(
                    color: value.isEmpty ? AppColors.textMuted : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _pickLogFile(onChanged),
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
      ],
    );
  }

  Future<void> _pickLogFile(Function(String) onChanged) async {
    try {
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Select Log File Location',
        fileName: 'metasampler.log',
        allowedExtensions: ['log', 'txt'],
      );
      
      if (outputFile != null) {
        onChanged(outputFile);
      }
    } catch (e) {
      _showError('Error selecting log file: $e');
    }
  }

  Future<void> _exportLogs() async {
    try {
      if (logFilePath.isEmpty) {
        _showError('Please select a log file path first');
        return;
      }
      
      // TODO: Implement actual log export
      await Future.delayed(const Duration(milliseconds: 1000)); // Simulate export
      
      // Success - logs exported
    } catch (e) {
      _showError('Error exporting logs: $e');
    }
  }

  Future<void> _clearLogs() async {
    try {
      // TODO: Implement actual log clearing
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate clear
      
      setState(() {
        logEntries.clear();
      });
      
      // Success - logs cleared
    } catch (e) {
      _showError('Error clearing logs: $e');
    }
  }

  Future<void> _autoSaveConfiguration() async {
    try {
      // TODO: Implement backend integration to save debug settings
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate save
      
      // Optional: Show brief success indicator (comment out to reduce noise)
      // _showSuccess('Debug configuration saved');
    } catch (e) {
      _showError('Error saving debug configuration: $e');
    }
  }

  Color _getLogLevelColor(String logEntry) {
    if (logEntry.contains('[ERROR]')) {
      return Colors.red;
    } else if (logEntry.contains('[WARNING]')) {
      return Colors.orange;
    } else if (logEntry.contains('[DEBUG]')) {
      return Colors.blue;
    } else {
      return AppColors.textPrimary;
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

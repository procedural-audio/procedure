import 'package:flutter/material.dart';
import '../style/colors.dart';
import '../style/text.dart';
import '../style/buttons.dart';
import '../style/dropdown.dart';

class MidiSettingsWidget extends StatefulWidget {
  const MidiSettingsWidget({super.key});

  @override
  State<MidiSettingsWidget> createState() => _MidiSettingsWidgetState();
}

class _MidiSettingsWidgetState extends State<MidiSettingsWidget> {
  List<String> availableInputDevices = [];
  List<String> availableOutputDevices = [];
  
  String? selectedInputDevice;
  String? selectedOutputDevice;
  
  bool isLoading = true;
  bool enableMidi = false;

  @override
  void initState() {
    super.initState();
    loadMidiConfig();
  }

  Future<void> loadMidiConfig() async {
    // TODO: Implement backend integration
    // For now, just simulate loading
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      // Mock data for now
      availableInputDevices = [
        'MIDI Keyboard',
        'USB MIDI Interface',
        'Virtual MIDI Port',
      ];
      availableOutputDevices = [
        'MIDI Out Port 1',
        'USB MIDI Interface',
        'Virtual MIDI Port',
      ];
      selectedInputDevice = availableInputDevices.isNotEmpty ? availableInputDevices.first : null;
      selectedOutputDevice = availableOutputDevices.isNotEmpty ? availableOutputDevices.first : null;
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
                // Enable MIDI Toggle
                Row(
                  children: [
                    Switch(
                      value: enableMidi,
                      onChanged: (value) {
                        setState(() {
                          enableMidi = value;
                        });
                      },
                      activeColor: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Enable MIDI',
                      style: AppTextStyles.headingSmall,
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                if (enableMidi) ...[
                  // Input Device Selection
                  AppDropdownWithLabel<String>(
                    label: 'MIDI Input Device:',
                    value: selectedInputDevice,
                    items: availableInputDevices,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedInputDevice = newValue;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Output Device Selection
                  AppDropdownWithLabel<String>(
                    label: 'MIDI Output Device:',
                    value: selectedOutputDevice,
                    items: availableOutputDevices,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedOutputDevice = newValue;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // MIDI Settings
                  Text(
                    'MIDI Settings',
                    style: AppTextStyles.headingSmall,
                  ),
                  const SizedBox(height: 8),
                  
                  _buildCheckbox(
                    'Enable MIDI Clock',
                    true,
                    (value) {
                      // TODO: Handle MIDI clock setting
                    },
                  ),
                  
                  _buildCheckbox(
                    'Enable MIDI Transport',
                    false,
                    (value) {
                      // TODO: Handle MIDI transport setting
                    },
                  ),
                  
                  _buildCheckbox(
                    'Enable MIDI Program Change',
                    true,
                    (value) {
                      // TODO: Handle MIDI program change setting
                    },
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
                ] else ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.backgroundBorder,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'MIDI is currently disabled. Enable MIDI to configure input and output devices.',
                      style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCheckbox(String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: (newValue) => onChanged(newValue ?? false),
            activeColor: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.body,
          ),
        ],
      ),
    );
  }

  Future<void> _saveConfiguration() async {
    if (!enableMidi) {
      _showSuccess('MIDI disabled');
      return;
    }
    
    if (selectedInputDevice == null) {
      _showError('Please select a MIDI input device');
      return;
    }
    
    if (selectedOutputDevice == null) {
      _showError('Please select a MIDI output device');
      return;
    }
    
    try {
      // TODO: Implement backend integration
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate save
      
      _showSuccess('MIDI configuration saved successfully');
    } catch (e) {
      _showError('Error saving MIDI configuration: $e');
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

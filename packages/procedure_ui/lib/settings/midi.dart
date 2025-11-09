import 'package:flutter/material.dart';
import 'package:procedure_bindings/bindings/api/io.dart';
import '../style/colors.dart';
import '../style/text.dart';
import '../style/dropdown.dart';

class MidiSettingsWidget extends StatefulWidget {
  const MidiSettingsWidget({super.key, this.audioManager});

  final AudioManager? audioManager;

  @override
  State<MidiSettingsWidget> createState() => _MidiSettingsWidgetState();
}

class _MidiSettingsWidgetState extends State<MidiSettingsWidget> {
  List<String> availableInputDevices = [];
  List<String> availableOutputDevices = [];
  
  String? selectedInputDevice;
  String? selectedOutputDevice;
  
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadMidiConfig();
  }

  Future<void> loadMidiConfig() async {
    try {
      if (widget.audioManager == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }
      
      // Get current MIDI configuration
      final currentConfig = await widget.audioManager!.getMidiSetup();
      
      // Get available devices
      final inputDevices = await widget.audioManager!.getMidiInputDevices();
      final outputDevices = await widget.audioManager!.getMidiOutputDevices();
      
      setState(() {
        // Add "None" option if no devices are available or as a default option
        availableInputDevices = inputDevices.isEmpty ? ['None'] : ['None', ...inputDevices];
        availableOutputDevices = outputDevices.isEmpty ? ['None'] : ['None', ...outputDevices];
        
        selectedInputDevice = currentConfig.inputDevice.isNotEmpty ? currentConfig.inputDevice : 'None';
        selectedOutputDevice = currentConfig.outputDevice.isNotEmpty ? currentConfig.outputDevice : 'None';
        isLoading = false;
      });
    } catch (e) {
      print('Error loading MIDI config: $e');
      setState(() {
        isLoading = false;
      });
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
          else if (widget.audioManager == null)
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.warning,
                    size: 48,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Audio System Unavailable',
                    style: AppTextStyles.headingSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The audio system is not currently initialized. MIDI settings will be available once the audio system is running.',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Input Device Selection
                AppDropdownWithLabel<String>(
                  label: 'MIDI Input Device:',
                  value: selectedInputDevice,
                  items: availableInputDevices,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedInputDevice = newValue;
                    });
                    _autoSaveConfiguration();
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
                    _autoSaveConfiguration();
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }


  Future<void> _autoSaveConfiguration() async {
    try {
      if (widget.audioManager == null) {
        return;
      }
      
      // Create configuration object
      final config = FlutterMidiConfiguration(
        inputDevice: selectedInputDevice == 'None' ? '' : (selectedInputDevice ?? ''),
        outputDevice: selectedOutputDevice == 'None' ? '' : (selectedOutputDevice ?? ''),
        enabled: true, // MIDI is always enabled when devices are configured
        clockEnabled: false, // Not configurable in UI
        transportEnabled: false, // Not configurable in UI
        programChangeEnabled: false, // Not configurable in UI
      );
      
      // Set the configuration
      await widget.audioManager!.setMidiSetup(config: config);
      
      // Optional: Show brief success indicator (comment out to reduce noise)
      // _showSuccess('MIDI configuration saved');
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

}

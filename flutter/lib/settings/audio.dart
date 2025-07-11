import 'package:flutter/material.dart';
import 'package:metasampler/bindings/api/io.dart';
import '../style/colors.dart';
import '../style/text.dart';
import '../style/buttons.dart';
import '../style/dropdown.dart';

class AudioSettingsWidget extends StatefulWidget {
  const AudioSettingsWidget({
    super.key,
    this.audioManager,
  });

  final AudioManager? audioManager;

  @override
  State<AudioSettingsWidget> createState() => _AudioSettingsWidgetState();
}

class _AudioSettingsWidgetState extends State<AudioSettingsWidget> {
  List<String> availableDeviceTypes = [];
  List<String> availableInputDevices = [];
  List<String> availableOutputDevices = [];
  
  String? selectedDeviceType;
  String? selectedInputDevice;
  String? selectedOutputDevice;
  String? currentInputDevice;
  String? currentOutputDevice;
  
  // Audio settings
  double sampleRate = 44100.0;
  int channels = 2;
  int bufferSize = 512;
  
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadAudioConfig();
  }

  Future<void> loadAudioConfig() async {
    try {
      if (widget.audioManager == null) {
        // AudioManager not provided, set loading to false and show message
        setState(() {
          isLoading = false;
        });
        return;
      }
      
      // Get current configuration
      final currentConfig = await widget.audioManager!.getSetup();
      
      setState(() {
        currentInputDevice = currentConfig.inputDevice;
        currentOutputDevice = currentConfig.outputDevice;
        sampleRate = currentConfig.sampleRate;
        bufferSize = currentConfig.bufferSize.toInt();
        isLoading = false;
      });
      
      // Get device types
      final deviceTypes = await widget.audioManager!.getDeviceTypes();
      setState(() {
        availableDeviceTypes = deviceTypes;
      });
      
      // Try to determine the appropriate device type based on current devices
      String? preferredDeviceType = null;
      if (deviceTypes.isNotEmpty) {
        preferredDeviceType = deviceTypes.first;
      }
      
      if (preferredDeviceType != null) {
        selectedDeviceType = preferredDeviceType;
        await loadDevicesForType(preferredDeviceType);
      }
    } catch (e) {
      print('Error loading audio config: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> loadDevicesForType(String deviceType) async {
    try {
      if (widget.audioManager == null) {
        throw Exception('AudioManager not provided');
      }
      
      final inputDevices = await widget.audioManager!.getInputDevices(deviceType: deviceType);
      final outputDevices = await widget.audioManager!.getOutputDevices(deviceType: deviceType);
      
      setState(() {
        availableInputDevices = inputDevices;
        availableOutputDevices = outputDevices;
        
        // Try to set current devices as defaults, fallback to first available
        if (currentInputDevice != null && inputDevices.contains(currentInputDevice)) {
          selectedInputDevice = currentInputDevice;
        } else {
          selectedInputDevice = inputDevices.isNotEmpty ? inputDevices.first : null;
        }
        
        if (currentOutputDevice != null && outputDevices.contains(currentOutputDevice)) {
          selectedOutputDevice = currentOutputDevice;
        } else {
          selectedOutputDevice = outputDevices.isNotEmpty ? outputDevices.first : null;
        }
      });
    } catch (e) {
      print('Error loading devices for type $deviceType: $e');
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
                    'The audio system is not currently initialized. Audio settings will be available once the audio system is running.',
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
                // Host Selection
                AppDropdownWithLabel<String>(
                  label: 'Audio Host:',
                  value: selectedDeviceType,
                  items: availableDeviceTypes,
                  onChanged: (String? newValue) async {
                    setState(() {
                      selectedDeviceType = newValue;
                    });
                    if (newValue != null) {
                      await loadDevicesForType(newValue);
                    }
                    _autoSaveConfiguration();
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Input Device Selection
                if (selectedDeviceType != null) ...[
                  AppDropdownWithLabel<String>(
                    label: 'Input Device:',
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
                ],
                
                // Output Device Selection
                if (selectedDeviceType != null) ...[
                  AppDropdownWithLabel<String>(
                    label: 'Output Device:',
                    value: selectedOutputDevice,
                    items: availableOutputDevices,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedOutputDevice = newValue;
                      });
                      _autoSaveConfiguration();
                    },
                  ),
                  const SizedBox(height: 20),
                ],
                
                // Sample Rate Selection
                AppDropdownWithLabel<double>(
                  label: 'Sample Rate:',
                  value: sampleRate,
                  items: [44100.0, 48000.0, 96000.0],
                  itemBuilder: (rate) => '${rate.toInt()} Hz',
                  onChanged: (double? newValue) {
                    setState(() {
                      sampleRate = newValue ?? 44100.0;
                    });
                    _autoSaveConfiguration();
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Buffer Size Selection
                AppDropdownWithLabel<int>(
                  label: 'Buffer Size:',
                  value: bufferSize,
                  items: [256, 512, 1024, 2048],
                  itemBuilder: (size) => '$size samples',
                  onChanged: (int? newValue) {
                    setState(() {
                      bufferSize = newValue ?? 512;
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
    // Only save if all required fields are set
    if (selectedDeviceType == null || selectedInputDevice == null || selectedOutputDevice == null) {
      return; // Don't show errors, just wait for user to complete configuration
    }
    
    try {
      if (widget.audioManager == null) {
        return; // AudioManager not available
      }
      
      // Create configuration object
      final config = AudioConfiguration(
        inputDevice: selectedInputDevice!,
        outputDevice: selectedOutputDevice!,
        sampleRate: sampleRate,
        bufferSize: BigInt.from(bufferSize),
      );
      
      // Set the configuration
      await widget.audioManager!.setSetup(config: config);
      
      // Optional: Show brief success indicator (comment out to reduce noise)
      // _showSuccess('Audio configuration saved');
    } catch (e) {
      _showError('Error saving audio configuration: $e');
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

import 'package:flutter/material.dart';
import 'package:procedure_bindings/bindings/api/io.dart';

class AudioConfigDialog extends StatefulWidget {
  AudioConfigDialog({
    super.key,
    this.audioManager,
  });

  final AudioManager? audioManager;

  @override
  _AudioConfigDialogState createState() => _AudioConfigDialogState();
}

class _AudioConfigDialogState extends State<AudioConfigDialog> {
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
      // Use the passed AudioManager instance
      if (widget.audioManager == null) {
        throw Exception('AudioManager not provided');
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
        // For now, just use the first device type, but in the future we could
        // determine which type the current devices belong to
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
    return AlertDialog(
      backgroundColor: const Color.fromRGBO(30, 30, 30, 1.0),
      title: const Text(
        'Audio Configuration',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      content: SizedBox(
        width: 400,
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    
                    // Host Selection
                    const Text(
                      'Audio Host:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(40, 40, 40, 1.0),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: const Color.fromRGBO(60, 60, 60, 1.0),
                        ),
                      ),
                      child: DropdownButton<String>(
                        value: selectedDeviceType,
                        isExpanded: true,
                        dropdownColor: const Color.fromRGBO(40, 40, 40, 1.0),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        underline: Container(),
                        items: availableDeviceTypes.map((deviceType) {
                          return DropdownMenuItem<String>(
                            value: deviceType,
                            child: Text(deviceType),
                          );
                        }).toList(),
                        onChanged: (String? newValue) async {
                          setState(() {
                            selectedDeviceType = newValue;
                            // Don't reset device selections immediately - let loadDevicesForType handle it
                          });
                          if (newValue != null) {
                            await loadDevicesForType(newValue);
                          }
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 15),
                    
                    // Input Device Selection
                    if (selectedDeviceType != null) ...[
                      const Text(
                        'Input Device:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(40, 40, 40, 1.0),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: const Color.fromRGBO(60, 60, 60, 1.0),
                          ),
                        ),
                        child: DropdownButton<String>(
                          value: selectedInputDevice,
                          isExpanded: true,
                          dropdownColor: const Color.fromRGBO(40, 40, 40, 1.0),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                          underline: Container(),
                          items: availableInputDevices.map((device) {
                            return DropdownMenuItem<String>(
                              value: device,
                              child: Text(device),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedInputDevice = newValue;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 15),
                    ],
                    
                    // Output Device Selection
                    if (selectedDeviceType != null) ...[
                      const Text(
                        'Output Device:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(40, 40, 40, 1.0),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: const Color.fromRGBO(60, 60, 60, 1.0),
                          ),
                        ),
                        child: DropdownButton<String>(
                          value: selectedOutputDevice,
                          isExpanded: true,
                          dropdownColor: const Color.fromRGBO(40, 40, 40, 1.0),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                          underline: Container(),
                          items: availableOutputDevices.map((device) {
                            return DropdownMenuItem<String>(
                              value: device,
                              child: Text(device),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedOutputDevice = newValue;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 15),
                    ],
                    
                    // Sample Rate Selection
                    const Text(
                      'Sample Rate:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(40, 40, 40, 1.0),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: const Color.fromRGBO(60, 60, 60, 1.0),
                        ),
                      ),
                      child: DropdownButton<double>(
                        value: sampleRate,
                        isExpanded: true,
                        dropdownColor: const Color.fromRGBO(40, 40, 40, 1.0),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        underline: Container(),
                        items: [44100.0, 48000.0, 96000.0].map((rate) {
                          return DropdownMenuItem<double>(
                            value: rate,
                            child: Text('$rate Hz'),
                          );
                        }).toList(),
                        onChanged: (double? newValue) {
                          setState(() {
                            sampleRate = newValue ?? 44100.0;
                          });
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 15),
                    
                    // Buffer Size Selection
                    const Text(
                      'Buffer Size:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(40, 40, 40, 1.0),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: const Color.fromRGBO(60, 60, 60, 1.0),
                        ),
                      ),
                      child: DropdownButton<int>(
                        value: bufferSize,
                        isExpanded: true,
                        dropdownColor: const Color.fromRGBO(40, 40, 40, 1.0),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        underline: Container(),
                        items: [256, 512, 1024, 2048].map((size) {
                          return DropdownMenuItem<int>(
                            value: size,
                            child: Text('$size samples'),
                          );
                        }).toList(),
                        onChanged: (int? newValue) {
                          setState(() {
                            bufferSize = newValue ?? 512;
                          });
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 15),
                    
                    // Save Configuration Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (selectedDeviceType == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select an audio device type'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          
                          if (selectedInputDevice == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select an input device'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          
                          if (selectedOutputDevice == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select an output device'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          
                          try {
                            if (widget.audioManager == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('AudioManager not initialized'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
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
                            
                            // Show success message
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Audio configuration saved successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error saving audio configuration: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(50, 100, 50, 1.0),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Save Configuration',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Close',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
} 
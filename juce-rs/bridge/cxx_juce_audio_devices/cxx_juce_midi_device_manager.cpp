#include "cxx_juce_midi_device_manager.h"
#include <juce_audio_devices/juce_audio_devices.h>

namespace cxx_juce {

rust::Vec<rust::String> getMidiInputDevices() {
    rust::Vec<rust::String> devices;
    
    auto input_devices = juce::MidiInput::getAvailableDevices();
    
    for (const auto& device : input_devices) {
        devices.push_back(device.name.toRawUTF8());
    }
    
    return devices;
}

rust::Vec<rust::String> getMidiOutputDevices() {
    rust::Vec<rust::String> devices;
    
    auto output_devices = juce::MidiOutput::getAvailableDevices();
    
    for (const auto& device : output_devices) {
        devices.push_back(device.name.toRawUTF8());
    }
    
    return devices;
}

std::unique_ptr<MidiConfiguration> createMidiConfiguration() {
    return std::make_unique<MidiConfiguration>();
}

void setMidiEnabled(MidiConfiguration& config, bool enabled) {
    config.midi_enabled = enabled;
}

void setMidiInputDevice(MidiConfiguration& config, rust::Str device_name) {
    config.input_device_name = std::string(device_name);
}

void setMidiOutputDevice(MidiConfiguration& config, rust::Str device_name) {
    config.output_device_name = std::string(device_name);
}

void setMidiClockEnabled(MidiConfiguration& config, bool enabled) {
    config.midi_clock_enabled = enabled;
}

void setMidiTransportEnabled(MidiConfiguration& config, bool enabled) {
    config.midi_transport_enabled = enabled;
}

void setMidiProgramChangeEnabled(MidiConfiguration& config, bool enabled) {
    config.midi_program_change_enabled = enabled;
}

bool getMidiEnabled(const MidiConfiguration& config) {
    return config.midi_enabled;
}

rust::String getMidiInputDevice(const MidiConfiguration& config) {
    return config.input_device_name;
}

rust::String getMidiOutputDevice(const MidiConfiguration& config) {
    return config.output_device_name;
}

bool getMidiClockEnabled(const MidiConfiguration& config) {
    return config.midi_clock_enabled;
}

bool getMidiTransportEnabled(const MidiConfiguration& config) {
    return config.midi_transport_enabled;
}

bool getMidiProgramChangeEnabled(const MidiConfiguration& config) {
    return config.midi_program_change_enabled;
}

} // namespace cxx_juce
#pragma once

#include <juce_audio_devices/juce_audio_devices.h>
#include <rust/cxx.h>

namespace cxx_juce {

struct MidiConfiguration {
    rust::String input_device_name;
    rust::String output_device_name;
    bool midi_enabled;
    bool midi_clock_enabled;
    bool midi_transport_enabled;
    bool midi_program_change_enabled;
};

// MIDI Device functions
rust::Vec<rust::String> getMidiInputDevices();
rust::Vec<rust::String> getMidiOutputDevices();

// MIDI Configuration functions
std::unique_ptr<MidiConfiguration> createMidiConfiguration();
void setMidiEnabled(MidiConfiguration& config, bool enabled);
void setMidiInputDevice(MidiConfiguration& config, rust::Str device_name);
void setMidiOutputDevice(MidiConfiguration& config, rust::Str device_name);
void setMidiClockEnabled(MidiConfiguration& config, bool enabled);
void setMidiTransportEnabled(MidiConfiguration& config, bool enabled);
void setMidiProgramChangeEnabled(MidiConfiguration& config, bool enabled);

bool getMidiEnabled(const MidiConfiguration& config);
rust::String getMidiInputDevice(const MidiConfiguration& config);
rust::String getMidiOutputDevice(const MidiConfiguration& config);
bool getMidiClockEnabled(const MidiConfiguration& config);
bool getMidiTransportEnabled(const MidiConfiguration& config);
bool getMidiProgramChangeEnabled(const MidiConfiguration& config);

} // namespace cxx_juce
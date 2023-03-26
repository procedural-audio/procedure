use modules::*;

static PLUGIN: Plugin = Plugin {
    name: "Default Modules Plugin",
    version: 1,
    modules: &[
        module::<AudioTrack>(),
        module::<Sampler>(),
        module::<MultiSampler>(),
        module::<Granular>(),
        module::<SampleRack>(),
        // module::<Slicer>(),
        // module::<SampleResynthesis>(),
        // module::<Looper>(),

        // Synthesis
        module::<SawModule>(),
        module::<SquareModule>(),
        module::<SineModule>(),
        module::<TriangleModule>(),
        module::<PulseModule>(),
        module::<AnalogOscillator>(),
        module::<WavetableOscillator>(),
        module::<sources::Noise>(),
        // module::<AdditiveOscillator>(),
        // module::<HarmonicOscillator>(),
        // module::<modules::Noise>(),
        // module::<Pluck>(),

        // Physical Modeling
        // module::<StringModel>(),
        // module::<AcousticGuitarModel>(),
        // module::<ElectricGuitarModel>(),
        // module::<ModalOscillator>(),

        // Machine Learning
        // module::<ToneTransfer>(),
        // module::<Spectrogram Resynthesis>(),

        /* ========== Effects ========== */

        // Dynamics
        module::<Gain>(),
        module::<Panner>(),
        module::<Mute>(),
        module::<Mixer>(),
        module::<Gate>(),
        module::<Compressor>(),
        // module::<TransientShaper>(),
        // module::<TransientSeparator>(),

        // Distortion
        // module::<Amplifier>(),
        // module::<AanalogSaturator>(),
        // module::<AnalogDistortion>(),
        // module::<Cassette>(),
        // module::<Tape>(),
        // module::<Tube>(),
        // module::<Wavefolder>(),
        module::<Waveshaper>(),

        // Filter
        // module::<DigitalFilter>(),
        module::<AnalogFilter>(),
        // module::<CreativeFilter>(),

        // Space
        // module::<Reverb>(),
        // module::<Delay>(),
        // module::<Shimmer>(),
        // module::<Convolution>(),
        // module::<Resonator>(),
        // module::<BinauralPanner>(),

        // Spectral
        // module::<Equalizer>(),
        // module::<Exciter>(),
        // module::<PitchShifter>(),
        // module::<PitchCorrector>(),
        // module::<Vocoder>(),
        // module::<Crossover>(),

        // Modulation
        module::<Chorus>(),
        module::<Flanger>(),
        module::<Phaser>(),
        // module::<Stereoizer>(),
        // module::<Vibrato>(),

        /* ========== Notes ========== */

        // Sources
        module::<NotesTrack>(),
        module::<StepSequencer>(),
        module::<Arpeggiator>(),
        module::<sequencing::Keyboard>(),

        // Effects
        module::<Transpose>(),
        module::<sequencing::Scale>(),
        module::<sequencing::Pitch>(),
        module::<Pressure>(),
        module::<Detune>(),
        module::<Drift>(),
        module::<Portamento>(),
        module::<Monophonic>(),

        /* ========== Control ========== */

        // Sources
        module::<Constant>(),
        module::<LfoModule>(),
        module::<EnvelopeModule>(),
        module::<Beats>(),
        module::<Random>(),
        // module::<ControlTrack>(),

        // Widgets
        module::<KnobModule>(),
        module::<ButtonModule>(),
        module::<PadModule>(),
        module::<XYPadModule>(),
        module::<control::Display>(),

        // Effects
        module::<Hold>(),
        module::<Bend>(),
        module::<Slew>(),
        module::<Slope>(),
        module::<Toggle>(),
        module::<Counter>(),
        module::<Multiplexer>(),

        // Logic
        module::<And>(),
        module::<Or>(),
        module::<Not>(),
        module::<Xor>(),

        // Operations
        module::<Add>(),
        module::<Subtract>(),
        module::<Multiply>(),
        module::<Divide>(),
        module::<Modulo>(),
        module::<Negative>(),
        module::<Clamp>(),

        // Comparisons
        module::<Equal>(),
        module::<NotEqual>(),
        module::<Less>(),
        module::<LessEqual>(),
        module::<Greater>(),
        module::<GreaterEqual>(),

        /* ========== Utilities ========== */

        // Conversions
        module::<ControlToNotes>(),
        module::<NotesToControl>(),

        // IO
        module::<AudioInput>(),
        module::<AudioOutput>(),
        module::<MidiInput>(),
        module::<MidiOutput>(),
        module::<AudioPluginModule>(),

        // Scripting
        // module::<LuaScripter>(),
        // module::<FaustScripter>(),
        // module::<DSPDesigner>(),

        // Time
        module::<GlobalTime>(),
        module::<GlobalTransport>(),
        module::<Rate>(),
        module::<Reverse>(),
        module::<Accumulator>(),
        // module::<Loop>(),
        // module::<Shift>(),
    ]
};

#[no_mangle]
pub extern fn export_plugin() -> *const Plugin {
    &PLUGIN
}

mod sampling;
mod synthesis;
mod distortion;
mod dynamics;
mod modulation;
//mod space;
mod spectral;

pub use sampling::*;
pub use synthesis::*;
pub use distortion::*;
pub use dynamics::*;
pub use modulation::*;
//pub use space::*;
pub use spectral::*;

use modules::*;

static PLUGIN: Plugin = Plugin {
    name: "Built-in Audio Modules",
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
        module::<synthesis::Noise>(),
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
        module::<VoiceSpread>(),
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
    ]
};

#[no_mangle]
pub extern fn export_plugin() -> *const Plugin {
    &PLUGIN
}

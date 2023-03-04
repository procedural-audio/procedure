pub use pa_dsp::*;

use serde::{Deserialize, Serialize};

pub mod control;
pub mod effects;
pub mod sequencing;
pub mod sources;
pub mod utilities;

pub use control::*;
pub use effects::*;
pub use sequencing::*;
pub use sources::*;
pub use utilities::*;

pub mod widget;
pub use crate::widget::*;

pub struct ModuleSpec {
    pub id: &'static str,
    pub path: &'static str,
    pub color: Color,
    create: fn() -> Box<dyn PolyphonicModule>
}

impl ModuleSpec {
    pub fn create(&self) -> Box<dyn PolyphonicModule> {
        (self.create)()
    }
}

pub fn create_module<T: 'static + Module>() -> Box<dyn PolyphonicModule> {
    Box::new(ModuleManager::<T>::new())
}

pub fn module<T: 'static + Module>() -> ModuleSpec {
    ModuleSpec {
        id: T::module_id(),
        path: T::INFO.path,
        color: T::INFO.color,
        create: create_module::<T>
    }
}

pub fn get_modules() -> Vec<ModuleSpec> {
    let mut modules = Vec::new();

    /* ========== Sources ========== */

    // Sampling
    modules.push(module::<AudioTrack>());
    modules.push(module::<Sampler>());
    modules.push(module::<MultiSampler>());
    modules.push(module::<Granular>());
    modules.push(module::<SampleRack>());
    // modules.push(module::<Slicer>());
    // modules.push(module::<SampleResynthesis>());
    // modules.push(module::<Looper>());

    // Synthesis
    modules.push(module::<SawModule>());
    modules.push(module::<SquareModule>());
    modules.push(module::<SineModule>());
    modules.push(module::<TriangleModule>());
    modules.push(module::<PulseModule>());
    modules.push(module::<AnalogOscillator>());
    modules.push(module::<WavetableOscillator>());
    modules.push(module::<sources::Noise>());
    // modules.push(module::<AdditiveOscillator>());
    // modules.push(module::<HarmonicOscillator>());
    // modules.push(module::<modules::Noise>());
    // modules.push(module::<Pluck>());

    // Physical Modeling
    // modules.push(module::<StringModel>());
    // modules.push(module::<AcousticGuitarModel>());
    // modules.push(module::<ElectricGuitarModel>());
    // modules.push(module::<ModalOscillator>());

    // Machine Learning
    // modules.push(module::<ToneTransfer>());
    // modules.push(module::<Spectrogram Resynthesis>());

    /* ========== Effects ========== */

    // Dynamics
    modules.push(module::<Gain>());
    modules.push(module::<Panner>());
    modules.push(module::<Mute>());
    modules.push(module::<Mixer>());
    modules.push(module::<Gate>());
    modules.push(module::<Compressor>());
    // modules.push(module::<TransientShaper>());
    // modules.push(module::<TransientSeparator>());

    // Distortion
    // modules.push(module::<Amplifier>());
    // modules.push(module::<AanalogSaturator>());
    // modules.push(module::<AnalogDistortion>());
    // modules.push(module::<Cassette>());
    // modules.push(module::<Tape>());
    // modules.push(module::<Tube>());
    // modules.push(module::<Wavefolder>());
    modules.push(module::<Waveshaper>());

    // Filter
    // modules.push(module::<DigitalFilter>());
    modules.push(module::<AnalogFilter>());
    // modules.push(module::<CreativeFilter>());

    // Space
    // modules.push(module::<Reverb>());
    // modules.push(module::<Delay>());
    // modules.push(module::<Shimmer>());
    // modules.push(module::<Convolution>());
    // modules.push(module::<Resonator>());
    // modules.push(module::<BinauralPanner>());

    // Spectral
    // modules.push(module::<Equalizer>());
    // modules.push(module::<Exciter>());
    // modules.push(module::<PitchShifter>());
    // modules.push(module::<PitchCorrector>());
    // modules.push(module::<Vocoder>());
    // modules.push(module::<Crossover>());

    // Modulation
    modules.push(module::<Chorus>());
    modules.push(module::<Flanger>());
    modules.push(module::<Phaser>());
    // modules.push(module::<Stereoizer>());
    // modules.push(module::<Vibrato>());

    /* ========== Notes ========== */

    // Sources
    modules.push(module::<NotesTrack>());
    modules.push(module::<StepSequencer>());
    modules.push(module::<Arpeggiator>());
    modules.push(module::<sequencing::Keyboard>());

    // Effects
    modules.push(module::<Transpose>());
    modules.push(module::<sequencing::Scale>());
    modules.push(module::<sequencing::Pitch>());
    modules.push(module::<Pressure>());
    modules.push(module::<Detune>());
    modules.push(module::<Drift>());
    modules.push(module::<Portamento>());
    modules.push(module::<Monophonic>());

    /* ========== Control ========== */

    // Sources
    modules.push(module::<Constant>());
    modules.push(module::<LfoModule>());
    modules.push(module::<EnvelopeModule>());
    modules.push(module::<Beats>());
    modules.push(module::<Random>());
    // modules.push(module::<ControlTrack>());

    // Widgets
    modules.push(module::<KnobModule>());
    modules.push(module::<ButtonModule>());
    modules.push(module::<PadModule>());
    modules.push(module::<XYPadModule>());
    modules.push(module::<control::Display>());

    // Effects
    modules.push(module::<Hold>());
    modules.push(module::<Bend>());
    modules.push(module::<Slew>());
    modules.push(module::<Slope>());
    modules.push(module::<Toggle>());
    modules.push(module::<Counter>());
    modules.push(module::<Multiplexer>());

    // Logic
    modules.push(module::<And>());
    modules.push(module::<Or>());
    modules.push(module::<Not>());
    modules.push(module::<Xor>());

    // Operations
    modules.push(module::<Add>());
    modules.push(module::<Subtract>());
    modules.push(module::<Multiply>());
    modules.push(module::<Divide>());
    modules.push(module::<Modulo>());
    modules.push(module::<Negative>());
    modules.push(module::<Clamp>());

    // Comparisons
    modules.push(module::<Equal>());
    modules.push(module::<NotEqual>());
    modules.push(module::<Less>());
    modules.push(module::<LessEqual>());
    modules.push(module::<Greater>());
    modules.push(module::<GreaterEqual>());

    /* ========== Utilities ========== */

    // Conversions
    modules.push(module::<ControlToNotes>());
    modules.push(module::<NotesToControl>());

    // IO
    modules.push(module::<AudioInput>());
    modules.push(module::<AudioOutput>());
    modules.push(module::<MidiInput>());
    modules.push(module::<MidiOutput>());
    modules.push(module::<AudioPluginModule>());

    // Scripting
    // modules.push(module::<LuaScripter>());
    // modules.push(module::<FaustScripter>());
    // modules.push(module::<DSPDesigner>());

    // Time
    modules.push(module::<GlobalTime>());
    modules.push(module::<GlobalTransport>());
    modules.push(module::<Rate>());
    modules.push(module::<Reverse>());
    modules.push(module::<Accumulator>());
    // modules.push(module::<Loop>());
    // modules.push(module::<Shift>());

    println!("Loaded {} static modules", modules.len());

    return modules;
}

#[repr(C)]
#[derive(Copy, Clone)]
pub struct ModuleSymbols {
    pub name: &'static str,
    pub sym_new: extern "C" fn() -> Box<ModuleFFI>,
    pub sym_new_voice: extern "C" fn(u32) -> Box<VoiceFFI>,
    pub sym_build: for<'m> extern "C" fn(&'m mut ModuleFFI, ui: &'m UI) -> Box<dyn WidgetNew + 'm>,
    pub sym_prepare: extern "C" fn(&ModuleFFI, &mut VoiceFFI, sample_rate: u32, block_size: usize),
    pub sym_process: extern "C" fn(&mut ModuleFFI, &mut VoiceFFI, inputs: &IO, outputs: &mut IO),
    pub sym_load: extern "C" fn(&mut ModuleFFI, state: &State),
    pub sym_save: extern "C" fn(&ModuleFFI, state: &mut State),
    pub sym_info: extern "C" fn(&ModuleFFI) -> Info,
}

pub struct ModuleFFI;

pub struct VoiceFFI;

#[derive(Copy, Clone)]
pub enum Pin {
    Audio(&'static str, i32),
    Notes(&'static str, i32),
    Control(&'static str, i32),
    Time(&'static str, i32),
    ExternalAudio(usize),
    ExternalNotes(usize),
}

pub struct UI {
    should_refresh: std::sync::Mutex<bool>,
}

impl UI {
    pub fn new() -> Self {
        Self {
            should_refresh: std::sync::Mutex::new(false),
        }
    }

    pub fn should_refresh(&self) -> bool {
        let mut v = self.should_refresh.lock().unwrap();
        if *v {
            *v = false;
            return true;
        }

        return false;
    }

    pub fn refresh(&self) {
        let mut v = self.should_refresh.lock().unwrap();
        *v = true;
    }
}

#[derive(Serialize, Deserialize, PartialEq)]
pub enum Key {
    Str(String),
    Int(usize)
}

pub trait ToKey {
    fn to_key(self) -> Key;
}

impl ToKey for &'static str {
    fn to_key(self) -> Key {
        Key::Str(self.to_string())
    }
}

impl ToKey for usize {
    fn to_key(self) -> Key {
        Key::Int(self)
    }
}

#[derive(Serialize, Deserialize, Copy, Clone)]
pub enum Value {
    Float(f32),
    Int(u32),
    Bool(bool),
    Color(Color),
    None,
}

pub trait ToValue {
    fn to_value(self) -> Value;
}

pub trait FromValue {
    fn from_value(value: Value) -> Self where Self: Sized;
}

impl ToValue for f32 {
    fn to_value(self) -> Value {
        Value::Float(self)
    }
}

impl FromValue for f32 {
    fn from_value(value: Value) -> Self {
        if let Value::Float(v) = value {
            v
        } else {
            panic!("Couldn't get type");
        }
    }
}

impl ToValue for u32 {
    fn to_value(self) -> Value {
        Value::Int(self)
    }
}

impl FromValue for u32 {
    fn from_value(value: Value) -> Self {
        if let Value::Int(v) = value {
            v
        } else {
            panic!("Couldn't get type");
        }
    }
}

impl ToValue for bool {
    fn to_value(self) -> Value {
        Value::Bool(self)
    }
}

impl FromValue for bool {
    fn from_value(value: Value) -> Self {
        if let Value::Bool(v) = value {
            v
        } else {
            panic!("Couldn't get type");
        }
    }
}

#[derive(Serialize, Deserialize)]
pub struct State {
    state: Vec<(Key, Value)>,
}

impl State {
    pub fn new() -> Self {
        State {
            state: Vec::new()
        }
    }

    pub fn save<K: ToKey, V: ToValue>(&mut self, key: K, value: V) {
        self.state.push((key.to_key(), value.to_value()));
    }

    pub fn load<K: ToKey, V: FromValue>(&self, key: K) -> V {
        let key = key.to_key();
        for (k, v) in &self.state {
            if *k == key {
                return V::from_value(*v);
            }
        }

        panic!("Couldn't find element");
    }
}

pub struct Presets {
    pub path: &'static str,
    pub extension: &'static str,
}

impl Presets {
    pub const NONE: Presets = Presets {
        path: "",
        extension: ""
    };
}

pub struct Info {
    pub title: &'static str,
    pub version: &'static str,
    pub color: Color,
    pub size: Size,
    pub voicing: Voicing,
    pub inputs: &'static [Pin],
    pub outputs: &'static [Pin],
    pub path: &'static str,
    pub presets: Presets
}

pub struct Param2<T>(&'static str, T);

pub trait Module {
    type Voice;

    const INFO: Info;

    fn info(&self) -> Info {
        Self::INFO
    }

    fn module_id() -> &'static str {
        std::any::type_name::<Self>()
    }

    fn new() -> Self;
    fn new_voice(&self, index: u32) -> Self::Voice;

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w>;

    fn load(&mut self, _version: &str, _state: &State) {
        // Load stuff here
    }

    fn save(&self, _state: &mut State) {
        // Load stuff here
    }

    fn prepare(&self, voice: &mut Self::Voice, sample_rate: u32, block_size: usize) where Self: Sized;
    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) where Self: Sized;
}

pub enum Size {
    Static(u32, u32),
    Reisizable {
        default: (u32, u32),
        min: (u32, u32),
        max: (u32, u32),
    },
}

#[derive(Copy, Clone, PartialEq)]
pub enum Voicing {
    Monophonic,
    Polyphonic,
    Dynamic,
}

pub trait PolyphonicModule {
    fn new() -> Self where Self: Sized;
    fn info(&self) -> Info;
    fn load(&mut self, version: &str, state: &State);
    fn save(&self, state: &mut State);
    fn should_refresh(&self) -> bool;
    fn should_rebuild(&self) -> bool;
    fn prepare(&mut self, sample_rate: u32, block_size: usize);
    fn process_voice(&mut self, voice_index: usize, inputs: &IO, outputs: &mut IO);
    fn voicing(&self) -> Voicing;

    fn module_id(&self) -> &'static str;

    fn get_module_root(&self) -> &dyn WidgetNew;
    fn get_module_size(&self) -> (f32, f32);
    fn set_module_size(&mut self, pair: (f32, f32));

    fn get_connected(&mut self) -> &mut Vec<bool>;
}

/* ========== Module Manager ========== */

pub struct ModuleManager<T: Module> {
    module: Box<T>,
    voices: [T::Voice; 16],
    connected: Vec<bool>,
    voicing: Voicing,
    widgets: Box<dyn WidgetNew>,
    module_size: (f32, f32),
}

impl<T: Module + 'static> PolyphonicModule for ModuleManager<T> {
    fn new() -> Self {
        let mut module = Box::new(T::new());
        let voicing = module.info().voicing;

        let voices = [
            T::new_voice(&*module, 0),
            T::new_voice(&*module, 1),
            T::new_voice(&*module, 2),
            T::new_voice(&*module, 3),
            T::new_voice(&*module, 4),
            T::new_voice(&*module, 5),
            T::new_voice(&*module, 6),
            T::new_voice(&*module, 7),
            T::new_voice(&*module, 8),
            T::new_voice(&*module, 9),
            T::new_voice(&*module, 10),
            T::new_voice(&*module, 11),
            T::new_voice(&*module, 12),
            T::new_voice(&*module, 13),
            T::new_voice(&*module, 14),
            T::new_voice(&*module, 15),
        ];

        let info = module.info();
        let count = info.inputs.len() + info.outputs.len();
        let mut vec = Vec::with_capacity(count);

        for _ in 0..count {
            vec.push(false)
        }

        let module_size = match module.info().size {
            Size::Static(w, h) => (w as f32, h as f32),
            Size::Reisizable { default, min: _, max: _ } => (default.0 as f32, default.1 as f32),
        };

        let module_ptr = (&mut *module) as *mut T;

        unsafe {
            let w = (&mut *module_ptr).build();

            ModuleManager {
                module,
                voices,
                connected: vec,
                voicing,
                widgets: w,
                module_size
            }
        }
    }

    fn module_id(&self) -> &'static str {
        T::module_id()
    }

    fn get_connected(&mut self) -> &mut Vec<bool> {
        &mut self.connected
    }

    fn get_module_root(&self) -> &dyn WidgetNew {
        &*self.widgets
    }

    fn get_module_size(&self) -> (f32, f32) {
        self.module_size
    }
    fn set_module_size(&mut self, pair: (f32, f32)) {
        self.module_size = pair;
    }

    fn info(&self) -> Info {
        self.module.info()
    }

    fn should_refresh(&self) -> bool {
        false
    }

    fn should_rebuild(&self) -> bool {
        false
    }

    fn save(&self, _state: &mut State) {
        println!("SAVE NOT IMPLEMENTED IN POLYPHONIC MODULE");
    }

    fn load(&mut self, version: &str, json: &State) {
        self.module.load(version, json);
    }

    fn prepare(&mut self, sample_rate: u32, block_size: usize) {
        for voice in &mut self.voices {
            <T as Module>::prepare(&mut self.module, voice, sample_rate, block_size);
        }
    }

    fn process_voice(&mut self, voice_index: usize, inputs: &IO, outputs: &mut IO) {
        <T as Module>::process(
            &mut self.module,
            &mut self.voices[voice_index],
            inputs,
            outputs,
        );
    }

    fn voicing(&self) -> Voicing {
        return self.voicing;
    }
}

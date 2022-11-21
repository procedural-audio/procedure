use std::io::Empty;

use serde::{Deserialize, Serialize};

use crate::buffers::*;

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

pub use pa_dsp::*;

/* ========== Abstractions ========== */

pub fn create_module<T: 'static + Module>() -> Box<dyn PolyphonicModule> {
    return Box::new(ModuleManager::<T>::new());
}

pub fn get_modules() -> Vec<(&'static str, fn() -> Box<dyn PolyphonicModule>)> {
    let mut modules: Vec<(&'static str, fn() -> Box<dyn PolyphonicModule>)> = Vec::new();

    modules.push(("Analog Oscillator", create_module::<AnalogOscillator>));
    modules.push(("Wavetable Oscillator", create_module::<WavetableOscillator>));
    modules.push(("Noise", create_module::<crate::sources::Noise>));
    modules.push(("Saw", create_module::<SawModule>));
    modules.push(("Square", create_module::<SquareModule>));
    modules.push(("Sine", create_module::<SineModule>));
    modules.push(("Triangle", create_module::<TriangleModule>));
    modules.push(("Pulse", create_module::<PulseModule>));

    modules.push(("Audio Track", create_module::<AudioTrack>));
    modules.push(("Multi-Sampler", create_module::<MultiSampler>));
    modules.push(("Sampler", create_module::<Sampler>));
    modules.push(("Granular", create_module::<Granular>));
    modules.push(("Slicer", create_module::<Slicer>));
    // modules.push(("Sample Resynthesis", create_module::<SampleResynthesis>));
    modules.push(("Looper", create_module::<Looper>));

    modules.push(("Waveshaper", create_module::<Waveshaper>));
    modules.push(("Gain", create_module::<effects::Gain>));
    modules.push(("Mute", create_module::<Mute>));
    modules.push(("Panner", create_module::<Panner>));
    modules.push(("Mixer", create_module::<Mixer>));
    modules.push(("Gate", create_module::<Gate>));
    modules.push(("Compressor", create_module::<Compressor>));
    modules.push(("Crossover", create_module::<Crossover>));

    modules.push(("Chorus", create_module::<Chorus>));
    modules.push(("Flanger", create_module::<Flanger>));
    modules.push(("Phaser", create_module::<Phaser>));

    modules.push(("Tube", create_module::<Tube>));

    modules.push(("Add", create_module::<Add>));
    modules.push(("Subtract", create_module::<Subtract>));
    modules.push(("Multiply", create_module::<Multiply>));
    modules.push(("Divide", create_module::<Divide>));
    modules.push(("Negative", create_module::<Negative>));
    modules.push(("Modulo", create_module::<Modulo>));
    modules.push(("Clamp", create_module::<Clamp>));

    modules.push(("And", create_module::<And>));
    modules.push(("Or", create_module::<Or>));
    modules.push(("Not", create_module::<Not>));
    modules.push(("Xor", create_module::<Xor>));

    modules.push(("Equal", create_module::<Equal>));
    modules.push(("Not equal", create_module::<NotEqual>));
    modules.push(("Greater than", create_module::<Greater>));
    modules.push(("Greater/equal to", create_module::<GreaterEqual>));
    modules.push(("Less than", create_module::<Less>));
    modules.push(("Less/equal to", create_module::<LessEqual>));

    /* Sources */
    modules.push(("LFO", create_module::<LfoModule>));
    modules.push(("Envelope", create_module::<EnvelopeModule>));
    modules.push(("Constant", create_module::<Constant>));
    modules.push(("Clock", create_module::<Clock>));
    modules.push(("Random", create_module::<Random>));
    modules.push(("Knob", create_module::<KnobModule>));

    modules.push(("Display", create_module::<crate::control::Display>));
    modules.push(("Bend", create_module::<Bend>));
    modules.push(("Scale", create_module::<Scale>));
    modules.push(("Hold", create_module::<Hold>));
    modules.push(("Slew", create_module::<Slew>));

    modules.push(("Pitch", create_module::<crate::sequencing::Pitch>));
    modules.push(("Pressure", create_module::<Pressure>));
    modules.push(("Timbre", create_module::<Timbre>));

    // modules.push(("Level Meter", create_module::<LevelMeter>));

    modules.push(("Audio Input", create_module::<AudioInput>));
    modules.push(("Audio Output", create_module::<AudioOutput>));
    modules.push(("Midi Input", create_module::<MidiInput>));
    modules.push(("Midi Output", create_module::<MidiOutput>));

    // modules.push(("Simple Fader", create_module::<SimpleFaderModule>));
    // modules.push(("Simple Button", create_module::<SimpleButtonModule>));
    // modules.push(("Simple Switch", create_module::<SimpleSwitch>));
    // modules.push(("Simple Pad", create_module::<SimplePad>));

    // modules.push(("Image Fader", create_module::<ImageFader>));
    // modules.push(("Image Knob", create_module::<ImageKnob>));

    // modules.push(("Solid Color", create_module::<SolidColor>));
    // modules.push(("Image", create_module::<Image>));
    // modules.push(("Keyboard", create_module::<Keyboard>));

    modules.push(("Notes Track", create_module::<NotesTrack>));
    modules.push(("Step Sequencer", create_module::<crate::sequencing::StepSequencer>));

    modules.push(("Transpose", create_module::<Transpose>));

    modules.push(("Arpeggiator", create_module::<Arpeggiator>));

    modules.push(("Control To Notes", create_module::<ControlToNotes>));
    modules.push(("Notes to Control", create_module::<NotesToControl>));

    modules.push(("Time", create_module::<GlobalTime>));
    // modules.push(("Time", create_module::<LocalTime>));
    modules.push(("Reverse", create_module::<Reverse>));
    modules.push(("Rate", create_module::<Rate>));

    modules.push(("Audio Plugin", create_module::<AudioPluginModule>));

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
    pub sym_load: extern "C" fn(&mut ModuleFFI, json: &JSON),
    pub sym_save: extern "C" fn(&ModuleFFI, json: &mut JSON),
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

#[derive(Clone, Serialize, Deserialize)]
pub struct JSON {}

impl JSON {
    pub fn new() -> Self {
        JSON {}
    }
}

pub struct Info {
    // pub title: Title(&'static str, Color)
    pub name: &'static str,
    pub color: Color,
    pub size: Size,
    pub voicing: Voicing,
    pub inputs: &'static [Pin],
    pub outputs: &'static [Pin],
}

#[derive(Copy, Clone)]
pub enum Value {
    Float(f32),
    Int(u32),
    Bool(bool),
    Str(&'static str),
    Color(Color),
    None,
}

pub struct Param2<T>(&'static str, T);

pub trait Module {
    type Voice;

    const INFO: Info;

    fn info(&self) -> Info {
        Self::INFO
    }

    fn new() -> Self;
    fn new_voice(index: u32) -> Self::Voice;

    fn build<'w>(&'w mut self, ui: &'w UI) -> Box<dyn WidgetNew + 'w>;

    fn is_active(_voice: &Self::Voice) -> bool {
        true
    }

    fn load(&mut self, state: &JSON);
    fn save(&self, state2: &mut JSON);

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
    fn load(&mut self, state: &JSON);
    fn save(&self, state: &mut JSON);
    fn should_refresh(&self) -> bool;
    fn should_rebuild(&self) -> bool;
    fn prepare(&mut self, sample_rate: u32, block_size: usize);
    fn process_voice(&mut self, voice_index: usize, inputs: &IO, outputs: &mut IO);
    fn voicing(&self) -> Voicing;

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

    /* Module */
    widgets: Box<dyn WidgetNew>,
    module_size: (f32, f32),

    /* UI  */
    /*ui_widgets: T::Widgets<'w>,
    ui_position: (f32, f32),
    ui_size: (f32, f32),
    ui: UI,*/
}

impl<T: Module + 'static> PolyphonicModule for ModuleManager<T> {
    fn new() -> Self {
        let mut module = Box::new(T::new());
        let voicing = module.info().voicing;

        let voices = [
            T::new_voice(0),
            T::new_voice(1),
            T::new_voice(2),
            T::new_voice(3),
            T::new_voice(4),
            T::new_voice(5),
            T::new_voice(6),
            T::new_voice(7),
            T::new_voice(8),
            T::new_voice(9),
            T::new_voice(10),
            T::new_voice(11),
            T::new_voice(12),
            T::new_voice(13),
            T::new_voice(14),
            T::new_voice(15),
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

        let mut ui = UI::new();
        let ui_ptr = &mut ui as *mut UI;

        //let voices_ptr = &mut voices as *mut T::Voice;

        unsafe {
            let w = (&mut *module_ptr).build(&*ui_ptr);
            // let w_main = (&mut *module_ptr).build_ui(&*ui_ptr);

            ModuleManager {
                module,
                voices,
                connected: vec,
                voicing: voicing,
                widgets: w,
                module_size,
                // ui_position: (100.0, 100.0),
                // ui_size: (100.0, 100.0),
                // ui,
            }
        }
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

    fn load(&mut self, json: &JSON) {
        self.module.load(json);
    }

    fn should_refresh(&self) -> bool {
        // self.ui.should_refresh()
        false
    }

    fn should_rebuild(&self) -> bool {
        false
    }

    fn save(&self, _json: &mut JSON) {
        println!("SAVE NOT IMPLEMENTED IN POLYPHONIC MODULE");
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

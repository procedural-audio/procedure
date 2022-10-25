use serde::{Deserialize, Serialize};

use crate::buffers::*;
use crate::widget::*;

pub struct State<T: Module> {
    voice_updates: [Option<Box<dyn FnMut(&mut <T as Module>::Voice)>>; 16],
    module_updates: [Option<Box<dyn FnMut(&mut T)>>; 16],
}

impl<T: Module> State<T> {
    pub fn new() -> Self {
        Self {
            voice_updates: [
                None, None, None, None, None, None, None, None, None, None, None, None, None, None,
                None, None,
            ],
            module_updates: [
                None, None, None, None, None, None, None, None, None, None, None, None, None, None,
                None, None,
            ],
        }
    }
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
    ExternalAudio(u32),
    ExternalNotes(u32),
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

pub enum Feature {
    MidiInput,
    MidiOutput,
    AudioInput,
    AudioOutput,
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

pub struct Info {
    pub name: &'static str,
    pub color: Color,
    pub size: Size,
    pub voicing: Voicing,
    pub features: &'static [Feature],
    pub vars: &'static [(&'static str, Value)],
    pub inputs: &'static [Pin],
    pub outputs: &'static [Pin],
}

pub type ModuleVars = &'static [(&'static str, f32)];

pub trait Module {
    type Voice;

    const INFO: Info;

    fn info(&self) -> Info {
        Self::INFO
    }

    fn new() -> Self;
    fn new_voice(index: u32) -> Self::Voice;

    fn build<'w>(&'w mut self, ui: &'w UI) -> Box<dyn WidgetNew + 'w>;

    fn build_ui<'w>(&'w mut self, _ui: &'w UI) -> Box<dyn WidgetNew + 'w> {
        Box::new(EmptyWidget)
    }

    fn is_active(_voice: &Self::Voice) -> bool {
        true
    }

    fn load(&mut self, state: &JSON);
    fn save(&self, state2: &mut JSON);

    fn prepare(&self, voice: &mut Self::Voice, sample_rate: u32, block_size: usize) where Self: Sized;
    fn process(&mut self, vars: &Vars, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) where Self: Sized;
}

pub type Vars = Vec<Var>;

pub struct Var {
    pub group: Option<String>,
    pub name: String,
    pub value: VarValue,
}

#[derive(Copy, Clone)]
pub enum VarValue {
    Float(f32),
    Bool(bool),
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

pub struct Lock<T: Copy> {
    data: std::sync::RwLock<T>,
    data_backup: T,
}

impl<T: Copy> Lock<T> {
    pub fn new(data: T) -> Self {
        Self {
            data: std::sync::RwLock::new(data),
            data_backup: data,
        }
    }

    pub fn load(&self) -> T {
        let data = *self.data.read().unwrap();

        unsafe {
            *(((&self.data_backup) as *const T) as *mut T) = data;
        }

        return data;
    }

    pub fn get(&self) -> T {
        match self.data.try_read() {
            Ok(data) => {
                unsafe {
                    *(((&self.data_backup) as *const T) as *mut T) = *data;
                }

                return *data;
            }
            Err(_e) => {
                return self.data_backup;
            }
        }
    }

    pub fn store(&self, value: T) {
        *self.data.write().unwrap() = value;
    }
}
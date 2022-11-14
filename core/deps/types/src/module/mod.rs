use std::io::Empty;

use serde::{Deserialize, Serialize};

use crate::buffers::*;
use crate::widget::*;

/*pub struct State<T: Module> {
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
}*/

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

pub type Params = &'static [Param];
pub struct Param(pub &'static str, pub Value);

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
    const PARAMS: Params;

    fn info(&self) -> Info {
        Self::INFO
    }

    fn params(&self) -> Params {
        Self::PARAMS
    }

    fn new() -> Self;
    fn new_voice(index: u32) -> Self::Voice;

    fn build<'w>(&'w mut self, ui: &'w UI) -> Box<dyn WidgetNew + 'w>;

    fn set_param(&mut self, name: &str, value: Value) {
        panic!("set_param(...) called but not implemented");
    }

    fn is_active(_voice: &Self::Voice) -> bool {
        true
    }

    fn load(&mut self, state: &JSON);
    fn save(&self, state2: &mut JSON);

    fn prepare(&self, voice: &mut Self::Voice, sample_rate: u32, block_size: usize) where Self: Sized;
    fn process(&mut self, vars: &Vars, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) where Self: Sized;
}

pub struct Vars {
    pub entries: Vec<VarEntry<Var>>
}

impl Vars {
    pub fn new() -> Self {
        Self {
            entries: vec![
                VarEntry::Variable(Var {
                    id: Id(0),
                    name: String::from("Variable 1"),
                    value: Value::Float(0.0)
                }),
                VarEntry::Variable(Var {
                    id: Id(1),
                    name: String::from("Variable 2"),
                    value: Value::Float(0.0)
                }),
                VarEntry::Group(
                    String::from("Group 1"),
                    vec![
                        Var {
                            id: Id(2),
                            name: String::from("Variable 3"),
                            value: Value::Bool(false)
                        },
                        Var {
                            id: Id(3),
                            name: String::from("Variable 4"),
                            value: Value::Bool(false)
                        },
                        Var {
                            id: Id(4),
                            name: String::from("Variable 5"),
                            value: Value::Bool(true)
                        },
                    ]
                ),
                VarEntry::Variable(Var {
                    id: Id(5),
                    name: String::from("Variable 6"),
                    value: Value::Bool(true)
                }),
            ]
        }
    }

    pub fn find_id(&mut self, id: Id) -> Option<&mut Var> {
        for entry in &mut self.entries {
            match entry {
                VarEntry::Variable(var) => {
                    if var.id.0 == id.0 {
                        return Some(var);
                    }
                },
                VarEntry::Group(name, group) => {
                    for var in group {
                        if var.id.0 == id.0 {
                            return Some(var);
                        }
                    }
                },
            }
        }

        return None;
    }
}

pub enum VarEntry<T> {
    Variable(T),
    Group(String, Vec<T>)
}

pub struct Id(pub usize);

pub struct Var {
    pub id: Id,
    pub name: String,
    pub value: Value,
}

pub struct VarAssignment {
    module_id: u32,
    param_name: String,
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

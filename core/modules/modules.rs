pub use pa_dsp::*;

use serde::{Deserialize, Serialize};

pub mod widget;
pub use crate::widget::*;

pub struct Plugin {
    pub name: &'static str,
    pub version: u64,
    pub modules: &'static [ModuleSpec]
}

pub struct ModuleSpec {
    pub id: &'static str,
    pub name: &'static str,
    pub path: &'static [&'static str],
    pub color: Color,
    pub create: fn() -> Box<dyn PolyphonicModule>
}

impl ModuleSpec {
    pub fn create(&self) -> Box<dyn PolyphonicModule> {
        (self.create)()
    }
}

pub fn create_module<T: 'static + Module>() -> Box<dyn PolyphonicModule> {
    Box::new(ModuleManager::<T>::new())
}

pub const fn module<T: 'static + Module>() -> ModuleSpec {
    ModuleSpec {
        id: T::INFO.id,
        name: T::INFO.title,
        path: T::INFO.path,
        color: T::INFO.color,
        create: create_module::<T>
    }
}

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
pub enum StateKey {
    Str(String),
    Int(usize)
}

pub trait ToKey {
    fn to_key(self) -> StateKey;
}

impl ToKey for &'static str {
    fn to_key(self) -> StateKey {
        StateKey::Str(self.to_string())
    }
}

impl ToKey for usize {
    fn to_key(self) -> StateKey {
        StateKey::Int(self)
    }
}

#[derive(Serialize, Deserialize, Copy, Clone)]
pub enum Value {
    Float(f32),
    Int(u32),
    Size(usize),
    Bool(bool),
    Color(Color),
    None,
}

pub trait ToValue {
    fn to_value(self) -> Value;
}

pub trait FromValue: Default {
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

impl ToValue for usize {
    fn to_value(self) -> Value {
        Value::Size(self)
    }
}

impl FromValue for usize {
    fn from_value(value: Value) -> Self {
        if let Value::Size(v) = value {
            v
        } else {
            panic!("Couldn't get type");
        }
    }
}

#[derive(Serialize, Deserialize)]
pub struct State {
    state: Vec<(StateKey, Value)>,
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

        let s = match key {
            StateKey::Str(s) => s,
            StateKey::Int(i) => i.to_string()
        };

        println!("Couldn't find value for key {}", s);
        return V::default();
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
    pub id: &'static str,
    pub version: &'static str,
    pub color: Color,
    pub size: Size,
    pub voicing: Voicing,
    pub inputs: &'static [Pin],
    pub outputs: &'static [Pin],
    pub path: &'static [&'static str],
    pub presets: Presets
}

pub struct Param2<T>(&'static str, T);

pub trait Module {
    type Voice;

    const INFO: Info;

    fn spec() -> ModuleSpec where Self: Sized + 'static {
        ModuleSpec {
            id: Self::INFO.id,
            name: Self::INFO.path[Self::INFO.path.len() - 1],
            path: Self::INFO.path,
            color: Self::INFO.color,
            create: create_module::<Self>
        }
    }

    fn info(&self) -> Info {
        Self::INFO
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

    fn save(&self, state: &mut State) {
        self.module.save(state);
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

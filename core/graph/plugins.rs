use dynamic_reload::{DynamicReload, Lib, PlatformName, Search, Symbol, UpdateState};
use std::{sync::Arc, sync::Mutex, sync::RwLock, thread, time::Duration};

use std::mem;

use modules::*;

use crate::*;
use pa_dsp::buffers::*;

#[cfg(target_os = "linux")]
const PLUGIN_DIR: &str = "/home/chase/github/metasampler/content/plugins/bin";
#[cfg(target_os = "linux")]
const SHADOW_DIR: &str = "/home/chase/github/metasampler/build/package/linux/plugins_shadow";

#[cfg(target_os = "macos")]
const PLUGIN_DIR: &str = "/Users/chasekanipe/Github/metasampler/content/plugins/bin";
#[cfg(target_os = "macos")]
const SHADOW_DIR: &str = "/Users/chasekanipe/Github/metasampler/build/package/macos/plugins_shadow";

pub struct Plugins {
    plugins: Vec<Arc<RwLock<ModulePlugin>>>,
    reloader: DynamicReload,
    sample_rate: u32,
    block_size: usize,
}

impl Default for Plugins {
    fn default() -> Self {
        Self::new()
    }
}

impl Plugins {
    pub fn new() -> Self {
        let plugins = Vec::new();
        let reloader = DynamicReload::new(
            Some(vec![PLUGIN_DIR]),
            Some(SHADOW_DIR),
            Search::Default,
            Duration::from_secs(1),
        );

        let mut plugins = Self {
            plugins,
            reloader,
            sample_rate: 44100,
            block_size: 256,
        };

        let paths = std::fs::read_dir(PLUGIN_DIR).unwrap();

        for path in paths {
            let path = path.unwrap();
            let name = path.file_name();
            let name = name.as_os_str();
            let name = name.to_str().unwrap();
            let name = name.replace(".so", "");
            let name = name.replace("lib", "");

            println!("Found library {}", name);

            plugins.add_library(&name);
        }

        return plugins;
    }

    pub fn add_library(&mut self, name: &str) {
        unsafe {
            match &self.reloader.add_library(name, PlatformName::Yes) {
                Ok(library) => match library.lib.get(b"register_modules") {
                    Ok(sym) => {
                        let mut symbols = Vec::new();

                        let sym: Symbol<fn(&mut Vec<ModuleSymbols>)> = sym;
                        (sym)(&mut symbols);

                        for symbol in &symbols {
                            self.plugins.push(Arc::new(RwLock::new(ModulePlugin::new(
                                library.clone(),
                                *symbol,
                            ))));
                        }
                    }
                    Err(_e) => println!("Plugin doesn't have any modules"),
                },
                Err(e) => {
                    println!("Unable to load dynamic lib, err {:?}", e);
                }
            }
        }
    }

    fn reload_callback(
        plugins: &mut Vec<Arc<RwLock<ModulePlugin>>>,
        state: UpdateState,
        lib: Option<&Arc<Lib>>,
    ) {
        match state {
            UpdateState::Before => {
                let _lib = lib.unwrap();
            }
            UpdateState::After => {
                let lib = lib.unwrap();

                for plugin in plugins {
                    let mut matched = false;

                    /* Check if libraries match */
                    match plugin.read() {
                        Ok(module_plugin) => {
                            match &*module_plugin {
                                ModulePlugin::Ready {
                                    library,
                                    symbols: _,
                                    version: _,
                                } => {
                                    if library == lib {
                                        matched = true;
                                    }
                                }
                                ModulePlugin::Deleted {
                                    library: _,
                                    symbols: _,
                                    version: _,
                                } => {
                                    panic!("Called reload on deleted module");
                                }
                            };
                        }
                        Err(e) => (),
                    }

                    /* Overwrite libraries */
                    if matched {
                        match plugin.write() {
                            Ok(mut module_plugin) => {
                                match &mut *module_plugin {
                                    ModulePlugin::Ready {
                                        library,
                                        symbols,
                                        version,
                                    } => {
                                        if library == lib {
                                            println!(
                                                "Updating library on plugin {:#?}",
                                                library
                                                    .original_path
                                                    .clone()
                                                    .unwrap()
                                                    .file_name()
                                                    .unwrap()
                                            );

                                            unsafe {
                                                match lib.lib.get(b"register_modules") {
                                                    Ok(sym) => {
                                                        let mut symbols_list = Vec::new();

                                                        let sym: Symbol<
                                                            fn(&mut Vec<ModuleSymbols>),
                                                        > = sym;
                                                        (sym)(&mut symbols_list);

                                                        let mut found = false;
                                                        for symbols_new in &symbols_list {
                                                            if symbols_new.name == symbols.name {
                                                                found = true;

                                                                *library = lib.clone();
                                                                *symbols = *symbols_new;
                                                                *version = *version + 1;

                                                                println!(
                                                                    "Updated module version to {}",
                                                                    *version
                                                                );
                                                            }
                                                            //self.plugins.push(Arc::new(RwLock::new(ModulePlugin::new(library.clone(), *symbol))));
                                                        }

                                                        if !found {
                                                            panic!("Couldn't find module plugin in reloaded plugin");
                                                        }
                                                    }
                                                    Err(_e) => {
                                                        println!("Plugin doesn't have any modules")
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    ModulePlugin::Deleted {
                                        library: _,
                                        symbols: _,
                                        version: _,
                                    } => {
                                        panic!("Called reload on deleted module 2");
                                    }
                                };
                            }
                            Err(_e) => (),
                        }
                    }
                }
            }
            UpdateState::ReloadFailed(_) => println!("Failed to reload"),
        }
    }

    pub fn prepare(&mut self, sample_rate: u32, block_size: usize) {
        self.sample_rate = sample_rate;
        self.block_size = block_size;
    }

    pub fn update(&mut self) {
        unsafe {
            self.reloader
                .update(&Plugins::reload_callback, &mut self.plugins);
        }
    }

    pub fn create_module(&mut self, name: &str) -> Option<Box<dyn PolyphonicModule>> {
        for plugin in &self.plugins {
            match &*plugin.read().unwrap() {
                ModulePlugin::Ready {
                    library,
                    symbols,
                    version,
                } => {
                    if symbols.name == name {
                        return Some(Box::new(ModuleDynamic {
                            plugin: plugin.clone(),
                            state: Box::new(State::new(
                                library.clone(),
                                *symbols,
                                *version,
                                self.sample_rate,
                                self.block_size,
                            )),
                            new_state: Arc::new(Mutex::new(None)),
                            status: Arc::new(RwLock::new(Status::Active)),
                            sample_rate: self.sample_rate,
                            block_size: self.block_size,
                        }));
                    }
                }
                ModulePlugin::Deleted {
                    library: _,
                    symbols: _,
                    version: _,
                } => {}
            }
        }

        return None;
    }
}

pub enum ModulePlugin {
    Ready {
        library: Arc<Lib>,
        symbols: ModuleSymbols,
        version: u32,
    },
    Deleted {
        library: Arc<Lib>,
        symbols: ModuleSymbols,
        version: u32,
    },
}

impl ModulePlugin {
    pub fn new(library: Arc<Lib>, symbols: ModuleSymbols) -> Self {
        let version = 0;

        Self::Ready {
            library,
            symbols,
            version,
        }
    }
}

pub struct ModuleDynamic {
    plugin: Arc<RwLock<ModulePlugin>>,
    state: Box<State>,
    new_state: Arc<Mutex<Option<Box<State>>>>,
    status: Arc<RwLock<Status>>,
    sample_rate: u32,
    block_size: usize,
}

enum Status {
    Active,
    Reloading,
    Reloaded {
        info: bool,
        widgets: bool,
        prepare: bool,
    },
    Deleted,
}

unsafe impl std::marker::Send for State {}

struct State {
    module: Box<ModuleFFI>,
    voices: [Box<VoiceFFI>; 16],
    connected: Vec<bool>,
    widgets: Box<dyn WidgetNew>,
    main_widgets: Option<Box<dyn WidgetNew>>,
    pub ui: UI,
    voicing: Voicing,
    library: Arc<Lib>,
    symbols: ModuleSymbols,
    version: u32,
}

impl State {
    pub fn new(
        library: Arc<Lib>,
        symbols: ModuleSymbols,
        version: u32,
        sample_rate: u32,
        block_size: usize,
    ) -> Self {
        println!("State::new() with version {}", version);
        let mut module = (symbols.sym_new)();
        let voicing = (symbols.sym_info)(&*module).voicing;

        let mut voices = [
            (symbols.sym_new_voice)(0),
            (symbols.sym_new_voice)(1),
            (symbols.sym_new_voice)(2),
            (symbols.sym_new_voice)(3),
            (symbols.sym_new_voice)(4),
            (symbols.sym_new_voice)(5),
            (symbols.sym_new_voice)(6),
            (symbols.sym_new_voice)(7),
            (symbols.sym_new_voice)(8),
            (symbols.sym_new_voice)(9),
            (symbols.sym_new_voice)(10),
            (symbols.sym_new_voice)(11),
            (symbols.sym_new_voice)(12),
            (symbols.sym_new_voice)(13),
            (symbols.sym_new_voice)(14),
            (symbols.sym_new_voice)(15),
        ];

        let info = (symbols.sym_info)(&*module);
        let count = info.inputs.len() + info.outputs.len();
        let mut vec = Vec::with_capacity(count);

        for _ in 0..count {
            vec.push(false);
        }

        let module_ptr = &mut *module as *mut ModuleFFI;

        let mut ui = UI::new();
        let ui_ptr = &mut ui as *mut UI;

        unsafe {
            let w = (symbols.sym_build)(&mut *module_ptr, &*ui_ptr);

            for voice in &mut voices {
                (symbols.sym_prepare)(&*module_ptr, &mut *voice, sample_rate, block_size);
            }

            Self {
                module,
                voices,
                ui,
                connected: vec,
                widgets: w,
                main_widgets: None,
                voicing: voicing,
                library,
                symbols,
                version,
            }
        }
    }
}

impl PolyphonicModule for ModuleDynamic {
    fn new() -> Self {
        panic!("Shouldn't ever call new on ModuleDynamic");
    }

    fn get_connected(&mut self) -> &mut Vec<bool> {
        println!("ModuleDynamic::get_connected()");
        &mut self.state.connected
    }

    fn get_module_root(&self) -> &dyn WidgetNew {
        println!("ModuleDynamic::get_widgets_root()");
        match &*self.status.read().unwrap() {
            Status::Active | Status::Reloading | Status::Deleted => &*self.state.widgets,
            Status::Reloaded {
                info,
                widgets,
                prepare,
            } => {
                if let Some(new_state) = &mut *self.new_state.lock().unwrap() {
                    println!(" > Got new state widgets");
                    let widgets_ptr = (widgets as *const bool) as *mut bool;
                    unsafe {
                        *widgets_ptr = true;
                    }

                    let ptr = &mut *new_state.widgets as *mut dyn WidgetNew;
                    unsafe { &*ptr }
                } else {
                    panic!("Widgets are none");
                }
            }
        }
    }

    /*fn get_ui_root(&self) -> Option<&dyn WidgetNew> {
        None
    }

    fn get_ui_position(&self) -> (f32, f32) {
        (0.0, 0.0)
    }

    fn set_ui_position(&mut self, pair: (f32, f32)) {}*/

    fn get_module_size(&self) -> (f32, f32) {
        panic!("Not implemented");
    }

    fn set_module_size(&mut self, pair: (f32, f32)) {
        panic!("Not implemented");
    }

    /*fn get_ui_size(&self) -> (f32, f32) {
        panic!("Not implemented");
    }

    fn set_ui_size(&mut self, pair: (f32, f32)) {
        panic!("Not implemented");
    }*/

    fn info(&self) -> Info {
        println!("ModuleDynamic::info()");
        match &*self.status.read().unwrap() {
            Status::Active | Status::Reloading | Status::Deleted => {
                return (self.state.symbols.sym_info)(&*self.state.module);
            }
            Status::Reloaded {
                info,
                widgets,
                prepare,
            } => {
                if let Some(new_state) = &mut *self.new_state.lock().unwrap() {
                    println!(" > GOT NEW STATE INFO");
                    let info_ptr = (info as *const bool) as *mut bool;
                    unsafe {
                        *info_ptr = true;
                    }

                    return (new_state.symbols.sym_info)(&*new_state.module);
                } else {
                    panic!("Widgets are none");
                }
            }
        }
    }

    fn should_rebuild(&self) -> bool {
        match &*self.status.read().unwrap() {
            Status::Active | Status::Reloading | Status::Deleted => false,
            Status::Reloaded {
                info,
                widgets,
                prepare,
            } => {
                if !widgets {
                    true
                } else {
                    false
                }
            }
        }
    }

    fn should_refresh(&self) -> bool {
        self.state.ui.should_refresh()
    }

    fn load(&mut self, state: &modules::State) {
        (self.state.symbols.sym_load)(&mut *self.state.module, state);
    }

    fn save(&self, state: &mut modules::State) {
        (self.state.symbols.sym_save)(&*self.state.module, state);
    }

    fn prepare(&mut self, sample_rate: u32, block_size: usize) {
        println!("ModuelDynamic::prepare()");
        match &mut *self.status.write().unwrap() {
            Status::Active | Status::Reloading | Status::Deleted => {
                for voice in &mut self.state.voices {
                    (self.state.symbols.sym_prepare)(
                        &*self.state.module,
                        voice,
                        sample_rate,
                        block_size,
                    );
                }
            }
            Status::Reloaded {
                info,
                widgets,
                prepare,
            } => {
                let mut state = self.new_state.lock().unwrap();

                panic!("Not sure if to prepare when reloaded");

                *prepare = true;

                match &mut *state {
                    Some(state) => {
                        for voice in &mut state.voices {
                            (state.symbols.sym_prepare)(
                                &*state.module,
                                voice,
                                sample_rate,
                                block_size,
                            );
                        }
                    }
                    None => (),
                }
            }
        }
    }

    fn process_voice(&mut self, voice_index: usize, inputs: &IO, outputs: &mut IO) {
        panic!("Must update to use time correctly");

        match self.status.try_write() {
            Ok(mut status) => {
                match &mut *status {
                    Status::Active => {
                        (self.state.symbols.sym_process)(
                            &mut *self.state.module,
                            &mut *self.state.voices[voice_index],
                            inputs,
                            outputs,
                        );

                        match self.plugin.try_read() {
                            Ok(plugin) => {
                                match &*plugin {
                                    ModulePlugin::Ready {
                                        library,
                                        symbols,
                                        version,
                                    } => {
                                        if self.state.version != *version
                                            && ((*version + 1) > 1 && (*version + 1) % 2 != 0)
                                        {
                                            /* Asynchronously update new_state */

                                            let new_state_async = self.new_state.clone();
                                            let status_async = self.status.clone();
                                            let library_async = library.clone();
                                            let symbols_async = *symbols;
                                            let version_async = *version;
                                            let sample_rate = self.sample_rate;
                                            let block_size = self.block_size;

                                            thread::spawn(move || {
                                                let mut new_state = new_state_async.lock().unwrap();
                                                *new_state = Some(Box::new(State::new(
                                                    library_async,
                                                    symbols_async,
                                                    version_async,
                                                    sample_rate,
                                                    block_size,
                                                )));

                                                let mut status = status_async.write().unwrap();
                                                *status = Status::Reloaded {
                                                    info: false,
                                                    widgets: false,
                                                    prepare: false,
                                                };

                                                println!("Module reloaded");
                                            });

                                            /* Change state to reloading */
                                            *status = Status::Reloading;
                                            println!("Module reloading");
                                        }
                                    }
                                    ModulePlugin::Deleted {
                                        library,
                                        symbols,
                                        version,
                                    } => {
                                        println!("SHOULD DELETE SELF");
                                    }
                                }
                            }
                            Err(_) => (),
                        }
                    }
                    Status::Reloading => {
                        (self.state.symbols.sym_process)(
                            &mut *self.state.module,
                            &mut *self.state.voices[voice_index],
                            inputs,
                            outputs,
                        );
                    }
                    Status::Reloaded {
                        info,
                        widgets,
                        prepare,
                    } => {
                        (self.state.symbols.sym_process)(
                            &mut *self.state.module,
                            &mut *self.state.voices[voice_index],
                            inputs,
                            outputs,
                        );

                        //if *info && *widgets && *prepare {
                        if *widgets {
                            if let Ok(mut new_state) = self.new_state.try_lock() {
                                match &mut *new_state {
                                    Some(new_state) => {
                                        mem::swap(&mut self.state, &mut *new_state);
                                        *status = Status::Active;
                                        println!("Module active");
                                    }
                                    None => {
                                        panic!("New state is None");
                                    }
                                }
                            }
                        }
                    }
                    Status::Deleted => {}
                }
            }
            Err(_) => {
                println!("Skipping process during status update (SHOULD CHANGE THIS)");
            }
        }
    }

    fn voicing(&self) -> Voicing {
        self.info().voicing
    }
}

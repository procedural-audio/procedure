use proc_macro::{self, TokenStream};
use quote::quote;
use quote::format_ident;
use syn::{parse_macro_input, DeriveInput};

#[proc_macro_derive(Widget)]
pub fn derive(input: TokenStream) -> TokenStream {
    let DeriveInput { ident, .. } = parse_macro_input!(input);
    let name = format_ident!("{}", ident);

    let output = quote! {
        impl WidgetTrait for #ident {
            fn new() -> Box<Self> {
                Box::new(Self::create())
            }

            fn get_name(&self) -> &'static str {
                return stringify!(#name);
            }

            fn get_state(&self) -> &WidgetState {
                return &self.state;
            }

            fn get_state_mut(&mut self) -> &mut WidgetState {
                return &mut self.state;
            }

            fn set_updated(&mut self, updated: bool) {
                self.updated = updated;
            }

            fn get_updated(&self) -> bool {
                self.updated
            }

            fn refresh(&mut self) {
                self.state.should_refresh = true;
            }

            fn should_refresh(&self) -> bool {
                self.state.should_refresh
            }

            fn refresh_done(&mut self) {
                self.state.should_refresh = false;
            }

            fn set_mouse_over(&mut self, over: bool) {
                return self.state.mouse_over = over;
            }

            fn mouse_over(&self) -> bool {
                return self.state.mouse_over;
            }
        }
    };

    output.into()
}

#[proc_macro_derive(Widget2)]
pub fn derive2(input: TokenStream) -> TokenStream {
    let DeriveInput { ident, .. } = parse_macro_input!(input);
    let name = format_ident!("{}", ident);

    let output = quote! {
        impl Widget for #ident {
            fn name(&self) -> &'static str {
                return stringify!(#name);
            }

            fn init_position(mut self: Box<Self>, x: i32, y: i32) -> Box<Self> {
                self.position = (x, y);
                return self;
            }

            fn init_size(mut self: Box<Self>, width: i32, height: i32) -> Box<Self> {
                self.size = (width, height);
                return self;
            }

            fn get_position(&self) -> (i32, i32) {
                self.position
            }

            fn get_size(&self) -> (i32, i32) {
                self.size
            }

            fn set_updated(&mut self, updated: bool) {
                self.updated = updated;
            }

            fn updated(&self) -> bool {
               self.updated 
            }

            fn refresh(&self) {

            }

            /*fn refresh(&mut self) {
                self.state.should_refresh = true;
            }

            fn should_refresh(&self) -> bool {
                self.state.should_refresh
            }*/
        }
    };

    output.into()
}

#[proc_macro_derive(ModuleBackend)]
pub fn derive_module(input: TokenStream) -> TokenStream {
    let DeriveInput { ident, .. } = parse_macro_input!(input);
    let name = format_ident!("{}", ident);

    let output = quote! {
        impl ModuleBackend for #ident {
            fn new() -> Self {
                Self {
                    state: Self::new_state(),
                    voice: Self::new_voice(0),
                    backend: Backend::new(),
                }
            }

            //fn set_state(&self, f: fn(&mut <Self as Module>::State)) {
            fn set_state<F: FnMut(&mut <Self as Module>::State)>(&self, f: F) {
                unsafe { // <-- COULD THIS CAUSE SEGFAULT ???
                    let const_ptr = self as *const Self;
                    let mut_ptr = const_ptr as *mut Self;
                    let mut_ref = &mut *mut_ptr;

                    //mut_ref.backend.tasks.push(f);

                    /*for i in 0..16 {
                        match mut_ref._state_updates[i] {
                            None => {
                                mut_ref._state_updates[i] = Some(f);
                                break;
                            },
                            _ => ()
                        }
                    }*/
                }
            }

            fn _update_state(&mut self) {
                /*for i in 0..16 {
                    match self._state_updates[i] {
                        Some(f) => {
                            f(&mut self.state);
                        },
                        None => break,
                    }
                }*/
            }

            fn rebuild_gui(&self) {
                unsafe {
                    let const_ptr = self as *const Self;
                    let mut_ptr = const_ptr as *mut Self;
                    let mut_ref = &mut *mut_ptr;

                    mut_ref.backend.rebuild_gui = true;
                }
            }


            fn update_gui(&self) {
                unsafe {
                    let const_ptr = self as *const Self;
                    let mut_ptr = const_ptr as *mut Self;
                    let mut_ref = &mut *mut_ptr;

                    mut_ref.backend.update_gui = true;
                }
            }
        }
    };

    output.into()
}

#[proc_macro_attribute]
pub fn module(args: TokenStream, input: TokenStream) -> TokenStream {
    let DeriveInput { ident, .. } = parse_macro_input!(input);
    let name = format_ident!("{}", ident);

    return format!("#[derive(ModuleBackend)]\npub struct {} {{\nstate: <Self as Module>::State,\nvoice: <Self as Module>::Voice,\nbackend: Backend<Self>}}", name).parse().unwrap();
}

#[proc_macro]
pub fn faust(item: TokenStream) -> TokenStream {
    let code = format!("{}", item);

    let name = &code[0..code.find(",").unwrap()];
    let code = &code[(code.find(",").unwrap() + 1)..code.len()];

    let mut code2 = String::from("import(\"stdfaust.lib\");\n");
    code2.push_str(&code);

    std::fs::write("/tmp/temp.dsp", code2).unwrap();

    let out = std::process::Command::new("faust")
        .args(["-lang", "rust", "/tmp/temp.dsp"])
        .output()
        .unwrap();

    let code2 = String::from_utf8(out.stdout).unwrap();
    if let Ok(err) = String::from_utf8(out.stderr) {
        if err.len() > 1 {
            panic!("{}", err);
        }
    }

    let mut name3 = String::from("mod");
    name3.push_str(name);

    let mut code3 = format!("mod {} {{\nuse faust_types::FaustDsp;\nuse faust_types::ParamIndex;\nuse faust_types::Meta;\n", name3);

    code3.push_str(&code2);

    let code3 = code3.replace("UI", "faust_types::UI");
    let code3 = code3.replace("mydsp", "FaustSaw");

    let mut code3 = code3.replace("pub struct", "#[derive(Clone)]\npub struct");

    code3.push_str("\n}\n");
    code3.push_str("#[derive(Clone)]");
    code3.push_str("pub struct Saw2 {dsp: FaustSaw,block_size: i32}");
    code3.push_str("impl Saw2 {");
    code3.push_str("pub fn new() -> Self {");
    code3.push_str("Self { dsp: FaustSaw::new(), block_size: 1 }");
    code3.push_str("}");
    code3.push_str("pub fn set_param(&mut self, index: i32, value: f32) { self.dsp.set_param(faust_types::ParamIndex(index), value); }");
    code3.push_str("pub fn prepare(&mut self, sample_rate: u32, block_size: usize) { self.block_size = block_size as i32; self.dsp.init(sample_rate as i32); }");
    code3.push_str("pub fn process(&mut self, inputs: &[&[f32]], outputs: &mut [&mut [f32]]) { self.dsp.compute(self.block_size, inputs, outputs); }");
    code3.push_str("}");

    let mut name2 = String::from("Faust");
    name2.push_str(name);

    let code3 = code3.replace("F32", "f32");
    let code3 = code3.replace("FaustSaw::new()", "somemod::FaustSaw::new()");
    let code3 = code3.replace("FaustSaw,block_size", "somemod::FaustSaw,block_size");
    let code3 = code3.replace("somemod", &name3);
    let code3 = code3.replace("FaustSaw", &name2);
    let code3 = code3.replace("Saw2", name);

    //panic!("{}", code3);

    code3.parse().unwrap()
}

#[proc_macro]
pub fn export_module(item: TokenStream) -> TokenStream {
    let name = format!("{}", item);

    let code = 
    r#"
    #[no_mangle]
unsafe extern "C" fn register_modules(modules: &mut Vec<ModuleSymbols>) {
    modules.push(
        ModuleSymbols {
            name: "Oscillator",
            sym_new: std::mem::transmute::<extern "C" fn () -> Box<Oscillator>, extern "C" fn () -> Box<ModuleFFI>>(new_module),
            sym_new_voice: std::mem::transmute::<extern "C" fn (u32) -> Box<<Oscillator as Module>::Voice>, extern "C" fn (u32) -> Box<VoiceFFI>>(new_voice_module),
            sym_build: std::mem::transmute::<for<'m> extern "C" fn (&'m mut Oscillator, &'m UI) -> Box<dyn WidgetNew + 'm>, for<'m> extern "C" fn (&'m mut ModuleFFI, &'m UI) -> Box<dyn WidgetNew + 'm>>(build_module),
            sym_prepare: std::mem::transmute::<extern "C" fn (&Oscillator, &mut <Oscillator as Module>::Voice, sample_rate: u32, block_size: usize), extern "C" fn (&ModuleFFI, &mut VoiceFFI, sample_rate: u32, block_size: usize)>(prepare_module),
            sym_process: std::mem::transmute::<extern "C" fn (&mut Oscillator, &mut <Oscillator as Module>::Voice, inputs: &IO, outputs: &mut IO), extern "C" fn (&mut ModuleFFI, &mut VoiceFFI, inputs: &IO, outputs: &mut IO)>(process_module),
            sym_load: std::mem::transmute::<extern "C" fn (&mut Oscillator, json: &JSON), extern "C" fn (&mut ModuleFFI, json: &JSON)>(load_module),
            sym_save: std::mem::transmute::<extern "C" fn (&Oscillator, json: &mut JSON), extern "C" fn (&ModuleFFI, json: &mut JSON)>(save_module),
            sym_info: std::mem::transmute::<extern "C" fn (&Oscillator) -> Info, extern "C" fn (&ModuleFFI) -> Info>(info_module),
        }
    );
}

#[no_mangle]
extern "C" fn info_module(module: &Oscillator) -> Info {
    module.info()
}

extern "C" fn new_module() -> Box<Oscillator> {
    Box::new(Oscillator::new())
}

#[no_mangle]
extern "C" fn new_voice_module(index: u32) -> Box<<Oscillator as Module>::Voice> {
    Box::new(Oscillator::new_voice(index))
}

#[no_mangle]
extern "C" fn build_module<'m>(module: &'m mut Oscillator, ui: &'m UI) -> Box<dyn WidgetNew + 'm> {
    module.build(ui)
}

#[no_mangle]
extern "C" fn prepare_module(module: &Oscillator, voice: &mut <Oscillator as Module>::Voice, sample_rate: u32, block_size: usize) {
    module.prepare(voice, sample_rate, block_size)
}

#[no_mangle]
extern "C" fn process_module(module: &mut Oscillator, voice: &mut <Oscillator as Module>::Voice, inputs: &IO, outputs: &mut IO) {
    module.process(voice, inputs, outputs);
}

#[no_mangle]
extern "C" fn load_module(module: &mut Oscillator, json: &JSON) {
    module.load(json);
}

#[no_mangle]
extern "C" fn save_module(module: &Oscillator, json: &mut JSON) {
    module.save(json);
}
"#;
    let code = code.replace("Oscillator", &name);

    code.parse().unwrap()
}

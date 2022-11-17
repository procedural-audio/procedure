use crate::*;

use std::sync::{Arc, Mutex};

pub struct ControlVariable {
    name: Arc<Mutex<String>>
}

impl Module for ControlVariable {
    type Voice = ();

    const INFO: Info = Info {
        name: "",
        color: Color::RED,
        size: Size::Static(180, 50),
        voicing: Voicing::Monophonic,
        inputs: &[
            Pin::Control("Input", 17)
        ],
        outputs: &[
            Pin::Control("Output", 17)
        ],
    };

    fn new() -> Self {
        Self {
            name: Arc::new(Mutex::new(String::new()))
        }
    }

    fn new_voice(_index: u32) -> Self::Voice { () }
    fn load(&mut self, _json: &JSON) {}
    fn save(&self, _json: &mut JSON) {}

    fn build<'w>(&'w mut self, _ui: &'w UI) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (35, 10),
            size: (180-35*2, 30),
            child: _ControlVariable {
                name: self.name.clone()
            }
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, _inputs: &IO, outputs: &mut IO) {
        match self.name.try_lock() {
            Ok(name) => {
                /*for var in vars {
                    if var.name == *name {
                        match var.value {
                            Value::Float(v) => {
                                outputs.control[0] = v;
                            },
                            Value::Bool(v) => {
                                if v {
                                    outputs.control[0] = 1.0;
                                } else {
                                    outputs.control[0] = 0.0;
                                }
                            }
                            _ => panic!("Note implemented")
                        }

                        break;
                    }
                }*/
            },
            Err(_e) => {
                println!("Couldn't lock control variable");
            }
        }

        // println!("{}", outputs.control[0]);
    }
}

#[repr(C)]
pub struct _ControlVariable {
    pub name: Arc<Mutex<String>>,
}

impl WidgetNew for _ControlVariable {
    fn get_name(&self) -> &'static str {
        "ControlVariable"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &()
    }
}

/* ========== FFI ========== */

use std::ffi::{CStr, CString};

#[no_mangle]
pub unsafe extern "C" fn ffi_control_var_get_name(knob: &mut _ControlVariable) -> *const i8 {
    let name = knob.name.lock().unwrap();
    let s = match CString::new((*name).as_str()) {
        Ok(s) => s,
        Err(e) => {
            println!("Error with control variable label {}: {}", (*name).as_str(), e);
            CString::new("Error").unwrap()
        }
    };

    let p = s.as_ptr();
    std::mem::forget(s);
    p
}

#[no_mangle]
pub unsafe extern "C" fn ffi_control_var_set_name(knob: &mut _ControlVariable, text: *const i8) {
    let c_str: &CStr = CStr::from_ptr(text);
    let str_slice: &str = c_str.to_str().unwrap();

    let mut text = knob.name.lock().unwrap();
    *text = String::from(str_slice);
}
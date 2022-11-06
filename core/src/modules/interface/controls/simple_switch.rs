use crate::modules::*;

pub struct SimpleSwitch {
    value: bool,
}

impl Module for SimpleSwitch {
    type Voice = ();

    const INFO: Info = Info {
        name: "Simple Switch",
                color: Color::RED,
        size: Size::Static(120, 110),
        voicing: Voicing::Monophonic,
        params: &[],
inputs: &[],
        outputs: &[Pin::Control("Control Output", 30)],
    };

    fn new() -> Self {
        Self { value: false }
    }

    fn new_voice(_index: u32) -> Self::Voice {
        ()
    }

    fn load(&mut self, _json: &JSON) {}
    fn save(&self, _json: &mut JSON) {}

    fn build<'w>(&'w mut self, _ui: &'w UI) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (35, 30),
            size: (50, 70),
            child: Svg {
                path: "operations/add.svg",
                color: Color::RED,
            },
        })
    }

    fn build_ui<'w>(&'w mut self, _ui: &'w UI) -> Box<dyn WidgetNew + 'w> {
        Box::new(_SimpleSwitch {
            text: "Gain",
            color: Color::BLUE,
            value: false,
            on_changed: Box::new(|v| {
                self.value = v;
            }),
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _vars: &Vars, _voice: &mut Self::Voice, _inputs: &IO, outputs: &mut IO) {
        if self.value {
            outputs.control[0] = 1.0;
        } else {
            outputs.control[0] = 0.0;
        }
    }
}

use std::ffi::CString;

#[repr(C)]
pub struct _SimpleSwitch<'a> {
    pub text: &'a str,
    pub color: Color,
    pub value: bool,
    pub on_changed: Box<dyn FnMut(bool) + 'a>,
}

impl<'a> WidgetNew for _SimpleSwitch<'a> {
    fn get_name(&self) -> &'static str {
        "SimpleSwitch"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &()
    }
}

/* ========== FFI ========== */

#[no_mangle]
pub unsafe extern "C" fn ffi_simple_switch_set_value(knob: &mut _SimpleSwitch, value: bool) {
    knob.value = value;
    (*knob.on_changed)(value);
}

#[no_mangle]
pub unsafe extern "C" fn ffi_simple_switch_get_color(knob: &mut _SimpleSwitch) -> u32 {
    knob.color.0
}

#[no_mangle]
pub unsafe extern "C" fn ffi_simple_switch_get_label(knob: &mut _SimpleSwitch) -> *const i8 {
    let s = match CString::new(knob.text) {
        Ok(s) => s,
        Err(e) => {
            println!("Error with switch label {}: {}", knob.text, e);
            CString::new("").unwrap()
        }
    };

    let p = s.as_ptr();
    std::mem::forget(s);
    p
}

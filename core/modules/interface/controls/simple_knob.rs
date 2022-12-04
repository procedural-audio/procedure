use crate::*;

pub struct SimpleKnob {
    value: f32,
}

impl Module for SimpleKnob {
    type Voice = ();

    const INFO: Info = Info {
        title: "Simple Knob",
        version: "0.0.0",
        color: Color::RED,
        size: Size::Static(120, 110),
        voicing: Voicing::Monophonic,
        inputs: &[],
        outputs: &[Pin::Control("Control Output", 30)],
        path: "Category 1/Category 2/Module Name"
    };

    
    fn new() -> Self {
        Self { value: 0.5 }
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
        Box::new(_SimpleKnob {
            label: String::from("Gain"),
            color: Color::BLUE,
            value: &mut self.value,
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, _inputs: &IO, outputs: &mut IO) {
        outputs.control[0] = self.value;
    }
}

use std::ffi::{CStr, CString};

#[repr(C)]
pub struct _SimpleKnob<'a> {
    pub label: String,
    pub color: Color,
    pub value: &'a mut f32,
}

impl<'a> WidgetNew for _SimpleKnob<'a> {
    fn get_name(&self) -> &'static str {
        "SimpleKnob"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &()
    }
}

/* ========== FFI ========== */

#[no_mangle]
pub unsafe extern "C" fn ffi_simple_knob_get_value(knob: &mut _SimpleKnob) -> f32 {
    *knob.value
}

#[no_mangle]
pub unsafe extern "C" fn ffi_simple_knob_set_value(knob: &mut _SimpleKnob, mut value: f32) {
    if value < 0.0 {
        value = 0.0;
    }

    if value > 1.0 {
        value = 1.0;
    }

    *knob.value = value;
}

#[no_mangle]
pub unsafe extern "C" fn ffi_simple_knob_get_color(knob: &mut _SimpleKnob) -> u32 {
    knob.color.0
}

#[no_mangle]
pub unsafe extern "C" fn ffi_simple_knob_set_color(knob: &mut _SimpleKnob, c: u32) {
    knob.color = Color(c);
}

#[no_mangle]
pub unsafe extern "C" fn ffi_simple_knob_set_label(knob: &mut _SimpleKnob, l: *const i8) {
    let c_str: &CStr = CStr::from_ptr(l);
    let str_slice: &str = c_str.to_str().unwrap();
    knob.label = str_slice.to_string();
}

#[no_mangle]
pub unsafe extern "C" fn ffi_simple_knob_get_label(knob: &mut _SimpleKnob) -> *const i8 {
    let s = match CString::new(knob.label.as_str()) {
        Ok(s) => s,
        Err(e) => {
            println!("Error with knob label {}: {}", &knob.label, e);
            CString::new("").unwrap()
        }
    };

    let p = s.as_ptr();
    std::mem::forget(s);
    p
}

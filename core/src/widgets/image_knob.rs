use std::ffi::CString;
use crate::widgets::*;

#[repr(C)]
pub struct ImageKnob<'a> {
    pub text: &'a str,
    pub color: Color,
    pub value: f32,
    pub control: &'a f32,
    pub on_changed: Box<dyn FnMut(f32) + 'a>,
}

impl<'a> WidgetNew for ImageKnob<'a> {
    fn get_name(&self) -> &'static str {
        "ImageKnob"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &()
    }
}

/* ========== FFI ========== */

#[no_mangle]
pub unsafe extern "C" fn ffi_image_knob_set_value(knob: &mut ImageKnob, value: f32) {
    knob.value = value;
    (*knob.on_changed)(value);
}

#[no_mangle]
pub unsafe extern "C" fn ffi_image_knob_get_color(knob: &mut ImageKnob) -> u32 {
    knob.color as u32
}

#[no_mangle]
pub unsafe extern "C" fn ffi_image_knob_get_label(knob: &mut ImageKnob) -> *const i8 {
    let s = match CString::new(knob.text) {
        Ok(s) => s,
        Err(e) => {
            println!("Error with knob label {}: {}", knob.text, e);
            CString::new("").unwrap()
        }
    };

    let p = s.as_ptr();
    std::mem::forget(s);
    p
}

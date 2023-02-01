use crate::*;

pub struct ImageFader {
    value: f32,
}

impl Module for ImageFader {
    type Voice = ();

    const INFO: Info = Info {
        title: "Image Fader",
        version: "0.0.0",
        color: Color::RED,
        size: Size::Static(120, 110),
        voicing: Voicing::Monophonic,
        inputs: &[],
        outputs: &[Pin::Control("Control Output", 30)],
        path: "Category 1/Category 2/Module Name",
        presets: Presets::NONE
    };

    
    fn new() -> Self {
        Self { value: 0.5 }
    }

    fn new_voice(&self, _index: u32) -> Self::Voice {
        ()
    }

    fn load(&mut self, _version: &str, _state: &State) {}
    fn save(&self, _state: &mut State) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (35, 30),
            size: (50, 70),
            child: Icon {
                path: "operations/add.svg",
                color: Color::RED,
            },
        })
    }

    fn build_ui<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(_ImageFader {
            text: "Gain",
            color: Color::GREEN,
            value: 0.0,
            control: &0.0,
            on_changed: Box::new(|mut v| {
                if v > 1.0 {
                    v = 1.0;
                } else if v < 0.0 {
                    v = 0.0;
                }

                self.value = v;
            }),
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, _inputs: &IO, outputs: &mut IO) {
        outputs.control[0] = self.value;
    }
}

use std::ffi::CString;

#[repr(C)]
pub struct _ImageFader<'a> {
    pub text: &'a str,
    pub color: Color,
    pub value: f32,
    pub control: &'a f32,
    pub on_changed: Box<dyn FnMut(f32) + 'a>,
}

impl<'a> WidgetNew for _ImageFader<'a> {
    fn get_name(&self) -> &'static str {
        "ImageFader"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &()
    }
}

/* ========== FFI ========== */

#[no_mangle]
pub unsafe extern "C" fn ffi_image_fader_set_value(knob: &mut _ImageFader, value: f32) {
    knob.value = value;
    (*knob.on_changed)(value);
}

#[no_mangle]
pub unsafe extern "C" fn ffi_image_fader_get_color(knob: &mut _ImageFader) -> u32 {
    knob.color.0
}

#[no_mangle]
pub unsafe extern "C" fn ffi_image_fader_get_label(knob: &mut _ImageFader) -> *const i8 {
    let s = match CString::new(knob.text) {
        Ok(s) => s,
        Err(e) => {
            println!("Error with image fader label {}: {}", knob.text, e);
            CString::new("").unwrap()
        }
    };

    let p = s.as_ptr();
    std::mem::forget(s);
    p
}

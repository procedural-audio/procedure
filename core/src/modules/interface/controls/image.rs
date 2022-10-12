use crate::modules::*;

pub struct Image {
    value: f32,
}

impl Module for Image {
    type Voice = ();

    const INFO: Info = Info {
        name: "Image",
        features: &[],
        color: Color::RED,
        size: Size::Static(120, 110),
        voicing: Voicing::Monophonic,
        vars: &[],
inputs: &[],
        outputs: &[Pin::Control("Control Output", 30)],
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
        Box::new(_Image {
            path: "/home/chase/github/metasampler/content/assets/images/background.jpeg",
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _vars: &Vars, _voice: &mut Self::Voice, _inputs: &IO, outputs: &mut IO) {
        outputs.control[0].set(self.value);
    }
}

use std::ffi::CString;

#[repr(C)]
pub struct _Image<'a> {
    pub path: &'a str,
}

impl<'a> WidgetNew for _Image<'a> {
    fn get_name(&self) -> &'static str {
        "Image"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &()
    }
}

/* ========== FFI ========== */

#[no_mangle]
pub unsafe extern "C" fn ffi_image_get_path(knob: &mut _Image) -> *const i8 {
    let s = match CString::new(knob.path) {
        Ok(s) => s,
        Err(e) => {
            println!("Error with image label {}: {}", knob.path, e);
            CString::new("").unwrap()
        }
    };

    let p = s.as_ptr();
    std::mem::forget(s);
    p
}

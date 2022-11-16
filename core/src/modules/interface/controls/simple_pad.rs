use crate::modules::*;

pub struct SimplePad {
    value: bool,
}

impl Module for SimplePad {
    type Voice = ();

    const INFO: Info = Info {
        name: "Simple Pad",
                color: Color::RED,
        size: Size::Static(120, 110),
        voicing: Voicing::Monophonic,
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
        Box::new(_SimplePad {
            color: Color::BLUE,
            value: false,
            on_changed: Box::new(|v| {
                self.value = v;
            }),
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, _inputs: &IO, outputs: &mut IO) {
        if self.value {
            outputs.control[0] = 1.0;
        } else {
            outputs.control[0] = 0.0;
        }
    }
}

#[repr(C)]
pub struct _SimplePad<'a> {
    pub color: Color,
    pub value: bool,
    pub on_changed: Box<dyn FnMut(bool) + 'a>,
}

impl<'a> WidgetNew for _SimplePad<'a> {
    fn get_name(&self) -> &'static str {
        "SimplePad"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &()
    }
}

/* ========== FFI ========== */

#[no_mangle]
pub unsafe extern "C" fn ffi_simple_pad_set_value(knob: &mut _SimplePad, value: bool) {
    knob.value = value;
    (*knob.on_changed)(value);
}

#[no_mangle]
pub unsafe extern "C" fn ffi_simple_pad_get_color(knob: &mut _SimplePad) -> u32 {
    knob.color.0
}

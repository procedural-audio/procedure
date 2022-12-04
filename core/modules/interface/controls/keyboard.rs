use crate::*;

pub struct Keyboard {
    value: f32,
}

impl Module for Keyboard {
    type Voice = ();

    const INFO: Info = Info {
        title: "",
        version: "0.0.0",
        color: Color::RED,
        size: Size::Reisizable {
            default: (400, 200),
            min: (400, 200),
            max: (400, 200),
        },
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
        Box::new(_Keyboard {
            text: "Gain",
            value: 0.0,
            control: &0.0,
            on_changed: Box::new(|v| {
                self.value = v;
            }),
        })
    }

    fn build_ui<'w>(&'w mut self, _ui: &'w UI) -> Box<dyn WidgetNew + 'w> {
        Box::new(_Keyboard {
            text: "Gain",
            value: 0.0,
            control: &0.0,
            on_changed: Box::new(|v| {
                self.value = v;
            }),
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, _inputs: &IO, outputs: &mut IO) {
        outputs.control[0] = self.value;
    }
}



#[repr(C)]
pub struct _Keyboard<'a> {
    pub text: &'a str,
    pub color: Color,
    pub value: f32,
    pub control: &'a f32,
    pub on_changed: Box<dyn FnMut(f32) + 'a>,
}

impl<'a> WidgetNew for _Keyboard<'a> {
    fn get_name(&self) -> &'static str {
        "Keyboard"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &()
    }
}

/* ========== FFI ========== */

#[no_mangle]
pub unsafe extern "C" fn ffi_keyboard_set_color(knob: &mut _Keyboard, value: u32) {
    knob.color = Color(value);
}

#[no_mangle]
pub unsafe extern "C" fn ffi_keyboard_get_color(knob: &mut _Keyboard) -> u32 {
    knob.color.0
}

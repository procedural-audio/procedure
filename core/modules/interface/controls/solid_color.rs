use crate::*;

pub struct SolidColor {
    value: f32,
}

impl Module for SolidColor {
    type Voice = ();

    const INFO: Info = Info {
        title: "Image Knob",
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
        Box::new(_SolidColor {
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



#[repr(C)]
pub struct _SolidColor<'a> {
    pub text: &'a str,
    pub color: Color,
    pub value: f32,
    pub control: &'a f32,
    pub on_changed: Box<dyn FnMut(f32) + 'a>,
}

impl<'a> WidgetNew for _SolidColor<'a> {
    fn get_name(&self) -> &'static str {
        "SolidColor"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &()
    }
}

/* ========== FFI ========== */

#[no_mangle]
pub unsafe extern "C" fn ffi_solid_color_set_color(knob: &mut _SolidColor, value: u32) {
    knob.color = Color(value);
}

#[no_mangle]
pub unsafe extern "C" fn ffi_solid_color_get_color(knob: &mut _SolidColor) -> u32 {
    knob.color.0
}

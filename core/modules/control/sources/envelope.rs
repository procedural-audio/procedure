use crate::*;

pub struct EnvelopeModule {
    /*attack: f32,
decay: f32,
sustain: f32,
release: f32,*/}

pub struct EnvelopeVoice {}

impl Module for EnvelopeModule {
    type Voice = EnvelopeVoice;

    const INFO: Info = Info {
        title: "Envelope",
        version: "0.0.0",
        color: Color::RED,
        size: Size::Static(300, 150),
        voicing: Voicing::Monophonic,
        inputs: &[
            Pin::Control("Attack", 20),
            Pin::Control("Decay", 50),
            Pin::Control("Sustain", 80),
            Pin::Control("Release", 110),
        ],
        outputs: &[
            Pin::Control("Output", 20)
        ],
        path: "Category 1/Category 2/Module Name",
        presets: Presets::NONE
    };
    
    fn new() -> Self {
        Self {
            /*attack: 0.0,
            decay: 1.0,
            sustain: 0.0,
            release: 0.0*/
        }
    }

    fn new_voice(&self, _index: u32) -> Self::Voice {
        Self::Voice {}
    }

    fn load(&mut self, _version: &str, _state: &State) {}
    fn save(&self, _state: &mut State) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Stack {
            children: (Transform {
                position: (35, 40),
                size: (235, 90),
                child: _Envelope {
                    on_changed: Box::new(|_v| {}),
                },
            }),
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, _inputs: &IO, _outputs: &mut IO) {
    }
}

#[repr(C)]
pub struct _Envelope<'a> {
    pub on_changed: Box<dyn FnMut(f32) + 'a>,
}

impl<'a> WidgetNew for _Envelope<'a> {
    fn get_name(&self) -> &'static str {
        "Envelope"
    }

    fn get_children<'w>(&'w self) -> &'w dyn WidgetGroup {
        &()
    }
}

/* ========== FFI ========== */

#[no_mangle]
pub unsafe extern "C" fn ffi_envelope_set_value(_knob: &mut _Envelope, _value: f32) {}

#[no_mangle]
pub unsafe extern "C" fn ffi_envelope_get_color(_knob: &mut _Envelope) -> u32 {
    0
}

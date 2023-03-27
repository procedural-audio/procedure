use crate::*;

enum Stage {
    Attack,
    Decay,
    Sustain,
    Release 
}

pub struct ADSR {
    attack: f32,
    decay: f32,
    sustain: f32,
    release: f32,
    mult: f32,
    rate: u32,
    stage: Stage,
    index: usize
}

impl ADSR {
    pub fn new() -> Self {
        Self {
            attack: 0.0,
            decay: 1.0,
            sustain: 0.3,
            release: 1.0,
            mult: 1.0,
            rate: 1,
            stage: Stage::Attack,
            index: 0
        }
    }

    pub fn gen(&mut self) -> f32 {
        match self.stage {
            Stage::Attack => {
                0.0
            },
            Stage::Decay => {
                0.0
            },
            Stage::Sustain => {
                0.0
            },
            Stage::Release => {
                0.0
            }
        }
    }

    pub fn prepare(&mut self, sample_rate: u32) {
        self.index = 0;
        self.rate = sample_rate;
    }
}

pub struct EnvelopeModule {
    attack: f32,
    decay: f32,
    sustain: f32,
    release: f32,
    mult: f32
}

pub struct EnvelopeVoice {
    adsr: ADSR
}

impl Module for EnvelopeModule {
    type Voice = EnvelopeVoice;

    const INFO: Info = Info {
        title: "ADSR",
        id: "default.control.operations.adsr",
        version: "0.0.0",
        color: Color::RED,
        size: Size::Static(300, 160),
        voicing: Voicing::Monophonic,
        inputs: &[
            Pin::Notes("Notes", 10+25*0),
            Pin::Control("Attack", 10+25*1),
            Pin::Control("Decay", 10+25*2),
            Pin::Control("Sustain", 10+25*3),
            Pin::Control("Release", 10+25*4),
            Pin::Control("Mult", 10+25*5)
        ],
        outputs: &[
            Pin::Control("Output", 10)
        ],
        path: &["Control", "Sources", "Envelope"],
        presets: Presets::NONE
    };

    fn new() -> Self {
        Self {
            attack: 0.2,
            decay: 1.0,
            sustain: 0.3,
            release: 1.0,
            mult: 0.9
        }
    }

    fn new_voice(&self, _index: u32) -> Self::Voice {
        Self::Voice {
            adsr: ADSR::new()
        }
    }

    fn load(&mut self, _version: &str, _state: &State) {}
    fn save(&self, _state: &mut State) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Stack {
            children: (Padding {
                padding: (35, 35, 5, 5),
                child: _Envelope {
                    attack: &mut self.attack,
                    decay: &mut self.decay,
                    sustain: &mut self.sustain,
                    release: &mut self.release,
                    mult: &mut self.mult
                }
            })
        })
    }

    fn prepare(&self, voice: &mut Self::Voice, sample_rate: u32, block_size: usize) {
        voice.adsr.prepare(sample_rate / block_size as u32);
    }

    fn process(&mut self, voice: &mut Self::Voice, _inputs: &IO, outputs: &mut IO) {
        outputs.control[0] = voice.adsr.gen();
    }
}

#[repr(C)]
pub struct _Envelope<'a> {
    pub attack: &'a mut f32,
    pub decay: &'a mut f32,
    pub sustain: &'a mut f32,
    pub release: &'a mut f32,
    pub mult: &'a mut f32
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
pub unsafe extern "C" fn ffi_envelope_get_attack(widget: &mut _Envelope) -> f32 {
    *widget.attack
}

#[no_mangle]
pub unsafe extern "C" fn ffi_envelope_get_decay(widget: &mut _Envelope) -> f32 {
    *widget.decay
}

#[no_mangle]
pub unsafe extern "C" fn ffi_envelope_get_sustain(widget: &mut _Envelope) -> f32 {
    *widget.sustain
}

#[no_mangle]
pub unsafe extern "C" fn ffi_envelope_get_release(widget: &mut _Envelope) -> f32 {
    *widget.release
}

#[no_mangle]
pub unsafe extern "C" fn ffi_envelope_get_mult(widget: &mut _Envelope) -> f32 {
    *widget.mult
}

#[no_mangle]
pub unsafe extern "C" fn ffi_envelope_set_attack(widget: &mut _Envelope, value: f32) {
    *widget.attack = value;
}

#[no_mangle]
pub unsafe extern "C" fn ffi_envelope_set_decay(widget: &mut _Envelope, value: f32) {
    *widget.decay = value;
}

#[no_mangle]
pub unsafe extern "C" fn ffi_envelope_set_sustain(widget: &mut _Envelope, value: f32) {
    *widget.sustain = value;
}

#[no_mangle]
pub unsafe extern "C" fn ffi_envelope_set_release(widget: &mut _Envelope, value: f32) {
    *widget.release = value;
}

#[no_mangle]
pub unsafe extern "C" fn ffi_envelope_set_mult(widget: &mut _Envelope, value: f32) {
    *widget.mult = value;
}

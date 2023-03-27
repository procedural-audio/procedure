use crate::*;

pub struct Hold;

pub struct HoldVoice {
    hold: bool,
    value: f32
}

impl Module for Hold {
    type Voice = HoldVoice;

    const INFO: Info = Info {
        title: "Hold",
        id: "default.control.effects.hold",
        version: "0.0.0",
        color: Color::RED,
        size: Size::Static(100, 75),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Control("Input", 15),
            Pin::Control("Hold (boolean)", 45),
        ],
        outputs: &[
            Pin::Control("Output", 30)
        ],
        path: &["Control", "Effects", "Hold"],
        presets: Presets::NONE
    };

    fn new() -> Self {
        Hold
    }

    fn new_voice(&self, _index: u32) -> Self::Voice {
        Self::Voice {
            hold: false,
            value: 0.0
        }
    }

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (35, 32),
            size: (30, 30),
            child: Icon {
                path: "hold.svg",
                color: Color::RED,
            },
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        let value = inputs.control[0];

        if voice.hold {
            if inputs.control[1] < 0.5 {
                outputs.control[0] = value;
                voice.hold = false;
            } else {
                outputs.control[0] = voice.value;
            }
        } else {
            if inputs.control[1] < 0.5 {
                outputs.control[0] = value;
            } else {
                voice.hold = true;
                voice.value = value;
                outputs.control[0] = value;
            }
        }
    }
}

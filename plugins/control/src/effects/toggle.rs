use modules::*;

pub struct Toggle;

pub struct ToggleVoice {
    last: f32,
    toggle: bool
}

impl Module for Toggle {
    type Voice = ToggleVoice;

    const INFO: Info = Info {
        title: "Toggle",
        id: "default.control.effects.toggle",
        version: "0.0.0",
        color: Color::RED,
        size: Size::Static(100, 75),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Control("Control Input", 30),
        ],
        outputs: &[
            Pin::Control("Control Output", 30)
        ],
        path: &["Control", "Effects", "Toggle"]
    };

    fn new() -> Self { Self }

    fn new_voice(&self, _index: u32) -> Self::Voice {
        Self::Voice {
            last: 0.0,
            toggle: false
        }
    }

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (30, 25),
            size: (40, 40),
            child: Icon {
                path: "waveforms/square.svg",
                color: Color::RED,
            },
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        let value = inputs.control[0];
        if value >= 0.5 && voice.last < 0.5 {
            voice.toggle = !voice.toggle;
            voice.last = value;
        } else {
            voice.last = value;
        }

        outputs.control[0] = if voice.toggle { 1.0 } else { 0.0 };
    }
}

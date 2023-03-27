use crate::*;

pub struct Slew {
    rate: f32,
}

impl Module for Slew {
    type Voice = f32;

    const INFO: Info = Info {
        title: "Slew",
        id: "default.control.effects.slew",
        version: "0.0.0",
        color: Color::RED,
        size: Size::Static(120, 110),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Control("Input", 25),
            Pin::Control("Slew (0-1)", 55)
        ],
        outputs: &[
            Pin::Control("Output", 25)
        ],
        path: &["Control", "Effects", "Slew"],
        presets: Presets::NONE
    };

    fn new() -> Self {
        Self {
            rate: 0.0
        }
    }

    fn new_voice(&self, _index: u32) -> Self::Voice {
        0.0
    }

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (35, 30),
            size: (50, 70),
            child: Knob {
                text: "Rate",
                color: Color::RED,
                value: &mut self.rate,
                feedback: Box::new(|v| format!("{:.2}", v)),
            },
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        let rate = f32::powf(self.rate, 2.0);
        let input = f32::clamp(inputs.control[0] - *voice, -rate, rate);
        *voice = *voice + input;

        // Todo: Use slew input value optionally
        outputs.control[0] = *voice;
    }
}

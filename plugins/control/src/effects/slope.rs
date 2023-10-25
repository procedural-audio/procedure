use modules::*;

pub struct Slope;

pub struct SlopeVoice {
    last: f32
}

impl Module for Slope {
    type Voice = SlopeVoice;

    const INFO: Info = Info {
        title: "Slope",
        id: "default.control.effects.slope",
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
        path: &["Control", "Effects", "Slope"]
    };

    fn new() -> Self { Self }

    fn new_voice(&self, _index: u32) -> Self::Voice {
        Self::Voice {
            last: 0.0
        }
    }

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (30, 25),
            size: (40, 40),
            child: Icon {
                path: "waveforms/triangle.svg",
                color: Color::RED,
            },
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        let value = inputs.control[0];
        outputs.control[0] = value - voice.last;
        voice.last = value;
    }
}

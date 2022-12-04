use crate::*;

pub struct Slew {
    rate: f32,
}

impl Module for Slew {
    type Voice = ();

    const INFO: Info = Info {
        title: Title("Slew", Color::RED),
        size: Size::Static(120, 110),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Control("Input", 25),
            Pin::Control("Rate (0-1)", 55)
        ],
        outputs: &[
            Pin::Control("Output", 25)
        ],
    };

        
    fn new() -> Self {
        Self { rate: 0.0 }
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
            child: Knob {
                text: "Rate",
                color: Color::RED,
                value: &mut self.rate,
                feedback: Box::new(|v| format!("{:.2}", v)),
            },
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        outputs.control[0] = inputs.control[0];
    }
}

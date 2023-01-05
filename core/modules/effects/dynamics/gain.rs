use crate::*;

pub struct Gain {
    value: f32,
}

impl Module for Gain {
    type Voice = ();

    const INFO: Info = Info {
        title: "Gain",
        version: "0.0.0",
        color: Color::BLUE,
        size: Size::Static(120, 110),
        voicing: Voicing::Monophonic,
        inputs: &[
            Pin::Audio("Audio Input", 25),
            Pin::Control("Linear Gain", 55),
        ],
        outputs: &[
            Pin::Audio("Audio Output", 25)
        ],
        path: "Category 1/Category 2/Module Name"
    };

    
    fn new() -> Self {
        Self { value: 0.5 }
    }

    fn new_voice(&self, _index: u32) -> Self::Voice {
        ()
    }

    fn load(&mut self, _json: &JSON) {}
    fn save(&self, _json: &mut JSON) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (35, 30),
            size: (50, 70),
            child: Knob {
                text: "Gain",
                color: Color::BLUE,
                value: &mut self.value,
                feedback: Box::new(|v| format!("{:.1}", v)),
            },
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        let mut value = self.value;

        if inputs.control.is_connected(0) {
            value = inputs.control[0];
        }

        outputs.audio[0].copy_from(&inputs.audio[0]);

        for sample in &mut outputs.audio[0] {
            sample.gain(value);
        }
    }
}
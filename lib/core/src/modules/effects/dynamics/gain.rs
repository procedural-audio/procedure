use crate::modules::*;


pub struct Gain {
    value: f32,
}

impl Module for Gain {
    type Voice = ();

    const INFO: Info = Info {
        name: "Gain",
        features: &[],
        color: Color::BLUE,
        size: Size::Static(120, 110),
        voicing: Voicing::Monophonic,
        vars: &[],
inputs: &[
            Pin::Audio("Audio Input", 25),
            Pin::Control("Linear Gain", 55),
        ],
        outputs: &[Pin::Audio("Audio Output", 25)],
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

    fn process(&mut self, _vars: &Vars, _voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        outputs.audio[0].copy_from(&inputs.audio[0]);
        outputs.audio[0].gain(self.value);
    }
}

use crate::*;

pub struct Panner {
    value: f32,
}

impl Module for Panner {
    type Voice = ();

    const INFO: Info = Info {
        title: "Panner",
        id: "default.effects.dynamics.panner",
        version: "0.0.0",
        color: Color::BLUE,
        size: Size::Static(120, 110),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Audio("Audio Input", 25),
            Pin::Control("Pan Amount", 55),
        ],
        outputs: &[
            Pin::Audio("Audio Output", 25)
        ],
        path: &["Audio", "Dynamics", "Panner"],
        presets: Presets::NONE
    };

    
    fn new() -> Self {
        Self { value: 0.5 }
    }

    fn new_voice(&self, _index: u32) -> Self::Voice {
        ()
    }

    fn load(&mut self, _version: &str, state: &State) {
        self.value = state.load("pan");
    }

    fn save(&self, state: &mut State) {
        state.save("pan", self.value);
    }

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (35, 30),
            size: (50, 70),
            child: Knob {
                text: "Pan",
                color: Color::BLUE,
                value: &mut self.value,
                feedback: Box::new(| v| {
                    if v == 0.5 {
                        String::from("C")
                    } else if v < 0.5 {
                        format!("{:.1} L", linear_to_db(1.0 - v))
                    } else {
                        format!("{:.1} R", linear_to_db(v))
                    }
                }),
            },
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        let mut value = self.value;

        if inputs.control.connected(0) {
            value = inputs.control[0];
        }

        value = f32::clamp(value, 0.0, 1.0);
        outputs.audio[0].copy_from(&inputs.audio[0]);

        for sample in &mut outputs.audio[0] {
            sample.left = sample.left * (1.0 - value);
            sample.right = sample.right * value;
        }
    }
}

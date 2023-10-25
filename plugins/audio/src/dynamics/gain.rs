use crate::*;
use pa_dsp::*;

pub struct Gain {
    value: f32,
}

impl Module for Gain {
    type Voice = ();

    const INFO: Info = Info {
        title: "Gain",
        id: "default.effects.dynamics.gain",
        version: "0.0.0",
        color: Color::BLUE,
        size: Size::Static(120, 110),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Audio("Audio Input", 25),
            Pin::Control("Gain (0-1)", 55),
        ],
        outputs: &[
            Pin::Audio("Audio Output", 25)
        ],
        path: &["Audio", "Dynamics", "Gain"]
    };

    fn new() -> Self {
        Self { value: 0.5 }
    }

    fn new_voice(&self, _index: u32) -> Self::Voice {
        ()
    }

    fn load(&mut self, _version: &str, state: &State) {
        self.value = state.load("gain");
    }

    fn save(&self, state: &mut State) {
        state.save("gain", self.value);
    }

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (35, 30),
            size: (50, 70),
            child: Knob {
                text: "Gain",
                color: Color::BLUE,
                value: &mut self.value,
                feedback: Box::new(| v| format!("{:.1} db", linear_to_db(v)))
            }
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        let value = if inputs.control.connected(0) {
            inputs.control[0].clamp(0.0, 1.0)
        } else {
            self.value
        };

        outputs.audio[0].copy_from(&inputs.audio[0]);
        outputs.audio[0].gain(linear_to_db(value));
    }
}

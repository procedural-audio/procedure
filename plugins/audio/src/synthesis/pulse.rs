use crate::*;

use pa_dsp::*;
use pa_algorithms::{Pulse, Player};

pub struct PulseModule {
    value: f32,
}

impl Module for PulseModule {
    type Voice = Player<Pulse<Stereo<f32>>>;

    const INFO: Info = Info {
        title: "Pulse",
        id: "default.audio.synthesis.pulse",
        version: "0.0.0",
        color: Color::BLUE,
        size: Size::Static(120, 110),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Notes("Notes Input", 25),
            Pin::Control("Duty (0-1)", 55),
        ],
        outputs: &[
            Pin::Audio("Audio Output", 25)
        ],
        path: &["Audio", "Synthesis", "Pulse"],
        presets: Presets::NONE
    };

    fn new() -> Self {
        Self { value: 0.5 }
    }

    fn new_voice(&self, _index: u32) -> Self::Voice {
        Player::from(Pulse::new())
    }

    fn load(&mut self, _version: &str, state: &State) {
        self.value = state.load("duty");
    }

    fn save(&self, state: &mut State) {
        state.save("duty", self.value);
    }

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (35, 30),
            size: (50, 70),
            child: Knob {
                text: "Gain",
                color: Color::BLUE,
                value: &mut self.value,
                feedback: Box::new(| v| format!("{:.1}", linear_to_db(v))),
            },
        })
    }

    fn prepare(&self, voice: &mut Self::Voice, sample_rate: u32, block_size: usize) {
        voice.prepare(sample_rate, block_size);
    }

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        let mut value = f32::clamp(self.value, 0.0, 1.0);

        if inputs.control.connected(0) {
            value = f32::clamp(inputs.control[0], 0.0, 1.0);
        }

        voice.set_duty(value * 0.4 + 0.1);
        voice.update_pitch(&inputs.events[0]);
        voice.update_playback(&inputs.events[0]);
        voice.generate_block(&mut outputs.audio[0]);

        for sample in (&mut outputs.audio[0]).into_iter() {
            sample.left *= 0.1;
            sample.right *= 0.1;
        }
    }
}

use crate::*;

use pa_algorithms::*;

pub struct Noise {
    value: f32,
}

impl Module for Noise {
    type Voice = ColoredNoise<Stereo<f32>>;

    const INFO: Info = Info {
        title: "Noise",
        id: "default.synthesis.noise",
        version: "0.0.0",
        color: Color::BLUE,
        size: Size::Static(120, 110),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Control("Noise Type", 25)
        ],
        outputs: &[
            Pin::Audio("Audio Output", 25)
        ],
        path: &["Audio", "Synthesis", "Noise"]
    };

    fn new() -> Self {
        Self { value: 0.5 }
    }

    fn new_voice(&self, _index: u32) -> Self::Voice {
        ColoredNoise::new()
    }

    fn load(&mut self, _version: &str, _state: &State) {}
    fn save(&self, _state: &mut State) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (35, 30),
            size: (50, 70),
            child: Knob {
                text: "Type",
                color: Color::BLUE,
                value: &mut self.value,
                feedback: Box::new(|v| {
                    if v < 1.0 / 3.0 {
                        String::from("Brown")
                    } else if v < 2.0 / 3.0 {
                        String::from("Pink")
                    } else {
                        String::from("White")
                    }
                })
            }
        })
    }

    fn prepare(&self, voice: &mut Self::Voice, sample_rate: u32, block_size: usize) {
		voice.prepare(sample_rate, block_size);
    }

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        let mut color = self.value;
        if inputs.control.connected(0) {
            color = f32::clamp(inputs.control[0], 0.0, 1.0);
        }

        voice.set_color(color - 1.0);
		voice.generate_block(&mut outputs.audio[0]);
    }
}

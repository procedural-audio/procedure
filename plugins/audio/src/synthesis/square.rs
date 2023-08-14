use crate::*;

use pa_algorithms::*;

pub struct SquareModule;

pub struct SquareModuleVoice {
    square: Square<Stereo<f32>>,
    active: bool,
}

impl Module for SquareModule {
    type Voice = SquareModuleVoice;

    const INFO: Info = Info {
        title: "Squ",
        id: "default.synthesis.square",
        version: "0.0.0",
        color: Color::BLUE,
        size: Size::Static(100, 75),
        voicing: Voicing::Polyphonic,
        inputs: &[Pin::Notes("Notes", 15)],
        outputs: &[Pin::Audio("Audio Output", 15)],
        path: &["Audio", "Synthesis", "Square"],
        presets: Presets::NONE
    };

    fn new() -> Self { Self }

    fn new_voice(&self, _index: u32) -> Self::Voice {
        Self::Voice {
            square: Square::new(),
            active: false,
        }
    }

    fn load(&mut self, _version: &str, _state: &State) {}
    fn save(&self, _state: &mut State) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Transform {
            position: (30, 25),
            size: (40, 40),
            child: Icon {
                path: "waveforms/square.svg",
                color: Color::BLUE,
            },
        })
    }

    fn prepare(&self, voice: &mut Self::Voice, sample_rate: u32, block_size: usize) {
        voice.active = false;
        voice.square.prepare(sample_rate, block_size);
    }

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        for msg in &inputs.events[0] {
            match msg.note {
                Event::NoteOn { pitch, pressure: _ } => {
                    voice.active = true;
                    voice.square.set_pitch(pitch);
                }
                Event::NoteOff => {
                    voice.active = false;
                }
                Event::Pitch(pitch) => {
                    voice.square.set_pitch(pitch);
                }
                _ => (),
            }
        }

        if voice.active {
            voice.square.generate_block(&mut outputs.audio[0]);

            for sample in outputs.audio[0].as_slice_mut() {
                sample.gain(0.1);
            }
        }
    }
}

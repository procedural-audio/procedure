use pa_dsp::loadable::{Loadable, Lock};

use crate::*;

pub struct Sampler {
    sample: Lock<SampleFile<Stereo<f32>>>,
    positions: [f32; 32],
    slider_1: f32,
    slider_2: f32,
    slider_3: f32,
    slider_4: f32
}

pub struct SamplerVoice {
    player: PitchedSamplePlayer<Stereo<f32>>,
    index: u32
}

impl Module for Sampler {
    type Voice = SamplerVoice;

    const INFO: Info = Info {
        title: "Sampler",
        id: "default.sampling.sampler",
        version: "0.0.0",
        color: Color::BLUE,
        size: Size::Static(280, 180),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Notes("Notes Input", 10)
        ],
        outputs: &[
            Pin::Audio("Audio Output", 10)
        ],
        path: &["Audio", "Sampling", "Sampler"],
        presets: Presets::NONE
    };

    fn new() -> Self {
        let path = if cfg!(target_os = "macos") {
            "/Users/chasekanipe/Music/Decent Samples/Flamenco Dreams Guitar/Samples/FlamencoDreams_55_C2_G_2.wav"
        } else if cfg!(target_os = "linux") {
            "/home/chase/guitar_samples/Samples/FlamencoDreams_55_C2_G_2.wav"
        } else {
            todo!()
        };

        return Self {
            sample: Lock::new(SampleFile::load(path).unwrap()),
            positions: [0.0; 32],
            slider_1: 0.5,
            slider_2: 0.5,
            slider_3: 0.5,
            slider_4: 0.5
        };
    }

    fn new_voice(&self, index: u32) -> Self::Voice {
        Self::Voice {
            player: PitchedSamplePlayer::new(),
            index
        }
    }

    fn load(&mut self, _version: &str, state: &State) {
        let path: String = state.load("sample");
        match SampleFile::load(&path) {
            Ok(sample) => {
                *self.sample.write() = sample;
            }
            Err(e) => {
                println!("Failed to load sample: {}", e);
            }
        }
    }

    fn save(&self, state: &mut State) {
        let path = self.sample.read().path().to_string();
        state.save("sample", path);
    }

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(
            Padding {
                padding: (5, 35, 5, 5),
                child: Background {
                    color: Color::rgb(20, 20, 20),
                    border: Border {
                        color: Color::rgb(20, 20, 20),
                        width: 0,
                        radius: 5
                    },
                    child: Column {
                        children: (
                            SizedBox {
                                size: (50, 30),
                                child: Row {
                                    children: (
                                        SizedBox {
                                            size: (60, 20),
                                            child: LabelSlider {
                                                value: &mut self.slider_1,
                                                color: Color::BLUE,
                                                text: | v | {
                                                    format!("{:.2} db", v)
                                                }
                                            }
                                        },
                                        SizedBox {
                                            size: (20, 20),
                                            child: LabelSlider {
                                                value: &mut self.slider_2,
                                                color: Color::BLUE,
                                                text: | v | {
                                                    let num = (v * 120.0).round() as usize;
                                                    let name = NOTE_NAMES[num];
                                                    format!("{}", name)
                                                }
                                            }
                                        }
                                    )
                                }
                            },
                            Expanded {
                                child: SampleViewer {
                                    sample: self.sample.clone()
                                }
                            }
                        )
                    }
                }
            }
        )
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        for msg in &inputs.events[0] {
            match msg.note {
                Event::NoteOn { pitch, pressure: _ } => {
                    if let Ok(sample) = self.sample.try_read() {
                        voice.player.set_sample(sample.clone());
                    } else {
                        println!("Couldn't update sample");
                    }

                    voice.player.set_pitch(pitch);
                    voice.player.play();
                },
                Event::NoteOff => {
                    voice.player.stop()
                },
                Event::Pitch(pitch) => {
                    voice.player.set_pitch(pitch)
                },
                _ => ()
            }
        }

        let i = voice.index as usize;
        if i < self.positions.len() {
            self.positions[i] = voice.player.progress();
        }

        voice.player.generate_block(&mut outputs.audio[0]);
    }
}

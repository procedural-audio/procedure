use std::sync::{Arc, RwLock};

use crate::*;

pub struct SampleRack {
    samples: [
        Arc<RwLock<SampleFile<Stereo2>>>; 12
    ],
    positions: [f32; 32]
}

pub struct SampleRackVoice {
    player: PitchedSamplePlayer<Stereo2>,
    index: u32
}

impl Module for SampleRack {
    type Voice = SampleRackVoice;

    const INFO: Info = Info {
        title: "Sample Rack",
        version: "0.0.0",
        color: Color::BLUE,
        size: Size::Static(10+80*4, 40+60*3),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Notes("Notes Input", 10)
        ],
        outputs: &[
            Pin::Audio("Audio Output", 10)
        ],
        path: "Audio Sources/Sampling/Sample Rack",
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

        let path2 = if cfg!(target_os = "macos") {
            "/Users/chasekanipe/Desktop/Iris.wav"
        } else if cfg!(target_os = "linux") {
            "/home/chase/guitar_samples/Samples/FlamencoDreams_55_C2_G_2.wav"
        } else {
            todo!()
        };

        let path3 = if cfg!(target_os = "macos") {
            "/Users/chasekanipe/Desktop/pad.wav"
        } else if cfg!(target_os = "linux") {
            "/home/chase/guitar_samples/Samples/FlamencoDreams_55_C2_G_2.wav"
        } else {
            todo!()
        };

        let path4 = if cfg!(target_os = "macos") {
            "/Users/chasekanipe/Desktop/Shimmer Pad.wav"
        } else if cfg!(target_os = "linux") {
            "/home/chase/guitar_samples/Samples/FlamencoDreams_55_C2_G_2.wav"
        } else {
            todo!()
        };

        let path5 = if cfg!(target_os = "macos") {
            "/Users/chasekanipe/Desktop/Spectrum.wav"
        } else if cfg!(target_os = "linux") {
            "/home/chase/guitar_samples/Samples/FlamencoDreams_55_C2_G_2.wav"
        } else {
            todo!()
        };

        return Self {
            samples: [
                Arc::new(RwLock::new(SampleFile::load(path))),
                Arc::new(RwLock::new(SampleFile::load(path2))),
                Arc::new(RwLock::new(SampleFile::load(path3))),
                Arc::new(RwLock::new(SampleFile::load(path4))),
                Arc::new(RwLock::new(SampleFile::load(path5))),
                Arc::new(RwLock::new(SampleFile::load(path))),
                Arc::new(RwLock::new(SampleFile::load(path))),
                Arc::new(RwLock::new(SampleFile::load(path))),
                Arc::new(RwLock::new(SampleFile::load(path))),
                Arc::new(RwLock::new(SampleFile::load(path))),
                Arc::new(RwLock::new(SampleFile::load(path))),
                Arc::new(RwLock::new(SampleFile::load(path))),
            ],
            positions: [0.0; 32]
        };
    }

    fn new_voice(&self, index: u32) -> Self::Voice {
        Self::Voice {
            player: PitchedSamplePlayer::new(),
            index
        }
    }

    fn load(&mut self, _version: &str, _state: &State) {}
    fn save(&self, _state: &mut State) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Padding {
            padding: (5, 35, 5, 0),
            child: Row {
                children: (
                    Column {
                        children: (
                            Padding {
                                padding: (0, 0, 5, 5),
                                child: Stack {
                                    children: (
                                        SampleFilePicker {
                                            sample: self.samples[0].clone()
                                        }
                                    )
                                }
                            },
                            Padding {
                                padding: (0, 0, 5, 5),
                                child: Stack {
                                    children: (
                                        SampleFilePicker {
                                            sample: self.samples[1].clone()
                                        }
                                    )
                                }
                            },
                            Padding {
                                padding: (0, 0, 5, 5),
                                child: Stack {
                                    children: (
                                        SampleFilePicker {
                                            sample: self.samples[2].clone()
                                        }
                                    )
                                }
                            }
                        )
                    },
                    Column {
                        children: (
                            Padding {
                                padding: (0, 0, 5, 5),
                                child: Stack {
                                    children: (
                                        SampleFilePicker {
                                            sample: self.samples[3].clone()
                                        }
                                    )
                                }
                            },
                            Padding {
                                padding: (0, 0, 5, 5),
                                child: Stack {
                                    children: (
                                        SampleFilePicker {
                                            sample: self.samples[4].clone()
                                        }
                                    )
                                }
                            },
                            Padding {
                                padding: (0, 0, 5, 5),
                                child: Stack {
                                    children: (
                                        SampleFilePicker {
                                            sample: self.samples[5].clone()
                                        }
                                    )
                                }
                            }
                        )
                    },
                    Column {
                        children: (
                            Padding {
                                padding: (0, 0, 5, 5),
                                child: Stack {
                                    children: (
                                        SampleFilePicker {
                                            sample: self.samples[6].clone()
                                        }
                                    )
                                }
                            },
                            Padding {
                                padding: (0, 0, 5, 5),
                                child: Stack {
                                    children: (
                                        SampleFilePicker {
                                            sample: self.samples[7].clone()
                                        }
                                    )
                                }
                            },
                            Padding {
                                padding: (0, 0, 5, 5),
                                child: Stack {
                                    children: (
                                        SampleFilePicker {
                                            sample: self.samples[8].clone()
                                        }
                                    )
                                }
                            }
                        )
                    },
                    Column {
                        children: (
                            Padding {
                                padding: (0, 0, 5, 5),
                                child: Stack {
                                    children: (
                                        SampleFilePicker {
                                            sample: self.samples[9].clone()
                                        }
                                    )
                                }
                            },
                            Padding {
                                padding: (0, 0, 5, 5),
                                child: Stack {
                                    children: (
                                        SampleFilePicker {
                                            sample: self.samples[10].clone()
                                        }
                                    )
                                }
                            },
                            Padding {
                                padding: (0, 0, 5, 5),
                                child: Stack {
                                    children: (
                                        SampleFilePicker {
                                            sample: self.samples[11].clone()
                                        }
                                    )
                                }
                            }
                        )
                    }
                )
            }
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        for msg in &inputs.events[0] {
            match msg.note {
                Event::NoteOn { pitch, pressure: _ } => {
                    let num = pitch_to_num(pitch) as usize % 12;
                    if let Ok(sample) = self.samples[num].try_read() {
                        voice.player.set_sample(sample.clone());
                    } else {
                        println!("Couldn't update sample");
                    }

                    voice.player.set_pitch(pitch);
                    voice.player.play();
                },
                Event::NoteOff => voice.player.stop(),
                Event::Pitch(pitch) => voice.player.set_pitch(pitch),
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

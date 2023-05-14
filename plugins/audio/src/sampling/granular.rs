use std::sync::{Arc, RwLock};
use modules::loadable::Loadable;
use rand::{rngs::ThreadRng, Rng};
use rlua::Thread;

use crate::*;

pub struct Granular {
    sample: Arc<RwLock<SampleFile<Stereo2<f32>>>>,
    positions: [f32; 32],
    buffer: StereoBuffer,
    rng: ThreadRng,
    grain_position: f32,
    grain_spread: f32,
    grain_count: f32,
    grain_length: f32
}

pub struct GranularVoice {
    players: [GranularSamplePlayer<Stereo2<f32>>; 32],
    index: u32
}

impl Module for Granular {
    type Voice = GranularVoice;

    const INFO: Info = Info {
        title: "Granular",
        id: "default.sampling.granular",
        version: "0.0.0",
        color: Color::BLUE,
        size: Size::Static(300, 240),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Notes("Notes Input", 10+25*0),
            Pin::Control("Position", 10+25*1),
            Pin::Control("Spread", 10+25*2),
            Pin::Control("Count", 10+25*3),
            Pin::Control("Length", 10+25*4),
        ],
        outputs: &[
            Pin::Audio("Audio Output", 10)
        ],
        path: &["Audio", "Sampling", "Granular"],
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
            sample: Arc::new(RwLock::new(SampleFile::load(path).unwrap())),
            buffer: StereoBuffer::init(Stereo2 {left: 0.0, right: 0.0 }, 512),
            rng: rand::thread_rng(),
            positions: [0.0; 32],
            grain_position: 0.0,
            grain_spread: 0.2,
            grain_count: 1.0,
            grain_length: 1.0
        };
    }

    fn new_voice(&self, index: u32) -> Self::Voice {
        Self::Voice {
            players: [
                GranularSamplePlayer::new(), GranularSamplePlayer::new(),
                GranularSamplePlayer::new(), GranularSamplePlayer::new(),
                GranularSamplePlayer::new(), GranularSamplePlayer::new(),
                GranularSamplePlayer::new(), GranularSamplePlayer::new(),
                GranularSamplePlayer::new(), GranularSamplePlayer::new(),
                GranularSamplePlayer::new(), GranularSamplePlayer::new(),
                GranularSamplePlayer::new(), GranularSamplePlayer::new(),
                GranularSamplePlayer::new(), GranularSamplePlayer::new(),
                GranularSamplePlayer::new(), GranularSamplePlayer::new(),
                GranularSamplePlayer::new(), GranularSamplePlayer::new(),
                GranularSamplePlayer::new(), GranularSamplePlayer::new(),
                GranularSamplePlayer::new(), GranularSamplePlayer::new(),
                GranularSamplePlayer::new(), GranularSamplePlayer::new(),
                GranularSamplePlayer::new(), GranularSamplePlayer::new(),
                GranularSamplePlayer::new(), GranularSamplePlayer::new(),
                GranularSamplePlayer::new(), GranularSamplePlayer::new(),
            ],
            index
        }
    }

    fn load(&mut self, _version: &str, _state: &State) {}
    fn save(&self, _state: &mut State) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(
            Stack {
                children: (
                    /*Padding {
                        padding: (35, 35, 10, 85),
                        child: SampleEditor {
                            sample: self.sample.clone()
                        }
                    },*/
                    Padding {
                        padding: (10, 35+130, 5, 5),
                        child: Row {
                            children: (
                                Knob {
                                    text: "Position",
                                    color: Color::BLUE,
                                    value: &mut self.grain_position,
                                    feedback: Box::new(| _v | { String::new() })
                                },
                                Knob {
                                    text: "Spread",
                                    color: Color::BLUE,
                                    value: &mut self.grain_spread,
                                    feedback: Box::new(| _v | { String::new() })
                                },
                                Knob {
                                    text: "Count",
                                    color: Color::BLUE,
                                    value: &mut self.grain_count,
                                    feedback: Box::new(| _v | { String::new() })
                                },
                                Knob {
                                    text: "Length",
                                    color: Color::BLUE,
                                    value: &mut self.grain_length,
                                    feedback: Box::new(| _v | { String::new() })
                                }
                            )
                        }
                    }
                )
            }
        )
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        for msg in &inputs.events[0] {
            match msg.note {
                Event::NoteOn { pitch, pressure: _ } => {
                    if let Ok(sample) = self.sample.try_read() {
                        for player in &mut voice.players {
                            player.set_sample(sample.clone());
                            player.play(self.grain_position, self.grain_spread, self.grain_length);
                        }
                    } else {
                        println!("Couldn't update sample");
                    }

                    for player in &mut voice.players {
                        player.set_pitch(pitch);
                    }
                },
                Event::NoteOff => {
                    for player in &mut voice.players {
                        player.stop();
                    }
                },
                Event::Pitch(pitch) => {
                    for player in &mut voice.players {
                        player.set_pitch(pitch);
                    }
                },
                _ => ()
            }
        }

        let mut i = 0.0;
        for player in &mut voice.players {
            if i / 32.0 > self.grain_count {
                break;
            }

            player.update(self.grain_position, self.grain_length);
            player.generate_block(&mut self.buffer);
            outputs.audio[0].add_from(&self.buffer);

            i += 1.0;
        }
    }
}

use std::sync::{Arc, RwLock};

use crate::*;

pub struct AudioTrack {
    sample: Arc<RwLock<SampleFile<Stereo2>>>,
    player: SamplePlayer<Stereo2>,
    rate: u32
}

pub struct AudioTrackVoice {
    index: u32,
    rate: u32
}

impl Module for AudioTrack {
    type Voice = AudioTrackVoice;

    const INFO: Info = Info {
        title: "Audio Track",
        version: "0.0.0",
        color: Color::BLUE,
        size: Size::Static(500, 150),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Time("Time", 10)
        ],
        outputs: &[
            Pin::Audio("Audio Output", 10)
        ],
        path: "Category 1/Category 2/Module Name"
    };

    fn new() -> Self {
        let path = if cfg!(target_os = "macos") {
            "/Users/chasekanipe/Desktop/Iris.wav"
        } else if cfg!(target_os = "linux") {
            todo!()
        } else {
            todo!()
        };

        let sample = SampleFile::load(path);
        let mut player = SamplePlayer::new();

        player.set_sample(sample.clone());
        player.play();
        let rate = 0;

        let sample = Arc::new(RwLock::new(sample));

        return Self { player, sample, rate };
    }

    fn new_voice(&self, index: u32) -> Self::Voice {
        Self::Voice {
            index,
            rate: 0
        }
    }

    fn load(&mut self, _json: &JSON) {}
    fn save(&self, _json: &mut JSON) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Stack {
            children: (Padding {
                padding: (5, 35, 5, 5),
                child: SampleFilePicker {
                    sample: self.sample.clone()
                }
            })
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        if voice.index == 0 {
            inputs.time[0].on_each(64.0 * 8.0, | beat | {
                self.player.set_playback_sample(0);
            });

            self.player.generate_block(&mut outputs.audio[0]);
        }
    }
}
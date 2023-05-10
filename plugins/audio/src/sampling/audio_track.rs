use std::sync::{Arc, RwLock};

use modules::loadable::Loadable;

use crate::*;

pub struct AudioTrack {
    sample: Arc<RwLock<SampleFile<Stereo2>>>,
    player: PitchedSamplePlayer<Stereo2>,
    rate: u32,
    position: f32
}

pub struct AudioTrackVoice {
    index: u32,
    rate: u32
}

impl Module for AudioTrack {
    type Voice = AudioTrackVoice;

    const INFO: Info = Info {
        title: "Audio Track",
        id: "default.sampling.audio_track",
        version: "0.0.0",
        color: Color::BLUE,
        size: Size::Static(600, 150),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Time("Time", 10)
        ],
        outputs: &[
            Pin::Audio("Audio Output", 10)
        ],
        path: &["Audio", "Sampling", "Audio Track"],
        presets: Presets::NONE
    };

    fn new() -> Self {
        let path = if cfg!(target_os = "macos") {
            // "/Users/chasekanipe/Desktop/Iris.wav"
            "/Users/chasekanipe/Desktop/Spectrum.wav"
        } else if cfg!(target_os = "linux") {
            todo!()
        } else {
            todo!()
        };

        let sample = SampleFile::load(path).unwrap();
        let mut player = PitchedSamplePlayer::new();

        player.set_sample(sample.clone());
        player.play();
        let rate = 0;
        let position = 0.0;

        let sample = Arc::new(RwLock::new(sample));

        return Self { player, sample, rate, position };
    }

    fn new_voice(&self, index: u32) -> Self::Voice {
        Self::Voice {
            index,
            rate: 0
        }
    }

    fn load(&mut self, _version: &str, _state: &State) {}
    fn save(&self, _state: &mut State) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Padding {
            padding: (5, 35, 5, 5),
            child: Stack {
                children: (
                    SampleFilePicker {
                        sample: self.sample.clone()
                    },
                    Painter {
                        paint: | canvas | {
                            canvas.draw_line(
                                (canvas.width * self.position, 0.0),
                                (canvas.width * self.position, canvas.height),
                                Paint::new());
                        }
                    }
                )
            }
        })
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        if voice.index == 0 {
            let time = inputs.time[0];
            let start = time.start_sample(120.0, 44100);
            self.player.set_position(start);

            if self.player.playing() {
                self.position = self.player.progress();
            }

            self.player.set_speed(inputs.time[0].get_rate());
            self.player.generate_block(&mut outputs.audio[0]);
        }
    }
}
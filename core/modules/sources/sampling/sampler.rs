use std::sync::{Arc, RwLock};

use crate::*;

pub struct Sampler {
    sample: Arc<RwLock<SampleFile<Stereo2>>>,
    position: f32
}

pub struct SamplerVoice {
    player: PitchedSamplePlayer<Stereo2>,
    index: u32
}

impl Module for Sampler {
    type Voice = SamplerVoice;

    const INFO: Info = Info {
        title: "Sampler",
        version: "0.0.0",
        color: Color::BLUE,
        size: Size::Static(300, 150),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Notes("Notes Input", 10)
        ],
        outputs: &[
            Pin::Audio("Audio Output", 10)
        ],
        path: "Category 1/Category 2/Module Name"
    };

    fn new() -> Self {
        let path = if cfg!(target_os = "macos") {
            "/Users/chasekanipe/guitar_samples/Samples/FlamencoDreams_55_C2_G_2.wav"
        } else if cfg!(target_os = "linux") {
            "/home/chase/guitar_samples/Samples/FlamencoDreams_55_C2_G_2.wav"
        } else {
            todo!()
        };

        return Self {
            sample: Arc::new(RwLock::new(SampleFile::load(path))),
            position: 0.0
        };
    }

    fn new_voice(&self, index: u32) -> Self::Voice {
        Self::Voice {
            player: PitchedSamplePlayer::new(),
            index
        }
    }

    fn load(&mut self, _json: &JSON) {}
    fn save(&self, _json: &mut JSON) {}

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
                Event::NoteOff => voice.player.stop(),
                Event::Pitch(pitch) => voice.player.set_pitch(pitch / 440.0),
                _ => ()
            }
        }

        if voice.player.playing() {
            self.position = voice.player.progress();
        }

        voice.player.generate_block(&mut outputs.audio[0]);
    }
}
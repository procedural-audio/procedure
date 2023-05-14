use crate::*;

use pa_dsp::loadable::{Loadable, Lock};

pub struct MultiSampler {
    map: Lock<SampleMap>,
}

impl Module for MultiSampler {
    type Voice = PitchedSamplePlayer<Stereo2<f32>>;

    const INFO: Info = Info {
        title: "Multi-Sampler",
        id: "default.sampling.multisampler",
        version: "0.0.0",
        color: Color::BLUE,
        size: Size::Static(600, 400),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Notes("Midi Input", 10)
        ],
        outputs: &[
            Pin::Audio("Audio Output", 10)
        ],
        path: &["Audio", "Sampling", "Multi-Sampler"],
        presets: Presets {
            path: "multi-samples",
            extension: ".multisample"
        }
    };

    fn new() -> Self {
        Self {
            map: Lock::new(SampleMap::new()),
        }
    }

    fn new_voice(&self, _index: u32) -> Self::Voice {
        PitchedSamplePlayer::new()
    }

    fn load(&mut self, version: &str, state: &State) {
        // *self.map.write().unwrap() = state.load("map");
    }

    fn save(&self, state: &mut State) {
        // state.save("map", *self.map.read().unwrap());
    }

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        return Box::new(
            Padding {
                padding: (5, 35, 5, 5),
                child: Browser {
                    loadable: self.map.clone(),
                    directory: Directory::SAMPLES,
                    extensions: &[".multisample", ".dspreset"],
                    child: Scripter {
                        dir: "directory/goes/here",
                        on_update: | script | {
                            println!("Update script with {}", script);
                        },
                        child: SampleMapper {
                            map: self.map.clone(),
                        }
                    }
                }
            }
        );
    }

    fn prepare(&self, voice: &mut Self::Voice, sample_rate: u32, block_size: usize) {
        voice.prepare(sample_rate, block_size);
    }

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        for msg in &inputs.events[0] {
            match msg.note {
                Event::NoteOn { pitch, pressure: _ } => {
                    /*if let Ok(map) = self.map.try_read() {
                        for region in &map.regions {
                            let num = pitch_to_num(pitch);
                            if region.low_note <= num && region.high_note >= num {
                                println!("Playing note {}", num);
                                voice.set_sample(region.sounds[0].clone());
                                voice.set_pitch(pitch);
                                voice.play();
                                break;
                            }
                        }
                    }*/
                },
                Event::NoteOff => voice.stop(),
                Event::Pitch(pitch) => voice.set_pitch(pitch),
                _ => ()
            }
        }

        voice.generate_block(&mut outputs.audio[0]);
    }
}

pub struct MySampler {
    pub map: Lock<SampleMap>,
}

impl MySampler {
    pub fn new() -> Self {
        Self {
            map: Lock::new(SampleMap::new()),
        }
    }
}

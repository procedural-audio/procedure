use pa_dsp::loadable::{Loadable, Lock};

use crate::*;

pub struct Convolution {
    sample: Lock<SampleFile<Stereo<f32>>>,
    positions: [f32; 32]
}

pub struct ConvolutionVoice {
    player: PitchedSamplePlayer<Stereo<f32>>,
    index: u32
}

impl Module for Convolution {
    type Voice = ConvolutionVoice;

    const INFO: Info = Info {
        title: "Sampler",
        id: "default.sampling.sampler",
        version: "0.0.0",
        color: Color::BLUE,
        size: Size::Static(300, 200),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Notes("Notes Input", 10)
        ],
        outputs: &[
            Pin::Audio("Audio Output", 10)
        ],
        path: &["Audio", "Sampling", "Convolver"]
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
            positions: [0.0; 32]
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
        *self.sample.write() = SampleFile::load(&path).unwrap();
    }

    fn save(&self, state: &mut State) {
        let path = self.sample.read().path().to_string();
        state.save("sample", path);
    }

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        Box::new(Padding {
            padding: (5, 35, 5, 5),
            child: Browser {
                loadable: self.sample.clone(),
                directory: Directory::SAMPLES,
                extensions: &[".wav", ".mp3"],
                child: Stack {
                    children: (
                        SampleViewer {
                            sample: self.sample.clone(),
                        }
                        /*Painter {
                            paint: | canvas | {
                                for position in self.positions {
                                    if position != 0.0 {
                                        canvas.draw_line(
                                            (canvas.width * position, 0.0),
                                            (canvas.width * position, canvas.height),
                                            Paint::new()
                                        );
                                    }
                                }
                            }
                        }*/
                    )
                }
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

fn dot_product<F: Sample>(xs: &[F], ys: &[F]) -> F {
    xs.iter()
        .zip(ys)
        .fold(F::EQUILIBRIUM, |acc, (&x, &y)| acc + x * y)
}

fn convolve<F: Sample>(sample: &[F], coeff: &[F], output: &mut [F]) {
    sample
        .windows(coeff.len())
        .map(|window| {
            window
                .iter()
                .zip(coeff)
                .fold(F::EQUILIBRIUM, |acc, (&x, &y)| acc + x * y)
        })
        .zip(output)
        .for_each(
            | (o, s) | {
                *s = o
            }
        );
}
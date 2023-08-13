use std::marker::PhantomData;

use pa_algorithms::waveshaper;
use pa_dsp::*;
use pa_algorithms::*;
use crate::*;

pub struct Waveshaper {
    selected: usize,
    gain: f32,
    gain2: f32,
}

fn shape_0<F: Frame> (x: F) -> F {
    let x = x * F::from(2.0 * std::f32::consts::PI);
    F::apply(x, f32::atan)
}

// https://www.musicdsp.org/en/latest/Effects/41-waveshaper.html
fn shape_1(x: f32, p: f32) -> f32 {
    x * (f32::abs(x) + p) / (x * x + (p - 1.0) * f32::abs(x) + 1.0)
}

// https://www.musicdsp.org/en/latest/Effects/43-waveshaper.html
fn shape_2(x: f32, p: f32) -> f32 {
    let z = std::f32::consts::PI * p;
    let s = 1.0 / f32::sin(z);
    let b = 1.0 / p;

    if x > b {
        1.0
    } else {
        f32::sin(z * x) * s
    }
}

// https://www.musicdsp.org/en/latest/Effects/46-waveshaper.html
// p ranges from -1 to 1
fn shape_3(x: f32, p: f32) -> f32 {
    let k = 2.0 * p / (1.0 - p);
    (1.0 + k) * x / (1.0 + k * f32::abs(x))
}

// https://www.musicdsp.org/en/latest/Effects/114-waveshaper-simple-description.html
fn shape_4(x: f32, p: f32) -> f32 {
    1.5 * x - 0.5 * x * x * x
}

impl Module for Waveshaper {
    type Voice = ();

    const INFO: Info = Info {
        title: "Waveshaper",
        id: "default.effects.distortion.waveshaper",
        version: "0.0.0",
        color: Color::BLUE,
        size: Size::Static(335, 170),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Audio("Audio Input", 20),
            Pin::Control("Knob 1", 50),
            Pin::Control("Knob 2", 80),
        ],
        outputs: &[Pin::Audio("Audio Output", 20)],
        path: &["Audio", "Distortion", "Waveshaper"],
        presets: Presets::NONE
    };
    
    fn new() -> Self {
        Self {
            selected: 0,
            gain: 1.0,
            gain2: 0.0,
        }
    }

    fn new_voice(&self, _index: u32) -> Self::Voice {
        ()
    }

    fn load(&mut self, _version: &str, _state: &State) {}
    fn save(&self, _state: &mut State) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        let selected_ptr = (&self.selected) as *const usize;
        let gain_ptr = (&self.gain) as *const f32;
        Box::new(
            Stack {
                children: (
                    Transform {
                        position: (35, 35),
                        size: (50, 70),
                        child: Knob {
                            text: "Gain",
                            color: Color::BLUE,
                            value: &mut self.gain,
                            feedback: Box::new(| v| {
                                format!("{:.1} dB", linear_to_db(v))
                            })
                        }
                    },
                    Transform {
                        position: (35 + 60, 35),
                        size: (50, 70),
                        child: Knob {
                            text: "Shape",
                            color: Color::BLUE,
                            value: &mut self.gain2,
                            feedback: Box::new(|_v| String::new())
                        }
                    },
                    Transform {
                        position: (35, 115),
                        size: (115, 40),
                        child: Dropdown {
                            index: &mut self.selected,
                            color: Color::BLUE,
                            elements: &[
                                "Shaper 1",
                                "Shaper 2",
                                "Shaper 3",
                                "Shaper 4",
                                "Shaper 5",
                            ],
                        },
                    },
                    Transform {
                        position: (160, 35),
                        size: (140, 120),
                        child: Background {
                            color: Color(0xff141414),
                            border: Border::radius(5),
                            child: Painter2 {
                                width: 2,
                                color: Color::BLUE,
                                paint: move | x | {
                                    unsafe {
                                        let x = x * 2.0 * std::f32::consts::PI;
                                        match *selected_ptr {
                                            0 => shape_0(x * *gain_ptr) / 2.0 + 0.5,
                                            1 => f32::cos(x) / 2.0 * *gain_ptr + 0.5,
                                            2 => f32::atan(x * *gain_ptr) / 2.0,
                                            _ => f32::atan(x * *gain_ptr) / 2.0
                                        }
                                    }
                                }
                            }
                        }
                    }
                )
            }
        )
    }

    fn prepare(&self, _voice: &mut Self::Voice, _sample_rate: u32, _block_size: usize) {}

    fn process(&mut self, _voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        let gain = db_to_gain(linear_to_db(self.gain));
        match self.selected {
            0 => (waveshaper(Stereo2::tan)).process_block(&inputs.audio[0], &mut outputs.audio[0]),
            1 => (waveshaper(Stereo2::sin)).process_block(&inputs.audio[0], &mut outputs.audio[0]),
            _ => (),
        }
        
        // input(&inputs.audio[0]) >> waveshaper(Stereo2::sin);
    }
}

use crate::*;

use pa_dsp::buffers::*;



pub struct AnalogOscillator {
    wave_index: u32,
    unison: f32,
    detune: f32,
    spread: f32,
    glide: f32,
    dropdown: u32,
}

pub struct OscillatorVoice {
    /*saws: Vec<Saw>,
    squares: Vec<Square>,
    sines: Vec<Sine>,
    triangles: Vec<Triangle>,*/
    buffer1: AudioBuffer,
    buffer2: AudioBuffer,
    freq: f32,
}

impl Module for AnalogOscillator {
    type Voice = OscillatorVoice;

    const INFO: Info = Info {
        title: "Analog Oscillator",
        version: "0.0.0",
        color: Color::BLUE,
        size: Size::Static(310, 200),
        voicing: Voicing::Polyphonic,
        inputs: &[
            Pin::Notes("Midi Input", 20),
            Pin::Control("Control 1", 50),
            Pin::Control("Control 2", 80),
            Pin::Control("Control 3", 110),
            Pin::Control("Control 4", 140),
        ],
        outputs: &[
            Pin::Audio("Audio Output", 20),
            Pin::Audio("Audio Output", 50)
        ],
        path: "Category 1/Category 2/Module Name"
    };

    fn new() -> Self {
        Self {
            wave_index: 0,
            unison: 2.0,
            detune: 0.0,
            spread: 0.0,
            glide: 0.0,
            dropdown: 0,
        }
    }

    fn new_voice(&self, index: u32) -> Self::Voice {
        println!("Created voice {}", index);

        Self::Voice {
            /*saws: vec![Saw::new(); 8],
            squares: vec![Square::new(); 8],
            sines: vec![Sine::new(); 8],
            triangles: vec![Triangle::new(); 8],*/
            buffer1: AudioBuffer::init(0.0, 512),
            buffer2: AudioBuffer::init(0.0, 512),
            freq: 100.0,
        }
    }

    fn load(&mut self, _state: &State) {}
    fn save(&self, _state: &mut State) {}

    fn build<'w>(&'w mut self) -> Box<dyn WidgetNew + 'w> {
        let size = 50;

        return Box::new(Stack {
            children: (
                Positioned {
                    position: (40 + size * 0, 40 + size * 0),
                    child: SizedBox {
                        size: (50, 50),
                        child: SvgButton {
                            path: "waveforms/saw.svg",
                            pressed: self.wave_index == 1,
                            color: Color::BLUE,
                            on_changed: Box::new(|pressed| {
                                println!("Saw is {}", pressed);
                                if pressed {
                                    unsafe {
                                        *((&self.wave_index as *const u32) as *mut u32) = 0;
                                    }

                                    //ui.refresh();
                                }
                            }),
                        },
                    },
                },
                Positioned {
                    position: (40 + size * 1, 40 + size * 0),
                    child: SizedBox {
                        size: (50, 50),
                        child: SvgButton {
                            path: "waveforms/square.svg",
                            pressed: self.wave_index == 2,
                            color: Color::BLUE,
                            on_changed: Box::new(|pressed| {
                                if pressed {
                                    unsafe {
                                        *((&self.wave_index as *const u32) as *mut u32) = 1;
                                    }

                                    //ui.refresh();
                                }
                            }),
                        },
                    },
                },
                Positioned {
                    position: (40 + size * 0, 40 + size * 1),
                    child: SizedBox {
                        size: (50, 50),
                        child: SvgButton {
                            path: "waveforms/sine.svg",
                            pressed: self.wave_index == 3,
                            color: Color::BLUE,
                            on_changed: Box::new(|pressed| {
                                if pressed {
                                    unsafe {
                                        *((&self.wave_index as *const u32) as *mut u32) = 2;
                                    }

                                    //ui.refresh();
                                }
                            }),
                        },
                    },
                },
                Positioned {
                    position: (40 + size * 1, 40 + size * 1),
                    child: SizedBox {
                        size: (50, 50),
                        child: SvgButton {
                            path: "waveforms/triangle.svg",
                            pressed: self.wave_index == 4,
                            color: Color::BLUE,
                            on_changed: Box::new(|pressed| {
                                if pressed {
                                    unsafe {
                                        *((&self.wave_index as *const u32) as *mut u32) = 3;
                                    }

                                    //ui.refresh();
                                }
                            }),
                        },
                    },
                },
                Transform {
                    position: (55, 40 + 100),
                    size: (70, 40),
                    child: Dropdown {
                        index: &mut self.dropdown,
                        color: Color::BLUE,
                        elements: &["Thick", "Thin", "Repro", "Classic"],
                    },
                },
                Transform {
                    position: (60 + size * 2, 40 + size * 0),
                    size: (60, 70),
                    child: Knob {
                        text: "Unison",
                        color: Color::BLUE,
                        value: &mut self.unison,
                        feedback: Box::new(|value| {
                            let mut unison = value * 6.0 + 2.0;

                            if unison < 1.0 {
                                unison = 1.0;
                            }

                            if unison > 8.0 {
                                unison = 8.0;
                            }

                            format!("{:.2}", unison)
                        }),
                    },
                },
                Transform {
                    position: (60 + size * 3 + 10, 40 + size * 0),
                    size: (60, 70),
                    child: Knob {
                        text: "Detune",
                        color: Color::BLUE,
                        value: &mut self.detune,
                        feedback: Box::new(|_value| String::new()),
                    },
                },
                Transform {
                    position: (60 + size * 2, 40 + 70 * 1),
                    size: (60, 70),
                    child: Knob {
                        text: "Spread",
                        color: Color::BLUE,
                        value: &mut self.spread,
                        feedback: Box::new(|_value| String::new()),
                    },
                },
                Transform {
                    position: (60 + size * 3 + 10, 40 + 70 * 1),
                    size: (60, 70),
                    child: Knob {
                        text: "Glide",
                        color: Color::BLUE,
                        value: &mut self.glide,
                        feedback: Box::new(|_value| String::new()),
                    },
                },
            ),
        });
    }

    fn prepare(&self, voice: &mut Self::Voice, sample_rate: u32, block_size: usize) {
        println!("Preparing oscillator with rate {}", sample_rate);

        // voice.buffer1 = AudioBuffer::init(Stereo2 { left: 0.0, right: 0.0 }, block_size);
        // voice.buffer2 = AudioBuffer::init(Stereo2 { left: 0.0, right: 0.0 }, block_size);

        /*for osc in &mut voice.saws {
            osc.prepare(sample_rate, block_size);
        }

        for osc in &mut voice.squares {
            osc.prepare(sample_rate, block_size);
        }

        for osc in &mut voice.sines {
            osc.prepare(sample_rate, block_size);
        }

        for osc in &mut voice.triangles {
            osc.prepare(sample_rate, block_size);
        }*/
    }

    fn process(&mut self, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        let mut unison = self.unison * 6.0 + 2.0;

        if unison < 1.0 {
            unison = 1.0;
        }

        if unison > 8.0 {
            unison = 8.0;
        }

        /*for event in &inputs.events[0] {
            match event {
                Event::NoteOn { note, offset: _ } => {
                    voice.freq = note.pitch;
                }
                Event::NoteOff { id: _ } => {}
                Event::Pitch { id: _, freq: _ } => {}
                Event::Pressure { id: _, pressure: _ } => {}
                Event::Controller { id: _, value: _ } => {}
                Event::ProgramChange { id: _, value: _ } => {}
                Event::None => {}
            }
        }*/

        /*if self.wave_index == 0 {
            let osc_count = unison as usize;
            for index in 0..osc_count {
                let saw = &mut voice.saws[index];

                let input = &voice.buffer1.as_array();
                let output = &mut voice.buffer2.as_array_mut();

                let freq = voice.freq + ((index as f32 - 4.0) * self.detune);

                saw.set_param(0, freq); // Freqency
                saw.set_param(1, 0.5); // Pan
                saw.set_param(2, 0.5); // Glide

                saw.process(input, output);

                /* Fade up last osc */
                if index == osc_count - 1 {
                    let m = unison - (osc_count as f32);
                    for sample in &mut voice.buffer2 {
                        *sample = *sample * m;
                    }
                }

                let pan = 1.0 - (index as f32 / 7.0) * self.spread;

                if index % 2 == 0 {
                    outputs.audio[0].left.add_from(&voice.buffer2);
                    voice.buffer2.gain(pan);
                    outputs.audio[0].right.add_from(&voice.buffer2);
                } else {
                    outputs.audio[0].right.add_from(&voice.buffer2);
                    voice.buffer2.gain(pan);
                    outputs.audio[0].left.add_from(&voice.buffer2);
                }
            }
        } else if self.wave_index == 1 {
            let osc_count = unison as usize;
            for index in 0..osc_count {
                let saw = &mut voice.squares[index];

                let input = &voice.buffer1.as_array();
                let output = &mut voice.buffer2.as_array_mut();

                let freq = voice.freq + ((index as f32 - 4.0) * self.detune);

                saw.set_param(0, freq); // Freqency
                saw.set_param(1, 0.5); // Pan
                saw.set_param(2, 0.5); // Glide

                saw.process(input, output);

                /* Fade up last osc */
                if index == osc_count - 1 {
                    let m = unison - (osc_count as f32);
                    for sample in &mut voice.buffer2 {
                        *sample = *sample * m;
                    }
                }

                outputs.audio[0].left.add_from(&voice.buffer2);
                outputs.audio[0].right.add_from(&voice.buffer2);
            }
        } else if self.wave_index == 2 {
            let osc_count = unison as usize;
            for index in 0..osc_count {
                let saw = &mut voice.sines[index];

                let input = &voice.buffer1.as_array();
                let output = &mut voice.buffer2.as_array_mut();

                let freq = voice.freq + ((index as f32 - 4.0) * self.detune);

                saw.set_param(0, freq); // Freqency
                saw.set_param(1, 0.5); // Pan
                saw.set_param(2, 0.5); // Glide

                saw.process(input, output);

                /* Fade up last osc */
                if index == osc_count - 1 {
                    let m = unison - (osc_count as f32);
                    for sample in &mut voice.buffer2 {
                        *sample = *sample * m;
                    }
                }

                outputs.audio[0].left.add_from(&voice.buffer2);
                outputs.audio[0].right.add_from(&voice.buffer2);
            }
        } else if self.wave_index == 3 {
            let osc_count = unison as usize;
            for index in 0..osc_count {
                let saw = &mut voice.triangles[index];

                let input = &voice.buffer1.as_array();
                let output = &mut voice.buffer2.as_array_mut();

                let freq = voice.freq + ((index as f32 - 4.0) * self.detune);

                saw.set_param(0, freq); // Freqency
                saw.set_param(1, 0.5); // Pan
                saw.set_param(2, 0.5); // Glide

                saw.process(input, output);

                /* Fade up last osc */
                if index == osc_count - 1 {
                    let m = unison - (osc_count as f32);
                    for sample in &mut voice.buffer2 {
                        *sample = *sample * m;
                    }
                }

                outputs.audio[0].left.add_from(&voice.buffer2);
                outputs.audio[0].right.add_from(&voice.buffer2);
            }
        }*/
    }
}

/*faust!(Saw,
    freq = hslider("freq[style:numerical]", 500, 200, 12000, 0.001) : si.smoo;
    pan = hslider("pan[style:numerical]", 0.5, 0, 1, 0.001) : si.smoo;
    glide = hslider("glide[style:numerical]", 0.5, 0, 1, 0.001) : si.smoo;
    //drift = hslider("drift[style:numerical]", 0.5, 0, 1, 0.001) : si.smoo;

    driftosc = os.lf_triangle(0.5) * 0.005 + 1;
    process = os.sawtooth(freq);
);

faust!(Square,
    freq = hslider("freq[style:numerical]", 500, 200, 12000, 0.001) : si.smoo;
    driftosc = os.lf_triangle(0.5) * 0.01 + 1;
    process = _ + os.square(freq * driftosc);
);

faust!(Sine,
    freq = hslider("freq[style:numerical]", 500, 200, 12000, 0.001) : si.smoo;
    process = _ + os.osc(freq);
);

faust!(Triangle,
    freq = hslider("freq[style:numerical]", 500, 200, 12000, 0.001) : si.smoo;
    process = _ + os.triangle(freq);
);*/
use crate::modules::*;

pub struct LfoModule {
    wave: usize,
    value: f32,
    // buttons: [[bool; 2]; 2]
}

pub struct LfoVoice {
    saw: Lfo,
    square: Lfo,
    sine: Lfo,
    triangle: Lfo,
    last_reset: f32,
}

impl Module for LfoModule {
    type Voice = LfoVoice;

    const INFO: Info = Info {
        name: "LFO",
                color: Color::RED,
        size: Size::Static(250, 140),
        voicing: Voicing::Monophonic,
        params: &[],
        inputs: &[
            Pin::Control("LFO Rate (hz)", 15),
            Pin::Control("Reset (trigger)", 45),
        ],
        outputs: &[
            Pin::Control("LFO Output", 15)
        ],
    };

    fn new() -> Self {
        Self {
            wave: 0,
            value: 0.5,
            // buttons: [[true, false], [false, false]]
        }
    }

    fn new_voice(_index: u32) -> Self::Voice {
        use std::f32::consts::PI;

        Self::Voice {
            saw: Lfo::from(|x| {
                let x = x % (2.0 * PI);

                x / PI - 1.0
            }),
            square: Lfo::from(|x| {
                let x = x % (2.0 * PI);

                if x < PI {
                    -1.0
                } else {
                    1.0
                }
            }),
            sine: Lfo::from(f32::sin),
            triangle: Lfo::from(|x| {
                let x = x % (2.0 * PI);

                if x < PI {
                    x / PI * 2.0 - 1.0
                } else {
                    -(x / PI * 2.0 - 1.0)
                }
            }),
            last_reset: 0.0,
        }
    }

    fn load(&mut self, _json: &JSON) {}

    fn save(&self, _json: &mut JSON) {}

    fn build<'w>(&'w mut self, _ui: &'w UI) -> Box<dyn WidgetNew + 'w> {
        Box::new(Stack {
            children: (
                Transform {
                    position: (40, 30),
                    size: (100, 100),
                    /*child: GridBuilder {
                        state: &self.buttons,
                        builder: | index | {
                            return Button {
                                pressed: self.wave == index,
                                toggle: true,
                                on_changed: | value | {
                                },
                                child: if index == 0 {
                                    Svg { path: "path/here", color: Color::RED }
                                } else if index == 1 {
                                    Svg { path: "path/here", color: Color::RED }
                                } else if index == 2 {
                                    Svg { path: "path/here", color: Color::RED }
                                } else {
                                    Svg { path: "path/here", color: Color::RED }
                                },
                            };
                        },
                    }*/
                    child: Grid {
                        columns: 2,
                        children: (
                            Button {
                                pressed: true,
                                toggle: false,
                                on_changed: |_v| {
                                    self.wave = 0;
                                },
                                child: Svg {
                                    path: "waveforms/saw.svg",
                                    color: Color::RED,
                                },
                            },
                            Button {
                                pressed: true,
                                toggle: false,
                                on_changed: |_v| {
                                    // self.wave = 1;
                                },
                                child: Svg {
                                    path: "waveforms/square.svg",
                                    color: Color::RED,
                                },
                            },
                            Button {
                                pressed: true,
                                toggle: false,
                                on_changed: |_v| {
                                    // self.wave = 1;
                                },
                                child: Svg {
                                    path: "waveforms/sine.svg",
                                    color: Color::RED,
                                },
                            },
                            Button {
                                pressed: true,
                                toggle: false,
                                on_changed: |_v| {
                                    // self.wave = 1;
                                },
                                child: Svg {
                                    path: "waveforms/triangle.svg",
                                    color: Color::RED,
                                },
                            },
                        ),
                    },
                },
                Transform {
                    position: (160, 40),
                    size: (50, 70),
                    child: Knob {
                        text: "Rate",
                        color: Color::RED,
                        value: &mut self.value,
                        feedback: Box::new(|v| format!("{:.2} hz", v * 20.0)),
                    },
                },
            ),
        })
    }

    fn prepare(&self, voice: &mut Self::Voice, sample_rate: u32, block_size: usize) {
        voice.saw.prepare(sample_rate / block_size as u32, 1);
        voice.square.prepare(sample_rate / block_size as u32, 1);
        voice.sine.prepare(sample_rate / block_size as u32, 1);
        voice.triangle.prepare(sample_rate / block_size as u32, 1);
    }

    fn process(&mut self, _vars: &Vars, voice: &mut Self::Voice, inputs: &IO, outputs: &mut IO) {
        let hz = self.value * 20.0;
        let reset = inputs.control[0];

        if voice.last_reset < 0.5 {
            if reset >= 0.5 {
                voice.saw.reset();
                voice.square.reset();
                voice.sine.reset();
                voice.triangle.reset();
            }
        }

        voice.last_reset = reset;

        if self.wave == 0 {
            voice.saw.set_pitch(hz);
            outputs.control[0] = voice.saw.gen();
        } else if self.wave == 1 {
            voice.square.set_pitch(hz);
            outputs.control[0] = voice.square.gen();
        } else if self.wave == 2 {
            voice.sine.set_pitch(hz);
            outputs.control[0] = voice.sine.gen();
        } else if self.wave == 3 {
            voice.triangle.set_pitch(hz);
            outputs.control[0] = voice.triangle.gen();
        }

        println!("{}", outputs.control[0]);
    }
}
